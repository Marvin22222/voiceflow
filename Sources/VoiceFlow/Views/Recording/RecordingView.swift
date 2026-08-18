//
//  RecordingView.swift
//  VoiceFlow
//
//  Full-screen recording UI shown while audio capture is active.
//  Contains: pulsing indicator, live RMS waveform (Issue #20b),
//  live partial transcription text (Issue #20c), MM:SS counter, and Stop/Cancel controls.
//

import SwiftUI
import VoiceFlowShared

// MARK: - RecordingView

/// Full-screen recording UI presented while audio capture is active.
///
/// Shown via `.fullScreenCover` from ``HomeView`` when `HomeViewModel.isRecording == true`.
/// Reads `HomeViewModel.recordingStartTime` and uses `TimelineView(.periodic)` to drive
/// the MM:SS counter at 1 Hz without managing a `Timer`.
///
/// ## Layers
///
/// 1. ``recordingIndicator`` — pulsing red dot + label (top).
/// 2. ``waveform`` — live RMS-driven bars via ``WaveformView`` (Issue #20b).
/// 3. ``livePartialTextView`` — running partial transcription via the
///    streaming backend (Issue #20c). Hidden when no streaming backend is
///    available; shows "Listening…" placeholder before the first chunk.
/// 4. ``controlsRow`` — Stop (primary) + Cancel (secondary) buttons.
/// 5. ``durationCounter`` — MM:SS counter (bottom).
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
                Spacer()
                waveform
                livePartialTextView
                Spacer()
                controlsRow
                durationCounter
            }
            .padding(Spacing.lg)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    
    /// Pulsing red dot + "Recording..." label. Pulse animation is gated by Reduce Motion.
    private var recordingIndicator: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(AppColors.recording)
                .frame(width: 12, height: 12)
                .opacity(pulseOpacity)
                .accessibilityHidden(true)
            Text("Recording...")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Recording in progress"))
        .onAppear {
            // Apple recommends gating decorative animation on Reduce Motion.
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
            ) {
                pulseOpacity = 0.3
            }
        }
    }
    
    /// Live waveform during recording. RMS-driven bars animated at 60fps via TimelineView.
    /// Freezes on stop (VM stops appending) and under Reduce Motion (View-side snapshot).
    private var waveform: some View {
        WaveformView(
            amplitudes: viewModel.audioLevels,
            isActive: viewModel.isRecording
        )
    }

    /// Live partial transcription text (Issue #20c).
    ///
    /// Shown when streaming is active. Three states:
    /// 1. **No streaming** — hidden (zero-height placeholder, animates out).
    /// 2. **Streaming, no text yet** — faint "Listening…" placeholder, animates in.
    /// 3. **Streaming, partial text** — the running text, scrollable to bottom,
    ///    with a 300 ms fade-in on each new chunk.
    ///
    /// Smooth scroll-to-bottom: ScrollViewReader anchors to `bottomAnchor`
    /// which we scroll to on each text change via `.onChange(of:)`.
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
                                .font(.body)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityLabel(Text("Live transcription"))
                        }
                        // Anchor for scroll-to-bottom.
                        Color.clear
                            .frame(height: 1)
                            .id(Self.bottomAnchor)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .frame(maxHeight: 140)
                .background(AppColors.surfaceDark.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadius))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.3),
                    value: viewModel.livePartialText.isEmpty
                )
                .onChange(of: viewModel.livePartialText) { _, _ in
                    // Scroll to the bottom anchor whenever new text arrives.
                    guard !reduceMotion else { return }
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
                    }
                }
                .onAppear {
                    // Initial scroll (in case text was already populated).
                    proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
                }
            }
        } else {
            // Streaming not active — zero-height placeholder so the layout
            // doesn't shift when streaming starts/stops.
            Color.clear.frame(height: 0)
        }
    }

    /// Anchor ID used by ``livePartialTextView`` for scroll-to-bottom.
    private static let bottomAnchor = "livePartialText.bottom"

    /// "Listening…" placeholder shown while streaming but no chunks yet.
    private var placeholderText: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
                .tint(.secondary)
            Text("Listening…")
                .font(.body.italic())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(Text("Listening for speech"))
    }
    
    /// Stop (primary, red) and Cancel (secondary, surface) buttons.
    /// Cancel discards captured audio without invoking transcription.
    private var controlsRow: some View {
        HStack(spacing: Spacing.md) {
            // Cancel (secondary)
            Button {
                Task { await viewModel.cancelRecording() }
            } label: {
                Text("Cancel")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.surfaceDark)
                    .clipShape(Capsule())
            }
            .accessibilityLabel(Text("Cancel recording"))
            
            // Stop (primary)
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
                .frame(height: 50)
                .background(AppColors.recording)
                .clipShape(Capsule())
            }
            .accessibilityLabel(Text("Stop recording and transcribe"))
        }
    }
    
    /// MM:SS counter driven by `TimelineView(.periodic)` at 1 Hz.
    /// Falls back to a hidden "00:00" placeholder when no start time is available.
    @ViewBuilder
    private var durationCounter: some View {
        if let startTime = viewModel.recordingStartTime {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = max(0, Int(context.date.timeIntervalSince(startTime)))
                Text(formatDuration(elapsed))
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .accessibilityLabel(Text("Recording duration"))
        } else {
            // Pre-recording tick state — view should rarely be visible in this branch.
            Text("00:00")
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityHidden(true)
        }
    }
    
    // MARK: - Helpers
    
    /// Formats elapsed seconds as `MM:SS` (e.g. 0 → "00:00", 75 → "01:15").
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Preview

#Preview {
    RecordingView(
        viewModel: HomeViewModel(
            audioService: AudioCaptureService(),
            transcriptionService: TranscriptionService(),
            modelManager: ModelManager()
        )
    )
}
