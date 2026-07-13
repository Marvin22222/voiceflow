//
//  RecordingView.swift
//  VoiceFlow
//
//  Full-screen recording UI shown while audio capture is active.
//  Contains: pulsing indicator, waveform placeholder, MM:SS counter, and Stop/Cancel controls.
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
/// The waveform area is a static placeholder in this PR; the live `WaveformView` with
/// RMS-driven bars will be added in a follow-up issue (#20b).
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
            AppColors.backgroundDark.ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                recordingIndicator
                Spacer()
                waveformPlaceholder
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
    
    /// Static placeholder for the live waveform: 30 bars at neutral height.
    /// Real `WaveformView` with RMS-driven bars will replace this in #20b.
    private var waveformPlaceholder: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<30, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.appAccent)
                    .frame(width: 4, height: 24)
            }
        }
        .frame(height: 60)
        .accessibilityLabel(Text("Audio waveform"))
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
