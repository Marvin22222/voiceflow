//
//  TranscriptionResult.swift
//  VoiceFlowShared
//
//  Result of a transcription operation. Shared between main app, keyboard
//  extension, and any other consumers.
//

import Foundation

// MARK: - TranscriptionResult

/// Result of a single transcription operation.
///
/// Contains the transcribed text plus metadata about the source audio
/// and detection confidence. Codable so it can be shared via App Group
/// `UserDefaults` or written to disk.
public struct TranscriptionResult: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// The transcribed text. Empty if transcription failed.
    public let text: String
    
    /// Confidence score in range 0.0–1.0. Backend-specific.
    public let confidence: Double
    
    /// The language detected (or explicitly set).
    public let language: Language
    
    /// When the transcription was completed.
    public let timestamp: Date
    
    /// Which backend produced the result.
    public let backendName: String
    
    /// Duration of the source audio in seconds.
    public let audioDuration: TimeInterval
    
    // MARK: - Initialization
    
    /// Creates a new transcription result.
    /// - Parameters:
    ///   - text: The transcribed text.
    ///   - confidence: Confidence score (0.0–1.0). Defaults to 1.0.
    ///   - language: Language detected or specified. Defaults to ``Language/auto``.
    ///   - timestamp: When transcription completed. Defaults to now.
    ///   - backendName: Name of the backend that produced this result.
    ///   - audioDuration: Duration of the source audio in seconds.
    public init(
        text: String,
        confidence: Double = 1.0,
        language: Language = .auto,
        timestamp: Date = Date(),
        backendName: String,
        audioDuration: TimeInterval
    ) {
        self.text = text
        self.confidence = max(0.0, min(1.0, confidence))
        self.language = language
        self.timestamp = timestamp
        self.backendName = backendName
        self.audioDuration = audioDuration
    }
}

// MARK: - Computed Properties

public extension TranscriptionResult {
    
    /// Whether the result contains any non-whitespace text.
    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Word count of the transcribed text.
    var wordCount: Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
    }
    
    /// Character count of the transcribed text (excluding whitespace).
    var characterCount: Int {
        text.filter { !$0.isWhitespace }.count
    }
    
    /// Whether the confidence score indicates a reliable result (≥ 0.7).
    var isHighConfidence: Bool {
        confidence >= 0.7
    }
    
    /// Processing speed in seconds per second of audio.
    var realtimeFactor: Double {
        guard audioDuration > 0 else { return 0 }
        return audioDuration > 0 ? 1.0 : 0  // populated by transcriber if available
    }
}

// MARK: - Factory Methods

public extension TranscriptionResult {
    
    /// An empty result, used as a placeholder.
    static let empty = TranscriptionResult(
        text: "",
        backendName: "none",
        audioDuration: 0
    )
}

// MARK: - Mock Helpers

#if DEBUG
public extension TranscriptionResult {
    
    /// Mock result for testing and previews.
    static let mock = TranscriptionResult(
        text: "Hello, this is a test transcription.",
        confidence: 0.95,
        language: .english,
        backendName: "Whisper Base",
        audioDuration: 2.5
    )
    
    /// Mock German result for testing.
    static let mockGerman = TranscriptionResult(
        text: "Hallo, das ist eine Testtranskription.",
        confidence: 0.93,
        language: .german,
        backendName: "Whisper Base",
        audioDuration: 3.0
    )
}
#endif
