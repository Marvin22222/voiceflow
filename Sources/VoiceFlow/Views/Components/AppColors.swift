//
//  AppColors.swift
//  VoiceFlow
//
//  Color tokens used throughout the app. Matches docs/DESIGN_SYSTEM.md.
//

import SwiftUI

// MARK: - AppColors

/// Semantic color tokens. Use these instead of raw Color values.
enum AppColors {
    
    // MARK: - Background
    
    /// Main app background (dark).
    static let backgroundDark = Color(hex: "#0A0A0F")
    
    /// Surface color for cards/sheets (dark).
    static let surfaceDark = Color(hex: "#1C1C1E")
    
    /// Light background alternative.
    static let backgroundLight = Color.white
    
    /// Light surface alternative.
    static let surfaceLight = Color(hex: "#F2F2F7")
    
    // MARK: - Semantic
    
    /// Primary brand accent (default: indigo).
    static var appAccent: Color { Color.appAccent }
    
    /// Success state color.
    static let success = Color(hex: "#34C759")
    
    /// Warning state color.
    static let warning = Color(hex: "#FF9500")
    
    /// Error state color.
    static let error = Color(hex: "#FF3B30")
    
    /// Recording indicator (pulsing red).
    static let recording = Color(hex: "#FF3B30")
    
    // MARK: - Text
    
    /// Primary text color.
    static let textPrimary = Color.primary
    
    /// Secondary text color.
    static let textSecondary = Color.secondary
    
    /// Tertiary text color (disabled, hints).
    static let textTertiary = Color(white: 0.5)
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
    
    /// User-configurable app accent color.
    static var appAccent: Color {
        let accent = AccentColorOption.indigo  // TODO: read from AppSettings
        return Color(hex: accent.hexValue)
    }
}
