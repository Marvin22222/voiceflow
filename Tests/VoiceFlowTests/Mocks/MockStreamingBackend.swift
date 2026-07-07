//
//  MockStreamingBackend.swift
//  VoiceFlowTests
//
//  Test doubles for the streaming-transcription surface (Issue #20c).
//

import AVFoundation
import Foundation
import VoiceFlowShared

#if canImport(VoiceFlow)
@testable import VoiceFlow
#endif

// MARK: - MockStreamingBackend

/// A streaming-capable mock backend for unit tests.
///
/// Configurable behavior:
/// - `textPerChunk`: yields one of these strings (cycled) per chunk.
/// - `chunksToYield`: total chunks to emit before finishing (default unlimited).
/// - `delayBetweenChunks`: artificial delay to simulate inference time.
/// - `isParakeetEOU`: whether this mock should be recognized as Parakeet-EOU.
final class MockStreamingBackend: TranscriptionBackend, @unchecked Sendable {

    // MARK: - Configuration

    let id: String
    let name: String
    let backendType: BackendType
    let isParakeetEOUBool: Bool

    /// Texts to emit, one per chunk. Empty = emit empty chunks only.
    var textPerChunk: [String]

    /// Maximum chunks to emit before finishing. `nil` = no limit.
    var chunksToYield: Int?

    /// Artificial delay between chunks (in nanoseconds).
    var delayBetweenChunks: UInt64

    // MARK: - Metadata Overrides

    var supportsStreaming: Bool { true }
    var isParakeetEOU: Bool { isParakeetEOUBool }

    private(set) var isLoaded = false

    // MARK: - Streaming Observation

    /// Sequence numbers of chunks this backend has emitted (for assertions).
    private(set) var emittedSequences: [UInt64] = []
    private let stateLock = NSLock()

    // MARK: - Init

    init(
        id: String = "mock-streaming",
        name: String = "Mock Streaming",
        backendType: BackendType = .mock,
        isParakeetEOU: Bool = false,
        textPerChunk: [String] = ["hello world", "this is a test"],
        chunksToYield: Int? = nil,
        delayBetweenChunks: UInt64 = 0
    ) {
        self.id = id
        self.name = name
        self.backendType = backendType
        self.isParakeetEOUBool = isParakeetEOU
        self.textPerChunk = textPerChunk
        self.chunksToYield = chunksToYield
        self.delayBetweenChunks = delayBetweenChunks
    }

    // MARK: - Lifecycle

    func load() async throws {
        isLoaded = true
    }

    func unload() async {
        isLoaded = false
    }

    // MARK: - Batch Transcription

    func transcribe(_ audio: AVAudioPCMBuffer) async throws -> TranscriptionResult {
        guard isLoaded else { throw TranscriptionError.notLoaded }
        return TranscriptionResult(
            text: textPerChunk.first ?? "",
            backendName: name,
            audioDuration: audio.duration
        )
    }

    // MARK: - Streaming Transcription

    func streamTranscribe(
        audioStream: AsyncStream<AudioChunk>
    ) -> AsyncStream<TranscriptionChunk> {
        AsyncStream { continuation in
            let worker = Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                var index = 0

                for await chunk in audioStream {
                    if Task.isCancelled { break }

                    if let limit = self.chunksToYield, index >= limit {
                        break
                    }

                    // Record observation.
                    self.stateLock.lock()
                    self.emittedSequences.append(chunk.sequence)
                    self.stateLock.unlock()

                    if self.delayBetweenChunks > 0 {
                        try? await Task.sleep(nanoseconds: self.delayBetweenChunks)
                    }

                    let text: String
                    if self.textPerChunk.isEmpty {
                        text = ""
                    } else {
                        text = self.textPerChunk[index % self.textPerChunk.count]
                    }
                    index += 1

                    continuation.yield(
                        TranscriptionChunk(
                            text: text,
                            isFinal: false,
                            language: .english,
                            audioSequence: chunk.sequence
                        )
                    )
                }

                if !Task.isCancelled {
                    continuation.yield(.endOfStream())
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                worker.cancel()
            }
        }
    }
}

// MARK: - MockBatchOnlyBackend

/// A mock backend that uses the protocol's default streaming impl.
///
/// Used in tests to verify the default implementation drains the input
/// without yielding chunks. Inherits `supportsStreaming == false` and the
/// drain-only `streamTranscribe` from the protocol extension.
final class MockBatchOnlyBackend: TranscriptionBackend, @unchecked Sendable {
    let id = "mock-batch-only"
    let name = "Mock Batch-Only"
    let backendType: BackendType = .mock
    private(set) var isLoaded = false

    func load() async throws { isLoaded = true }
    func unload() async { isLoaded = false }

    func transcribe(_ audio: AVAudioPCMBuffer) async throws -> TranscriptionResult {
        guard isLoaded else { throw TranscriptionError.notLoaded }
        return TranscriptionResult(text: "batch result", backendName: name, audioDuration: audio.duration)
    }
}