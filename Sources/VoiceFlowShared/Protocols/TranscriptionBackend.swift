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

    // MARK: - Streaming (opt-in)

    /// Whether this backend can stream partial transcriptions as audio arrives.
    ///
    /// Backends that support real-time or chunked streaming override this
    /// to return `true`. Backends that are batch-only inherit the default
    /// (`false`) and should be used via ``transcribe(_:)`` instead.
    ///
    /// Callers should always check this property before invoking
    /// ``streamTranscribe(audioStream:)`` — the default implementation
    /// drains the input stream and yields nothing, which is wasted work
    /// for batch-only backends.
    var supportsStreaming: Bool { get }

    /// Whether this backend is a Parakeet-EOU (low-latency) implementation.
    ///
    /// Replaces the previous `id.contains("parakeet-eou")` string-match
    /// (Marvis review note 3, 2026-06-18). Default is `false`; Parakeet-EOU
    /// backends override to `true`.
    ///
    /// Used by ``ModelRegistry/selectStreamingBackend(for:among:userPreference:)``
    /// to pick a low-latency backend when one is loaded.
    var isParakeetEOU: Bool { get }

    /// Streams partial transcription chunks as audio arrives.
    ///
    /// The returned stream yields text **increments** via
    /// ``TranscriptionChunk`` as the backend finishes processing each
    /// chunk of audio. Callers are responsible for concatenating the
    /// increments to reconstruct the running transcript.
    ///
    /// The stream is finished when the input stream finishes (or the
    /// consumer's task is cancelled). The default implementation drains
    /// the input stream and yields no chunks — useful as a safe no-op for
    /// batch-only backends. Override in streaming-capable backends.
    ///
    /// - Parameter audioStream: Continuous audio chunks at the backend's
    ///   expected rate (typically 16 kHz mono Float32 for VoiceFlow).
    /// - Returns: `AsyncStream<TranscriptionChunk>` of partial increments.
    func streamTranscribe(
        audioStream: AsyncStream<AudioChunk>
    ) -> AsyncStream<TranscriptionChunk>
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

    // MARK: Streaming defaults

    /// Default: batch-only backends don't stream. Override to `true` in streaming backends.
    var supportsStreaming: Bool { false }

    /// Default: this is not a Parakeet-EOU backend. Override to `true` in Parakeet-EOU impls.
    var isParakeetEOU: Bool { false }

    /// Default streaming implementation.
    ///
    /// Drains the input stream (so the producer doesn't block) and yields
    /// an empty output stream. Safe to call on batch-only backends — the
    /// caller will get zero chunks and can fall back to batch
    /// ``transcribe(_:)`` if needed.
    ///
    /// Marvis review note 2 (2026-06-18): uses `continuation.onTermination`
    /// to cancel the drain task when the consumer cancels, preventing a
    /// resource leak when callers don't check ``supportsStreaming``.
    func streamTranscribe(
        audioStream: AsyncStream<AudioChunk>
    ) -> AsyncStream<TranscriptionChunk> {
        AsyncStream { continuation in
            // Drain the input stream to avoid producer backpressure.
            let drainTask = Task.detached(priority: .background) {
                for await _ in audioStream {
                    // Discard — batch-only backends don't produce partials.
                }
                continuation.finish()
            }
            // If the consumer cancels the output stream, stop the drain task
            // so the input stream is freed (no resource leak).
            continuation.onTermination = { _ in
                drainTask.cancel()
            }
        }
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
