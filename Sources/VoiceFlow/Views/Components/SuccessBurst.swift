//
//  SuccessBurst.swift
//  VoiceFlow
//
//  iOS 26 inspired celebration animation — subtle, one-shot burst of
//  accent-colored particles + checkmark that auto-dismisses after ~1.2 s.
//  Uses iOS 26's Liquid Glass circle behind the checkmark for a
//  translucent, floating appearance.
//
//  Designed to feel like Apple's "delight" moments (App Store download
//  completed, podcast subscribed, etc.) without being over the top.
//

import SwiftUI

// MARK: - SuccessBurst

/// A one-shot celebratory animation. Place above your content as an overlay
/// and trigger with a binding.
struct SuccessBurst: View {

    // MARK: - Properties

    /// Whether the animation is currently visible. Bind to a `@State` and
    /// flip to `true` to play.
    @Binding var isActive: Bool

    /// Tint of the particles and checkmark. Defaults to the brand accent.
    var tint: Color = .appAccent

    // MARK: - State

    /// Animation phase 0…1 driving particle motion.
    @State private var phase: Double = 0

    /// Whether the checkmark has scaled in.
    @State private var checkmarkAppeared: Bool = false

    /// Whether the burst is in its fade-out phase.
    @State private var fading: Bool = false

    // MARK: - Constants

    private let particleCount = 14
    private let totalDuration: Double = 1.4
    private let checkmarkDelay: Double = 0.15

    // MARK: - Body

    var body: some View {
        ZStack {
            if isActive {
                // Particles
                ForEach(0..<particleCount, id: \.self) { i in
                    particleView(index: i)
                }

                // Liquid Glass checkmark
                ZStack {
                    // Glass background circle
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 130, height: 130)
                        .overlay(
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
                                    lineWidth: 1.2
                                )
                        )
                        .shadow(color: tint.opacity(0.4), radius: 24, y: 8)

                    // Checkmark icon
                    Image(systemName: "checkmark")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                }
                .scaleEffect(checkmarkAppeared ? 1.0 : 0.3)
                .opacity(fading ? 0 : 1)
            }
        }
        .allowsHitTesting(false)  // Doesn't intercept gestures
        .onChange(of: isActive) { _, newValue in
            if newValue { play() }
        }
    }

    // MARK: - Subviews

    /// A single particle. Position and opacity are driven by `phase`.
    private func particleView(index: Int) -> some View {
        // Angle for this particle — evenly spaced around the circle.
        let angle = Double(index) / Double(particleCount) * 2 * .pi
        // Distance traveled, eased out (fast then slow).
        let rawDistance = easeOut(phase) * 140
        let x = cos(angle) * rawDistance
        let y = sin(angle) * rawDistance
        // Size shrinks over time.
        let scale = 1.0 - easeIn(phase) * 0.6
        // Opacity fades out near the end.
        let opacity = 1.0 - smoothstep(start: 0.4, end: 1.0, value: phase)

        return Circle()
            .fill(tint)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .offset(x: x, y: y)
            .opacity(opacity)
            .blur(radius: 0.5)
    }

    // MARK: - Animation

    /// Plays the burst. Resets state, runs the timeline, then dismisses.
    private func play() {
        phase = 0
        checkmarkAppeared = false
        fading = false

        // Drive phase 0→1 over `totalDuration`.
        withAnimation(.linear(duration: totalDuration)) {
            phase = 1
        }
        // Checkmark scale-in after a brief beat. iOS 26 bouncy spring.
        withAnimation(
            .spring(response: 0.5, dampingFraction: 0.55, blendDuration: 0.1)
                .delay(checkmarkDelay)
        ) {
            checkmarkAppeared = true
        }
        // Start fading near the end, then dismiss.
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration * 0.7) {
            withAnimation(.easeOut(duration: totalDuration * 0.3)) {
                fading = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            isActive = false
        }
    }

    // MARK: - Easing Helpers

    /// Cubic ease-out: 1 - (1 - t)^3. Fast start, slow finish.
    private func easeOut(_ t: Double) -> Double {
        let clamped = max(0, min(1, t))
        return 1 - pow(1 - clamped, 3)
    }

    /// Cubic ease-in: t^3. Slow start, fast finish.
    private func easeIn(_ t: Double) -> Double {
        let clamped = max(0, min(1, t))
        return clamped * clamped * clamped
    }

    /// Smoothstep between start and end values.
    private func smoothstep(start: Double, end: Double, value: Double) -> Double {
        let t = max(0, min(1, (value - start) / (end - start)))
        return t * t * (3 - 2 * t)
    }
}

// MARK: - Preview

#Preview {
    struct BurstDemo: View {
        @State private var active = false
        var body: some View {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                Button("Replay Burst") {
                    active = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        active = true
                    }
                }
                .foregroundStyle(.white)
                SuccessBurst(isActive: $active)
            }
        }
    }
    return BurstDemo()
}
