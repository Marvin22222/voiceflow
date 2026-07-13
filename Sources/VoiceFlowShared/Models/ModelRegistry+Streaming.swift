//
//  ModelRegistry+Streaming.swift
//  VoiceFlowShared
//
//  Streaming-backend selection factory for Issue #20c (Live-Partial-Text).
//  Additive extension to ModelRegistry — the existing query/mutation surface
//  is untouched.
//
//  Spec: memory/projects/voiceflow-streaming-architecture.md (FINAL, 418 lines)
//  Decision log: memory/decisions/2026-06-18-voiceflow-20c-backend-decision.md
//

import Foundation

// MARK: - Streaming selection

extension ModelRegistry {

    /// Selects the best streaming-capable backend for a given language and
    /// user preference.
    ///
    /// Returns `nil` if no streaming-capable backend is available — callers
    /// should fall back to batch ``TranscriptionBackend/transcribe(_:)``.
    ///
    /// ## Selection Priority
    ///
    /// 1. **Parakeet-EOU (low-latency)** — for English + European languages
    ///    if a Parakeet-EOU backend is loaded and the user preference
    ///    allows it. Sub-second partial latency.
    /// 2. **WhisperKit** — fallback for all languages. Chunked batch
    ///    streaming with ~1–3s latency per update.
    ///
    /// ## Behavior by User Preference
    ///
    /// | Preference         | EN/EU language                  | Other language             |
    /// |--------------------|---------------------------------|----------------------------|
    /// | `.auto`            | Parakeet-EOU → WhisperKit       | WhisperKit                 |
    /// | `.forceWhisperKit` | WhisperKit                      | WhisperKit                 |
    /// | `.forceLowLatency` | Parakeet-EOU → WhisperKit       | WhisperKit (forced fallback)|
    ///
    /// - Parameters:
    ///   - language: The active or expected recording language.
    ///   - available: Backends currently loaded (caller provides — keeps
    ///                the registry decoupled from runtime state).
    ///   - userPreference: Override for which backend family to prefer.
    ///                    Defaults to ``StreamingPreference/auto``.
    /// - Returns: A streaming-capable backend, or `nil`.
    public static func selectStreamingBackend(
        for language: Language,
        among available: [TranscriptionBackend],
        userPreference: StreamingPreference = .auto
    ) -> TranscriptionBackend? {
        // Priority 1: Parakeet-EOU for EN + EU languages (low-latency path).
        // Only attempt when the preference allows it.
        let parakeetAllowed: Bool
        switch userPreference {
        case .forceWhisperKit:
            parakeetAllowed = false
        case .auto, .forceLowLatency:
            parakeetAllowed = true
        }

        if parakeetAllowed, isLowLatencyCandidate(language) {
            if let parakeet = available.first(where: { backend in
                backend.supportsStreaming && backend.isParakeetEOU
            }) {
                return parakeet
            }
        }

        // Priority 2: WhisperKit (multilingual fallback).
        // `userPreference == .forceLowLatency` still falls through here when
        // Parakeet isn't loaded or the language isn't a low-latency candidate.
        return available.first(where: { backend in
            backend.supportsStreaming && backend.backendType == .whisperKit
        })
    }

    /// Whether a language is a good candidate for Parakeet-EOU's low-latency mode.
    ///
    /// Parakeet-EOU supports English + 25 European languages (per NVIDIA docs).
    /// `.auto` is explicitly listed as `true`: the caller will try Parakeet-EOU
    /// first, then fall back to WhisperKit if the detected language is not in
    /// the EN/EU list.
    ///
    /// Marvis review note 1 (2026-06-18): explicit case list (no `default`) —
    /// adding a new `Language` case forces a compile warning, so we never
    /// silently exclude a newly-added language from low-latency mode.
    private static func isLowLatencyCandidate(_ language: Language) -> Bool {
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