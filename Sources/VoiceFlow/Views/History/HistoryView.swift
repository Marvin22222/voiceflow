//
//  HistoryView.swift
//  VoiceFlow
//
//  List of past transcriptions.
//

import SwiftUI

// MARK: - HistoryView

/// Shows past transcriptions from SwiftData store.
struct HistoryView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TranscriptionRecord.createdAt, order: .reverse) private var records: [TranscriptionRecord]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(records) { record in
                            HistoryRow(record: record)
                        }
                        .onDelete(perform: deleteRecords)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .background(AppColors.backgroundDark)
        }
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Transcriptions Yet")
                .font(.title3)
            Text("Your past transcriptions will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}

// MARK: - HistoryRow

/// A single row in the history list.
struct HistoryRow: View {
    
    // MARK: - Properties
    
    let record: TranscriptionRecord
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(record.text)
                .font(.body)
                .lineLimit(3)
            HStack {
                Label(record.backendName, systemImage: "cpu")
                    .font(.caption2)
                if let flag = record.language.flagEmoji {
                    Text(flag)
                }
                Text(record.language.displayName)
                    .font(.caption2)
                Spacer()
                Text(record.createdAt, style: .relative)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: TranscriptionRecord.self, inMemory: true)
}
