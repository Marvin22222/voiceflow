//
//  StreamingPreference+AppSettings.swift
//  VoiceFlow
//
//  Bridge between ``StreamingPreference`` (VoiceFlowShared) and
//  ``AppSettings`` (the SwiftData model that lives in the app target).
//
//  Only the AppSettings-side accessor is implemented here:
//  ``StreamingPreference/persistToAppSettings()``. The reverse direction
//  (`fromAppSettings`) is intentionally not provided — the Settings UI
//  reads the preference directly via `@AppStorage` on UserDefaults, and
//  ``HomeViewModel`` reads via ``StreamingPreference/storedValue(in:)``.
//
//  Kept here so the VoiceFlowShared module stays SwiftData-free and
//  the AppSettings schema migration remains backward-compatible.
//

import Foundation
import VoiceFlowShared

// MARK: - Persistence Helpers

public extension StreamingPreference {

    /// Persists this preference to the shared App Group UserDefaults.
    ///
    /// Called from ``AppSettings/streamingPreference``'s setter so the
    /// value is mirrored outside SwiftData and can be read by future
    /// extensions (keyboard) without a SwiftData container.
    func persistToAppSettings() {
        AppGroup.sharedDefaults.set(rawValue, forKey: Self.appGroupKey)
    }

    /// App Group UserDefaults key used for the mirrored copy.
    /// Kept private to this file — the standard-suite key (used by
    /// `@AppStorage`) is ``StreamingPreference/userDefaultsKey``.
    private static let appGroupKey = "voiceflow.streamingPreference"
}