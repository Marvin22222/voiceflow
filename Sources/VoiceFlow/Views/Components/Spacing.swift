//
//  Spacing.swift
//  VoiceFlow
//
//  iOS 26 spacing tokens. The 8pt grid is preserved but with finer
//  refinements for iOS 26's rounded surfaces and glass effects.
//

import SwiftUI

// MARK: - Spacing

/// Spacing tokens on an 8pt grid with iOS 26 refinements.
enum Spacing {

    /// 2pt — micro gap (icons inside tight badges)
    static let xxs: CGFloat = 2

    /// 4pt — small icon padding
    static let xs: CGFloat = 4

    /// 8pt — inline spacing
    static let sm: CGFloat = 8

    /// 12pt — between related elements
    static let smPlus: CGFloat = 12

    /// 16pt — default content spacing
    static let md: CGFloat = 16

    /// 20pt — generous inline spacing
    static let mdPlus: CGFloat = 20

    /// 24pt — section spacing
    static let lg: CGFloat = 24

    /// 32pt — large gaps
    static let xl: CGFloat = 32

    /// 48pt — major sections
    static let xxl: CGFloat = 48

    /// 64pt — hero spacing
    static let xxxl: CGFloat = 64

    // MARK: - Page Insets

    /// Default horizontal page padding (iOS 26 prefers slightly more).
    static let pageHorizontal: CGFloat = 20

    /// Default vertical page padding.
    static let pageVertical: CGFloat = 16
}

// MARK: - Sizes

/// Common sizing tokens for iOS 26 layout.
enum Sizing {

    /// Standard button height — iOS 26 prefers slightly taller.
    static let buttonHeight: CGFloat = 52

    /// Small button height.
    static let buttonHeightSmall: CGFloat = 36

    /// Standard list row height.
    static let rowHeight: CGFloat = 60

    /// Mic button (large state).
    static let micButtonLarge: CGFloat = 180

    /// Mic button (compact state).
    static let micButtonCompact: CGFloat = 120

    /// Standard card corner radius.
    static let cardCornerRadius: CGFloat = 20

    /// Sheet corner radius.
    static let sheetCornerRadius: CGFloat = 28

    /// Tab bar height.
    static let tabBarHeight: CGFloat = 64

    /// Glass badge size.
    static let badgeSize: CGFloat = 44

    /// Glass badge size (small).
    static let badgeSizeSmall: CGFloat = 32
}
