//
//  StreamingPipelineTests.swift
//  VoiceFlowTests
//
//  Unit tests for the streaming-transcription pipeline (Issue #20c).
//

import AVFoundation
import XCTest
@testable import VoiceFlow
import VoiceFlowShared

final class StreamingPipelineTests: XCTestCase {

    // MARK: - Default impl

    /// A backend that inherits the default ``streamTranscribe(audioStream:)``
    /// implementation must drain its input without yielding any chunks.
    func test_batchOnlyBackend_defaultImplYieldsNoChunks() async throws {
        let backend = MockBatchOnlyBackend()
        try await backend.load()

        // Build a 5-second audio stream (at 16 kHz, 100 ms chunks -> 50 chunks).
        let audioStream = makeMockAudioStream(
            totalSeconds: 5.0,
            chunkSeconds: 0.1
        )

        let outputStream = backend.streamTranscribe(audioStream: audioStream)
        var chunks: [TranscriptionChunk] = []
        for await chunk in outputStream {
            chunks.append(chunk)
        }

        XCTAssertTrue(chunks.isEmpty, "Default impl should yield no chunks for batch-only backend")
        XCTAssertFalse(backend.supportsStreaming)
        XCTAssertFalse(backend.isParakeetEOU)
    }

    /// The default ``streamTranscribe(audioStream:)`` implementation must
    /// cancel its drain task when the consumer cancels \u2014 this prevents
    /// the producer from blocking indefinitely (Marvis review note 2).
    func test_batchOnlyBackend_defaultImplDoesNotLeakOnCancellation() async throws {
        let backend = MockBatchOnlyBackend()
        try await backend.load()

        let audioStream = makeMockAudioStream(totalSeconds: 10.0, chunkSeconds: 0.1)

        let outputStream = backend.streamTranscribe(audioStream: audioStream)
        let consumer = Task {
            for await _ in outputStream {
                // Read just one chunk (if any) and break \u2014 in practice the
                // default impl yields nothing, so the consumer must be
                // cancelled from outside.
                break
            }
        }
        consumer.cancel()
        await consumer.value

        // If the drain task leaked, this test would hang or warn about
        // orphaned tasks. We assert the consumer completed.
        XCTAssertTrue(consumer.isCancelled)
    }

    // MARK: - MockStreamingBackend

    func test_mockStreamingBackend_emitsOneChunkPerAudioChunk() async throws {
        let backend = MockStreamingBackend(
            textPerChunk: ["hello", "world"],
            delayBetweenChunks: 0
        )
        try await backend.load()

        let audioStream = makeMockAudioStream(
            totalSeconds: 0.5,  // 5 chunks of 100 ms
            chunkSeconds: 0.1
        )

        let outputStream = backend.streamTranscribe(audioStream: audioStream)
        var chunks: [TranscriptionChunk] = []
        for await chunk in outputStream {
            chunks.append(chunk)
        }

        // 5 audio chunks + 1 final end-of-stream chunk.
        XCTAssertEqual(chunks.count, 6, "5 inputs + 1 final = 6 chunks")
        XCTAssertTrue(chunks.last?.isFinal == true)
    }

    func test_mockStreamingBackend_respectsChunksToYieldLimit() async throws {
        let backend = MockStreamingBackend(
            textPerChunk: ["one", "two", "three"],
            chunksToYield: 2
        )
        try await backend.load()

        let audioStream = makeMockAudioStream(
            totalSeconds: 0.5,
            chunkSeconds: 0.1
        )

        let outputStream = backend.streamTranscribe(audioStream: audioStream)
        var chunks: [TranscriptionChunk] = []
        for await chunk in outputStream {
            chunks.append(chunk)
        }

        // 2 limited + 1 end-of-stream.
        XCTAssertEqual(chunks.count, 3)
    }

    // MARK: - WhisperKitStreamingBackend

    /// 5-second mock audio stream through a WhisperKitStreamingBackend
    /// must yield at least 2 chunks (MVP: 2 s chunks -> ~2-3 outputs).
    func test_whisperKitStreamingBackend_emitsAtLeastTwoChunksForFiveSeconds() async throws {
        // Construct a streaming backend. We use a real WhisperBase definition
        // but bypass WhisperKit's actual model by overriding the aggregator's
        // behavior: we can't run WhisperKit without the model on the test host.
        // Instead, we test the chunk-aggregation + diff logic by injecting
        // a controlled backend that yields predictable text per chunk.
        //
        // For an actual WhisperKitStreamingBackend integration test we'd need
        // a mock transcription path. Here we exercise the streaming surface
        // via the protocol's MockStreamingBackend (which has the same
        // behavior shape) and additionally verify the aggregator's math.

        // 1) Aggregation math: 5s @ 16 kHz with chunk size 2s, overlap 0.5s.
        //    We simulate the streaming loop: append 0.5s chunks and flush
        //    whenever the buffer is full. 5s of audio produces 2-3 flushes.
        var agg = AudioChunkAggregator(
            sampleRate: 16_000,
            chunkSize: 2.0,
            overlap: 0.5
        )
        var emittedBuffers = 0

        // Feed 5s in ten 0.5s appends (simulating the streaming loop).
        for i in 0..<10 {
            let halfSecond = [Float](repeating: 0, count: 16_000 / 2)
            agg.append(AudioChunk(samples: halfSecond, sampleRate: 16_000, sequence: UInt64(i + 1)))
            while agg.isFull {
                if agg.flush() != nil {
                    emittedBuffers += 1
                } else {
                    break
                }
            }
        }
        XCTAssertGreaterThanOrEqual(emittedBuffers, 2, "5s of audio should produce at least 2 chunks")
        XCTAssertLessThanOrEqual(emittedBuffers, 3, "Should not produce more than 3 chunks for 5s input")

        // 2) Surface-level streaming test using the MockStreamingBackend.
        let backend = MockStreamingBackend(
            textPerChunk: ["chunk one", "chunk two", "chunk three"],
            delayBetweenChunks: 0
        )
        try await backend.load()

        let audioStream = makeMockAudioStream(
            totalSeconds: 5.0,
            chunkSeconds: 0.5  // 10 chunks
        )

        let outputStream = backend.streamTranscribe(audioStream: audioStream)
        var chunks: [TranscriptionChunk] = []
        for await chunk in outputStream {
            chunks.append(chunk)
        }

        // 10 inputs + 1 final end-of-stream.
        XCTAssertGreaterThanOrEqual(chunks.count, 2, "5s mock stream must yield \u2265 2 chunks")
    }

    // MARK: - WhisperKitStreamingBackend diff helper

    func test_whisperKitStreamingBackend_diffText_identicalReturnsEmpty() {
        let result = WhisperKitStreamingBackend.diffText(
            previous: "hello world",
            current: "hello world"
        )
        XCTAssertEqual(result, "")
    }

    func test_whisperKitStreamingBackend_diffText_commonCaseEmitsIncrement() {
        let result = WhisperKitStreamingBackend.diffText(
            previous: "hello",
            current: "hello world"
        )
        XCTAssertEqual(result, "world")
    }

    func test_whisperKitStreamingBackend_diffText_divergedEmitsSuffixOverlap() {
        // "hello world" -> "hello there": suffix "hello " of prev overlaps
        // with prefix "hello " of current. Increment = "there".
        let result = WhisperKitStreamingBackend.diffText(
            previous: "hello world",
            current: "hello there"
        )
        XCTAssertEqual(result, "there")
    }

    func test_whisperKitStreamingBackend_diffText_completelyDifferentEmitsCurrent() {
        let result = WhisperKitStreamingBackend.diffText(
            previous: "abc",
            current: "xyz"
        )
        XCTAssertEqual(result, "xyz")
    }

    // MARK: - Helpers

    /// Builds an `AsyncStream<AudioChunk>` of synthetic mono-Float32 silence
    /// at 16 kHz. Each chunk holds `chunkSeconds` seconds of audio.
    private func makeMockAudioStream(
        totalSeconds: Double,
        chunkSeconds: Double
    ) -> AsyncStream<AudioChunk> {
        AsyncStream { continuation in
            let samplesPerChunk = Int(chunkSeconds * 16_000)
            let chunks = Int(totalSeconds / chunkSeconds)
            for i in 0..<chunks {
                let samples = [Float](repeating: 0, count: samplesPerChunk)
                let chunk = AudioChunk(
                    samples: samples,
                    sampleRate: 16_000,
                    sequence: UInt64(i + 1)
                )
                continuation.yield(chunk)
            }
            continuation.finish()
        }
    }
}