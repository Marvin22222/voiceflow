//
//  DesignSystem.swift
//  VoiceFlow
//
//  iOS 26 Liquid Glass design system primitives.
//  Provides reusable components: GlassCard, GlassButton, GlassSection,
//  LiquidSurface, and sensor feedback modifiers.
//
//  All glass effects fall back gracefully on iOS 17+ using `.regularMaterial`
//  and shadow stacks so previews still render beautifully, but the true
//  Liquid Glass material shines on iOS 26.
//

import SwiftUI

// MARK: - Glass Material

/// Liquid Glass effect style. Mirrors iOS 26's `GlassEffect` API surface.
enum LiquidGlassStyle {
    case regular
    case clear
    case tinted(Color)
    case identity
}

// MARK: - GlassEffect Modifier

extension View {
    /// Apply a Liquid Glass effect to the view.
    ///
    /// On iOS 26+, uses the native `.glassEffect()` modifier. On earlier
    /// iOS versions, falls back to a layered material + shadow so the
    /// visual intent is preserved.
    @ViewBuilder
    func liquidGlass(
        _ style: LiquidGlassStyle = .regular,
        in shape: some Shape = Capsule(),
        isEnabled: Bool = true
    ) -> some View {
        if isEnabled {
            if #available(iOS 26.0, *) {
                self.modifier(LiquidGlassEffectModifier(style: style, shape: shape))
            } else {
                self.modifier(LiquidGlassFallbackModifier(style: style, shape: shape))
            }
        } else {
            self
        }
    }
}

/// iOS 26+ native Liquid Glass modifier.
@available(iOS 26.0, *)
private struct LiquidGlassEffectModifier<S: Shape>: ViewModifier {
    let style: LiquidGlassStyle
    let shape: S

    func body(content: Content) -> some View {
        switch style {
        case .regular:
            content.glassEffect(.regular, in: shape)
        case .clear:
            content.glassEffect(.clear, in: shape)
        case .tinted(let color):
            content.glassEffect(.regular.tinted(color), in: shape)
        case .identity:
            content
        }
    }
}

/// iOS 17-25 fallback: layered material + shadow stack to mimic glass.
private struct LiquidGlassFallbackModifier<S: Shape>: ViewModifier {
    let style: LiquidGlassStyle
    let shape: S

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: shape)
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}

// MARK: - GlassCard

/// A reusable Liquid Glass card surface. Used for content blocks like
/// model cards, history rows, and settings sections.
struct GlassCard<Content: View>: View {
    let content: Content
    var style: LiquidGlassStyle = .regular
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    init(
        style: LiquidGlassStyle = .regular,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlass(style, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - GlassButton

/// A Liquid Glass button with leading icon, optional label, and accent color.
struct GlassButton: View {
    enum Size {
        case small, medium, large

        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }

        var font: Font {
            switch self {
            case .small: return .footnote.weight(.semibold)
            case .medium: return .body.weight(.semibold)
            case .large: return .title3.weight(.semibold)
            }
        }
    }

    let title: String
    var systemImage: String?
    var tint: Color = .appAccent
    var size: Size = .medium
    var fullWidth: Bool = false
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(size.font.weight(.semibold))
                }
                Text(title)
                    .font(size.font)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size == .large ? 24 : 16)
            .foregroundStyle(tint)
            .liquidGlass(.regular, in: Capsule())
        }
        .buttonStyle(GlassButtonStyle())
        .sensoryFeedback(.impact(weight: .light), trigger: false)
    }
}

/// Custom button style for liquid press animation.
private struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(
                .spring(response: 0.28, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

// MARK: - GlassSection Header

/// Section header for in-card sections. Uses the iOS 26 uppercase caption style.
struct GlassSectionHeader: View {
    let title: String
    var accessory: String?

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.4)
            Spacer()
            if let accessory {
                Text(accessory)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - LiquidSurface

/// A full-width Liquid Glass surface — used for toolbars, sheets, and
/// floating tab bars.
struct LiquidSurface<Content: View>: View {
    let content: Content
    var style: LiquidGlassStyle = .regular
    var cornerRadius: CGFloat = 0

    init(
        style: LiquidGlassStyle = .regular,
        cornerRadius: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .liquidGlass(
                style,
                in: cornerRadius > 0
                    ? AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    : AnyShape(Rectangle()
                )
            )
    }
}

// MARK: - Icon Container

/// A small Liquid Glass circle behind an icon — used in onboarding and
/// feature rows.
struct GlassIconBadge: View {
    let systemImage: String
    var tint: Color = .appAccent
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            Circle()
                .fill(tint.opacity(0.18))
            Image(systemName: systemImage)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
        .shadow(color: tint.opacity(0.25), radius: 16, y: 8)
    }
}

// MARK: - Divider

/// iOS 26's hairline divider — softer than the default.
struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(.separator.opacity(0.4))
            .frame(height: 1.0 / UIScreen.main.scale)
            .padding(.vertical, 4)
    }
}

// MARK: - Title Style

extension Text {
    /// Apply iOS 26 large-title style with refined weight and tracking.
    func glassTitle() -> some View {
        self.font(.system(size: 34, weight: .bold, design: .rounded))
            .tracking(-0.5)
    }

    /// Apply iOS 26 section-title style.
    func glassSectionTitle() -> some View {
        self.font(.system(size: 22, weight: .semibold, design: .rounded))
            .tracking(-0.3)
    }
}

// MARK: - Reusable Bouncy Spring

extension Animation {
    /// iOS 26's preferred bouncy spring for interactive elements.
    static var glassBouncy: Animation {
        .spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0.1)
    }

    /// iOS 26's preferred smooth spring for sheet/tab transitions.
    static var glassSmooth: Animation {
        .spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.2)
    }
}

// MARK: - Tab Bar Background

/// iOS 26 floating tab bar background — translucent, rounded, floating
/// above the content with a subtle shadow.
struct FloatingTabBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.20), radius: 24, y: 8)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
    }
}

extension View {
    /// Apply the iOS 26 floating tab bar background.
    func floatingTabBar() -> some View {
        modifier(FloatingTabBarBackground())
    }
}

// MARK: - Preview

#Preview("Glass Components") {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()

        VStack(spacing: 24) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hello, Liquid Glass")
                        .font(.headline)
                    Text("This is a glass card on iOS 26.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                GlassButton(title: "Cancel", systemImage: nil, tint: .secondary)
                GlassButton(title: "Continue", systemImage: "arrow.right", fullWidth: true)
            }
            .padding(.horizontal)
        }
    }
    .preferredColorScheme(.dark)
}
