//
//  ResultView.swift
//  VoiceFlow
//
//  iOS 26 Liquid Glass Result screen shown after a successful
//  transcription (Issue #23). Editable glass text container, refined
//  metadata caption, and glass action buttons.
//

import SwiftUI
import SwiftData
import UIKit
import VoiceFlowShared

// MARK: - ResultView

/// Modal sheet shown after a successful transcription.
///
/// iOS 26 design:
/// - Glass text editor with rounded typography
/// - Inline metadata caption with accent color
/// - Three glass action buttons (Copy, Share, Re-record)
/// - Insert button (primary, large) — only when triggered from keyboard
/// - Refined haptic feedback
///
/// Polish comes from iOS 26 spacing, typography, and bouncy spring animations.
struct ResultView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    @ObservedObject var viewModel: HomeViewModel

    /// Whether this view was triggered from the keyboard extension's
    /// "Stop & Insert" flow.
    var isKeyboardTriggered: Bool = false

    // MARK: - State

    @State private var editableText: String = ""
    @FocusState private var isEditorFocused: Bool
    @State private var didCopy: Bool = false
    @State private var showShareSheet: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, Spacing.pageHorizontal)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.md)

                editor
                    .padding(.horizontal, Spacing.pageHorizontal)

                Spacer(minLength: Spacing.sm)

                actionBar
                    .padding(.horizontal, Spacing.pageHorizontal)
                    .padding(.bottom, Spacing.md)
            }
            .background(AppColors.backgroundDark.ignoresSafeArea())
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Text(isKeyboardTriggered ? "Cancel" : "Back")
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(isKeyboardTriggered ? "Cancel insertion" : "Back to home")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isKeyboardTriggered {
                        Button {
                            saveAndDismiss()
                        } label: {
                            Text("Insert")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.appAccent)
                        .accessibilityLabel("Insert transcribed text")
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if didCopy {
                    copiedToast
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [editableText])
        }
        .onAppear {
            editableText = viewModel.transcribedText
            isEditorFocused = true
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: Spacing.xs) {
            if let model = viewModel.activeModel {
                Text(model.displayName)
            } else if let name = viewModel.lastResult?.backendName {
                Text(name)
            } else {
                Text("Unknown")
            }
            Text("·").foregroundStyle(.secondary)
            Text(formatDuration(viewModel.lastResult?.audioDuration ?? 0))
            Text("·").foregroundStyle(.secondary)
            Text("\(Int((viewModel.lastResult?.confidence ?? 0) * 100))% confidence")
            Text("·").foregroundStyle(.secondary)
            Text(viewModel.lastResult?.language.displayName ?? "Auto")
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(captionAccessibilityLabel)
    }

    // MARK: - Editor

    private var editor: some View {
        TextEditor(text: $editableText)
            .font(.system(.body, design: .rounded))
            .foregroundStyle(.primary)
            .scrollContentBackground(.hidden)
            .padding(Spacing.md)
            .frame(minHeight: 200, maxHeight: .infinity)
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
            .focused($isEditorFocused)
            .accessibilityLabel("Transcribed text")
            .accessibilityHint("Edit the text before sharing or copying")
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: Spacing.sm) {
            if !isKeyboardTriggered {
                actionButton(
                    icon: "arrow.counterclockwise",
                    label: "Re-record",
                    tint: .secondary,
                    action: {
                        Task {
                            dismiss()
                            try? await Task.sleep(nanoseconds: 200_000_000)
                            await viewModel.startRecording()
                        }
                    }
                )
            }

            actionButton(
                icon: "doc.on.doc.fill",
                label: didCopy ? "Copied" : "Copy",
                tint: didCopy ? AppColors.success : .appAccent,
                action: copyToClipboard
            )

            actionButton(
                icon: "square.and.arrow.up.fill",
                label: "Share",
                tint: .appAccent,
                action: { showShareSheet = true }
            )
        }
    }

    private func actionButton(
        icon: String,
        label: String,
        tint: Color = .appAccent,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundStyle(tint)
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
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
    }

    // MARK: - Toast

    private var copiedToast: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
            Text("Copied to clipboard")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(AppColors.success)
        )
        .shadow(color: AppColors.success.opacity(0.4), radius: 16, y: 8)
    }

    // MARK: - Actions

    private func copyToClipboard() {
        UIPasteboard.general.string = editableText
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.glassBouncy) {
            didCopy = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.glassBouncy) {
                    didCopy = false
                }
            }
        }
    }

    private func saveAndDismiss() {
        viewModel.transcribedText = editableText
        viewModel.saveToHistory(modelContext: modelContext)
        viewModel.showResult = false
        dismiss()
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private var captionAccessibilityLabel: String {
        var parts: [String] = []
        if let model = viewModel.activeModel { parts.append(model.displayName) }
        parts.append("Duration \(formatDuration(viewModel.lastResult?.audioDuration ?? 0))")
        let pct = Int((viewModel.lastResult?.confidence ?? 0) * 100)
        parts.append("\(pct) percent confidence")
        if let lang = viewModel.lastResult?.language.displayName { parts.append(lang) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ResultView(
        viewModel: HomeViewModel(
            transcriptionService: TranscriptionService(),
            modelManager: ModelManager()
        )
    )
    .modelContainer(for: [TranscriptionRecord.self, AppSettings.self], inMemory: true)
    .preferredColorScheme(.dark)
}
