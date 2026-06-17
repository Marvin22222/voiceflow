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
struct HomeView: View {
    
    // MARK: - Environment
    
    @Environment(TranscriptionService.self) private var transcriptionService
    @Environment(ModelManager.self) private var modelManager
    
    // MARK: - State
    
    @StateObject private var viewModel: HomeViewModel
    @State private var showSettings = false
    
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
            
            VStack(spacing: Spacing.lg) {
                header
                Spacer()
                micButton
                Spacer()
                modelSelector
            }
            .padding(Spacing.md)
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
            Button("OK") { viewModel.errorMessage = nil }
        } message: { error in
            Text(error)
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
            } else {
                Text("Tap and hold to dictate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: Spacing.md) {
                if let activeModel = viewModel.activeModel {
                    ModelBadge(model: activeModel)
                }
                
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

// MARK: - MicButton

/// Large circular mic button with hold-to-talk gesture and pulse animation.
struct MicButton: View {
    
    // MARK: - Properties
    
    let isRecording: Bool
    let isProcessing: Bool
    let onPress: () async -> Void
    let onRelease: () async -> Void
    
    // MARK: - State
    
    @State private var scale: CGFloat = 1.0
    @State private var pulseScale: CGFloat = 1.0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Pulse ring (only when recording)
            if isRecording {
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
                            if !isRecording && !isProcessing {
                                Task {
                                    await onPress()
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    scale = 0.92
                                }
                            }
                        }
                        .onEnded { _ in
                            if isRecording {
                                Task {
                                    await onRelease()
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    scale = 1.0
                                }
                            }
                        }
                )
        }
        .onChange(of: isRecording) { _, newValue in
            pulseScale = newValue ? 1.3 : 1.0
        }
    }
    
    private var iconName: String {
        if isProcessing { return "ellipsis.circle.fill" }
        return isRecording ? "stop.fill" : "mic.fill"
    }
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

#Preview {
    HomeView()
        .environment(TranscriptionService())
        .environment(ModelManager())
}
