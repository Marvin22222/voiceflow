//
//  SettingsView.swift
//  VoiceFlow
//
//  App settings — presented as a modal sheet from HomeView (Issue #21).
//

import SwiftUI
import SwiftData
import UIKit
import VoiceFlowShared

// MARK: - SettingsView

/// App settings screen, designed to be presented as a modal sheet
/// from ``HomeView`` via `.sheet(isPresented: $showSettings)`.
///
/// Layout follows Apple Human Interface Guidelines for sheets:
/// - Drag handle visible at the top
/// - `.medium` and `.large` detents
/// - Done button in top-right
/// - Drag-to-dismiss enabled (default sheet behavior)
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
            Form {
                modelSection
                appearanceSection
                keyboardSection
                actionButtonSection
                advancedSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.backgroundDark)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("Close settings")
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingFlow(onFinish: {
                showOnboarding = false
            })
        }
    }
    
    // MARK: - Sections
    
    private var modelSection: some View {
        Section {
            LabeledContent {
                Text(settings.activeModel?.displayName ?? "None")
                    .foregroundStyle(.secondary)
            } label: {
                Label("Active Model", systemImage: "waveform")
            }
            
            NavigationLink {
                ModelsView()
            } label: {
                Label("Manage Models", systemImage: "square.stack.3d.up")
            }
        } header: {
            Text("Model")
        } footer: {
            Text("Manage downloaded transcription models and their storage.")
        }
    }
    
    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: Binding(
                get: { settings.themeRaw },
                set: { settings.themeRaw = $0 }
            )) {
                ForEach(Theme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme.rawValue)
                }
            }
            
            Picker("Accent", selection: Binding(
                get: { settings.accentColorRaw },
                set: { settings.accentColorRaw = $0 }
            )) {
                ForEach(AccentColorOption.allCases, id: \.self) { color in
                    HStack {
                        Circle()
                            .fill(Color(hex: color.hexValue))
                            .frame(width: 16, height: 16)
                        Text(color.displayName)
                    }
                    .tag(color.rawValue)
                }
            }
        } header: {
            Text("Appearance")
        }
    }
    
    private var keyboardSection: some View {
        Section {
            Button {
                openSystemSettings()
            } label: {
                Label("Setup Guide", systemImage: "keyboard")
            }
            
            HStack {
                Label("Allow Full Access", systemImage: "lock.shield")
                Spacer()
                Text(fullAccessStatusText)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            
            Button {
                // TODO(#24): Trigger keyboard self-test once keyboard extension ships.
            } label: {
                Label("Test Keyboard", systemImage: "checkmark.circle")
            }
            .disabled(true)
        } header: {
            Text("Keyboard")
        } footer: {
            Text("""
                VoiceFlow's keyboard lets you dictate into any app. \
                Enable it in Settings → General → Keyboard → Keyboards.
                """)
        }
    }
    
    private var actionButtonSection: some View {
        Section {
            Button {
                openActionButtonGuide()
            } label: {
                Label("Setup Guide", systemImage: "button.programmable")
            }
            
            Toggle("Enable on Action Button", isOn: Binding(
                get: { settings.actionButtonEnabled },
                set: { settings.actionButtonEnabled = $0 }
            ))
        } header: {
            Text("Action Button")
        } footer: {
            Text("iPhone 15 Pro / 16 Pro only. Bind VoiceFlow via Shortcuts → Action Button.")
        }
    }
    
    private var advancedSection: some View {
        Section {
            Picker("Streaming", selection: Binding(
                get: { settings.streamingPreferenceRaw },
                set: { settings.streamingPreference = StreamingPreference(rawValue: $0) ?? .auto }
            )) {
                ForEach(StreamingPreference.allCases, id: \.self) { pref in
                    Text(pref.displayName).tag(pref.rawValue)
                }
            }
            
            Toggle("Auto-punctuation", isOn: Binding(
                get: { settings.autoPunctuationEnabled },
                set: { settings.autoPunctuationEnabled = $0 }
            ))
            Toggle("Auto-capitalize", isOn: Binding(
                get: { settings.autoCapitalizationEnabled },
                set: { settings.autoCapitalizationEnabled = $0 }
            ))
            
            Button {
                showOnboarding = true
            } label: {
                Label("Show Onboarding", systemImage: "sparkles")
            }
        } header: {
            Text("Advanced")
        } footer: {
            Text("Streaming preference controls how the live partial text behaves during recording.")
        }
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(appVersionString)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            Link(destination: URL(string: "https://github.com/Marvin22222/voiceflow")!) {
                Label("View on GitHub", systemImage: "link")
            }
            Link(destination: URL(string: "https://github.com/Marvin22222/voiceflow/blob/main/LICENSE")!) {
                Label("MIT License", systemImage: "doc.text")
            }
            Link(destination: URL(string: "https://github.com/Marvin22222/voiceflow/blob/main/PRIVACY.md")!) {
                Label("Privacy", systemImage: "hand.raised")
            }
        } header: {
            Text("About")
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

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}