//
//  MicButton.swift
//  VoiceFlow
//
//  Circular microphone button with hold-to-record, haptics, and accessibility.
//

import SwiftUI
import UIKit

// MARK: - MicButton

/// A circular microphone button that handles hold-to-record gestures
/// with haptic feedback and full accessibility support.
///
/// The button shows a pulse-ring animation while recording and
/// automatically respects the system Reduce Motion setting.
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
    @State private var didPressHaptic = false
    
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
                    .stroke(AppColors.recording.opacity(0.3), lineWidth: 4)
                    .frame(
                        width: Sizing.micButtonLarge + 40,
                        height: Sizing.micButtonLarge + 40
                    )
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: pulseScale
                    )
            }
            
            // Main button
            Circle()
                .fill(isRecording ? AppColors.recording : AppColors.appAccent)
                .frame(
                    width: Sizing.micButtonLarge,
                    height: Sizing.micButtonLarge
                )
                .scaleEffect(scale)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                .overlay {
                    Image(systemName: iconName)
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !isRecording, !isProcessing else { return }
                            if !didPressHaptic {
                                pressHaptic.impactOccurred()
                                didPressHaptic = true
                            }
                            Task {
                                await onPress()
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                scale = 0.92
                            }
                        }
                        .onEnded { _ in
                            guard isRecording else {
                                didPressHaptic = false
                                return
                            }
                            releaseHaptic.notificationOccurred(.success)
                            didPressHaptic = false
                            Task {
                                await onRelease()
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                scale = 1.0
                            }
                        }
                )
        }
        .accessibilityLabel(Text("Hold to start dictation"))
        // TODO(l10n): Localize VoiceOver strings once localization is set up
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
            pulseScale = (newValue && !reduceMotion) ? 1.3 : 1.0
        }
    }
    
    private var iconName: String {
        if isProcessing { return "ellipsis.circle.fill" }
        return isRecording ? "stop.fill" : "mic.fill"
    }
}
