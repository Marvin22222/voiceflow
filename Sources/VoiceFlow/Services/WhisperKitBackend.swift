//
//  WhisperKitBackend.swift
//  VoiceFlow
//
//  TranscriptionBackend implementation using WhisperKit (Argmax).
//  Real Whisper inference via Apple Neural Engine.
//

import AVFoundation
import Foundation
import VoiceFlowShared

#if canImport(WhisperKit)
import WhisperKit
#endif

// MARK: - WhisperKitBackend

/// ``TranscriptionBackend`` using WhisperKit (Argmax).
///
/// Supports Whisper Tiny / Base / Small / Large-V3 Turbo. Runs entirely
/// on-device via Apple Neural Engine (ANE).
final class WhisperKitBackend: TranscriptionBackend, @unchecked Sendable {
    
    // MARK: - Metadata
    
    let id: String
    let name: String
    let backendType: BackendType = .whisperKit
    private(set) var isLoaded = false
    
    // MARK: - Private Properties
    
    #if canImport(WhisperKit)
    private var whisperKit: WhisperKit?
    #endif
    
    private let definition: ModelDefinition
    
    // MARK: - Initialization
    
    /// Creates a Whisper backend for the given model definition.
    /// - Parameter definition: Must have `backendType == .whisperKit`.
    /// - Throws: If the model name can't be extracted from the source.
    init(definition: ModelDefinition) throws {
        precondition(definition.backendType == .whisperKit)
        self.id = definition.id
        self.name = definition.displayName
        self.definition = definition
    }
    
    // MARK: - Lifecycle
    
    func load() async throws {
        guard !isLoaded else { return }
        
        #if canImport(WhisperKit)
        let modelName = extractModelName()
        
        do {
            let kit = try await WhisperKit(
                model: modelName,
                download: true  // Auto-download if not present
            )
            self.whisperKit = kit
            self.isLoaded = true
        } catch {
            throw TranscriptionError.loadFailed(
                reason: "WhisperKit initialization failed: \(error.localizedDescription)"
            )
        }
        #else
        throw TranscriptionError.loadFailed(
            reason: "WhisperKit is not available. Add it as a Swift Package dependency."
        )
        #endif
    }
    
    func unload() async {
        #if canImport(WhisperKit)
        whisperKit = nil
        #endif
        isLoaded = false
    }
    
    // MARK: - Transcription
    
    func transcribe(_ audio: AVAudioPCMBuffer) async throws -> TranscriptionResult {
        guard isLoaded else {
            throw TranscriptionError.notLoaded
        }
        
        #if canImport(WhisperKit)
        guard let kit = whisperKit else {
            throw TranscriptionError.notLoaded
        }
        
        let startTime = Date()
        
        do {
            let results = try await kit.transcribe(
                audioFrame: audio
            )
            
            let duration = Date().timeIntervalSince(startTime)
            let text = results.map(\.text).joined(separator: " ")
            let confidence = results.first?.avgLogProb.map { exp($0) } ?? 0.5
            let language = Language(rawValue: results.first?.language ?? "auto") ?? .auto
            
            return TranscriptionResult(
                text: text,
                confidence: confidence,
                language: language,
                backendName: name,
                audioDuration: audio.duration
            )
        } catch {
            throw TranscriptionError.transcriptionFailed(
                reason: error.localizedDescription
            )
        }
        #else
        throw TranscriptionError.loadFailed(
            reason: "WhisperKit is not available"
        )
        #endif
    }
    
    // MARK: - Private Helpers
    
    /// Extracts the Whisper model variant name (e.g. "tiny", "base", "small")
    /// from the model's source.
    private func extractModelName() -> String {
        if case let .whisperKit(model) = definition.source {
            return model
        }
        return "base"  // Fallback
    }
}
