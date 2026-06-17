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
    // TODO(#21): Settings-Sheet hier einhängen (.sheet(isPresented: $showSettings))
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
            
            GeometryReader { geo in
                VStack(spacing: Spacing.lg) {
                    header
                    title
                    // 30 % vom oberen Rand minus halbe Button-Höhe → Button-Zentrum auf ~30 %
                    Spacer().frame(height: max(0, geo.size.height * 0.3 - 50))
                    micButton
                    Spacer()
                    hintView
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
    
    private var title: some View {
        Text("VoiceFlow")
            .font(.title2)
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
    }
    
    private var hintView: some View {
        Text("Press and hold")
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
