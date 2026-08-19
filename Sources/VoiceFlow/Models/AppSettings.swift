//
//  AppSettings.swift
//  VoiceFlow
//
//  SwiftData @Model for persisting user settings.
//

import Foundation
import SwiftData
import VoiceFlowShared

// MARK: - Theme

/// App theme preference.
enum Theme: String, Codable, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - AccentColorOption

/// Available accent colors.
enum AccentColorOption: String, Codable, CaseIterable {
    case indigo
    case violet
    case pink
    case coral
    case mint
    case amber
    case cyan
    case sky

    var displayName: String {
        switch self {
        case .indigo: return "Indigo"
        case .violet: return "Violet"
        case .pink: return "Pink"
        case .coral: return "Coral"
        case .mint: return "Mint"
        case .amber: return "Amber"
        case .cyan: return "Cyan"
        case .sky: return "Sky"
        }
    }

    var hexValue: String {
        switch self {
        case .indigo: return "#5B5FE6"
        case .violet: return "#8C52EB"
        case .pink: return "#F4529E"
        case .coral: return "#FF4D6D"
        case .mint: return "#3DD68C"
        case .amber: return "#FFB340"
        case .cyan: return "#33C7F5"
        case .sky: return "#4DA8FF"
        }
    }

    /// Resolved SwiftUI `Color` for the accent.
    var color: Color {
        if #available(iOS 14.0, *) {
            return Color(hex: hexValue)
        }
        return .blue
    }
}

// MARK: - AppSettings

/// Persisted app settings.
@Model
final class AppSettings {
    
    // MARK: - Properties
    
    /// Singleton identifier (always 1).
    @Attribute(.unique) var id: Int
    
    /// ID of the active model (matches ``ModelDefinition/id``).
    var activeModelId: String
    
    /// Preferred language for transcription.
    var preferredLanguageCode: String
    
    /// Auto-detect language if true.
    var autoDetectLanguage: Bool
    
    /// App theme.
    var themeRaw: String
    
    /// Accent color.
    var accentColorRaw: String
    
    /// Enable hold-to-talk trigger.
    var holdToTalkEnabled: Bool
    
    /// Enable tap-to-toggle trigger.
    var tapToToggleEnabled: Bool
    
    /// Enable keyboard extension mic button.
    var keyboardMicButtonEnabled: Bool
    
    /// Enable Action Button trigger.
    var actionButtonEnabled: Bool
    
    /// Enable automatic punctuation.
    var autoPunctuationEnabled: Bool

    /// Enable automatic capitalization.
    var autoCapitalizationEnabled: Bool

    /// Streaming backend selection preference (Issue #20c).
    /// Persisted as a raw string so it survives schema evolution cleanly.
    var streamingPreferenceRaw: String

    // MARK: - Initialization
    
    init(
        id: Int = 1,
        activeModelId: String = ModelDefinition.whisperBase.id,
        preferredLanguageCode: String = Language.auto.rawValue,
        autoDetectLanguage: Bool = true,
        themeRaw: String = Theme.dark.rawValue,
        accentColorRaw: String = AccentColorOption.indigo.rawValue,
        holdToTalkEnabled: Bool = true,
        tapToToggleEnabled: Bool = false,
        keyboardMicButtonEnabled: Bool = true,
        actionButtonEnabled: Bool = true,
        autoPunctuationEnabled: Bool = true,
        autoCapitalizationEnabled: Bool = true,
        streamingPreferenceRaw: String = StreamingPreference.auto.rawValue
    ) {
        self.id = id
        self.activeModelId = activeModelId
        self.preferredLanguageCode = preferredLanguageCode
        self.autoDetectLanguage = autoDetectLanguage
        self.themeRaw = themeRaw
        self.accentColorRaw = accentColorRaw
        self.holdToTalkEnabled = holdToTalkEnabled
        self.tapToToggleEnabled = tapToToggleEnabled
        self.keyboardMicButtonEnabled = keyboardMicButtonEnabled
        self.actionButtonEnabled = actionButtonEnabled
        self.autoPunctuationEnabled = autoPunctuationEnabled
        self.autoCapitalizationEnabled = autoCapitalizationEnabled
        self.streamingPreferenceRaw = streamingPreferenceRaw
    }
    
    // MARK: - Typed Accessors
    
    var theme: Theme {
        get { Theme(rawValue: themeRaw) ?? .system }
        set { themeRaw = newValue.rawValue }
    }
    
    var accentColor: AccentColorOption {
        get { AccentColorOption(rawValue: accentColorRaw) ?? .indigo }
        set { accentColorRaw = newValue.rawValue }
    }
    
    var preferredLanguage: Language {
        get { Language(rawValue: preferredLanguageCode) ?? .auto }
        set { preferredLanguageCode = newValue.rawValue }
    }

    /// Typed accessor for ``streamingPreferenceRaw``. Falls back to
    /// ``StreamingPreference/auto`` if the persisted value is unrecognized
    /// (e.g. forward-compat with a future preference case).
    var streamingPreference: StreamingPreference {
        get { StreamingPreference(rawValue: streamingPreferenceRaw) ?? .auto }
        set {
            streamingPreferenceRaw = newValue.rawValue
            // Mirror to App Group so extensions can read it without SwiftData.
            newValue.persistToAppSettings()
        }
    }

    /// The active model definition (looked up in the registry).
    var activeModel: ModelDefinition? {
        ModelRegistry.shared.model(for: activeModelId)
    }
}
