//
//  OnboardingFlow.swift
//  VoiceFlow
//
//  iOS 26 Liquid Glass style 5-screen onboarding experience. Each
//  page features a glass-card layout with iOS 26 typography, smooth
//  page transitions, and refined spring animations.
//

import SwiftUI

// MARK: - OnboardingFlow

/// First-launch onboarding flow with iOS 26 Liquid Glass design.
struct OnboardingFlow: View {

    // MARK: - Properties

    let onFinish: () -> Void

    // MARK: - State

    @State private var currentPage = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

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
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Actions

    private func advance() {
        withAnimation(.glassSmooth) {
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
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.2)

                Text("VoiceFlow")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .tracking(-0.5)

                Text("Voice-to-text, 100% local.\nNo subscriptions. No cloud.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Glass card with features
            VStack(alignment: .leading, spacing: Spacing.md) {
                FeatureRow(icon: "lock.shield.fill", title: "Privacy first", tint: AppColors.violet)
                FeatureRow(icon: "gift.fill", title: "Free forever", tint: AppColors.pink)
                FeatureRow(icon: "cpu.fill", title: "On-device AI", tint: AppColors.cyan)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
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
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            .padding(.horizontal, Spacing.pageHorizontal)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizing.buttonHeight)
                    .background(
                        Capsule()
                            .fill(.appAccent)
                    )
                    .shadow(color: .appAccent.opacity(0.4), radius: 16, y: 8)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.bottom, Spacing.xxl)
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
                .padding(.horizontal, Spacing.pageHorizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Choose your model")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .tracking(-0.4)
                Text("You can change this anytime in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.pageHorizontal)

            VStack(spacing: Spacing.sm) {
                ForEach([ModelDefinition.whisperTiny, .whisperBase, .whisperSmall], id: \.id) { model in
                    ModelPickerRow(
                        model: model,
                        isSelected: selectedModel.id == model.id,
                        onSelect: { selectedModel = model }
                    )
                }
            }
            .padding(.horizontal, Spacing.pageHorizontal)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizing.buttonHeight)
                    .background(
                        Capsule()
                            .fill(.appAccent)
                    )
                    .shadow(color: .appAccent.opacity(0.4), radius: 16, y: 8)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.bottom, Spacing.xxl)
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
                .padding(.horizontal, Spacing.pageHorizontal)

            Spacer()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 140, height: 140)
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
                                    lineWidth: 1.2
                                )
                        )
                    Circle()
                        .fill(.appAccent.opacity(0.15))
                        .frame(width: 110, height: 110)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.appAccent)
                }
                .shadow(color: .appAccent.opacity(0.3), radius: 24, y: 12)

                Text("Allow microphone access")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .tracking(-0.3)

                Text("We need the microphone to capture your voice. Audio is processed 100% on-device and never leaves your phone.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            Button(action: onNext) {
                Text(permissionGranted ? "Continue" : "Allow Microphone")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizing.buttonHeight)
                    .background(
                        Capsule()
                            .fill(.appAccent)
                    )
                    .shadow(color: .appAccent.opacity(0.4), radius: 16, y: 8)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.bottom, Spacing.xxl)
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
                .padding(.horizontal, Spacing.pageHorizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Enable Keyboard")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .tracking(-0.4)
                Text("Optional — use VoiceFlow in any app:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.pageHorizontal)

            VStack(spacing: Spacing.sm) {
                StepRow(number: 1, text: "Open Settings app")
                StepRow(number: 2, text: "General → Keyboard → Keyboards")
                StepRow(number: 3, text: "Add New Keyboard...")
                StepRow(number: 4, text: "Select \"VoiceFlow\"")
            }
            .padding(.horizontal, Spacing.pageHorizontal)

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button(action: onNext) {
                    Text("I've Done This")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: Sizing.buttonHeight)
                        .background(
                            Capsule()
                                .fill(.appAccent)
                        )
                        .shadow(color: .appAccent.opacity(0.4), radius: 16, y: 8)
                }
                .buttonStyle(PressableButtonStyle())

                Button("Skip for Now", action: onSkip)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.bottom, Spacing.xxl)
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
                .padding(.horizontal, Spacing.pageHorizontal)

            Spacer()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 140, height: 140)
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
                                    lineWidth: 1.2
                                )
                        )
                    Circle()
                        .fill(AppColors.success.opacity(0.15))
                        .frame(width: 110, height: 110)
                    Image(systemName: "checkmark")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.success)
                }
                .shadow(color: AppColors.success.opacity(0.3), radius: 24, y: 12)

                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .tracking(-0.5)

                Text("Tap the mic on Home to start dictating. Your voice never leaves your phone.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            Button(action: onFinish) {
                Text("Start Using VoiceFlow")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizing.buttonHeight)
                    .background(
                        Capsule()
                            .fill(.appAccent)
                    )
                    .shadow(color: .appAccent.opacity(0.4), radius: 16, y: 8)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let title: String
    var tint: Color = .appAccent

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }

            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))

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
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Spacing.xs) {
                        Text(model.displayName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        if model.id == "whisper-base" {
                            Text("Recommended")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(.appAccent.opacity(0.25))
                                )
                                .foregroundStyle(.appAccent)
                        }
                    }
                    Text("\(model.sizeString) · \(model.languageSummary)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    ZStack {
                        Circle()
                            .fill(.appAccent)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Sizing.cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Sizing.cardCornerRadius, style: .continuous)
                    .stroke(
                        isSelected
                            ? LinearGradient(
                                colors: [Color.appAccent, Color.appAccent.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(.appAccent)
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlow(onFinish: {})
}
