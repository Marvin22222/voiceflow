//
//  TranscriptionChunk.swift
//  VoiceFlowShared
//
//  Streaming types for live partial transcription (Issue #20c).
//  AudioChunk carries a slice of captured audio through the streaming pipeline.
//  TranscriptionChunk carries the partial text increment that a streaming
//  backend produces for each completed chunk.
//
//  These types are intentionally decoupled from AVAudioPCMBuffer / String so
//  the streaming surface doesn't depend on the input encoding. PR-1 (WhisperKit)
//  bridges AVAudioPCMBuffer → AudioChunk internally. Future PRs (Parakeet-EOU)
//  can keep the same surface even if their internal representation changes.
//

import Foundation

// MARK: - AudioChunk

/// A slice of captured audio passed through the streaming pipeline.
///
/// AudioChunk is `Sendable` so it can cross actor boundaries safely. The
/// `samples` payload is a normalized mono Float32 array at ``sampleRate``
/// Hz — same shape as what the rest of VoiceFlow feeds into its batch
/// transcribers, so converting from `AVAudioPCMBuffer` is cheap.
public struct AudioChunk: Sendable, Equatable {

    // MARK: - Properties

    /// Mono Float32 PCM samples in chronological order. Length is `frameCount`.
    public let samples: [Float]

    /// Sample rate of `samples` in Hz. Typically 16 000 for VoiceFlow's standard format.
    public let sampleRate: Double

    /// When this chunk was captured. Used for telemetry + UI ordering.
    public let timestamp: Date

    /// Monotonically increasing sequence number, assigned by the producer.
    /// Consumers use this to detect gaps and reorder if needed.
    public let sequence: UInt64

    // MARK: - Computed Properties

    /// Number of audio frames in this chunk. Equivalent to `samples.count`.
    public var frameCount: Int { samples.count }

    /// Duration of this chunk in seconds (samples / sampleRate).
    public var duration: TimeInterval {
        guard sampleRate > 0 else { return 0 }
        return Double(frameCount) / sampleRate
    }

    // MARK: - Initialization

    /// Creates an audio chunk.
    /// - Parameters:
    ///   - samples: Mono Float32 PCM samples.
    ///   - sampleRate: Sample rate in Hz.
    ///   - timestamp: Capture timestamp. Defaults to `Date()`.
    ///   - sequence: Producer-assigned sequence number. Defaults to `0`.
    public init(
        samples: [Float],
        sampleRate: Double,
        timestamp: Date = Date(),
        sequence: UInt64 = 0
    ) {
        self.samples = samples
        self.sampleRate = sampleRate
        self.timestamp = timestamp
        self.sequence = sequence
    }
}

// MARK: - TranscriptionChunk

/// A single output unit from a streaming transcription backend.
///
/// Streaming backends emit one ``TranscriptionChunk`` each time they finish
/// processing a chunk of audio. `text` is an **increment** (new text not
/// previously yielded for this stream) — callers concatenate increments to
/// reconstruct the running transcript.
///
/// `isFinal == true` marks the closing chunk for the current stream. After
/// receiving a final chunk, callers should expect the stream to finish.
public struct TranscriptionChunk: Sendable, Equatable {

    // MARK: - Properties

    /// The new (incremental) text yielded by the backend for this chunk.
    /// Empty if the backend produced no new text for this window.
    public let text: String

    /// Whether this is the final chunk of the stream.
    /// `true` ⇒ the backend is done and no further chunks will be yielded.
    /// `false` ⇒ more chunks may follow.
    public let isFinal: Bool

    /// Confidence score in `0.0…1.0`. Backend-specific. Default `1.0`.
    public let confidence: Double

    /// Detected (or pre-set) language for this chunk.
    public let language: Language

    /// When this chunk was produced. Set by the backend.
    public let timestamp: Date

    /// Identifier of the chunk's audio input. Mirrors ``AudioChunk/sequence``
    /// from the producer, when available.
    public let audioSequence: UInt64

    // MARK: - Initialization

    /// Creates a transcription chunk.
    /// - Parameters:
    ///   - text: Incremental text yielded by the backend.
    ///   - isFinal: Whether this is the closing chunk of the stream.
    ///   - confidence: Confidence score (`0.0…1.0`). Defaults to `1.0`.
    ///   - language: Detected or pre-set language. Defaults to ``Language/auto``.
    ///   - timestamp: When the chunk was produced. Defaults to `Date()`.
    ///   - audioSequence: Sequence number of the input audio chunk.
    public init(
        text: String,
        isFinal: Bool,
        confidence: Double = 1.0,
        language: Language = .auto,
        timestamp: Date = Date(),
        audioSequence: UInt64 = 0
    ) {
        self.text = text
        self.isFinal = isFinal
        self.confidence = max(0.0, min(1.0, confidence))
        self.language = language
        self.timestamp = timestamp
        self.audioSequence = audioSequence
    }
}

// MARK: - Convenience

public extension TranscriptionChunk {

    /// A final empty chunk — used by backends to signal end-of-stream without text.
    static func endOfStream(audioSequence: UInt64 = 0) -> TranscriptionChunk {
        TranscriptionChunk(text: "", isFinal: true, audioSequence: audioSequence)
    }

    /// A non-final empty chunk — used by backends to ack a chunk they couldn't process.
    static func empty(audioSequence: UInt64 = 0) -> TranscriptionChunk {
        TranscriptionChunk(text: "", isFinal: false, audioSequence: audioSequence)
    }
}