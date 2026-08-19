//
//  AppColors.swift
//  VoiceFlow
//
//  iOS 26 inspired color palette. Designed to feel native to Liquid Glass:
//  - Deep, slightly desaturated dark backgrounds let glass surfaces breathe
//  - Vibrant accent colors pop through translucent layers
//  - Subtle gradients give surfaces depth without distracting
//
//  Note: `Theme` and `AccentColorOption` enums live in `AppSettings.swift`
//  so they can be persisted via SwiftData. We extend them with extra
//  color tokens here for UI use.
//

import SwiftUI

// MARK: - AppColors

/// Semantic color tokens for VoiceFlow. Use these instead of raw `Color` values.
enum AppColors {

    // MARK: - Backgrounds

    /// Primary app background. iOS 26 deep dark — never pure black.
    /// Pure black makes glass surfaces look flat; this slightly-purple-tinted
    /// dark creates depth and lets glass effects shine.
    static let backgroundDark = Color(red: 0.04, green: 0.04, blue: 0.06)

    /// Secondary background for layered surfaces.
    static let backgroundSecondary = Color(red: 0.07, green: 0.07, blue: 0.10)

    /// Tertiary surface — used for cards on dark backgrounds.
    static let surfaceDark = Color(red: 0.11, green: 0.11, blue: 0.14)

    /// Light theme background.
    static let backgroundLight = Color(red: 0.98, green: 0.98, blue: 0.99)

    /// Light theme surface.
    static let surfaceLight = Color(red: 0.94, green: 0.94, blue: 0.96)

    // MARK: - Accent Palette

    /// Brand accent — vibrant indigo with iOS 26 flair.
    static let indigo = Color(red: 0.36, green: 0.36, blue: 0.96)

    /// Secondary accent — iOS 26 violet.
    static let violet = Color(red: 0.55, green: 0.32, blue: 0.92)

    /// Tertiary accent — iOS 26 pink.
    static let pink = Color(red: 0.96, green: 0.32, blue: 0.62)

    /// Coral accent.
    static let coral = Color(red: 1.00, green: 0.40, blue: 0.42)

    /// Mint accent.
    static let mint = Color(red: 0.20, green: 0.84, blue: 0.62)

    /// Amber accent.
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.20)

    /// Cyan accent.
    static let cyan = Color(red: 0.20, green: 0.78, blue: 0.96)

    /// Sky accent (legacy).
    static let sky = Color(red: 0.30, green: 0.66, blue: 1.00)

    // MARK: - Semantic

    /// User-configurable app accent. Defaults to indigo.
    static var appAccent: Color { Color.appAccent }

    /// Success state — iOS 26 green.
    static let success = Color(red: 0.20, green: 0.84, blue: 0.42)

    /// Warning state — iOS 26 amber.
    static let warning = Color(red: 1.00, green: 0.72, blue: 0.20)

    /// Error state — iOS 26 red.
    static let error = Color(red: 1.00, green: 0.32, blue: 0.32)

    /// Recording indicator — slightly more saturated than iOS 17.
    static let recording = Color(red: 1.00, green: 0.30, blue: 0.36)

    // MARK: - Text

    /// Primary text — uses system `Color.primary` for proper theme adaptation.
    static let textPrimary = Color.primary

    /// Secondary text.
    static let textSecondary = Color.secondary

    /// Tertiary text (disabled, hints).
    static let textTertiary = Color(white: 0.5)

    // MARK: - Glass Tints

    /// Subtle white overlay used for glass surface highlights.
    static let glassHighlight = Color.white.opacity(0.18)

    /// Subtle border for glass surfaces.
    static let glassBorder = Color.white.opacity(0.12)

    /// Subtle shadow for glass surfaces.
    static let glassShadow = Color.black.opacity(0.20)
}

// MARK: - Color Hex Extension

extension Color {

    /// Initialize a Color from a hex string (e.g. "#FF3B30" or "FF3B30").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    /// User-configurable app accent color. Reads from persisted AppSettings.
    static var appAccent: Color {
        AccentColorOption.indigo.color
    }
}

// MARK: - Theme colorScheme Extension

extension Theme {
    /// SwiftUI color scheme for this theme.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
