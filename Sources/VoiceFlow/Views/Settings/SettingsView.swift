//
//  SettingsView.swift
//  VoiceFlow
//
//  iOS 26 Liquid Glass style settings — presented as a modal sheet
//  from HomeView (Issue #21). Sections are floating glass cards with
//  rounded typography and refined animations.
//

import SwiftUI
import SwiftData
import UIKit
import VoiceFlowShared

// MARK: - SettingsView

/// App settings screen, designed to be presented as a modal sheet
/// from ``HomeView`` via `.sheet(isPresented: $showSettings)`.
///
/// iOS 26 layout:
/// - Drag handle visible at the top
/// - `.medium` and `.large` detents
/// - Glass background with `.regularMaterial`
/// - Each section is a glass card
/// - Refined typography with `design: .rounded`
struct SettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [AppSettings]

    // MARK: - State

    @State private var showOnboarding = false

    // MARK: - Computed Properties

    /// The persisted ``AppSettings`` row, creating one if absent.
    private var settings: AppSettings {
        if let existing = settingsList.first {
            return existing
        }
        let new = AppSettings()
        modelContext.insert(new)
        return new
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.lg, pinnedViews: []) {
                    headerView

                    modelSection
                    appearanceSection
                    keyboardSection
                    actionButtonSection
                    advancedSection
                    aboutSection

                    Spacer()
                        .frame(height: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.pageHorizontal)
                .padding(.top, Spacing.md)
            }
            .background(AppColors.backgroundDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.appAccent)
                    .accessibilityLabel("Close settings")
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingFlow(onFinish: {
                showOnboarding = false
            })
            .presentationBackground(.regularMaterial)
            .presentationCornerRadius
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Settings")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-0.5)
            Text("Personalize VoiceFlow for your workflow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sections

    private var modelSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                SettingsRow(
                    icon: "waveform",
                    title: "Active Model",
                    trailing: settings.activeModel?.displayName ?? "None",
                    trailingColor: .secondary
                )
                GlassDivider()
                NavigationLink {
                    ModelsView()
                        .navigationTitle("Models")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    SettingsRow(
                        icon: "square.stack.3d.up.fill",
                        title: "Manage Models",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        } footer: {
            Text("Manage downloaded transcription models and their storage.")
        }
    }

    private var appearanceSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                SettingsPicker(
                    icon: "paintbrush.fill",
                    title: "Theme",
                    selection: Binding(
                        get: { settings.themeRaw },
                        set: { settings.themeRaw = $0 }
                    ),
                    options: Theme.allCases.map { ($0.displayName, $0.rawValue) }
                )
                GlassDivider()
                SettingsColorPicker(
                    icon: "drop.fill",
                    title: "Accent",
                    selection: Binding(
                        get: { settings.accentColorRaw },
                        set: { settings.accentColorRaw = $0 }
                    )
                )
            }
        }
    }

    private var keyboardSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    openSystemSettings()
                } label: {
                    SettingsRow(
                        icon: "keyboard",
                        title: "Setup Guide",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)

                GlassDivider()

                SettingsRow(
                    icon: "lock.shield.fill",
                    title: "Allow Full Access",
                    trailing: fullAccessStatusText,
                    trailingColor: fullAccessStatusText == "Granted" ? AppColors.success : .secondary
                )

                GlassDivider()

                Button {
                    // TODO(#24): Trigger keyboard self-test once keyboard extension ships.
                } label: {
                    SettingsRow(
                        icon: "checkmark.circle.fill",
                        title: "Test Keyboard",
                        showChevron: true,
                        disabled: true
                    )
                }
                .buttonStyle(.plain)
                .disabled(true)
            }
        } footer: {
            Text("""
                VoiceFlow's keyboard lets you dictate into any app. \
                Enable it in Settings → General → Keyboard → Keyboards.
                """)
        }
    }

    private var actionButtonSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    openActionButtonGuide()
                } label: {
                    SettingsRow(
                        icon: "button.programmable",
                        title: "Setup Guide",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)

                GlassDivider()

                SettingsToggle(
                    icon: "bolt.fill",
                    title: "Enable on Action Button",
                    isOn: Binding(
                        get: { settings.actionButtonEnabled },
                        set: { settings.actionButtonEnabled = $0 }
                    )
                )
            }
        } footer: {
            Text("iPhone 15 Pro / 16 Pro only. Bind VoiceFlow via Shortcuts → Action Button.")
        }
    }

    private var advancedSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                SettingsPicker(
                    icon: "waveform.path.ecg",
                    title: "Streaming",
                    selection: Binding(
                        get: { settings.streamingPreferenceRaw },
                        set: { settings.streamingPreference = StreamingPreference(rawValue: $0) ?? .auto }
                    ),
                    options: StreamingPreference.allCases.map { ($0.displayName, $0.rawValue) }
                )

                GlassDivider()

                SettingsToggle(
                    icon: "text.alignleft",
                    title: "Auto-punctuation",
                    isOn: Binding(
                        get: { settings.autoPunctuationEnabled },
                        set: { settings.autoPunctuationEnabled = $0 }
                    )
                )

                GlassDivider()

                SettingsToggle(
                    icon: "textformat",
                    title: "Auto-capitalize",
                    isOn: Binding(
                        get: { settings.autoCapitalizationEnabled },
                        set: { settings.autoCapitalizationEnabled = $0 }
                    )
                )

                GlassDivider()

                Button {
                    showOnboarding = true
                } label: {
                    SettingsRow(
                        icon: "sparkles",
                        title: "Show Onboarding",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        } footer: {
            Text("Streaming preference controls how the live partial text behaves during recording.")
        }
    }

    private var aboutSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                SettingsRow(
                    icon: "info.circle.fill",
                    title: "Version",
                    trailing: appVersionString,
                    trailingColor: .secondary
                )

                GlassDivider()

                Link(destination: URL(string: "https://github.com/Marvin22222/voiceflow")!) {
                    SettingsRow(
                        icon: "link",
                        title: "View on GitHub",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)

                GlassDivider()

                Link(destination: URL(string: "https://github.com/Marvin22222/voiceflow/blob/main/LICENSE")!) {
                    SettingsRow(
                        icon: "doc.text.fill",
                        title: "MIT License",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)

                GlassDivider()

                Link(destination: URL(string: "https://github.com/Marvin22222/voiceflow/blob/main/PRIVACY.md")!) {
                    SettingsRow(
                        icon: "hand.raised.fill",
                        title: "Privacy",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    /// Open iOS Settings app at the VoiceFlow keyboard section.
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Action Button is configured via the Shortcuts app; we deep-link there.
    private func openActionButtonGuide() {
        guard let url = URL(string: "shortcuts://") else { return }
        UIApplication.shared.open(url)
    }

    /// Best-effort "Allow Full Access" status. The keyboard extension reports
    /// this via the App Group; we read a flag written by the extension.
    private var fullAccessStatusText: String {
        let granted = AppGroup.sharedDefaults.bool(forKey: "voiceflow.keyboard.hasFullAccess")
        return granted ? "Granted" : "Not granted"
    }

    /// Bundle version + build number, e.g. `0.1.0 (1)`.
    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(v) (\(b))"
    }
}

// MARK: - SettingsCard

/// A glass card container for a settings section.
struct SettingsCard<Content: View, Footer: View>: View {
    let content: Content
    let footer: Footer?

    init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.content = content()
        self.footer = footer()
    }

    init(@ViewBuilder content: () -> Content) where Footer == EmptyView {
        self.content = content()
        self.footer = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            content
                .padding(.vertical, Spacing.sm)
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
                .shadow(color: .black.opacity(0.10), radius: 16, y: 8)

            if let footer {
                footer
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.sm)
            }
        }
    }
}

// MARK: - SettingsRow

/// A single row in a settings card.
struct SettingsRow: View {
    let icon: String
    let title: String
    var trailing: String? = nil
    var trailingColor: Color = .secondary
    var showChevron: Bool = false
    var disabled: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(disabled ? .secondary : .appAccent)
            }

            Text(title)
                .font(.body)
                .foregroundStyle(disabled ? .secondary : .primary)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.subheadline)
                    .foregroundStyle(trailingColor)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.smPlus)
        .contentShape(Rectangle())
        .opacity(disabled ? 0.5 : 1.0)
    }
}

// MARK: - SettingsPicker

/// A picker row in a settings card.
struct SettingsPicker: View {
    let icon: String
    let title: String
    @Binding var selection: String
    let options: [(String, String)]  // (displayName, rawValue)

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.appAccent)
            }

            Text(title)
                .font(.body)

            Spacer()

            Picker(title, selection: $selection) {
                ForEach(options, id: \.1) { option in
                    Text(option.0).tag(option.1)
                }
            }
            .pickerStyle(.menu)
            .tint(.secondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.smPlus)
    }
}

// MARK: - SettingsColorPicker

/// Accent color picker row.
struct SettingsColorPicker: View {
    let icon: String
    let title: String
    @Binding var selection: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.appAccent)
            }

            Text(title)
                .font(.body)

            Spacer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(AccentColorOption.allCases, id: \.rawValue) { option in
                        Button {
                            selection = option.rawValue
                        } label: {
                            Circle()
                                .fill(option.color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selection == option.rawValue ? Color.white : .clear,
                                            lineWidth: 2
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(.black.opacity(0.2), lineWidth: 0.5)
                                )
                                .scaleEffect(selection == option.rawValue ? 1.1 : 1.0)
                                .animation(.glassBouncy, value: selection)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.displayName)
                    }
                }
            }
            .frame(width: 200)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.smPlus)
    }
}

// MARK: - SettingsToggle

/// A toggle row in a settings card.
struct SettingsToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.appAccent)
            }

            Text(title)
                .font(.body)

            Spacer()

            Toggle(isOn: $isOn) {}
                .tint(.appAccent)
                .labelsHidden()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.smPlus)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: AppSettings.self, inMemory: true)
        .preferredColorScheme(.dark)
}
