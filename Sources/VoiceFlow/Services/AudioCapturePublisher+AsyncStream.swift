//
//  AudioCapturePublisher+AsyncStream.swift
//  VoiceFlow
//
//  Combine → AsyncStream adapter for the streaming-transcription pipeline
//  (Issue #20c, Marvis review note 4 — 2026-06-18).
//
//  `AudioCaptureService.audioBufferPublisher` is a Combine
//  `AnyPublisher<AVAudioPCMBuffer, Never>`. The streaming backend surface
//  consumes `AsyncStream<AudioChunk>`. This file provides the conversion.
//
//  Why a dedicated file:
//  - Keeps `AudioCaptureService` unaware of streaming concerns
//    (single-responsibility).
//  - Centralizes the lifecycle management so the streaming pipeline can
//    cancel the Combine subscription cleanly when the consumer goes away.
//

import AVFoundation
import Combine
import Foundation
import VoiceFlowShared

// MARK: - AudioCapturePublisherStream

/// AsyncStream-producing wrapper around a Combine `AnyPublisher<AVAudioPCMBuffer, Never>`.
///
/// Produces an `AsyncStream<AudioChunk>` that emits one element for each
/// upstream buffer, with a monotonic sequence number and the buffer's
/// capture timestamp. The stream uses `.bufferingNewest(2)` so a slow
/// consumer (e.g. a busy WhisperKit forward-pass) doesn't accumulate
/// audio indefinitely — only the two most recent buffers are retained.
///
/// ## Lifecycle
///
/// - The returned `AsyncStream` finishes when the upstream publisher
///   completes (never, for `AudioCaptureService.audioBufferPublisher`) or
///   when the consumer cancels.
/// - Cancellation of the consumer's task cancels the Combine subscription
///   via `continuation.onTermination`, so the upstream stops emitting.
enum AudioCapturePublisherStream {

    // MARK: - Public API

    /// Converts a Combine audio-buffer publisher into an `AsyncStream<AudioChunk>`.
    ///
    /// - Parameter publisher: The upstream publisher. Typically
    ///   `AudioCaptureService.audioBufferPublisher`.
    /// - Returns: An `AsyncStream<AudioChunk>` that emits each upstream
    ///   buffer as a chunk. Sequence numbers are assigned in arrival order.
    static func makeStream(
        from publisher: AnyPublisher<AVAudioPCMBuffer, Never>
    ) -> AsyncStream<AudioChunk> {
        AsyncStream<AudioChunk>(bufferingPolicy: .bufferingNewest(2)) { continuation in
            // Sequence counter — captured by the sink closure, only mutated
            // from the publisher's emission thread (Combine delivers on the
            // thread the value is sent from; for AudioCaptureService that's
            // MainActor). Safe to be a value-captured Int because Combine
            // serializes emissions on a single scheduler in practice — but
            // we still mark it as state to silence strict-concurrency.
            let state = SequenceState()

            // Build the subscription and retain it via the closure capture.
            // Combine's `sink` returns an AnyCancellable; we keep it alive
            // by storing it in a local variable that the closure captures.
            var cancellable: AnyCancellable?
            cancellable = publisher.sink(
                receiveCompletion: { _ in
                    // AudioCaptureService's publisher never completes in practice,
                    // but if it does (e.g. test scenarios), honor it.
                    continuation.finish()
                },
                receiveValue: { buffer in
                    let chunk = Self.makeChunk(buffer: buffer, state: state)
                    continuation.yield(chunk)
                }
            )

            // Consumer cancellation → tear down the upstream subscription.
            // Marvis review note 2 (2026-06-18): cleanup on consumer cancel
            // prevents the producer (audio engine) from continuing to push
            // values that nobody is consuming.
            continuation.onTermination = { _ in
                cancellable?.cancel()
                cancellable = nil
            }
        }
    }

    // MARK: - Private Helpers

    /// Wraps an `AVAudioPCMBuffer` as an `AudioChunk`, extracting samples
    /// from `floatChannelData[0]` into a Sendable `[Float]` array.
    ///
    /// Note: we copy the samples into a new `[Float]` rather than wrapping
    /// the buffer directly, because `AVAudioPCMBuffer` is not `Sendable`
    /// and would trigger Swift 6 strict-concurrency warnings.
    private static func makeChunk(
        buffer: AVAudioPCMBuffer,
        state: SequenceState
    ) -> AudioChunk {
        let sampleRate = buffer.format.sampleRate
        let sequence = state.next()

        guard let channelData = buffer.floatChannelData?[0] else {
            return AudioChunk(samples: [], sampleRate: sampleRate, sequence: sequence)
        }

        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else {
            return AudioChunk(samples: [], sampleRate: sampleRate, sequence: sequence)
        }

        // Copy the samples into a Sendable `[Float]`.
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))

        return AudioChunk(
            samples: samples,
            sampleRate: sampleRate,
            timestamp: Date(),
            sequence: sequence
        )
    }
}

// MARK: - Sequence State

/// Mutable counter holder for monotonic chunk sequence numbers.
///
/// Implemented as a class so the `AudioCapturePublisherStream`'s sink
/// closure can mutate the counter by reference. Internally synchronized
/// via a lock because Combine's `sink` may deliver on arbitrary threads
/// (in practice it's MainActor for our publisher, but we don't rely on that).
private final class SequenceState: @unchecked Sendable {
    private let lock = NSLock()
    private var counter: UInt64 = 0

    func next() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        counter += 1
        return counter
    }
}