//
//  Language.swift
//  VoiceFlowShared
//
//  Language codes supported by transcription backends.
//  Mirrors ISO 639-1 codes where possible, with `auto` for detection.
//

import Foundation

// MARK: - Language

/// Languages supported by VoiceFlow transcription backends.
///
/// Backends declare which languages they support via
/// ``TranscriptionBackend/supportedLanguages``. Use ``Language/auto`` when
/// letting the backend detect the spoken language automatically.
public enum Language: String, Codable, CaseIterable, Hashable, Sendable {
    
    // MARK: - Special
    
    /// Auto-detect spoken language. Most backends support this.
    case auto = "auto"
    
    /// Language could not be determined or is not supported.
    case unknown = "unknown"
    
    // MARK: - Most Common
    
    case english = "en"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case portuguese = "pt"
    case dutch = "nl"
    case russian = "ru"
    case mandarinSimplified = "zh-CN"
    case mandarinTraditional = "zh-TW"
    
    // MARK: - European
    
    case polish = "pl"
    case czech = "cs"
    case swedish = "sv"
    case norwegian = "no"
    case danish = "da"
    case finnish = "fi"
    case hungarian = "hu"
    case romanian = "ro"
    case greek = "el"
    case ukrainian = "uk"
    case bulgarian = "bg"
    
    // MARK: - Asian
    
    case japanese = "ja"
    case korean = "ko"
    case vietnamese = "vi"
    case thai = "th"
    case hindi = "hi"
    case arabic = "ar"
    
    // MARK: - Other
    
    case turkish = "tr"
    case hebrew = "he"
    case indonesian = "id"
    case malay = "ms"
}

// MARK: - Display Properties

public extension Language {
    
    /// Human-readable name in the language's native script.
    var displayName: String {
        switch self {
        case .auto: return "Auto-detect"
        case .unknown: return "Unknown"
        case .english: return "English"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .dutch: return "Nederlands"
        case .russian: return "Русский"
        case .mandarinSimplified: return "简体中文"
        case .mandarinTraditional: return "繁體中文"
        case .polish: return "Polski"
        case .czech: return "Čeština"
        case .swedish: return "Svenska"
        case .norwegian: return "Norsk"
        case .danish: return "Dansk"
        case .finnish: return "Suomi"
        case .hungarian: return "Magyar"
        case .romanian: return "Română"
        case .greek: return "Ελληνικά"
        case .ukrainian: return "Українська"
        case .bulgarian: return "Български"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .vietnamese: return "Tiếng Việt"
        case .thai: return "ไทย"
        case .hindi: return "हिन्दी"
        case .arabic: return "العربية"
        case .turkish: return "Türkçe"
        case .hebrew: return "עברית"
        case .indonesian: return "Bahasa Indonesia"
        case .malay: return "Bahasa Melayu"
        }
    }
    
    /// SF Symbol flag emoji for the language (best-effort, may be nil).
    var flagEmoji: String? {
        switch self {
        case .english: return "🇬🇧"
        case .german: return "🇩🇪"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇵🇹"
        case .dutch: return "🇳🇱"
        case .russian: return "🇷🇺"
        case .mandarinSimplified, .mandarinTraditional: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        default: return nil
        }
    }
    
    /// Whether this is a specific language (not auto/unknown).
    var isConcrete: Bool {
        self != .auto && self != .unknown
    }
}

// MARK: - Mock Helpers

#if DEBUG
public extension Language {
    /// Mock language for testing.
    static let mock = Language.english
}
#endif
