//
//  RecordingView.swift
//  VoiceFlow
//
//  iOS 26 Liquid Glass recording screen. Full-screen capture UI with
//  a glass waveform container, pulsing recording indicator, MM:SS
//  counter, and glass Stop/Cancel buttons — all with iOS 26 spring
//  animations and sensory feedback.
//

import SwiftUI
import VoiceFlowShared

// MARK: - RecordingView

/// Full-screen recording UI presented while audio capture is active.
///
/// Shown via `.fullScreenCover` from ``HomeView`` when `HomeViewModel.isRecording == true`.
///
/// iOS 26 visual layers:
/// 1. ``recordingIndicator`` — pulsing glass pill with live status
/// 2. ``waveform`` — Liquid Glass container with live RMS bars
/// 3. ``livePartialTextView`` — glass card with live partial text
/// 4. ``controlsRow`` — Cancel (glass) + Stop (filled) buttons
/// 5. ``durationCounter`` — MM:SS counter in glass badge
///
/// - Parameters:
///   - viewModel: The shared `HomeViewModel` that owns recording state and the audio service.
struct RecordingView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: HomeViewModel

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var pulseOpacity: Double = 1.0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Slightly more intense background during recording — gives the
            // full-screen record UI a sense of focus / "we're capturing now".
            AnimatedGradientBackground(intensity: 1.4)
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                recordingIndicator
                    .padding(.top, Spacing.md)

                Spacer()

                waveform

                livePartialTextView

                Spacer()

                controlsRow

                durationCounter
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.bottom, Spacing.xl)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    /// Pulsing glass pill with "Recording..." label.
    private var recordingIndicator: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(AppColors.recording)
                .frame(width: 12, height: 12)
                .opacity(pulseOpacity)
                .shadow(color: AppColors.recording.opacity(0.6), radius: 8, y: 0)
                .accessibilityHidden(true)
            Text("Recording")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
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
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Recording in progress"))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
            ) {
                pulseOpacity = 0.3
            }
        }
    }

    /// Liquid Glass waveform container.
    private var waveform: some View {
        WaveformView(
            amplitudes: viewModel.audioLevels,
            isActive: viewModel.isRecording
        )
        .frame(height: 140)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Sizing.cardCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Sizing.cardCornerRadius, style: .continuous)
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
        )
        .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
    }

    /// Live partial transcription text (Issue #20c).
    @ViewBuilder
    private var livePartialTextView: some View {
        if viewModel.isStreaming {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        if viewModel.livePartialText.isEmpty {
                            placeholderText
                        } else {
                            Text(viewModel.livePartialText)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityLabel(Text("Live transcription"))
                        }
                        Color.clear
                            .frame(height: 1)
                            .id(Self.bottomAnchor)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                }
                .frame(maxHeight: 140)
                .background(
                    RoundedRectangle(cornerRadius: Sizing.cardCornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Sizing.cardCornerRadius, style: .continuous)
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
                )
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.3),
                    value: viewModel.livePartialText.isEmpty
                )
                .onChange(of: viewModel.livePartialText) { _, _ in
                    guard !reduceMotion else { return }
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
                    }
                }
            }
        } else {
            Color.clear.frame(height: 0)
        }
    }

    private static let bottomAnchor = "livePartialText.bottom"

    /// "Listening…" placeholder.
    private var placeholderText: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
                .tint(.secondary)
            Text("Listening…")
                .font(.system(.body, design: .rounded).italic())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(Text("Listening for speech"))
    }

    /// Cancel + Stop buttons.
    private var controlsRow: some View {
        HStack(spacing: Spacing.md) {
            Button {
                Task { await viewModel.cancelRecording() }
            } label: {
                Text("Cancel")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizing.buttonHeight)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
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
                    )
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(Text("Cancel recording"))

            Button {
                Task { await viewModel.stopRecording() }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Sizing.buttonHeight)
                .background(
                    Capsule()
                        .fill(AppColors.recording)
                )
                .shadow(color: AppColors.recording.opacity(0.4), radius: 16, y: 8)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(Text("Stop recording and transcribe"))
        }
    }

    /// MM:SS counter in glass badge.
    @ViewBuilder
    private var durationCounter: some View {
        if let startTime = viewModel.recordingStartTime {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = max(0, Int(context.date.timeIntervalSince(startTime)))
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "timer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(formatDuration(elapsed))
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule()
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
                )
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            }
            .accessibilityLabel(Text("Recording duration"))
        } else {
            Text("00:00")
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityHidden(true)
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - PressableButtonStyle

/// iOS 26 native-feeling press animation for buttons.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.glassBouncy, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    RecordingView(
        viewModel: HomeViewModel(
            transcriptionService: TranscriptionService(),
            modelManager: ModelManager()
        )
    )
}
