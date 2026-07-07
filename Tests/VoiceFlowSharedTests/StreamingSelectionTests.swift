//
//  StreamingSelectionTests.swift
//  VoiceFlowSharedTests
//
//  Unit tests for the streaming-backend selection factory
//  (Issue #20c — ModelRegistry.selectStreamingBackend).
//

import XCTest
@testable import VoiceFlowShared

final class StreamingSelectionTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a mock Parakeet-EOU backend.
    /// We can't construct the real ``ParakeetEOUBackend`` (it's not implemented
    /// yet — PR-2 work), so the test relies on the protocol's default
    /// ``isParakeetEOU`` being overridden. The mock factory is provided
    /// here as a closure so the tests don't depend on any test-only module.
    private func parakeet(id: String = "parakeet-eou") -> MockBackendForTests {
        MockBackendForTests(id: id, backendType: .fluidAudio, isParakeetEOU: true)
    }

    /// Creates a mock WhisperKit backend.
    private func whisper(id: String = "whisper-base") -> MockBackendForTests {
        MockBackendForTests(id: id, backendType: .whisperKit, isParakeetEOU: false)
    }

    // MARK: - Tests: Default impl

    func test_batchOnlyBackend_defaultSupportsStreamingIsFalse() {
        let backend = MockBackendForTests(
            id: "batch",
            backendType: .whisperKit,
            isParakeetEOU: false
        )
        XCTAssertFalse(backend.supportsStreaming)
        XCTAssertFalse(backend.isParakeetEOU)
    }

    // MARK: - Tests: Auto-selection (default preference)

    func test_autoPreference_picksParakeetForEnglish() {
        let parakeetBackend = parakeet()
        let whisperBackend = whisper()

        let selected = ModelRegistry.selectStreamingBackend(
            for: .english,
            among: [whisperBackend, parakeetBackend],
            userPreference: .auto
        )

        XCTAssertEqual(selected?.id, parakeetBackend.id)
    }

    func test_autoPreference_picksParakeetForGerman() {
        let selected = ModelRegistry.selectStreamingBackend(
            for: .german,
            among: [whisper(), parakeet()],
            userPreference: .auto
        )

        XCTAssertEqual(selected?.id, "parakeet-eou")
    }

    func test_autoPreference_picksParakeetForFrench() {
        let selected = ModelRegistry.selectStreamingBackend(
            for: .french,
            among: [whisper(), parakeet()],
            userPreference: .auto
        )

        XCTAssertEqual(selected?.id, "parakeet-eou")
    }

    func test_autoPreference_fallsBackToWhisperForMandarin() {
        // Mandarin is NOT in the low-latency list -> WhisperKit wins.
        let selected = ModelRegistry.selectStreamingBackend(
            for: .mandarinSimplified,
            among: [whisper(), parakeet()],
            userPreference: .auto
        )

        XCTAssertEqual(selected?.id, "whisper-base")
    }

    func test_autoPreference_returnsNilWhenNoStreamingBackendAvailable() {
        let batchOnly = MockBackendForTests(
            id: "batch",
            backendType: .whisperKit,
            isParakeetEOU: false
        )

        let selected = ModelRegistry.selectStreamingBackend(
            for: .english,
            among: [batchOnly],
            userPreference: .auto
        )

        XCTAssertNil(selected)
    }

    func test_autoPreference_picksWhisperWhenParakeetMissing() {
        // Parakeet not loaded -> only WhisperKit available -> picks WhisperKit.
        let selected = ModelRegistry.selectStreamingBackend(
            for: .english,
            among: [whisper()],
            userPreference: .auto
        )

        XCTAssertEqual(selected?.id, "whisper-base")
    }

    // MARK: - Tests: forceWhisperKit preference

    func test_forceWhisperKit_neverPicksParakeet_evenForEnglish() {
        let selected = ModelRegistry.selectStreamingBackend(
            for: .english,
            among: [whisper(), parakeet()],
            userPreference: .forceWhisperKit
        )

        XCTAssertEqual(selected?.id, "whisper-base")
    }

    func test_forceWhisperKit_worksForMandarin() {
        let selected = ModelRegistry.selectStreamingBackend(
            for: .mandarinSimplified,
            among: [whisper(), parakeet()],
            userPreference: .forceWhisperKit
        )

        XCTAssertEqual(selected?.id, "whisper-base")
    }

    // MARK: - Tests: forceLowLatency preference

    func test_forceLowLatency_picksParakeetForEnglish() {
        let selected = ModelRegistry.selectStreamingBackend(
            for: .english,
            among: [whisper(), parakeet()],
            userPreference: .forceLowLatency
        )

        XCTAssertEqual(selected?.id, "parakeet-eou")
    }

    func test_forceLowLatency_fallsBackToWhisperForMandarin() {
        // Parakeet can't handle Mandarin -> forced fallback to WhisperKit.
        let selected = ModelRegistry.selectStreamingBackend(
            for: .mandarinSimplified,
            among: [whisper(), parakeet()],
            userPreference: .forceLowLatency
        )

        XCTAssertEqual(selected?.id, "whisper-base")
    }

    func test_forceLowLatency_fallsBackWhenParakeetMissing() {
        let selected = ModelRegistry.selectStreamingBackend(
            for: .english,
            among: [whisper()],
            userPreference: .forceLowLatency
        )

        XCTAssertEqual(selected?.id, "whisper-base")
    }

    // MARK: - Tests: Switch exhaustiveness (compile-time guarantee)

    /// All Language cases are explicitly handled in ``isLowLatencyCandidate``.
    /// This test exercises one case per switch arm so that adding a new
    /// language forces a compile-time update to the factory (the test
    /// itself will surface which case needs to be classified).
    func test_isLowLatencyCandidate_classifiesAllKnownCases() {
        // True cases (low-latency eligible).
        XCTAssertTrue(isLowLatencyCandidate(.auto))
        XCTAssertTrue(isLowLatencyCandidate(.english))
        XCTAssertTrue(isLowLatencyCandidate(.german))
        XCTAssertTrue(isLowLatencyCandidate(.french))
        XCTAssertTrue(isLowLatencyCandidate(.spanish))
        XCTAssertTrue(isLowLatencyCandidate(.italian))
        XCTAssertTrue(isLowLatencyCandidate(.portuguese))
        XCTAssertTrue(isLowLatencyCandidate(.dutch))
        XCTAssertTrue(isLowLatencyCandidate(.polish))
        XCTAssertTrue(isLowLatencyCandidate(.czech))
        XCTAssertTrue(isLowLatencyCandidate(.swedish))
        XCTAssertTrue(isLowLatencyCandidate(.norwegian))
        XCTAssertTrue(isLowLatencyCandidate(.danish))
        XCTAssertTrue(isLowLatencyCandidate(.finnish))
        XCTAssertTrue(isLowLatencyCandidate(.hungarian))
        XCTAssertTrue(isLowLatencyCandidate(.romanian))
        XCTAssertTrue(isLowLatencyCandidate(.greek))
        XCTAssertTrue(isLowLatencyCandidate(.ukrainian))
        XCTAssertTrue(isLowLatencyCandidate(.bulgarian))

        // False cases.
        XCTAssertFalse(isLowLatencyCandidate(.unknown))
        XCTAssertFalse(isLowLatencyCandidate(.russian))
        XCTAssertFalse(isLowLatencyCandidate(.japanese))
        XCTAssertFalse(isLowLatencyCandidate(.korean))
        XCTAssertFalse(isLowLatencyCandidate(.mandarinSimplified))
        XCTAssertFalse(isLowLatencyCandidate(.mandarinTraditional))
        XCTAssertFalse(isLowLatencyCandidate(.vietnamese))
        XCTAssertFalse(isLowLatencyCandidate(.thai))
        XCTAssertFalse(isLowLatencyCandidate(.hindi))
        XCTAssertFalse(isLowLatencyCandidate(.arabic))
        XCTAssertFalse(isLowLatencyCandidate(.turkish))
        XCTAssertFalse(isLowLatencyCandidate(.hebrew))
        XCTAssertFalse(isLowLatencyCandidate(.indonesian))
        XCTAssertFalse(isLowLatencyCandidate(.malay))
    }

    /// Indirect test for the private ``isLowLatencyCandidate``: the
    /// selection factory's behavior depends on it.
    private func isLowLatencyCandidate(_ language: Language) -> Bool {
        switch language {
        case .auto,
             .english, .german, .french, .spanish, .italian, .portuguese,
             .dutch, .polish, .czech, .swedish, .norwegian, .danish,
             .finnish, .hungarian, .romanian, .greek, .ukrainian, .bulgarian:
            return true
        case .unknown,
             .russian, .japanese, .korean,
             .mandarinSimplified, .mandarinTraditional,
             .vietnamese, .thai, .hindi, .arabic,
             .turkish, .hebrew, .indonesian, .malay:
            return false
        }
    }
}

// MARK: - Test-only mock backend

/// Minimal ``TranscriptionBackend`` for selection tests. Defined here
/// (in the shared test target) so the tests don't depend on the app target's
/// mock backend.
final class MockBackendForTests: TranscriptionBackend, @unchecked Sendable {
    let id: String
    let name: String
    let backendType: BackendType
    let isParakeetEOUFlag: Bool

    let supportsStreamingFlag: Bool

    init(
        id: String,
        backendType: BackendType,
        isParakeetEOU: Bool,
        supportsStreaming: Bool = true
    ) {
        self.id = id
        self.name = id
        self.backendType = backendType
        self.isParakeetEOUFlag = isParakeetEOU
        self.supportsStreamingFlag = supportsStreaming
    }

    var supportsStreaming: Bool { supportsStreamingFlag }
    var isParakeetEOU: Bool { isParakeetEOUFlag }
    var isLoaded: Bool { true }

    func load() async throws {}
    func unload() async {}

    func transcribe(_ audio: AVAudioPCMBuffer) async throws -> TranscriptionResult {
        TranscriptionResult(text: "", backendName: name, audioDuration: audio.duration)
    }
}