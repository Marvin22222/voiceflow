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
    
    // MARK: - Dependencies
    
    private let audioService: AudioCaptureService
    private let transcriptionService: TranscriptionService
    private let modelManager: ModelManager
    
    // MARK: - Private State
    
    private var collectedAudio: [AVAudioPCMBuffer] = []
    private var bufferSubscription: AnyCancellable?
    private var recordingStartTime: Date?
    
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
        
        guard !collectedAudio.isEmpty else {
            AppGroup.setRecordingStatus(.idle)
            return
        }
        
        await transcribeCollectedAudio()
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
        bufferSubscription = audioService.audioBufferPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buffer in
                self?.handleAudioBuffer(buffer)
            }
    }
    
    private func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        collectedAudio.append(buffer)
        // TODO: Update audioLevel based on buffer amplitude
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

// MARK: - UIKit Bridge

import UIKit
