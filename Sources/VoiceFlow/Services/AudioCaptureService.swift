//
//  AudioCaptureService.swift
//  VoiceFlow
//
//  Captures microphone audio and streams PCM buffers to subscribers.
//

import AVFoundation
import Combine
import Foundation
import VoiceFlowShared

// MARK: - AudioCaptureError

/// Errors thrown by ``AudioCaptureService``.
enum AudioCaptureError: LocalizedError {
    case permissionDenied
    case audioSessionConfigurationFailed(underlying: Error)
    case engineStartFailed(underlying: Error)
    case alreadyRecording
    case notRecording
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied. Please enable it in Settings."
        case .audioSessionConfigurationFailed(let err):
            return "Could not configure audio session: \(err.localizedDescription)"
        case .engineStartFailed(let err):
            return "Could not start audio engine: \(err.localizedDescription)"
        case .alreadyRecording:
            return "Audio capture is already in progress."
        case .notRecording:
            return "Audio capture is not running."
        }
    }
}

// MARK: - AudioCaptureService

/// Captures microphone audio using `AVAudioEngine` and publishes PCM buffers.
///
/// Buffers are published as 16 kHz mono Float32 (see ``StandardAudioFormat``).
/// Subscribe to ``audioBufferPublisher`` to receive buffers in real-time.
///
/// ## Example
///
/// ```swift
/// let service = AudioCaptureService()
/// service.audioBufferPublisher
///     .sink { buffer in
///         // Process buffer (e.g. accumulate for transcription)
///     }
///     .store(in: &cancellables)
///
/// try await service.start()
/// // ... later
/// await service.stop()
/// ```
@MainActor
final class AudioCaptureService {
    
    // MARK: - Public Properties
    
    /// Publisher that emits PCM buffers as they're captured.
    ///
    /// Buffers are at 16 kHz mono Float32 (see ``StandardAudioFormat``).
    var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> {
        audioBufferSubject.eraseToAnyPublisher()
    }
    
    /// Whether audio capture is currently active.
    private(set) var isRecording = false
    
    /// Current audio level in dB FS (decibels relative to full scale).
    /// Range: typically -160 (silence) to 0 (max).
    var currentLevel: Float = -160
    
    /// Duration of current recording session, in seconds.
    var recordingDuration: TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Private Properties
    
    private let audioEngine = AVAudioEngine()
    private let audioBufferSubject = PassthroughSubject<AVAudioPCMBuffer, Never>()
    private var recordingStartTime: Date?
    private var levelTimer: Timer?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Requests microphone permission if not already granted.
    /// - Returns: `true` if permission is granted, `false` otherwise.
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// Starts audio capture. Requests permission if needed.
    /// - Throws: ``AudioCaptureError`` if permission denied or engine fails to start.
    func start() async throws {
        guard !isRecording else {
            throw AudioCaptureError.alreadyRecording
        }
        
        // 1. Request permission
        let granted = await requestPermission()
        guard granted else {
            throw AudioCaptureError.permissionDenied
        }
        
        // 2. Configure audio session
        do {
            try configureAudioSession()
        } catch {
            throw AudioCaptureError.audioSessionConfigurationFailed(underlying: error)
        }
        
        // 3. Install tap on input node
        installAudioTap()
        
        // 4. Start engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            throw AudioCaptureError.engineStartFailed(underlying: error)
        }
        
        // 5. Update state
        recordingStartTime = Date()
        isRecording = true
        startLevelMonitoring()
    }
    
    /// Stops audio capture and cleans up resources.
    func stop() async {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        stopLevelMonitoring()
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        recordingStartTime = nil
        isRecording = false
        currentLevel = -160
    }
    
    // MARK: - Private Methods: Audio Session
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .record,
            mode: .measurement,
            options: [.duckOthers]
        )
        try session.setPreferredSampleRate(StandardAudioFormat.sampleRate)
        try session.setPreferredIOBufferDuration(0.1)  // 100ms latency
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Private Methods: Tap Installation
    
    private func installAudioTap() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap with buffer size 4096 frames (~256ms at 16kHz)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: inputFormat
        ) { [weak self] buffer, _ in
            // Convert to standard format if needed
            guard let normalized = buffer.normalizedForTranscription() else {
                return
            }
            
            Task { @MainActor [weak self] in
                self?.audioBufferSubject.send(normalized)
            }
        }
    }
    
    // MARK: - Private Methods: Level Monitoring
    
    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateCurrentLevel()
            }
        }
    }
    
    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    private func updateCurrentLevel() {
        // Average power of last buffer can be computed via meters,
        // but a simple approximation: track the last buffer's peak
        // (this is a simplified level — production should use AVAudioRecorder meters)
        // For now, we'll just compute peak from last emitted buffer
        
        // (Simplified implementation — production should use audio meter)
        // In a full implementation, we'd keep a reference to the last buffer
        // and compute its RMS level here.
    }
}
