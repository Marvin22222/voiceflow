//
//  WaveformView.swift
//  VoiceFlow
//
//  Live audio waveform during recording. Canvas-based, redrawn at 60fps via TimelineView,
//  driven by RMS-normalized amplitudes from HomeViewModel.
//

import SwiftUI
import VoiceFlowShared

// MARK: - WaveformView

/// Live waveform view shown in ``RecordingView`` while audio is captured.
///
/// Draws up to 30 vertical bars (4pt wide) whose height is proportional to the
/// corresponding normalized RMS amplitude (0–1). Bars are rendered via SwiftUI
/// `Canvas` and redrawn at ~60fps using `TimelineView(.animation)`.
///
/// Freeze-on-stop behavior is driven by the parent: `HomeViewModel.handleAudioBuffer`
/// stops appending to `amplitudes` when `isRecording == false`, so this View's
/// `amplitudes` parameter naturally holds its last value. Reduce Motion further
/// freezes the snapshot at the point it was toggled on, via an internal `@State`.
///
/// - Parameters:
///   - amplitudes: Rolling buffer of normalized RMS values, oldest first. Up to 30 entries.
///   - isActive: Whether audio is currently being recorded. `false` freezes the bars.
struct WaveformView: View {
    
    // MARK: - Properties
    
    let amplitudes: [Float]
    let isActive: Bool
    
    // MARK: - Environment
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - State
    
    /// Snapshot of `amplitudes` taken at the last non-Reduce-Motion update.
    /// Used to keep the bars static while Reduce Motion is active.
    @State private var frozenSnapshot: [Float] = []
    
    // MARK: - Body
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { _ in
            Canvas { ctx, size in
                drawBars(ctx: ctx, size: size, amps: displayAmplitudes)
            }
        }
        .frame(height: 60)
        .accessibilityLabel(Text("Audio waveform"))
        .onAppear {
            // Capture initial snapshot so Reduce Motion has something to show.
            frozenSnapshot = amplitudes
        }
        .onChange(of: amplitudes) { _, _ in
            // Track live values only when Reduce Motion is OFF. When Reduce Motion
            // is ON, the snapshot stays at its last value, freezing the bars.
            guard !reduceMotion else { return }
            frozenSnapshot = amplitudes
        }
    }
    
    // MARK: - Display Selection
    
    /// Selects which amplitude array to render.
    /// - **Not recording:** VM has frozen `amplitudes`; render as-is.
    /// - **Recording + Reduce Motion:** render the frozen snapshot.
    /// - **Recording + no Reduce Motion:** render the live `amplitudes`.
    private var displayAmplitudes: [Float] {
        if !isActive { return amplitudes }
        if reduceMotion { return frozenSnapshot }
        return amplitudes
    }
    
    // MARK: - Drawing
    
    /// Renders one rounded bar per amplitude value, centered vertically,
    /// distributed evenly across the canvas width.
    private func drawBars(ctx: GraphicsContext, size: CGSize, amps: [Float]) {
        guard !amps.isEmpty else { return }
        
        let barCount = amps.count
        let barWidth: CGFloat = 4
        let totalBarWidth = CGFloat(barCount) * barWidth
        let remainingWidth = max(0, size.width - totalBarWidth)
        let spacing = barCount > 1 ? remainingWidth / CGFloat(barCount - 1) : 0
        let cornerRadius = min(barWidth / 2, 2)
        let maxHeight = size.height
        
        for (i, amplitude) in amps.enumerated() {
            let clampedAmp = max(0, min(1, amplitude))
            // Floor at 2pt so even silent buffers show a thin sliver
            // (consistent with the #20 placeholder design).
            let barHeight = max(2, CGFloat(clampedAmp) * maxHeight)
            let x = CGFloat(i) * (barWidth + spacing)
            let y = (maxHeight - barHeight) / 2
            let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = Path(roundedRect: rect, cornerRadius: cornerRadius)
            ctx.fill(path, with: .color(AppColors.appAccent))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        // Idle (no amplitudes)
        WaveformView(amplitudes: [], isActive: false)
            .frame(width: 300)
        
        // Mid-recording (partial buffer)
        WaveformView(
            amplitudes: [0.1, 0.3, 0.5, 0.7, 0.4, 0.2, 0.6, 0.8, 0.5, 0.3],
            isActive: true
        )
        .frame(width: 300)
        
        // Full buffer (30 bars at various heights)
        WaveformView(
            amplitudes: (0..<30).map { i in
                Float(abs(sin(Double(i) * 0.4)) * 0.7 + 0.1)
            },
            isActive: true
        )
        .frame(width: 300)
    }
    .padding()
    .background(AppColors.backgroundDark)
}
