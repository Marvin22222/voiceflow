//
//  TranscriptionService.swift
//  VoiceFlow
//
//  High-level transcription facade. Manages the active backend and
//  provides a simple API for the rest of the app.
//

import AVFoundation
import Foundation
import VoiceFlowShared

// MARK: - TranscriptionService

/// High-level facade for transcription operations.
///
/// Manages a single active ``TranscriptionBackend`` instance and routes
/// transcription requests to it. Provides a simple, stable API that
/// hides the complexity of model loading, backend selection, etc.
///
/// ## Lifecycle
///
/// ```swift
/// let service = TranscriptionService(modelRegistry: .shared)
/// try await service.setActiveModel(.whisperBase)
/// let result = try await service.transcribe(audioBuffer)
/// ```
@MainActor
final class TranscriptionService {
    
    // MARK: - Published State
    
    /// The currently active model definition.
    private(set) var activeModel: ModelDefinition?
    
    /// The loaded backend instance (nil if no model is loaded).
    private(set) var activeBackend: (any TranscriptionBackend)?
    
    /// Whether a transcription is currently in progress.
    private(set) var isTranscribing = false
    
    // MARK: - Dependencies
    
    private let modelRegistry: ModelRegistry
    private let backendFactory: TranscriptionBackendFactory
    
    // MARK: - Initialization
    
    init(
        modelRegistry: ModelRegistry = .shared,
        backendFactory: TranscriptionBackendFactory = .live
    ) {
        self.modelRegistry = modelRegistry
        self.backendFactory = backendFactory
    }
    
    // MARK: - Public API: Active Model
    
    /// Sets the active model. Loads it if not already loaded.
    /// - Parameter model: The model to activate.
    /// - Throws: If the model can't be loaded.
    func setActiveModel(_ model: ModelDefinition) async throws {
        // No-op if already active and loaded
        if activeModel?.id == model.id, activeBackend?.isLoaded == true {
            return
        }
        
        // Unload previous backend
        await activeBackend?.unload()
        activeBackend = nil
        
        // Construct new backend
        let backend = try backendFactory.make(definition: model)
        try await backend.load()
        
        activeBackend = backend
        activeModel = model
    }
    
    // MARK: - Public API: Transcription
    
    /// Transcribes an audio buffer using the active model.
    /// - Parameter audio: PCM buffer in standard format.
    /// - Returns: The transcription result.
    /// - Throws: If no model is active, or transcription fails.
    func transcribe(_ audio: AVAudioPCMBuffer) async throws -> TranscriptionResult {
        guard let backend = activeBackend else {
            throw TranscriptionError.notLoaded
        }
        
        isTranscribing = true
        defer { isTranscribing = false }
        
        return try await backend.transcribe(audio)
    }
}

// MARK: - TranscriptionBackendFactory

/// Factory for constructing ``TranscriptionBackend`` instances from ``ModelDefinition``s.
struct TranscriptionBackendFactory: Sendable {
    
    /// Closure that produces a backend for a given model definition.
    let make: @Sendable (ModelDefinition) throws -> any TranscriptionBackend
    
    /// Live factory that produces real backends.
    static let live = TranscriptionBackendFactory { definition in
        switch definition.backendType {
        case .whisperKit:
            return try WhisperKitBackend(definition: definition)
            
        case .fluidAudio, .coreML, .onnx:
            // TODO: Implement as Phase 1.5/2 progresses
            throw TranscriptionError.loadFailed(
                reason: "Backend \(definition.backendType.displayName) is not yet implemented"
            )
            
        case .mock:
            return MockTranscriptionBackend(definition: definition)
        }
    }
    
    /// Test factory that always returns a mock backend.
    static let mock = TranscriptionBackendFactory { definition in
        MockTranscriptionBackend(definition: definition)
    }
}

// MARK: - MockTranscriptionBackend

/// A transcription backend that returns canned results. For testing/previews.
final class MockTranscriptionBackend: TranscriptionBackend, @unchecked Sendable {
    
    let id: String
    let name: String
    let backendType: BackendType = .mock
    private(set) var isLoaded = false
    
    private let mockText: String
    
    init(definition: ModelDefinition, mockText: String = "Mock transcription result") {
        self.id = definition.id
        self.name = definition.displayName
        self.mockText = mockText
    }
    
    func load() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)  // Simulate 0.5s load
        isLoaded = true
    }
    
    func unload() async {
        isLoaded = false
    }
    
    func transcribe(_ audio: AVAudioPCMBuffer) async throws -> TranscriptionResult {
        guard isLoaded else { throw TranscriptionError.notLoaded }
        try await Task.sleep(nanoseconds: 1_000_000_000)  // Simulate 1s inference
        
        return TranscriptionResult(
            text: mockText,
            confidence: 0.99,
            language: .english,
            backendName: name,
            audioDuration: audio.duration
        )
    }
}
