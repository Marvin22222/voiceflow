//
//  HomeView.swift
//  VoiceFlow
//
//  Main capture screen with iOS 26 Liquid Glass design language.
//  Hold-to-talk mic button centered on a layered background
//  with translucent glass cards for status and result preview.
//

import SwiftUI
import VoiceFlowShared

// MARK: - HomeView

/// Main screen for capturing voice. Hold to talk, release to insert.
///
/// Layered states (Issue #22):
/// - **Blocked** — microphone permission denied or no model downloaded.
///   Renders an inline ``ErrorStateView`` or ``EmptyStateView`` in place of
///   the mic button so the user sees a clear next action.
/// - **Ready** — model loaded, permission granted. Shows the hold-to-talk
///   mic button with the current model badge and result preview.
struct HomeView: View {

    // MARK: - Environment

    @Environment(TranscriptionService.self) private var transcriptionService
    @Environment(ModelManager.self) private var modelManager

    // MARK: - State

    @StateObject private var viewModel: HomeViewModel
    @State private var showSettings = false

    /// One-shot celebration burst when a new result arrives. Only fires on
    /// the *first* result in this session so it stays a delight moment
    /// rather than becoming visual noise on every recording.
    @State private var showCelebrationBurst = false
    @State private var didCelebrateFirstResult = false

    // MARK: - Computed State (Issue #22)

    /// Whether the app is fully ready to record (permission + model).
    private var isBlocked: Bool {
        viewModel.microphonePermission == .denied || viewModel.activeModel == nil
    }

    /// Reason recording is currently blocked (nil when ready).
    private var blockedState: BlockedState? {
        if viewModel.microphonePermission == .denied {
            return .microphoneDenied
        }
        if viewModel.activeModel == nil {
            return .noModel
        }
        return nil
    }

    // MARK: - Initialization

    init() {
        // We need to use a placeholder here since @Environment isn't available in init
        // The real initialization happens in .onAppear or body
        // TODO: Refactor to use proper DI
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            transcriptionService: TranscriptionService(),
            modelManager: ModelManager()
        ))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

            GeometryReader { geo in
                VStack(spacing: Spacing.md) {
                    header

                    Spacer()
                        .frame(height: Spacing.lg)

                    content

                    Spacer()

                    if !isBlocked {
                        hintView
                            .padding(.bottom, Spacing.sm)
                    }

                    modelSelector
                        .padding(.bottom, Spacing.md)
                }
                .padding(.horizontal, Spacing.pageHorizontal)
                .padding(.top, Spacing.sm)
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .task {
            await viewModel.onAppear()
        }
        // Issue #27: respond to `voiceflow://record` deep-links from the
        // keyboard extension by triggering a recording session.
        .onReceive(NotificationCenter.default.publisher(for: .voiceflowStartRecording)) { _ in
            Task { await viewModel.startRecording() }
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            // Issue #22: offer a Retry button when transcription failed.
            if let msg = viewModel.errorMessage, msg.lowercased().contains("transcrib") {
                Button("Retry") {
                    viewModel.errorMessage = nil
                    Task { await viewModel.retryLastTranscription() }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } else {
                Button("OK") { viewModel.errorMessage = nil }
            }
        } message: { error in
            Text(error)
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.isRecording },
            set: { _ in /* VM is source of truth; cover auto-dismisses when isRecording flips to false */ }
        )) {
            RecordingView(viewModel: viewModel)
        }
        // Issue #23: present polished Result screen as a sheet after
        // transcription completes. The VM flips showResult=true on success;
        // the sheet auto-dismisses when the user taps Back/Insert (which
        // sets it back to false).
        .sheet(isPresented: Binding(
            get: { viewModel.showResult && !viewModel.transcribedText.isEmpty },
            set: { presented in
                if !presented { viewModel.showResult = false }
            }
        )) {
            ResultView(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationBackground(.regularMaterial)
                .presentationCornerRadius
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.regularMaterial)
                .presentationCornerRadius
        }
        .overlay {
            // First-result celebration: a subtle particle burst with checkmark.
            SuccessBurst(isActive: $showCelebrationBurst)
                .allowsHitTesting(false)
        }
        .onChange(of: viewModel.lastResult) { _, newResult in
            guard let newResult, !didCelebrateFirstResult else { return }
            didCelebrateFirstResult = true
            showCelebrationBurst = true
            // Subtle haptic on first success.
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            _ = newResult // suppress unused
        }
    }

    // MARK: - Content Switch (Issue #22)

    /// The main content area: either the ready-state mic button, or one of
    /// the blocked-state views (model missing / mic denied / permission pending).
    @ViewBuilder
    private var content: some View {
        switch blockedState {
        case .microphoneDenied:
            ErrorStateView(
                icon: "mic.slash.fill",
                title: "Microphone Access Denied",
                message: "VoiceFlow needs microphone access to record audio. Open Settings to grant permission.",
                primaryActionLabel: "Open Settings",
                primaryAction: {
                    viewModel.openSystemSettings()
                },
                secondaryActionLabel: "Retry",
                secondaryAction: {
                    Task { await viewModel.requestMicrophonePermission() }
                }
            )
        case .noModel:
            EmptyStateView(
                icon: "arrow.down.circle.fill",
                title: "No Model Downloaded",
                message: "Download a transcription model to start using VoiceFlow. Whisper Base is a good starting point (~75 MB). Switch to the Models tab below to get started.",
                actionLabel: nil,
                action: nil
            )
        case nil:
            micButton
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Good " + timeOfDayGreeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("VoiceFlow")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .tracking(-0.5)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
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
                                lineWidth: 1
                            )
                    )
            }
            .accessibilityLabel("Settings")
        }
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<18: return "afternoon"
        default: return "evening"
        }
    }

    private var hintView: some View {
        Text(viewModel.transcribedText.isEmpty ? "Tap to dictate" : "Tap to record again")
            .font(.footnote)
            .foregroundStyle(.secondary)
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
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
    }

    private var micButton: some View {
        MicButton(
            isRecording: viewModel.isRecording,
            isProcessing: viewModel.isTranscribing,
            onPress: {
                await viewModel.startRecording()
            },
            onRelease: {
                await viewModel.stopRecording()
            }
        )
    }

    private var modelSelector: some View {
        VStack(spacing: Spacing.smPlus) {
            // TODO(#23): transcribedText + Copy/Reuse-Buttons (Result Screen)
            if !viewModel.transcribedText.isEmpty {
                Text(viewModel.transcribedText)
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 120)
                    .background(
                        RoundedRectangle(cornerRadius: Sizing.cardCornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Sizing.cardCornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
            }

            HStack(spacing: Spacing.sm) {
                if let activeModel = viewModel.activeModel {
                    ModelBadge(model: activeModel)
                }
            }
        }
    }
}

// MARK: - BlockedState

/// Reason the recording flow is blocked (Issue #22).
private enum BlockedState {
    case microphoneDenied
    case noModel
}

// MARK: - ModelBadge

/// Small badge showing the currently active model.
struct ModelBadge: View {

    // MARK: - Properties

    let model: ModelDefinition

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: model.backendType.symbolName)
                .font(.system(size: 12, weight: .semibold))
            Text(model.displayName)
                .font(.caption.weight(.semibold))
            Text(model.sizeString)
                .font(.caption2)
                .foregroundStyle(.secondary)
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
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - Preview

#Preview("Ready") {
    HomeView()
        .environment(TranscriptionService())
        .environment(ModelManager())
}

#Preview("Blocked — No Model") {
    HomeView()
        .environment(TranscriptionService())
        .environment(ModelManager())
}

#Preview("Blocked — Mic Denied") {
    HomeView()
        .environment(TranscriptionService())
        .environment(ModelManager())
}
