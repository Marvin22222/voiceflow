//
//  ModelsView.swift
//  VoiceFlow
//
//  iOS 26 Liquid Glass style model browser. Downloaded and available
//  models are presented as floating glass cards with smooth download
//  progress and tap-to-action gestures.
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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg, pinnedViews: []) {
                header

                if !installedSection.isEmpty {
                    sectionHeader("Downloaded", count: installedSection.count)

                    VStack(spacing: Spacing.sm) {
                        ForEach(installedSection, id: \.id) { model in
                            ModelCard(
                                model: model,
                                status: .installed(isActive: false),
                                progress: nil,
                                onAction: { handleAction(for: model) }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.pageHorizontal)

                    storageFooter
                        .padding(.horizontal, Spacing.pageHorizontal)
                }

                if !availableSection.isEmpty {
                    sectionHeader("Available", count: availableSection.count)

                    VStack(spacing: Spacing.sm) {
                        ForEach(availableSection, id: \.id) { model in
                            ModelCard(
                                model: model,
                                status: .available,
                                progress: downloadProgress[model.id],
                                onAction: { handleAction(for: model) }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.pageHorizontal)
                }

                Spacer()
                    .frame(height: Spacing.xxl)
            }
            .padding(.top, Spacing.md)
        }
        .background(AppColors.backgroundDark)
        .task {
            await refresh()
        }
        .refreshable {
            await refresh()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Models")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-0.5)
            Text("All transcription runs on-device. Pick the model that fits your trade-off between accuracy and speed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.pageHorizontal)
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.4)
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, Spacing.pageHorizontal)
    }

    private var storageFooter: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "internaldrive")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(storageFooterText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
    }

    private var storageFooterText: String {
        let used = modelManager.storageUsed()
        let available = modelManager.storageAvailable()
        let usedStr = ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
        let availableStr = ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
        return "\(usedStr) used · \(availableStr) available"
    }

    // MARK: - Computed

    private var installedSection: [ModelDefinition] {
        allModels.filter { installedModels.contains($0.id) }
    }

    private var availableSection: [ModelDefinition] {
        allModels.filter { !installedModels.contains($0.id) }
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

/// Liquid Glass card showing a model with status, scores, and action button.
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
        VStack(alignment: .leading, spacing: Spacing.smPlus) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Liquid glass icon badge
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
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
                                    lineWidth: 1
                                )
                        )
                    Image(systemName: model.backendType.symbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.appAccent)
                }

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
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

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
        .padding(Spacing.md)
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
    }

    // MARK: - Subviews

    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case .installed:
            Button("Delete", role: .destructive, action: onAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.secondary)
        case .available:
            Button(action: onAction) {
                Label("Get", systemImage: "arrow.down.circle.fill")
                    .font(.footnote.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.appAccent)
        case .downloading:
            ProgressView()
                .controlSize(.small)
        }
    }

    private func progressView(_ progress: DownloadProgress) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ProgressView(value: progress.fraction)
                .tint(.appAccent)
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
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i < score ? Color.appAccent : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 12)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ModelsView()
        .environment(ModelManager())
        .preferredColorScheme(.dark)
}
