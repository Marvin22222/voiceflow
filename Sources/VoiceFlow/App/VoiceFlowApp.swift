//
//  VoiceFlowApp.swift
//  VoiceFlow
//
//  Main app entry point with iOS 26 Liquid Glass design language.
//  The main tab bar uses iOS 26's floating glass style with rounded
//  transitions and an optional glass-effect tab bar background.
//

import SwiftUI
import SwiftData
import VoiceFlowShared

// MARK: - VoiceFlowApp

@main
struct VoiceFlowApp: App {

    // MARK: - Properties

    let modelContainer: ModelContainer

    @State private var transcriptionService = TranscriptionService()
    @State private var modelManager = ModelManager()

    // MARK: - Initialization

    init() {
        // Set up SwiftData
        do {
            let schema = Schema([
                TranscriptionRecord.self,
                AppSettings.self
            ])
            let config = ModelConfiguration(schema: schema)
            self.modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to set up SwiftData: \(error)")
        }
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(transcriptionService)
                .environment(modelManager)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(modelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "voiceflow" else { return }
        switch url.host {
        case "record":
            NotificationCenter.default.post(
                name: .voiceflowStartRecording,
                object: nil
            )
        default:
            break
        }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let voiceflowStartRecording = Notification.Name("de.marvinschwab.voiceflow.startRecording")
}

// MARK: - RootView

/// Root view containing the main tab navigation.
struct RootView: View {

    @State private var selectedTab: AppTab = .home
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(selectedTab: $selectedTab)
            } else {
                OnboardingFlow(onFinish: {
                    hasCompletedOnboarding = true
                })
            }
        }
        .animation(.glassSmooth, value: hasCompletedOnboarding)
    }
}

// MARK: - AppTab

enum AppTab: Hashable {
    case home
    case models
    case history
}

// MARK: - MainTabView

/// iOS 26 floating glass tab bar.
///
/// Uses iOS 26's native floating tab bar style with a glass background.
/// Each tab is represented with a refined SF Symbols 7 icon and label.
struct MainTabView: View {

    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "mic.fill")
                }
                .tag(AppTab.home)

            NavigationStack {
                ModelsView()
                    .navigationTitle("Models")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Models", systemImage: "square.stack.3d.up.fill")
            }
            .tag(AppTab.models)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppTab.history)
        }
        .tint(.appAccent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environment(TranscriptionService())
        .environment(ModelManager())
        .modelContainer(for: [TranscriptionRecord.self, AppSettings.self], inMemory: true)
}
