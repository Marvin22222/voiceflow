//
//  EmptyStateView.swift
//  VoiceFlow
//
//  Reusable empty-state component (Issue #22).
//

import SwiftUI

// MARK: - EmptyStateView

/// A centered, friendly empty state with an icon, title, message, and optional CTA.
///
/// Used across the app wherever a list or feature has no content yet:
///
/// - `HomeView` — when no model is installed ("Download Whisper Base" CTA)
/// - `HomeView` — when no transcription has been recorded yet ("Press and hold" hint)
/// - `HistoryView` — when no past transcriptions exist (no CTA, just a hint)
/// - `ModelsView` — when a filter results in zero models
///
/// Apple's Human Interface Guidelines recommend empty states that:
/// - Educate the user about what _should_ be there
/// - Offer a clear next action when one makes sense
/// - Stay visually calm — no jarring colors, no scary icons
struct EmptyStateView: View {
    
    // MARK: - Properties
    
    /// SF Symbol name for the icon (e.g. `"mic.fill"`, `"tray"`, `"sparkles"`).
    let icon: String
    
    /// Bold headline (e.g. "No Transcriptions Yet").
    let title: String
    
    /// Secondary explanatory text below the title.
    let message: String
    
    /// Optional CTA button label (e.g. "Download Whisper Base").
    /// When nil, no button is rendered.
    let actionLabel: String?
    
    /// Optional CTA action. Ignored when ``actionLabel`` is nil.
    let action: (() -> Void)?
    
    /// Tint for the icon and CTA. Defaults to the app accent.
    var tint: Color = .appAccent
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(tint.opacity(0.85))
                .accessibilityHidden(true)
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: 280, minHeight: Sizing.buttonHeight)
                        .background(tint)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, Spacing.sm)
                .accessibilityLabel(actionLabel)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - ErrorStateView

/// Inline error state with an icon, message, and one or two action buttons.
///
/// Designed for embed-in-place errors that aren't full-screen modals
/// (e.g. a failed model download shown inside ModelsView). For app-blocking
/// errors, use a `.alert` instead.
struct ErrorStateView: View {
    
    // MARK: - Properties
    
    /// SF Symbol name (defaults to a warning triangle).
    let icon: String
    
    /// Bold error title (e.g. "Microphone Access Denied").
    let title: String
    
    /// Explanatory message describing what went wrong and how to fix it.
    let message: String
    
    /// Optional primary action button label.
    let primaryActionLabel: String?
    
    /// Optional primary action.
    let primaryAction: (() -> Void)?
    
    /// Optional secondary (less prominent) action button label.
    let secondaryActionLabel: String?
    
    /// Optional secondary action.
    let secondaryAction: (() -> Void)?
    
    /// Accent color for the icon and primary button. Defaults to ``AppColors/error``.
    var tint: Color = AppColors.error
    
    // MARK: - Initializer
    
    init(
        icon: String = "exclamationmark.triangle.fill",
        title: String,
        message: String,
        primaryActionLabel: String? = nil,
        primaryAction: (() -> Void)? = nil,
        secondaryActionLabel: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        tint: Color = AppColors.error
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.primaryActionLabel = primaryActionLabel
        self.primaryAction = primaryAction
        self.secondaryActionLabel = secondaryActionLabel
        self.secondaryAction = secondaryAction
        self.tint = tint
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if primaryActionLabel != nil || secondaryActionLabel != nil {
                VStack(spacing: Spacing.sm) {
                    if let primaryActionLabel, let primaryAction {
                        Button(action: primaryAction) {
                            Text(primaryActionLabel)
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: 280, minHeight: Sizing.buttonHeight)
                                .background(tint)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .accessibilityLabel(primaryActionLabel)
                    }
                    
                    if let secondaryActionLabel, let secondaryAction {
                        Button(action: secondaryAction) {
                            Text(secondaryActionLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(secondaryActionLabel)
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("Empty — No CTA") {
    EmptyStateView(
        icon: "tray",
        title: "Nothing here yet",
        message: "Your past transcriptions will appear here."
    )
    .background(AppColors.backgroundDark)
}

#Preview("Empty — With CTA") {
    EmptyStateView(
        icon: "arrow.down.circle",
        title: "No Model Downloaded",
        message: "Download Whisper Base (~75 MB) to start transcribing audio.",
        actionLabel: "Download Whisper Base",
        action: {}
    )
    .background(AppColors.backgroundDark)
}

#Preview("Error — Permission") {
    ErrorStateView(
        title: "Microphone Access Denied",
        message: "VoiceFlow needs microphone access to record audio. Open Settings to grant permission.",
        primaryActionLabel: "Open Settings",
        primaryAction: {},
        secondaryActionLabel: "Cancel",
        secondaryAction: {}
    )
    .background(AppColors.backgroundDark)
}