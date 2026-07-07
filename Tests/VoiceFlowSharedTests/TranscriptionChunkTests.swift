//
//  TranscriptionChunkTests.swift
//  VoiceFlowSharedTests
//
//  Unit tests for the streaming I/O types (Issue #20c).
//

import XCTest
@testable import VoiceFlowShared

final class TranscriptionChunkTests: XCTestCase {

    // MARK: - AudioChunk

    func test_audioChunk_durationMatchesFrameCountAndRate() {
        let samples = [Float](repeating: 0, count: 1600)  // 0.1s @ 16kHz
        let chunk = AudioChunk(samples: samples, sampleRate: 16_000)

        XCTAssertEqual(chunk.frameCount, 1600)
        XCTAssertEqual(chunk.duration, 0.1, accuracy: 0.0001)
    }

    func test_audioChunk_zeroDurationWhenEmpty() {
        let chunk = AudioChunk(samples: [], sampleRate: 16_000)
        XCTAssertEqual(chunk.duration, 0)
    }

    func test_audioChunk_zeroDurationWhenSampleRateZero() {
        let chunk = AudioChunk(samples: [0.5, 0.5], sampleRate: 0)
        XCTAssertEqual(chunk.duration, 0)
    }

    func test_audioChunk_isEquatable() {
        let a = AudioChunk(samples: [0.1, 0.2], sampleRate: 16_000, sequence: 1)
        let b = AudioChunk(samples: [0.1, 0.2], sampleRate: 16_000, sequence: 1)
        let c = AudioChunk(samples: [0.1, 0.3], sampleRate: 16_000, sequence: 1)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - TranscriptionChunk

    func test_transcriptionChunk_confidenceClampedToRange() {
        let high = TranscriptionChunk(text: "x", isFinal: false, confidence: 2.0)
        XCTAssertEqual(high.confidence, 1.0)

        let low = TranscriptionChunk(text: "x", isFinal: false, confidence: -1.0)
        XCTAssertEqual(low.confidence, 0.0)
    }

    func test_transcriptionChunk_endOfStream_isFinalAndEmpty() {
        let eos = TranscriptionChunk.endOfStream()
        XCTAssertTrue(eos.isFinal)
        XCTAssertTrue(eos.text.isEmpty)
    }

    func test_transcriptionChunk_empty_isNotFinal() {
        let empty = TranscriptionChunk.empty()
        XCTAssertFalse(empty.isFinal)
        XCTAssertTrue(empty.text.isEmpty)
    }

    func test_transcriptionChunk_isEquatable() {
        let a = TranscriptionChunk(text: "hi", isFinal: false, audioSequence: 1)
        let b = TranscriptionChunk(text: "hi", isFinal: false, audioSequence: 1)
        XCTAssertEqual(a, b)
    }
}