//
//  OnboardingFlow.swift
//  VoiceFlow
//
//  5-screen onboarding experience for first launch.
//

import SwiftUI

// MARK: - OnboardingFlow

/// First-launch onboarding flow.
struct OnboardingFlow: View {
    
    // MARK: - Properties
    
    let onFinish: () -> Void
    
    // MARK: - State
    
    @State private var currentPage = 0
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomePage(onNext: { advance() })
                .tag(0)
            
            ChooseModelPage(onNext: { advance() })
                .tag(1)
            
            MicrophonePermissionPage(onNext: { advance() })
                .tag(2)
            
            KeyboardSetupPage(onNext: { advance() }, onSkip: { finish() })
                .tag(3)
            
            ReadyPage(onFinish: { finish() })
                .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(AppColors.backgroundDark.ignoresSafeArea())
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
    
    // MARK: - Actions
    
    private func advance() {
        withAnimation {
            currentPage += 1
        }
    }
    
    private func finish() {
        onFinish()
    }
}

// MARK: - WelcomePage

struct WelcomePage: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            VStack(spacing: Spacing.md) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("VoiceFlow ✨")
                    .font(.largeTitle.bold())
                Text("Voice-to-text, 100% local.\nNo subscriptions. No cloud.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                FeatureRow(icon: "lock.shield.fill", title: "Privacy first")
                FeatureRow(icon: "gift.fill", title: "Free forever")
                FeatureRow(icon: "cpu.fill", title: "On-device AI")
            }
            .padding(.horizontal, Spacing.xl)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizing.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .tint(.appAccent)
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - ChooseModelPage

struct ChooseModelPage: View {
    let onNext: () -> Void
    @State private var selectedModel: ModelDefinition = .whisperBase
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressIndicator(current: 1, total: 4)
                .padding(.top, Spacing.lg)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Choose your model")
                    .font(.title.bold())
                Text("You can change this anytime in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            
            VStack(spacing: Spacing.sm) {
                ForEach([ModelDefinition.whisperTiny, .whisperBase, .whisperSmall], id: \.id) { model in
                    ModelPickerRow(
                        model: model,
                        isSelected: selectedModel.id == model.id,
                        onSelect: { selectedModel = model }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizing.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .tint(.appAccent)
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - MicrophonePermissionPage

struct MicrophonePermissionPage: View {
    let onNext: () -> Void
    @State private var permissionGranted = false
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            ProgressIndicator(current: 2, total: 4)
                .padding(.top, Spacing.lg)
            
            Spacer()
            
            VStack(spacing: Spacing.lg) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.appAccent)
                
                Text("Allow microphone access")
                    .font(.title2.bold())
                
                Text("We need the microphone to capture your voice. Audio is processed 100% on-device and never leaves your phone.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            
            Spacer()
            
            Button(action: onNext) {
                Text(permissionGranted ? "Continue" : "Allow Microphone")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizing.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .tint(.appAccent)
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - KeyboardSetupPage

struct KeyboardSetupPage: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressIndicator(current: 3, total: 4)
                .padding(.top, Spacing.lg)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Enable Keyboard")
                    .font(.title.bold())
                Text("Optional — use VoiceFlow in any app:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                StepRow(number: 1, text: "Open Settings app")
                StepRow(number: 2, text: "General → Keyboard → Keyboards")
                StepRow(number: 3, text: "Add New Keyboard...")
                StepRow(number: 4, text: "Select \"VoiceFlow\"")
            }
            .padding(.horizontal, Spacing.md)
            
            Spacer()
            
            VStack(spacing: Spacing.sm) {
                Button(action: onNext) {
                    Text("I've Done This")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: Sizing.buttonHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appAccent)
                
                Button("Skip for Now", action: onSkip)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - ReadyPage

struct ReadyPage: View {
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            ProgressIndicator(current: 4, total: 4)
                .padding(.top, Spacing.lg)
            
            Spacer()
            
            VStack(spacing: Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(AppColors.success)
                
                Text("You're All Set!")
                    .font(.largeTitle.bold())
                
                Text("Press and hold the mic button to start dictating.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            
            Spacer()
            
            Button(action: onFinish) {
                Text("Start Using VoiceFlow")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizing.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .tint(.appAccent)
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.appAccent)
                .frame(width: 32)
            Text(title)
                .font(.body)
            Spacer()
        }
    }
}

struct ModelPickerRow: View {
    let model: ModelDefinition
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(model.displayName)
                            .font(.headline)
                        if model.id == "whisper-base" {
                            Text("Recommended")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.appAccent.opacity(0.2))
                                .foregroundStyle(.appAccent)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(model.sizeString) · \(model.languageSummary)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.appAccent)
                }
            }
            .padding(Spacing.md)
            .background(AppColors.surfaceDark)
            .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Sizing.cornerRadius)
                    .stroke(isSelected ? Color.appAccent : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

struct StepRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.appAccent)
                .clipShape(Circle())
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

struct ProgressIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < current ? Color.appAccent : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlow(onFinish: {})
}
