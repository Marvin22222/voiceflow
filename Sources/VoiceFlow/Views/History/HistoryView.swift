//
//  HistoryView.swift
//  VoiceFlow
//
//  iOS 26 Liquid Glass style list of past transcriptions. Each row
//  is a floating glass card with smooth iOS 26 hover effects.
//

import SwiftUI
import SwiftData

// MARK: - HistoryView

/// Shows past transcriptions from SwiftData store.
struct HistoryView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TranscriptionRecord.createdAt, order: .reverse) private var records: [TranscriptionRecord]

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg, pinnedViews: []) {
                header

                if records.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: Spacing.sm) {
                        ForEach(records) { record in
                            HistoryRow(record: record)
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
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("History")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-0.5)
            Text("Your transcriptions are saved on-device. Swipe left to delete.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.pageHorizontal)
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 96, height: 96)
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
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.appAccent)
            }

            Text("No Transcriptions Yet")
                .font(.title3.weight(.semibold))

            Text("Tap the mic on Home to record your first transcription. It will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxl)
    }

    // MARK: - Actions

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}

// MARK: - HistoryRow

/// A single glass card row in the history list.
struct HistoryRow: View {

    // MARK: - Properties

    let record: TranscriptionRecord

    // MARK: - State

    @State private var isPressed: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(record.text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Spacing.sm) {
                Label(record.backendName, systemImage: "cpu")
                    .font(.caption2.weight(.medium))
                if let flag = record.language.flagEmoji {
                    Text(flag)
                        .font(.caption2)
                }
                Text(record.language.displayName)
                    .font(.caption2.weight(.medium))
                Spacer()
                Text(record.createdAt, style: .relative)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
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
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.glassBouncy, value: isPressed)
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity) { _ in
            // no-op
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = record.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            ShareLink(item: record.text) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: TranscriptionRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
}
