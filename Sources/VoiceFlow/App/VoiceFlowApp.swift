//
//  VoiceFlowApp.swift
//  VoiceFlow
//
//  Main app entry point. Sets up SwiftData, services, and root view.
//

import SwiftUI
import SwiftData
import VoiceFlowShared

// MARK: - VoiceFlowApp

@main
struct VoiceFlowApp: App {
    
    // MARK: - Properties
    
    /// SwiftData model container for local persistence.
    let modelContainer: ModelContainer
    
    /// Shared transcription service (app-lifetime).
    @State private var transcriptionService = TranscriptionService()
    
    /// Shared model manager (app-lifetime).
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
                .preferredColorScheme(.dark)  // Dark mode by default
                // Issue #27: handle voiceflow:// URL scheme deep-links
                // from the keyboard extension.
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(modelContainer)
    }
    
    /// Handles inbound URL scheme requests.
    ///
    /// Supported paths:
    /// - `voiceflow://record` — start a new recording session
    ///   (used by the keyboard's mic button)
    /// - `voiceflow://settings` — open the Settings sheet (future use)
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "voiceflow" else { return }
        switch url.host {
        case "record":
            // NotificationCenter bridges to HomeViewModel since the VM
            // is created inside HomeView's @StateObject. The observation
            // is set up in HomeView.onAppear.
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
    /// Posted when the app receives a `voiceflow://record` deep-link.
    /// ``HomeView`` listens for this and calls ``HomeViewModel/startRecording()``.
    static let voiceflowStartRecording = Notification.Name("de.marvinschwab.voiceflow.startRecording")
}

// MARK: - RootView

/// Root view containing the main tab navigation.
struct RootView: View {
    
    // MARK: - Properties
    
    @State private var selectedTab: AppTab = .home
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // MARK: - Body
    
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
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}

// MARK: - AppTab

/// Main app tabs.
enum AppTab: Hashable {
    case home
    case models
    case history
}

// MARK: - MainTabView

/// The main tab view shown after onboarding is complete.
struct MainTabView: View {
    
    // MARK: - Properties
    
    @Binding var selectedTab: AppTab
    
    // MARK: - Body
    
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
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environment(TranscriptionService())
        .environment(ModelManager())
        .modelContainer(for: [TranscriptionRecord.self, AppSettings.self], inMemory: true)
}
