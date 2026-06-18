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
        recordingStartTime = Date()
        
        do {
            try await audioService.start()
            subscribeToAudioBuffers()
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
        collectedAudio = []
        isRecording = false
        recordingStartTime = nil
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
