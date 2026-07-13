//
//  TranscriptionRecord.swift
//  VoiceFlow
//
//  SwiftData @Model for persisting transcription history.
//

import Foundation
import SwiftData
import VoiceFlowShared

// MARK: - TranscriptionRecord

/// A saved transcription in the app's history.
///
/// Persisted via SwiftData. Audio is NOT stored — only the resulting text.
@Model
final class TranscriptionRecord {
    
    // MARK: - Properties
    
    /// Unique identifier.
    @Attribute(.unique) var id: UUID
    
    /// Transcribed text.
    var text: String
    
    /// Detected language code.
    var languageCode: String
    
    /// Confidence score (0.0–1.0).
    var confidence: Double
    
    /// Backend that produced the transcription.
    var backendName: String
    
    /// When the transcription was created.
    var createdAt: Date
    
    /// Duration of the source audio in seconds.
    var audioDuration: TimeInterval
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        text: String,
        languageCode: String,
        confidence: Double,
        backendName: String,
        createdAt: Date = Date(),
        audioDuration: TimeInterval
    ) {
        self.id = id
        self.text = text
        self.languageCode = languageCode
        self.confidence = confidence
        self.backendName = backendName
        self.createdAt = createdAt
        self.audioDuration = audioDuration
    }
    
    // MARK: - Convenience
    
    /// The detected language as a typed enum.
    var language: Language {
        Language(rawValue: languageCode) ?? .unknown
    }
    
    /// Constructs a record from a ``TranscriptionResult``.
    convenience init(from result: TranscriptionResult) {
        self.init(
            text: result.text,
            languageCode: result.language.rawValue,
            confidence: result.confidence,
            backendName: result.backendName,
            audioDuration: result.audioDuration
        )
    }
}
