//
//  MicButton.swift
//  VoiceFlow
//
//  iOS 26 Liquid Glass style microphone button with hold-to-record,
//  sensory feedback, and refined animations. The button is composed
//  of multiple glass layers — a base glass disc, a tinted accent
//  inner ring, and the icon — that come together for a floating
//  glass feel.
//

import SwiftUI
import UIKit

// MARK: - MicButton

/// A Liquid Glass circular microphone button.
///
/// iOS 26 visual:
/// - Outer glass disc with depth (UltraThinMaterial + highlight gradient)
/// - Tinted accent ring that fills the disc
/// - Crisp SF Symbols 7 icon
/// - Pulse ring animation while recording
/// - Bouncy spring on press
/// - Sensory feedback for tactile confirmation
///
/// - Parameters:
///   - isRecording: Whether the button is currently in the recording state.
///   - isProcessing: Whether the button should show a processing indicator.
///   - onPress: Async closure invoked once when the user starts pressing.
///   - onRelease: Async closure invoked when the user releases the button.
struct MicButton: View {

    // MARK: - Properties

    let isRecording: Bool
    let isProcessing: Bool
    let onPress: () async -> Void
    let onRelease: () async -> Void

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var scale: CGFloat = 1.0
    @State private var pulseScale: CGFloat = 1.0

    // MARK: - Haptic Generators

    @State private let pressHaptic = UIImpactFeedbackGenerator(style: .light)
    @State private let recordingHaptic = UIImpactFeedbackGenerator(style: .medium)
    @State private let releaseHaptic = UINotificationFeedbackGenerator()

    // MARK: - Body

    var body: some View {
        ZStack {
            // Pulse ring (only when recording AND motion is allowed)
            if isRecording && !reduceMotion {
                Circle()
                    .stroke(AppColors.recording.opacity(0.4), lineWidth: 4)
                    .frame(
                        width: Sizing.micButtonLarge + 60,
                        height: Sizing.micButtonLarge + 60
                    )
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)
                    .animation(
                        .easeInOut(duration: 1.6).repeatForever(autoreverses: false),
                        value: pulseScale
                    )
            }

            // Liquid Glass outer ring — iOS 26 depth
            Circle()
                .fill(.ultraThinMaterial)
                .frame(
                    width: Sizing.micButtonLarge + 16,
                    height: Sizing.micButtonLarge + 16
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .black.opacity(0.35), radius: 30, y: 16)

            // Tinted accent layer — fills with recording color or accent
            Circle()
                .fill(
                    LinearGradient(
                        colors: isRecording
                            ? [AppColors.recording, AppColors.recording.opacity(0.8)]
                            : [Color.appAccent, Color.appAccent.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: Sizing.micButtonLarge,
                    height: Sizing.micButtonLarge
                )
                .scaleEffect(scale)
                .shadow(
                    color: (isRecording ? AppColors.recording : Color.appAccent).opacity(0.4),
                    radius: 24,
                    y: 12
                )
                .overlay(
                    // Inner glass highlight — iOS 26 signature
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(
                            width: Sizing.micButtonLarge,
                            height: Sizing.micButtonLarge
                        )
                )
                .overlay {
                    Image(systemName: iconName)
                        .font(.system(size: 72, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: isRecording)
                }
                .gesture(
                    TapGesture()
                        .onEnded {
                            guard !isProcessing else { return }
                            if isRecording {
                                // Tap to stop — success haptic + visual scale-down.
                                releaseHaptic.notificationOccurred(.success)
                                withAnimation(.glassBouncy) {
                                    scale = 0.92
                                }
                                Task { await onRelease() }
                            } else {
                                // Tap to start — light haptic + visual scale-down.
                                pressHaptic.impactOccurred()
                                withAnimation(.glassBouncy) {
                                    scale = 0.92
                                }
                                Task { await onPress() }
                            }
                        }
                )
        }
        .accessibilityLabel(Text("Tap to start dictation"))
        .accessibilityValue(Text(isRecording ? "Recording" : "Idle"))
        .accessibilityAddTraits(.isButton)
        .onAppear {
            // Apple recommends preparing haptic generators up front to
            // minimize latency on the first impact.
            pressHaptic.prepare()
            recordingHaptic.prepare()
            releaseHaptic.prepare()
        }
        .onChange(of: isRecording) { _, newValue in
            // Fire medium haptic on the transition into recording.
            if newValue {
                recordingHaptic.impactOccurred()
            }
            // Drive pulse animation; gated by Reduce Motion.
            pulseScale = (newValue && !reduceMotion) ? 1.4 : 1.0
            // Snap button back to resting scale when state changes.
            withAnimation(.glassBouncy) {
                scale = 1.0
            }
        }
    }

    private var iconName: String {
        if isProcessing { return "ellipsis.circle.fill" }
        return isRecording ? "stop.fill" : "mic.fill"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        VStack(spacing: 40) {
            MicButton(
                isRecording: false,
                isProcessing: false,
                onPress: {},
                onRelease: {}
            )
            MicButton(
                isRecording: true,
                isProcessing: false,
                onPress: {},
                onRelease: {}
            )
        }
    }
}
