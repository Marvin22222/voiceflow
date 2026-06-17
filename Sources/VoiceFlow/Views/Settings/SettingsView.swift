//
//  SettingsView.swift
//  VoiceFlow
//
//  App settings — model, language, theme, triggers.
//

import SwiftUI
import VoiceFlowShared

// MARK: - SettingsView

/// App settings screen.
struct SettingsView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]
    
    // MARK: - Computed Properties
    
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
                languageSection
                triggerSection
                appearanceSection
                advancedSection
                aboutSection
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(AppColors.backgroundDark)
        }
    }
    
    // MARK: - Sections
    
    private var modelSection: some View {
        Section("Model") {
            NavigationLink {
                // TODO: ModelPickerView
                Text("Model Picker")
            } label: {
                LabeledContent("Active Model", value: settings.activeModelId)
            }
        }
    }
    
    private var languageSection: some View {
        Section("Language") {
            Picker("Preferred", selection: Binding(
                get: { settings.preferredLanguageCode },
                set: { settings.preferredLanguageCode = $0 }
            )) {
                ForEach(Language.allCases.filter { $0.isConcrete || $0 == .auto }, id: \.self) { lang in
                    Text(lang.displayName).tag(lang.rawValue)
                }
            }
            
            Toggle("Auto-detect Language", isOn: Binding(
                get: { settings.autoDetectLanguage },
                set: { settings.autoDetectLanguage = $0 }
            ))
        }
    }
    
    private var triggerSection: some View {
        Section("Trigger") {
            Toggle("Hold to Talk", isOn: Binding(
                get: { settings.holdToTalkEnabled },
                set: { settings.holdToTalkEnabled = $0 }
            ))
            Toggle("Tap to Toggle", isOn: Binding(
                get: { settings.tapToToggleEnabled },
                set: { settings.tapToToggleEnabled = $0 }
            ))
            Toggle("Keyboard Mic Button", isOn: Binding(
                get: { settings.keyboardMicButtonEnabled },
                set: { settings.keyboardMicButtonEnabled = $0 }
            ))
            Toggle("Action Button", isOn: Binding(
                get: { settings.actionButtonEnabled },
                set: { settings.actionButtonEnabled = $0 }
            ))
        }
    }
    
    private var appearanceSection: some View {
        Section("Appearance") {
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
        }
    }
    
    private var advancedSection: some View {
        Section("Advanced") {
            Toggle("Auto-punctuation", isOn: Binding(
                get: { settings.autoPunctuationEnabled },
                set: { settings.autoPunctuationEnabled = $0 }
            ))
            Toggle("Auto-capitalize", isOn: Binding(
                get: { settings.autoCapitalizationEnabled },
                set: { settings.autoCapitalizationEnabled = $0 }
            ))
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("0.1.0 (1)")
                    .foregroundStyle(.secondary)
            }
            Link(destination: URL(string: "https://github.com/Marvin22222/voiceflow")!) {
                Label("View on GitHub", systemImage: "link")
            }
            Link(destination: URL(string: "https://github.com/Marvin22222/voiceflow/blob/main/LICENSE")!) {
                Label("MIT License", systemImage: "doc.text")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}
