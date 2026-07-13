//
//  StreamingPreferenceTests.swift
//  VoiceFlowSharedTests
//
//  Unit tests for the user-preference override behavior of
//  ``ModelRegistry/selectStreamingBackend(for:among:userPreference:)``.
//

import XCTest
@testable import VoiceFlowShared

final class StreamingPreferenceTests: XCTestCase {

    // MARK: - Display

    func test_displayName_returnsHumanReadableLabels() {
        XCTAssertEqual(StreamingPreference.auto.displayName, "Auto")
        XCTAssertEqual(StreamingPreference.forceWhisperKit.displayName, "Multilingual (WhisperKit)")
        XCTAssertEqual(StreamingPreference.forceLowLatency.displayName, "Low-Latency (EN/EU)")
    }

    func test_explanation_returnsNonEmptyStrings() {
        for preference in StreamingPreference.allCases {
            XCTAssertFalse(preference.explanation.isEmpty, "\(preference) must have an explanation")
        }
    }

    // MARK: - Override logic (all preferences x representative languages)

    /// ``StreamingPreference/forceWhisperKit`` ignores Parakeet-EOU even
    /// when available and the language supports it.
    func test_forceWhisperKit_alwaysPicksWhisperKit_forEN() {
        let candidates: [any TranscriptionBackend] = [
            MockBackendForTests(id: "w", backendType: .whisperKit, isParakeetEOU: false),
            MockBackendForTests(id: "p", backendType: .fluidAudio, isParakeetEOU: true),
        ]
        let selected = ModelRegistry.selectStreamingBackend(
            for: .english, among: candidates, userPreference: .forceWhisperKit
        )
        XCTAssertEqual(selected?.id, "w")
    }

    /// ``StreamingPreference/forceWhisperKit`` also wins for non-EU languages.
    func test_forceWhisperKit_alwaysPicksWhisperKit_forMandarin() {
        let candidates: [any TranscriptionBackend] = [
            MockBackendForTests(id: "w", backendType: .whisperKit, isParakeetEOU: false),
            MockBackendForTests(id: "p", backendType: .fluidAudio, isParakeetEOU: true),
        ]
        let selected = ModelRegistry.selectStreamingBackend(
            for: .mandarinSimplified, among: candidates, userPreference: .forceWhisperKit
        )
        XCTAssertEqual(selected?.id, "w")
    }

    /// ``StreamingPreference/forceLowLatency`` prefers Parakeet for EN/EU.
    func test_forceLowLatency_picksParakeet_forEN() {
        let candidates: [any TranscriptionBackend] = [
            MockBackendForTests(id: "w", backendType: .whisperKit, isParakeetEOU: false),
            MockBackendForTests(id: "p", backendType: .fluidAudio, isParakeetEOU: true),
        ]
        let selected = ModelRegistry.selectStreamingBackend(
            for: .english, among: candidates, userPreference: .forceLowLatency
        )
        XCTAssertEqual(selected?.id, "p")
    }

    /// ``StreamingPreference/forceLowLatency`` falls back to Whisper for
    /// languages Parakeet doesn't support.
    func test_forceLowLatency_fallsBackToWhisper_forMandarin() {
        let candidates: [any TranscriptionBackend] = [
            MockBackendForTests(id: "w", backendType: .whisperKit, isParakeetEOU: false),
            MockBackendForTests(id: "p", backendType: .fluidAudio, isParakeetEOU: true),
        ]
        let selected = ModelRegistry.selectStreamingBackend(
            for: .mandarinSimplified, among: candidates, userPreference: .forceLowLatency
        )
        XCTAssertEqual(selected?.id, "w")
    }

    /// ``StreamingPreference/auto`` picks Parakeet for EN/EU but Whisper for
    /// languages Parakeet doesn't support.
    func test_auto_picksParakeetForEN_butWhisperForMandarin() {
        let candidates: [any TranscriptionBackend] = [
            MockBackendForTests(id: "w", backendType: .whisperKit, isParakeetEOU: false),
            MockBackendForTests(id: "p", backendType: .fluidAudio, isParakeetEOU: true),
        ]

        let enSelected = ModelRegistry.selectStreamingBackend(
            for: .english, among: candidates, userPreference: .auto
        )
        XCTAssertEqual(enSelected?.id, "p")

        let zhSelected = ModelRegistry.selectStreamingBackend(
            for: .mandarinSimplified, among: candidates, userPreference: .auto
        )
        XCTAssertEqual(zhSelected?.id, "w")
    }

    /// Default preference (omitted argument) is `.auto`.
    func test_defaultPreferenceIsAuto() {
        let candidates: [any TranscriptionBackend] = [
            MockBackendForTests(id: "w", backendType: .whisperKit, isParakeetEOU: false),
            MockBackendForTests(id: "p", backendType: .fluidAudio, isParakeetEOU: true),
        ]
        let selected = ModelRegistry.selectStreamingBackend(
            for: .english, among: candidates
        )
        XCTAssertEqual(selected?.id, "p", "Default preference must be .auto -> picks Parakeet for EN")
    }

    /// All preferences return nil when no streaming-capable backend is available.
    func test_noStreamingBackend_returnsNil_forAllPreferences() {
        let candidates: [any TranscriptionBackend] = [
            MockBackendForTests(
                id: "batch",
                backendType: .whisperKit,
                isParakeetEOU: false,
                supportsStreaming: false
            ),
        ]
        for preference in StreamingPreference.allCases {
            let selected = ModelRegistry.selectStreamingBackend(
                for: .english, among: candidates, userPreference: preference
            )
            XCTAssertNil(selected, "\(preference) should return nil when no streaming backend available")
        }
    }

    /// `forceLowLatency` returns nil if only batch-only backends are loaded
    /// (no fallback to batch — selection is for streaming only).
    func test_forceLowLatency_returnsNilIfNoStreamingBackend() {
        let candidates: [any TranscriptionBackend] = [
            MockBackendForTests(
                id: "batch",
                backendType: .whisperKit,
                isParakeetEOU: false,
                supportsStreaming: false
            ),
        ]
        let selected = ModelRegistry.selectStreamingBackend(
            for: .english, among: candidates, userPreference: .forceLowLatency
        )
        XCTAssertNil(selected)
    }
}