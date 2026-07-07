//
//  HomeViewModel.swift
//  VoiceFlow
//
//  ViewModel for HomeView. Manages recording state and result display.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI
import UIKit
import VoiceFlowShared

// MARK: - HomeViewModel

/// ViewModel for ``HomeView``. Owns recording state and result.
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Whether audio is currently being captured.
    @Published var isRecording = false
    
    /// Whether audio is being transcribed.
    @Published var isTranscribing = false
    
    /// The most recent transcription result (nil until first recording).
    @Published var lastResult: TranscriptionResult?
    
    /// Currently displayed transcribed text (editable).
    @Published var transcribedText: String = ""
    
    /// Currently active model.
    @Published var activeModel: ModelDefinition?
    
    /// Available models for quick selection.
    @Published var availableModels: [ModelDefinition] = []
    
    /// Error message to show in UI (if any).
    @Published var errorMessage: String?
    
    /// Live audio level (0.0 to 1.0, normalized from dB).
    @Published var audioLevel: Float = 0
    
    /// Rolling buffer of normalized RMS values for the live waveform.
    /// Stores up to ``maxAudioLevels`` entries (oldest first).
    /// Updated only while ``isRecording`` is `true`; freezes at last value otherwise
    /// so the View can render the final state until the next session starts.
    @Published var audioLevels: [Float] = []

    /// Live partial transcription text yielded by the streaming backend during
    /// the current recording session (Issue #20c).
    ///
    /// Empty when no streaming session is active. Appended as the streaming
    /// backend yields new increments. Reset by ``resetLivePartialText``.
    @Published var livePartialText: String = ""

    /// Indicates whether a streaming transcription session is currently active.
    /// Useful for the UI to show a "Live" badge or to gate the partial-text view.
    @Published var isStreaming: Bool = false

    // MARK: - Audio Level Constants
    
    /// Maximum number of bars rendered in the live waveform (Issue #20 spec).
    private static let maxAudioLevels = 30
    
    /// EMA smoothing factor for RMS amplitude. Lower = smoother, higher = more responsive.
    private static let rmsSmoothingAlpha: Float = 0.3
    
    // MARK: - Dependencies
    
    private let audioService: AudioCaptureService
    private let transcriptionService: TranscriptionService
    private let modelManager: ModelManager
    
    // MARK: - Private State

    private var collectedAudio: [AVAudioPCMBuffer] = []
    private var bufferSubscription: AnyCancellable?

    /// Long-running streaming transcription task (Issue #20c).
    /// Created in ``startStreamingIfAvailable`` when a streaming-capable
    /// backend is loaded and a session starts. Cancelled in ``stopRecording``
    /// and ``cancelRecording``.
    private var streamingTask: Task<Void, Never>?

    /// The streaming backend instance selected for this session. Nil when
    /// no streaming backend is available or when streaming is disabled.
    private var streamingBackend: (any TranscriptionBackend)?

    /// Smoothed RMS amplitude (EMA) carried across buffers. Reset in ``resetAudioLevels``.
    private var smoothedRMS: Float = 0
    
    /// Start time of the current recording session (single source of truth for duration UI).
    /// `nil` when not recording. Read by ``RecordingView`` via TimelineView to drive MM:SS counter.
    @Published var recordingStartTime: Date?
    
    // MARK: - Initialization
    
    init(
        audioService: AudioCaptureService = AudioCaptureService(),
        transcriptionService: TranscriptionService,
        modelManager: ModelManager
    ) {
        self.audioService = audioService
        self.transcriptionService = transcriptionService
        self.modelManager = modelManager
    }
    
    // MARK: - Lifecycle
    
    func onAppear() async {
        await loadModels()
        await ensureActiveModelLoaded()
    }
    
    // MARK: - Public Actions
    
    /// Starts recording. Called by hold-to-talk.
    func startRecording() async {
        guard !isRecording else { return }

        errorMessage = nil
        collectedAudio = []
        resetLivePartialText()
        recordingStartTime = Date()

        do {
            try await audioService.start()
            subscribeToAudioBuffers()
            await startStreamingIfAvailable()
            isRecording = true
            AppGroup.setRecordingStatus(.recording)
        } catch {
            errorMessage = error.localizedDescription
            isRecording = false
        }
    }
    
    /// Stops recording and starts transcription. Called on release.
    func stopRecording() async {
        guard isRecording else { return }

        await audioService.stop()
        bufferSubscription?.cancel()
        bufferSubscription = nil
        isRecording = false
        recordingStartTime = nil
        cancelStreamingTask()

        guard !collectedAudio.isEmpty else {
            AppGroup.setRecordingStatus(.idle)
            return
        }

        await transcribeCollectedAudio()
    }
    
    /// Cancels the current recording without transcription. Buffers are discarded.
    /// Called from the Cancel button in ``RecordingView``.
    func cancelRecording() async {
        guard isRecording else { return }

        // Tactile confirmation that the recording was discarded.
        // Apple recommends preparing the generator up front to minimize
        // latency on the first notification.
        let cancelHaptic = UINotificationFeedbackGenerator()
        cancelHaptic.prepare()
        cancelHaptic.notificationOccurred(.warning)

        await audioService.stop()
        bufferSubscription?.cancel()
        bufferSubscription = nil
        cancelStreamingTask()
        collectedAudio = []
        isRecording = false
        recordingStartTime = nil
        resetLivePartialText()
        errorMessage = nil
        AppGroup.setRecordingStatus(.idle)
    }
    
    /// Copies the current transcribed text to clipboard.
    func copyToClipboard() {
        UIPasteboard.general.string = transcribedText
    }
    
    /// Clears the current result.
    func clearResult() {
        transcribedText = ""
        lastResult = nil
    }
    
    // MARK: - Private Methods
    
    private func loadModels() async {
        availableModels = modelManager.installedModels
    }
    
    private func ensureActiveModelLoaded() async {
        guard let model = availableModels.first ?? ModelDefinition.whisperBase as ModelDefinition? else {
            return
        }
        
        activeModel = model
        do {
            try await transcriptionService.setActiveModel(model)
        } catch {
            errorMessage = "Failed to load model: \(error.localizedDescription)"
        }
    }
    
    private func subscribeToAudioBuffers() {
        // Defensive reset: clear any stale data from the previous session
        // before the new Combine subscription starts emitting.
        resetAudioLevels()
        bufferSubscription = audioService.audioBufferPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buffer in
                self?.handleAudioBuffer(buffer)
            }
    }
    
    @MainActor
    private func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // VM stops updates when not recording. The audioLevels array freezes at
        // its last value, which the View continues to render (frozen-on-stop).
        guard isRecording else { return }
        
        collectedAudio.append(buffer)
        let rawRMS = Self.computeRMS(buffer)
        // EMA smoothing on the current value (not the whole array).
        smoothedRMS = Self.rmsSmoothingAlpha * rawRMS
            + (1 - Self.rmsSmoothingAlpha) * smoothedRMS
        let normalized = Self.normalizeDB(smoothedRMS)
        
        audioLevels.append(normalized)
        if audioLevels.count > Self.maxAudioLevels {
            audioLevels.removeFirst(audioLevels.count - Self.maxAudioLevels)
        }
        audioLevel = normalized
    }
    
    /// Clears the rolling audio levels buffer. Called from ``subscribeToAudioBuffers``
    /// at session start; also exposed publicly for manual reset (e.g., after error paths).
    func resetAudioLevels() {
        audioLevels = []
        smoothedRMS = 0
    }

    /// Resets the live partial-transcription text (Issue #20c).
    /// Called from session start (via ``startRecording``) and on cancel.
    func resetLivePartialText() {
        livePartialText = ""
        isStreaming = false
    }

    /// Selects a streaming-capable backend for the current session and starts
    /// the long-running streaming task that consumes the audio publisher.
    ///
    /// No-op if no streaming-capable backend is loaded or if the active model
    /// doesn't support streaming. The selection respects the user's
    /// ``StreamingPreference`` via ``ModelRegistry/selectStreamingBackend(for:among:userPreference:)``.
    private func startStreamingIfAvailable() async {
        // Tear down any leftover task before starting a new one.
        cancelStreamingTask()

        guard activeModel != nil else { return }

        // Read the user-configured streaming preference from UserDefaults
        // (matches `@AppStorage` key in `SettingsView`).
        let preference = StreamingPreference.storedValue()

        // Candidate backends: the active backend if it supports streaming,
        // otherwise an empty list (no other backends are loaded in MVP).
        var candidates: [any TranscriptionBackend] = []
        if let backend = transcriptionService.activeBackend, backend.supportsStreaming {
            candidates.append(backend)
        }

        // For the MVP, hint with `.auto` — backend auto-detects language on
        // each chunk. A future PR will pass the user's preferred language here.
        guard let selected = ModelRegistry.selectStreamingBackend(
            for: .auto,
            among: candidates,
            userPreference: preference
        ) else {
            // No streaming backend available — silently fall back to batch
            // transcription after stop. No live partial text is shown.
            return
        }

        streamingBackend = selected

        // Build the audio stream from the existing Combine publisher.
        let audioStream = AudioCapturePublisherStream.makeStream(
            from: audioService.audioBufferPublisher
        )

        // Start the streaming task. It runs for the lifetime of the recording
        // session and forwards partial chunks into `livePartialText`.
        isStreaming = true
        streamingTask = Task { [weak self] in
            guard let self else { return }
            for await chunk in selected.streamTranscribe(audioStream: audioStream) {
                if Task.isCancelled { break }
                await self.appendLivePartialChunk(chunk)
                if chunk.isFinal { break }
            }
            await self.markStreamingFinished()
        }
    }

    /// Appends a streaming ``TranscriptionChunk`` to ``livePartialText``.
    ///
    /// Concatenates with a leading space when needed. No-op for empty chunks.
    private func appendLivePartialChunk(_ chunk: TranscriptionChunk) {
        let text = chunk.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if livePartialText.isEmpty {
            livePartialText = text
        } else {
            livePartialText += " " + text
        }
    }

    /// Marks streaming as finished and clears internal backend handle.
    private func markStreamingFinished() {
        isStreaming = false
        streamingBackend = nil
    }

    /// Cancels and discards the active streaming task. Safe to call when no
    /// task is active.
    private func cancelStreamingTask() {
        streamingTask?.cancel()
        streamingTask = nil
        streamingBackend = nil
        isStreaming = false
    }
    
    /// Computes RMS (Root Mean Square) amplitude from a 32-bit float PCM buffer.
    /// Returns 0 for empty or non-float buffers.
    private static func computeRMS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }
        var sumOfSquares: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sumOfSquares += sample * sample
        }
        return (sumOfSquares / Float(frameLength)).squareRoot()
    }
    
    /// Maps RMS amplitude to 0–1 with -50 dB floor and 0 dB ceiling (linear interp).
    /// -50 dB floor matches audio-meter standards for speech; below-floor = 0, above-ceiling = 1.
    private static func normalizeDB(_ rms: Float) -> Float {
        // Clamp away from log(0) — smallest representable Float that still maps to floor.
        let safeRMS = max(rms, 1e-7)
        let db = 20 * log10(safeRMS)
        let clampedDB = max(-50.0, min(0.0, db))
        return Float((clampedDB + 50.0) / 50.0)
    }
    
    private func transcribeCollectedAudio() async {
        guard !collectedAudio.isEmpty else { return }
        
        isTranscribing = true
        AppGroup.setRecordingStatus(.processing)
        defer {
            isTranscribing = false
            AppGroup.setRecordingStatus(.idle)
        }
        
        // Concatenate all buffers into one
        guard let combined = concatenateBuffers(collectedAudio) else {
            errorMessage = "Could not combine audio buffers"
            return
        }
        
        do {
            let result = try await transcriptionService.transcribe(combined)
            lastResult = result
            transcribedText = result.text
            AppGroup.setPendingText(result.text)
        } catch {
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            AppGroup.setRecordingStatus(.error)
        }
    }
    
    private func concatenateBuffers(_ buffers: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer? {
        guard !buffers.isEmpty else { return nil }
        
        let format = buffers[0].format
        let totalFrames = buffers.reduce(0) { $0 + Int($1.frameLength) }
        
        guard let output = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(totalFrames)
        ) else { return nil }
        
        output.frameLength = AVAudioFrameCount(totalFrames)
        
        // Copy samples
        guard let sourceData = buffers[0].floatChannelData?[0],
              let destData = output.floatChannelData?[0] else {
            return nil
        }
        
        var offset = 0
        for buffer in buffers {
            guard let channelData = buffer.floatChannelData?[0] else { continue }
            let frameCount = Int(buffer.frameLength)
            memcpy(destData.advanced(by: offset), channelData, frameCount * MemoryLayout<Float>.size)
            offset += frameCount
        }
        
        return output
        // Suppress unused warning
        _ = sourceData
    }
}
