//
//  ModelDefinition.swift
//  VoiceFlowShared
//
//  Catalog entry describing a transcription model. Used by ModelRegistry
//  and ModelManager to present and download models.
//

import Foundation

// MARK: - ModelDefinition

/// Catalog entry describing a transcription model.
///
/// A `ModelDefinition` is the static, immutable description of a model:
/// what it is, where to get it, what it can do. The actual loaded model
/// is represented by a ``TranscriptionBackend`` instance.
public struct ModelDefinition: Identifiable, Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Identity
    
    /// Stable identifier (e.g. "whisper-base", "parakeet-tdt-v3").
    public let id: String
    
    /// Display name shown to users (e.g. "Whisper Base").
    public let displayName: String
    
    /// Short tagline (e.g. "Fast and balanced").
    public let description: String
    
    /// Maintainer/creator (e.g. "OpenAI", "NVIDIA").
    public let author: String
    
    // MARK: - Performance
    
    /// Download size in bytes (approximate).
    public let sizeBytes: Int64
    
    /// Accuracy score (1–5). Higher = more accurate.
    public let accuracyScore: Int
    
    /// Speed score (1–5). Higher = faster.
    public let speedScore: Int
    
    // MARK: - Capabilities
    
    /// Languages this model supports (excluding `.auto`).
    public let supportedLanguages: [Language]
    
    /// Whether the model supports auto-detection of language.
    public let supportsAutoDetection: Bool
    
    // MARK: - Source
    
    /// Where to download this model from.
    public let source: ModelSource
    
    /// Backend type to use for inference.
    public let backendType: BackendType
    
    // MARK: - Metadata
    
    /// License (e.g. "MIT", "Apache 2.0").
    public let license: String
    
    /// When this model definition was added (informational only).
    public let addedAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: String,
        displayName: String,
        description: String,
        author: String,
        sizeBytes: Int64,
        accuracyScore: Int,
        speedScore: Int,
        supportedLanguages: [Language],
        supportsAutoDetection: Bool = false,
        source: ModelSource,
        backendType: BackendType,
        license: String,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.author = author
        self.sizeBytes = sizeBytes
        self.accuracyScore = accuracyScore
        self.speedScore = speedScore
        self.supportedLanguages = supportedLanguages
        self.supportsAutoDetection = supportsAutoDetection
        self.source = source
        self.backendType = backendType
        self.license = license
        self.addedAt = addedAt
    }
}

// MARK: - Computed Properties

public extension ModelDefinition {
    
    /// Human-readable size string (e.g. "74 MB", "1.5 GB").
    var sizeString: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
    
    /// Visual representation of accuracy score (filled bars out of 5).
    var accuracyBars: String {
        String(repeating: "█", count: accuracyScore) +
        String(repeating: "░", count: 5 - accuracyScore)
    }
    
    /// Visual representation of speed score (filled bars out of 5).
    var speedBars: String {
        String(repeating: "█", count: speedScore) +
        String(repeating: "░", count: 5 - speedScore)
    }
    
    /// Whether this model supports a specific language.
    func supports(_ language: Language) -> Bool {
        guard language.isConcrete else { return true }
        return supportedLanguages.contains(language)
    }
    
    /// Whether this model is multilingual (supports > 5 languages).
    var isMultilingual: Bool {
        supportedLanguages.count > 5
    }
    
    /// Brief language summary (e.g. "Multilingual (99+)" or "Russian").
    var languageSummary: String {
        if isMultilingual {
            return "Multilingual (\(supportedLanguages.count)+)"
        }
        if supportsAutoDetection {
            return "Multilingual"
        }
        return supportedLanguages.map(\.displayName).joined(separator: ", ")
    }
}

// MARK: - Built-in Definitions

public extension ModelDefinition {
    
    /// Whisper Tiny (39 MB, fastest, lower accuracy).
    static let whisperTiny = ModelDefinition(
        id: "whisper-tiny",
        displayName: "Whisper Tiny",
        description: "Fastest model, lower accuracy. Good for quick notes.",
        author: "OpenAI",
        sizeBytes: 39_000_000,
        accuracyScore: 3,
        speedScore: 5,
        supportedLanguages: Language.allCases.filter { $0.isConcrete },
        supportsAutoDetection: true,
        source: .whisperKit(model: "tiny"),
        backendType: .whisperKit,
        license: "MIT"
    )
    
    /// Whisper Base (74 MB, balanced — recommended default).
    static let whisperBase = ModelDefinition(
        id: "whisper-base",
        displayName: "Whisper Base",
        description: "Balanced accuracy and speed. Recommended for most users.",
        author: "OpenAI",
        sizeBytes: 74_000_000,
        accuracyScore: 4,
        speedScore: 5,
        supportedLanguages: Language.allCases.filter { $0.isConcrete },
        supportsAutoDetection: true,
        source: .whisperKit(model: "base"),
        backendType: .whisperKit,
        license: "MIT"
    )
    
    /// Whisper Small (244 MB, better accuracy).
    static let whisperSmall = ModelDefinition(
        id: "whisper-small",
        displayName: "Whisper Small",
        description: "Higher accuracy, slower. Great for important recordings.",
        author: "OpenAI",
        sizeBytes: 244_000_000,
        accuracyScore: 5,
        speedScore: 3,
        supportedLanguages: Language.allCases.filter { $0.isConcrete },
        supportsAutoDetection: true,
        source: .whisperKit(model: "small"),
        backendType: .whisperKit,
        license: "MIT"
    )
}

// MARK: - Mock Helpers

#if DEBUG
public extension ModelDefinition {
    
    /// Mock model for testing.
    static let mock = ModelDefinition.whisperBase
}
#endif
