//
//  TranscriptionBackend.swift
//  VoiceFlowShared
//
//  Protocol that all transcription backends must implement. Enables pluggable
//  model support (Whisper, Parakeet, Breeze, GigaAM, Cohere, Moonshine, ...).
//

import Foundation
import AVFoundation

// MARK: - TranscriptionBackend

/// A pluggable transcription backend (Whisper, Parakeet, Breeze, etc.).
///
/// All transcription engines conform to this protocol so the rest of
/// VoiceFlow doesn't need to know which one is active.
///
/// Implementations are typically reference types (classes) because they
/// hold expensive model state loaded in memory.
///
/// ## Lifecycle
///
/// 1. Construct via ``TranscriptionBackendFactory/make(definition:)``
/// 2. Call ``load()`` to initialize the model (async, may download on first use)
/// 3. Call ``transcribe(audio:)`` zero or more times
/// 4. Call ``unload()`` to free resources
///
/// ## Thread Safety
///
/// Implementations must be safe to call from any actor. Methods are `async`
/// to allow backends to do their own internal concurrency.
public protocol TranscriptionBackend: AnyObject, Sendable {
    
    // MARK: - Metadata
    
    /// Stable identifier matching ``ModelDefinition/id``.
    var id: String { get }
    
    /// Display name (matches ``ModelDefinition/displayName``).
    var name: String { get }
    
    /// Backend type identifier.
    var backendType: BackendType { get }
    
    /// Whether this backend is currently loaded and ready to transcribe.
    var isLoaded: Bool { get }
    
    // MARK: - Lifecycle
    
    /// Loads model files and initializes the backend.
    ///
    /// This may take several seconds for large models. Implementations
    /// should report progress if possible.
    func load() async throws
    
    /// Frees all model resources. After `unload`, ``isLoaded`` is `false`.
    func unload() async
    
    // MARK: - Transcription
    
    /// Transcribes a complete audio buffer.
    ///
    /// - Parameter audio: PCM buffer at 16 kHz mono Float32.
    /// - Returns: The transcription result.
    /// - Throws: ``TranscriptionError`` if transcription fails.
    func transcribe(_ audio: AVAudioPCMBuffer) async throws -> TranscriptionResult
    
    /// Transcribes multiple audio buffers in a stream.
    ///
    /// Default implementation just maps over ``transcribe(_:)``.
    /// Backends can override for better performance (e.g. streaming).
    func transcribe<S: Sequence>(
        _ audioBuffers: S
    ) async throws -> [TranscriptionResult] where S.Element == AVAudioPCMBuffer
}

// MARK: - Default Implementations

public extension TranscriptionBackend {
    
    func transcribe<S: Sequence>(
        _ audioBuffers: S
    ) async throws -> [TranscriptionResult] where S.Element == AVAudioPCMBuffer {
        var results: [TranscriptionResult] = []
        for buffer in audioBuffers {
            let result = try await transcribe(buffer)
            results.append(result)
        }
        return results
    }
}

// MARK: - TranscriptionError

/// Errors thrown by transcription backends.
public enum TranscriptionError: LocalizedError, Equatable, Sendable {
    
    /// Backend has not been loaded yet.
    case notLoaded
    
    /// Audio format is not supported by this backend.
    case unsupportedAudioFormat(reason: String)
    
    /// Model file is missing or corrupted.
    case modelMissing(modelId: String)
    
    /// Loading failed.
    case loadFailed(reason: String)
    
    /// Transcription failed.
    case transcriptionFailed(reason: String)
    
    /// Language is not supported by this backend.
    case unsupportedLanguage(Language)
    
    public var errorDescription: String? {
        switch self {
        case .notLoaded:
            return "Transcription backend is not loaded. Call load() first."
        case .unsupportedAudioFormat(let reason):
            return "Unsupported audio format: \(reason)"
        case .modelMissing(let id):
            return "Model '\(id)' is missing. Please download it first."
        case .loadFailed(let reason):
            return "Failed to load model: \(reason)"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .unsupportedLanguage(let lang):
            return "Language '\(lang.displayName)' is not supported by this model."
        }
    }
}
