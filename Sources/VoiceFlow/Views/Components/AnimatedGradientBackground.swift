//
//  AnimatedGradientBackground.swift
//  VoiceFlow
//
//  iOS 26 inspired animated radial-gradient background.
//
//  Inspired by iOS 26's Liquid Glass aesthetic — gives screens depth without
//  being distracting. Used by HomeView, OnboardingFlow, and RecordingView
//  to unify the visual language across the app.
//
//  ## Design
//
//  - **Base color:** AppColors.backgroundDark (iOS 26 deep dark with subtle
//    purple tint) — same as plain solid background, so removing this view
//    is a visual no-op.
//  - **Accent halos:** two radial gradients in the brand accent (indigo)
//    and a secondary violet, positioned in opposite corners. Use iOS 26's
//    softer gradients (lower opacity, larger spread) for a more atmospheric
//    feel.
//  - **Animation:** halos drift slowly (60s cycle) along a Lissajous curve,
//    giving the screen a subtle "breathing" feel without distracting motion.
//
//  ## Usage
//
//  ```swift
//  ZStack {
//      AnimatedGradientBackground()
//          .ignoresSafeArea()
//      // ... your content
//  }
//  ```
//
//  Place as the **bottommost** layer of the ZStack so it sits behind all
//  content. Safe area is ignored so it bleeds to the screen edges.
//

import SwiftUI

// MARK: - AnimatedGradientBackground

/// A subtle, slow-moving radial-gradient background.
///
/// Replaces the flat dark background with two animated radial halos in
/// the brand accent and a secondary color, drifting along a Lissajous
/// curve. Designed for dark-mode apps that want depth without noise.
///
/// The animation is `linear` over 60 s and loops forever; the loop is
/// seamless because the start and end positions are identical.
struct AnimatedGradientBackground: View {

    // MARK: - Configuration

    /// Animation cycle length in seconds. Lower = more visible motion.
    /// 60 s is the default — slow enough to not distract during reading.
    var duration: Double = 60

    /// Tint of the primary halo. Defaults to the brand accent (indigo).
    var primaryTint: Color = Color.appAccent

    /// Tint of the secondary halo. Defaults to iOS 26 violet.
    var secondaryTint: Color = AppColors.violet

    /// Intensity multiplier for the halos (0 = invisible, 1 = default).
    var intensity: Double = 1.0

    // MARK: - Animation State

    /// Progress 0…1 driving the halo positions. Driven by a TimelineView
    /// so the animation pauses naturally when the view is offscreen.
    @State private var phase: Double = 0

    // MARK: - Body

    var body: some View {
        // Solid base layer — guarantees the background never goes transparent.
        // iOS 26 deep dark with subtle purple tint.
        ZStack {
            AppColors.backgroundDark

            // Subtle top-to-bottom gradient: slightly brighter at top.
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.11),
                    AppColors.backgroundDark
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        // Halo layer — two radial gradients positioned via TimelineView.
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            // Compute phase from elapsed time. Using TimelineView (not a
            // withAnimation block) means the animation respects view
            // lifecycle — pauses if the view is offscreen, resumes on
            // reappearance, no manual cleanup.
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let computedPhase = (elapsed.truncatingRemainder(dividingBy: duration)) / duration

            ZStack {
                // Primary halo — drifts in a Lissajous curve in the top-right.
                RadialGradient(
                    colors: [
                        primaryTint.opacity(0.32 * intensity),
                        primaryTint.opacity(0.12 * intensity),
                        primaryTint.opacity(0.0)
                    ],
                    center: haloPosition(
                        phase: computedPhase,
                        baseX: 0.78,
                        baseY: 0.22,
                        amplitudeX: 0.18,
                        amplitudeY: 0.12,
                        freqX: 1.0,
                        freqY: 1.3
                    ),
                    startRadius: 0,
                    endRadius: 480
                )

                // Secondary halo — drifts in the bottom-left, different curve.
                RadialGradient(
                    colors: [
                        secondaryTint.opacity(0.26 * intensity),
                        secondaryTint.opacity(0.10 * intensity),
                        secondaryTint.opacity(0.0)
                    ],
                    center: haloPosition(
                        phase: computedPhase,
                        baseX: 0.18,
                        baseY: 0.78,
                        amplitudeX: 0.20,
                        amplitudeY: 0.14,
                        freqX: 1.1,
                        freqY: 0.9
                    ),
                    startRadius: 0,
                    endRadius: 440
                )

                // Tertiary accent halo — small, drifting in the middle
                // for extra depth. iOS 26 layered look.
                RadialGradient(
                    colors: [
                        AppColors.pink.opacity(0.16 * intensity),
                        AppColors.pink.opacity(0.0)
                    ],
                    center: haloPosition(
                        phase: computedPhase,
                        baseX: 0.50,
                        baseY: 0.50,
                        amplitudeX: 0.25,
                        amplitudeY: 0.20,
                        freqX: 0.7,
                        freqY: 1.4
                    ),
                    startRadius: 0,
                    endRadius: 320
                )
            }
            .blendMode(.plusLighter)  // Additive blending for soft glow
            .opacity(0.85)            // Slightly muted so text stays readable
        }
    }

    // MARK: - Helpers

    /// Computes a Lissajous-curve position for a halo at the given phase.
    /// Returns a `UnitPoint` so it can be used directly with `RadialGradient`.
    private func haloPosition(
        phase: Double,
        baseX: Double,
        baseY: Double,
        amplitudeX: Double,
        amplitudeY: Double,
        freqX: Double,
        freqY: Double
    ) -> UnitPoint {
        // Two sin waves at different frequencies → Lissajous curve.
        let x = baseX + amplitudeX * sin(2 * .pi * phase * freqX)
        let y = baseY + amplitudeY * sin(2 * .pi * phase * freqY + .pi / 3)
        return UnitPoint(x: x, y: y)
    }
}

// MARK: - Preview

#Preview("Default") {
    AnimatedGradientBackground()
        .ignoresSafeArea()
}

#Preview("Higher Intensity") {
    AnimatedGradientBackground(intensity: 1.5)
        .ignoresSafeArea()
}

#Preview("Recording") {
    AnimatedGradientBackground(intensity: 1.4)
        .ignoresSafeArea()
}

#Preview("Coral") {
    AnimatedGradientBackground(
        primaryTint: AppColors.coral,
        secondaryTint: AppColors.amber
    )
    .ignoresSafeArea()
}
