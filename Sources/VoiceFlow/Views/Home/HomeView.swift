//
//  HomeView.swift
//  VoiceFlow
//
//  Main capture screen with hold-to-talk mic button.
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
    
    // MARK: - Computed State (Issue #22)
    
    /// Whether the app is fully ready to record (permission + model).
    private var isBlocked: Bool {
        viewModel.microphonePermission == .denied || viewModel.activeModel == nil
    }
    
    /// Whether we're waiting for the user to grant microphone permission
    /// (system prompt pending or about to be shown).
    private var needsMicrophonePermission: Bool {
        viewModel.microphonePermission == .undetermined
    }
    
    /// Why recording is currently blocked (nil when ready).
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
            AppColors.backgroundDark.ignoresSafeArea()
            
            GeometryReader { geo in
                VStack(spacing: Spacing.lg) {
                    header
                    title
                    Spacer().frame(height: max(0, geo.size.height * 0.25 - 50))
                    content
                    Spacer()
                    if !isBlocked {
                        hintView
                    }
                    modelSelector
                }
                .padding(Spacing.md)
            }
        }
        .task {
            await viewModel.onAppear()
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
            // Heuristic: errors that mention "transcrib" are recoverable;
            // other errors (e.g. permission, storage) just dismiss.
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
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.backgroundDark)
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
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var title: some View {
        Text("VoiceFlow")
            .font(.title2)
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
    }
    
    private var hintView: some View {
        Text(viewModel.transcribedText.isEmpty ? "Press and hold" : "Tap mic to record again")
            .font(.footnote)
            .foregroundStyle(.secondary)
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
        VStack(spacing: Spacing.sm) {
            // TODO(#23): transcribedText + Copy/Reuse-Buttons (Result Screen)
            if !viewModel.transcribedText.isEmpty {
                Text(viewModel.transcribedText)
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(AppColors.surfaceDark)
                    .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadius))
                    .frame(maxHeight: 100)
            }
            
            HStack(spacing: Spacing.md) {
                if let activeModel = viewModel.activeModel {
                    ModelBadge(model: activeModel)
                }
                
                // TODO(#XX): Switch-Model-Button → Picker-Screen
                Button {
                    // TODO: Show model picker
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.stack.3d.up")
                        Text("Switch Model")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
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

// Removed unused AppTab declaration (was previously here).

// MARK: - ModelBadge

/// Small badge showing the currently active model.
struct ModelBadge: View {
    
    // MARK: - Properties
    
    let model: ModelDefinition
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: model.backendType.symbolName)
                .font(.caption)
            Text(model.displayName)
                .font(.caption.weight(.medium))
            Text(model.sizeString)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(AppColors.surfaceDark)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Ready") {
    HomeView()
        .environment(TranscriptionService())
        .environment(ModelManager())
}

#Preview("Blocked — No Model") {
    // Force the no-model state by wrapping with a VM that has no active model.
    HomeView()
        .environment(TranscriptionService())
        .environment(ModelManager())
}

#Preview("Blocked — Mic Denied") {
    HomeView()
        .environment(TranscriptionService())
        .environment(ModelManager())
}