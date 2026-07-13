//
//  WhisperKitStreamingBackend.swift
//  VoiceFlow
//
//  Streaming variant of WhisperKitBackend for Issue #20c (Live-Partial-Text).
//  Wraps a standard ``WhisperKitBackend`` and exposes chunked streaming
//  transcription via ``TranscriptionBackend/streamTranscribe(audioStream:)``.
//
//  ## Design
//
//  - **Chunk size:** 2 seconds of mono Float32 @ 16 kHz = 32 000 samples
//    (F2 default from the 2026-06-18 decision log).
//  - **Overlap:** 0.5 seconds = 8 000 samples carried forward between
//    chunks to avoid losing phonemes at the boundary.
//  - **Partial-text diff:** naive prefix-match (chunk-stitching, per Marvis
//    resolution of spec §10 question 2). LCS-based diff is deferred to
//    PR-2 (Parakeet-EOU).
//  - **Cancellation:** `continuation.onTermination` cancels the worker
//    task; the worker's `for await` loop is also Task-cancellation-aware.
//
//  ## Constraints
//
//  - Implements the same `TranscriptionBackend` protocol as the batch backend,
//    so existing callers (`TranscriptionService`) keep working — they just
//    opt-in via `supportsStreaming == true`.
//  - `Sendable` conformance is `@unchecked` because `WhisperKitBackend` is
//    `@unchecked Sendable` (the embedded `WhisperKit?` is not strictly
//    Sendable but is read-only after `load`).
//

import AVFoundation
import Foundation
import VoiceFlowShared

// MARK: - WhisperKitStreamingBackend

/// ``TranscriptionBackend`` streaming variant of WhisperKit.
///
/// Aggregates incoming audio into 2-second windows (with 0.5s overlap) and
/// runs the batch ``WhisperKitBackend/transcribe(_:)`` on each window. Each
/// window yields a single ``TranscriptionChunk`` containing the new text
/// since the previous window.
///
/// Chunk size and overlap are tunable via ``init(definition:chunkSize:overlap:)``.
final class WhisperKitStreamingBackend: TranscriptionBackend, @unchecked Sendable {

    // MARK: - Constants

    /// Default chunk size for MVP streaming. 2 s matches the F2 default from
    /// the 2026-06-18 decision log (1–3 s MVP latency OK).
    static let defaultChunkSize: TimeInterval = 2.0

    /// Default overlap carried forward between chunks. 0.5 s is enough to
    /// keep a syllable from being split across two chunk boundaries.
    static let defaultOverlap: TimeInterval = 0.5

    /// Standard sample rate for VoiceFlow's audio pipeline.
    private static let sampleRate: Double = StandardAudioFormat.sampleRate

    // MARK: - Metadata

    let id: String
    let name: String
    let backendType: BackendType = .whisperKit
    private(set) var isLoaded = false

    // MARK: - Streaming Overrides

    var supportsStreaming: Bool { true }
    var isParakeetEOU: Bool { false }

    // MARK: - Configuration

    /// Chunk size in seconds. VoiceFlow uses mono Float32 @ 16 kHz so this
    /// translates to `chunkSize * sampleRate` samples per chunk.
    let chunkSize: TimeInterval

    /// Overlap in seconds carried forward between chunks.
    let overlap: TimeInterval

    // MARK: - Private State

    /// Underlying batch backend. Reused for each chunk's transcription.
    /// Kept private to the streaming wrapper so callers don't accidentally
    /// bypass the streaming surface and call batch directly.
    private let batchBackend: WhisperKitBackend

    // MARK: - Initialization

    /// Creates a streaming Whisper backend for the given model definition.
    /// - Parameters:
    ///   - definition: Must have `backendType == .whisperKit`.
    ///   - chunkSize: Chunk window size in seconds. Defaults to
    ///                ``defaultChunkSize`` (2 s).
    ///   - overlap: Overlap carried forward between chunks in seconds.
    ///              Defaults to ``defaultOverlap`` (0.5 s).
    /// - Throws: If the model name can't be extracted from the source.
    init(
        definition: ModelDefinition,
        chunkSize: TimeInterval = WhisperKitStreamingBackend.defaultChunkSize,
        overlap: TimeInterval = WhisperKitStreamingBackend.defaultOverlap
    ) throws {
        precondition(definition.backendType == .whisperKit)
        precondition(chunkSize > 0, "Chunk size must be positive")
        precondition(overlap >= 0 && overlap < chunkSize, "Overlap must be in [0, chunkSize)")
        self.id = definition.id
        self.name = definition.displayName
        self.chunkSize = chunkSize
        self.overlap = overlap
        self.batchBackend = try WhisperKitBackend(definition: definition)
    }

    // MARK: - Lifecycle

    func load() async throws {
        try await batchBackend.load()
        isLoaded = true
    }

    func unload() async {
        await batchBackend.unload()
        isLoaded = false
    }

    // MARK: - Batch Transcription

    /// Delegates to the underlying ``WhisperKitBackend``. Provided for
    /// callers that want to use the streaming wrapper for batch work too
    /// (e.g. when a stream is cancelled before completion).
    func transcribe(_ audio: AVAudioPCMBuffer) async throws -> TranscriptionResult {
        try await batchBackend.transcribe(audio)
    }

    // MARK: - Streaming Transcription

    /// Streams partial transcription chunks as audio arrives.
    ///
    /// Algorithm:
    /// 1. Aggregate incoming `AudioChunk`s into a rolling buffer until it
    ///    reaches `chunkSize` seconds of audio.
    /// 2. Build a `AVAudioPCMBuffer` for that window (keeping the trailing
    ///    `overlap` seconds for the next chunk).
    /// 3. Run ``WhisperKitBackend/transcribe(_:)`` on the window.
    /// 4. Diff the new text against the previously-emitted text and yield
    ///    the increment as a non-final ``TranscriptionChunk``.
    /// 5. When the input stream finishes, yield a final empty chunk and
    ///    finish the output stream.
    ///
    /// Cancellation: `continuation.onTermination` cancels the worker
    /// task. The worker checks `Task.isCancelled` between chunks and
    /// yields no further chunks after cancellation.
    func streamTranscribe(
        audioStream: AsyncStream<AudioChunk>
    ) -> AsyncStream<TranscriptionChunk> {
        AsyncStream { continuation in
            // Run the worker in a detached task — it doesn't need to be on
            // any specific actor (WhisperKitBackend handles its own isolation).
            let workerTask = Task.detached(priority: .userInitiated) { [chunkSize, overlap, batchBackend] in
                let aggregator = AudioChunkAggregator(
                    sampleRate: Self.sampleRate,
                    chunkSize: chunkSize,
                    overlap: overlap
                )
                var lastChunkText = ""

                for await audioChunk in audioStream {
                    // Honor cancellation between chunks.
                    if Task.isCancelled { break }

                    aggregator.append(audioChunk)
                    guard aggregator.isFull else { continue }

                    guard let windowBuffer = aggregator.flush() else {
                        // Not enough samples to build a buffer — skip.
                        continue
                    }

                    do {
                        let result = try await batchBackend.transcribe(windowBuffer)
                        let increment = Self.diffText(
                            previous: lastChunkText,
                            current: result.text
                        )
                        if !increment.isEmpty {
                            continuation.yield(
                                TranscriptionChunk(
                                    text: increment,
                                    isFinal: false,
                                    confidence: result.confidence,
                                    language: result.language,
                                    audioSequence: audioChunk.sequence
                                )
                            )
                            lastChunkText = result.text
                        }
                    } catch {
                        // Per spec §6: skip the chunk on error; the next chunk
                        // may succeed. Surface via continuation.yield of an
                        // empty (non-final) chunk so consumers know the window
                        // was attempted.
                        continuation.yield(.empty(audioSequence: audioChunk.sequence))
                    }
                }

                // End-of-stream: signal that the stream is done.
                if !Task.isCancelled {
                    continuation.yield(.endOfStream())
                }
                continuation.finish()
            }

            // Marvis review note 2 (2026-06-18): cleanup on consumer cancel.
            continuation.onTermination = { _ in
                workerTask.cancel()
            }
        }
    }

    // MARK: - Diff Helper

    /// Naive chunk-stitching diff: yields only the new portion of `current`
    /// that wasn't already in `previous`.
    ///
    /// Strategy:
    /// - If `current` starts with `previous`, drop the prefix → emit the
    ///   rest. (Common case: chunk-N text starts with chunk-N-1 text.)
    /// - Otherwise emit `current` in full (the model diverged — caller
    ///   probably wants to replace the running transcript).
    /// - If they're identical, emit nothing (avoids duplicate tokens on
    ///   quiet chunks).
    ///
    /// LCS-based diff is deferred to PR-2 (Parakeet-EOU) where re-ordering
    /// of tokens is more common.
    static func diffText(previous: String, current: String) -> String {
        // Identical → nothing new.
        if previous == current { return "" }

        // Common case: current extends previous.
        if current.hasPrefix(previous) {
            let trimmed = current.dropFirst(previous.count)
            // Strip leading whitespace for clean concatenation.
            return String(trimmed).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Diverged: try suffix-overlap. Find the longest suffix of `previous`
        // that matches a prefix of `current`. This handles cases where the
        // model revised its earlier output (e.g. "Hello world" → "Hello there").
        let maxOverlap = min(previous.count, current.count)
        if maxOverlap > 0 {
            for overlapLength in stride(from: maxOverlap, to: 0, by: -1) {
                let prevSuffix = previous.suffix(overlapLength)
                let currPrefix = current.prefix(overlapLength)
                if prevSuffix == currPrefix {
                    let increment = current.dropFirst(overlapLength)
                    let trimmed = String(increment)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? current : trimmed
                }
            }
        }

        // No overlap found: replace entirely.
        return current
    }
}

// MARK: - Audio Chunk Aggregator

/// Accumulates incoming `AudioChunk`s into a rolling buffer of mono Float32
/// samples, exposing `isFull` when enough audio has been collected and
/// `flush()` to extract a window while keeping the trailing overlap.
///
/// Not thread-safe — designed to be owned by a single streaming worker task.
struct AudioChunkAggregator {

    // MARK: - Configuration

    let sampleRate: Double
    let chunkSize: TimeInterval
    let overlap: TimeInterval

    // MARK: - State

    private var samples: [Float] = []

    // MARK: - Computed

    /// Target sample count for a full chunk.
    var targetSamples: Int { Int(chunkSize * sampleRate) }

    /// Overlap sample count (carried forward between flushes).
    var overlapSamples: Int { Int(overlap * sampleRate) }

    /// Whether the rolling buffer holds at least `targetSamples`.
    var isFull: Bool { samples.count >= targetSamples }

    // MARK: - Mutation

    /// Appends an audio chunk's samples to the rolling buffer.
    mutating func append(_ chunk: AudioChunk) {
        samples.append(contentsOf: chunk.samples)
    }

    /// Extracts a window of audio from the rolling buffer.
    ///
    /// Returns `nil` if the rolling buffer doesn't have enough samples to
    /// fill a full window plus the overlap tail. Keeps the trailing
    /// `overlapSamples` in the buffer for the next chunk.
    mutating func flush() -> AVAudioPCMBuffer? {
        guard samples.count >= targetSamples else { return nil }

        // Take exactly `targetSamples` from the front.
        let window = Array(samples.prefix(targetSamples))

        // Keep the trailing overlap for the next chunk.
        let tailStart = max(0, samples.count - overlapSamples)
        samples = Array(samples[tailStart...])

        // Build an AVAudioPCMBuffer from `window`.
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Float(sampleRate),
            channels: 1,
            interleaved: false
        ) else { return nil }

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(window.count)
        ) else { return nil }

        buffer.frameLength = AVAudioFrameCount(window.count)

        // Copy samples into the buffer. Both pointers must be unwrapped for
        // memcpy (matching the pattern in `HomeViewModel.concatenateBuffers`).
        guard let destData = buffer.floatChannelData?[0] else { return nil }
        window.withUnsafeBufferPointer { src in
            guard let base = src.baseAddress else { return }
            memcpy(destData, base, window.count * MemoryLayout<Float>.size)
        }

        return buffer
    }
}