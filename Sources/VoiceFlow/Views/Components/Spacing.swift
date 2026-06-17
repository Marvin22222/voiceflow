//
//  Spacing.swift
//  VoiceFlow
//
//  Spacing tokens used throughout the app. Matches docs/DESIGN_SYSTEM.md.
//

import SwiftUI

// MARK: - Spacing

/// Spacing tokens on an 8pt grid. Use these instead of magic numbers.
enum Spacing {
    
    /// 4pt — icon padding
    static let xs: CGFloat = 4
    
    /// 8pt — inline spacing
    static let sm: CGFloat = 8
    
    /// 16pt — default spacing
    static let md: CGFloat = 16
    
    /// 24pt — section spacing
    static let lg: CGFloat = 24
    
    /// 32pt — large gaps
    static let xl: CGFloat = 32
    
    /// 48pt — major sections
    static let xxl: CGFloat = 48
}

// MARK: - Sizes

/// Common sizing tokens.
enum Sizing {
    
    /// Standard button height.
    static let buttonHeight: CGFloat = 50
    
    /// Standard list row height.
    static let rowHeight: CGFloat = 56
    
    /// Mic button (large state).
    static let micButtonLarge: CGFloat = 200
    
    /// Mic button (compact state).
    static let micButtonCompact: CGFloat = 140
    
    /// Standard corner radius.
    static let cornerRadius: CGFloat = 12
    
    /// Card corner radius.
    static let cardCornerRadius: CGFloat = 16
}
