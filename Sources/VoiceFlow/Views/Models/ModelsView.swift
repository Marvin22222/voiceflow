//
//  ModelsView.swift
//  VoiceFlow
//
//  Browse, download, and manage transcription models (Handy-style).
//

import SwiftUI
import VoiceFlowShared

// MARK: - ModelsView

/// Browse, download, and manage transcription models.
struct ModelsView: View {
    
    // MARK: - Environment
    
    @Environment(ModelManager.self) private var modelManager
    
    // MARK: - State
    
    @State private var allModels: [ModelDefinition] = []
    @State private var installedModels: Set<String> = []
    @State private var downloadingModelId: String?
    @State private var downloadProgress: [String: DownloadProgress] = [:]
    
    // MARK: - Body
    
    var body: some View {
        List {
            Section {
                ForEach(installedSection, id: \.id) { model in
                    ModelCard(
                        model: model,
                        status: .installed(isActive: false),
                        progress: nil,
                        onAction: { handleAction(for: model) }
                    )
                }
            } header: {
                Text("Downloaded")
            } footer: {
                Text(storageFooter)
            }

            Section("Available for Download") {
                ForEach(availableSection, id: \.id) { model in
                    ModelCard(
                        model: model,
                        status: .available,
                        progress: downloadProgress[model.id],
                        onAction: { handleAction(for: model) }
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.backgroundDark)
        .task {
            await refresh()
        }
        .refreshable {
            await refresh()
        }
    }
    
    // MARK: - Computed
    
    private var installedSection: [ModelDefinition] {
        allModels.filter { installedModels.contains($0.id) }
    }
    
    private var availableSection: [ModelDefinition] {
        allModels.filter { !installedModels.contains($0.id) }
    }
    
    private var storageFooter: String {
        let used = modelManager.storageUsed()
        let available = modelManager.storageAvailable()
        let usedStr = ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
        let availableStr = ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
        return "\(usedStr) used · \(availableStr) available"
    }
    
    // MARK: - Actions
    
    private func handleAction(for model: ModelDefinition) {
        if installedModels.contains(model.id) {
            // Delete (with confirmation)
            Task { try? modelManager.delete(model); await refresh() }
        } else {
            // Download
            startDownload(model)
        }
    }
    
    private func startDownload(_ model: ModelDefinition) {
        downloadingModelId = model.id
        Task {
            for try await progress in modelManager.download(model) {
                downloadProgress[model.id] = progress
                if progress.state == .completed || progress.state == .failed {
                    downloadingModelId = nil
                    await refresh()
                    break
                }
            }
        }
    }
    
    private func refresh() async {
        allModels = modelManager.allModels
        installedModels = Set(modelManager.installedModels.map(\.id))
    }
}

// MARK: - ModelCard

/// Reusable card showing a model with status, scores, and action button.
struct ModelCard: View {
    
    // MARK: - Types
    
    enum Status {
        case installed(isActive: Bool)
        case downloading
        case available
    }
    
    // MARK: - Properties
    
    let model: ModelDefinition
    let status: Status
    let progress: DownloadProgress?
    let onAction: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        Text(model.displayName)
                            .font(.headline)
                        if case .installed(let isActive) = status, isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.success)
                                .font(.subheadline)
                        }
                    }
                    Text(model.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                actionButton
            }
            
            HStack(spacing: Spacing.md) {
                Label(model.sizeString, systemImage: "internaldrive")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label(model.languageSummary, systemImage: "globe")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: Spacing.md) {
                ScoreIndicator(label: "Acc", score: model.accuracyScore)
                ScoreIndicator(label: "Speed", score: model.speedScore)
                Spacer()
                Text("by \(model.author)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if let progress = progress, progress.state == .downloading {
                progressView(progress)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case .installed:
            Button("Delete", role: .destructive, action: onAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
        case .available:
            Button(action: onAction) {
                Label("Download", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        case .downloading:
            ProgressView()
                .controlSize(.small)
        }
    }
    
    private func progressView(_ progress: DownloadProgress) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ProgressView(value: progress.fraction)
            HStack {
                Text("\(progress.bytesDownloadedString) / \(progress.totalBytesString)")
                Spacer()
                if let speed = progress.speedString {
                    Text(speed)
                }
                if let remaining = progress.timeRemainingString {
                    Text("· \(remaining) left")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - ScoreIndicator

/// Visual indicator for accuracy/speed scores (5 bars filled).
struct ScoreIndicator: View {
    
    // MARK: - Properties
    
    let label: String
    let score: Int  // 1-5
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { i in
                    Rectangle()
                        .fill(i < score ? AppColors.appAccent : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 12)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ModelsView()
        .environment(ModelManager())
}
