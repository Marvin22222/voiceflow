//
//  BackendType.swift
//  VoiceFlowShared
//
//  Enumeration of supported transcription backends.
//

import Foundation

// MARK: - BackendType

/// Identifies which transcription backend implementation to use for a model.
///
/// Used by ``ModelRegistry`` and ``ModelManager`` to construct the right
/// ``TranscriptionBackend`` instance when a model is loaded.
public enum BackendType: String, Codable, CaseIterable, Hashable, Sendable {
    
    /// WhisperKit (Argmax) — supports Whisper models.
    case whisperKit
    
    /// FluidAudio (FluidInference) — supports Parakeet models on Apple Silicon.
    case fluidAudio
    
    /// Apple CoreML — for custom-converted models (e.g. Breeze ASR).
    case coreML
    
    /// ONNX Runtime — for models in ONNX format (e.g. GigaAM).
    case onnx
    
    /// Mock backend for testing.
    case mock
}

// MARK: - Display Properties

public extension BackendType {
    
    /// Human-readable name for UI display.
    var displayName: String {
        switch self {
        case .whisperKit: return "WhisperKit"
        case .fluidAudio: return "FluidAudio"
        case .coreML: return "Core ML"
        case .onnx: return "ONNX Runtime"
        case .mock: return "Mock (Testing)"
        }
    }
    
    /// SF Symbol for visual representation.
    var symbolName: String {
        switch self {
        case .whisperKit: return "waveform"
        case .fluidAudio: return "drop.fill"
        case .coreML: return "cpu"
        case .onnx: return "square.stack.3d.up"
        case .mock: return "hammer"
        }
    }
}
