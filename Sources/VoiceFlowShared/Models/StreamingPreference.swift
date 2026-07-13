//
//  StreamingPreference.swift
//  VoiceFlowShared
//
//  User-facing preference for streaming-backend selection (Issue #20c).
//  Persisted in AppSettings and consumed by ModelRegistry.selectStreamingBackend.
//

import Foundation

// MARK: - StreamingPreference

/// Controls which streaming backend ``ModelRegistry/selectStreamingBackend(for:among:userPreference:)``
/// picks when more than one streaming-capable backend is loaded.
///
/// Marvis defaults (final per 2026-06-18 decision log, triggered 2026-07-07):
/// F1 = WhisperKit-first (multilingual safety)
/// F2 = 1–3s MVP latency OK
/// F3 = Auto-selection with user override (this enum is the override).
public enum StreamingPreference: String, Codable, CaseIterable, Hashable, Sendable {

    /// Pick the best streaming backend automatically:
    /// Parakeet-EOU (low-latency) for EN + European languages, otherwise WhisperKit.
    case auto

    /// Always prefer WhisperKit for streaming — multilingual fallback wins over
    /// Parakeet-EOU even when Parakeet is available. Use when accuracy or
    /// multilingual coverage matters more than latency.
    case forceWhisperKit

    /// Prefer Parakeet-EOU when it's loaded and the active language is one
    /// it supports. Falls back to WhisperKit if Parakeet isn't available
    /// or the language isn't in its supported set.
    case forceLowLatency
}

// MARK: - Display Properties

public extension StreamingPreference {

    /// Human-readable label for the Settings UI.
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .forceWhisperKit: return "Multilingual (WhisperKit)"
        case .forceLowLatency: return "Low-Latency (EN/EU)"
        }
    }

    /// User-facing explanation of what this preference does, shown below the picker.
    var explanation: String {
        switch self {
        case .auto:
            return "Picks Parakeet-EOU for English and European languages, WhisperKit everywhere else."
        case .forceWhisperKit:
            return "Always streams via WhisperKit. Best for multilingual recordings or when accuracy matters more than latency."
        case .forceLowLatency:
            return "Prefers Parakeet-EOU for sub-second partials. Falls back to WhisperKit when the language isn't supported."
        }
    }

    // MARK: - Persistence

    /// UserDefaults key used by `@AppStorage` (Issue #20c).
    /// Mirrors the key in `SettingsView.streamingSection` — keep in sync.
    static let userDefaultsKey = "voiceflow.streamingPreference"

    /// Reads the persisted preference from the standard UserDefaults.
    /// Falls back to ``StreamingPreference/auto`` when the value is missing
    /// or unrecognized (forward-compat with future cases).
    static func storedValue(in defaults: UserDefaults = .standard) -> StreamingPreference {
        guard let raw = defaults.string(forKey: userDefaultsKey) else { return .auto }
        return StreamingPreference(rawValue: raw) ?? .auto
    }
}