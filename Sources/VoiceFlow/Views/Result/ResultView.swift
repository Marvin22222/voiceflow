//
//  ResultView.swift
//  VoiceFlow
//
//  Polished Result screen shown after a successful transcription (Issue #23).
//

import SwiftUI
import SwiftData
import UIKit
import VoiceFlowShared

// MARK: - ResultView

/// Modal sheet shown after a successful transcription.
///
/// Acceptance criteria (Issue #23):
/// - Editable ``TextEditor`` (cursor at end, auto-focus on appear)
/// - Metadata caption: `<model> · <duration> · <confidence>% · <language>`
/// - Three action buttons (icon + label): Copy, Share, Re-record
/// - Insert button (primary, large) — only when triggered from keyboard
/// - Back button returns to Home (via `Done`)
/// - Save transcription to History (SwiftData) on dismiss
///
/// The view is intentionally minimal: a single scrollable text area with
/// actions below. Polish comes from spacing, typography, and haptic feedback —
/// not from chrome.
struct ResultView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    /// The shared HomeViewModel. We read transcription state and call its
    /// actions; we don't own the state directly.
    @ObservedObject var viewModel: HomeViewModel
    
    /// Whether this view was triggered from the keyboard extension's
    /// "Stop & Insert" flow. When true, an Insert button is shown in place
    /// of the Back button.
    var isKeyboardTriggered: Bool = false
    
    // MARK: - State
    
    /// Local editable copy of the transcribed text. Initialized from the
    /// view model's current `transcribedText` so user edits don't fight
    /// with VM updates.
    @State private var editableText: String = ""
    
    /// Auto-focus the editor on appear (iOS 17-compatible `@FocusState`).
    @FocusState private var isEditorFocused: Bool
    
    /// True for ~2 s after Copy is tapped, drives the "Copied ✓" toast.
    @State private var didCopy: Bool = false
    
    /// True while a Share Sheet is presented.
    @State private var showShareSheet: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                metadataCaption
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.md)
                
                editor
                
                Spacer(minLength: Spacing.sm)
                
                actionBar
                    .padding(.horizontal, Spacing.md)
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
            // Seed the editable text with the latest transcription and
            // focus the editor so the keyboard pops up.
            editableText = viewModel.transcribedText
            isEditorFocused = true
        }
    }
    
    // MARK: - Subviews
    
    /// Metadata caption: `Whisper Base · 0:08 · 95% confidence · English`.
    private var metadataCaption: some View {
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
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(captionAccessibilityLabel)
    }
    
    /// Editable text editor.
    ///
    /// Auto-focuses on appear via `@FocusState`. The iOS 17 `TextEditor`
    /// doesn't expose cursor-position control from a binding, but focusing
    /// the field places the cursor at the end automatically.
    private var editor: some View {
        TextEditor(text: $editableText)
            .font(.body)
            .foregroundStyle(.white)
            .scrollContentBackground(.hidden)
            .padding(Spacing.md)
            .background(AppColors.surfaceDark)
            .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadius))
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: 200, maxHeight: .infinity)
            .focused($isEditorFocused)
            .accessibilityLabel("Transcribed text")
            .accessibilityHint("Edit the text before sharing or copying")
    }
    
    /// Action bar with three icon+label buttons: Copy, Share, Re-record.
    ///
    /// In keyboard-triggered mode, the Re-record button is hidden (the
    /// keyboard can't start a new recording) and the primary Insert button
    /// moves into the toolbar at the top instead.
    private var actionBar: some View {
        HStack(spacing: Spacing.md) {
            if !isKeyboardTriggered {
                actionButton(
                    icon: "arrow.counterclockwise",
                    label: "Re-record",
                    action: {
                        Task {
                            dismiss()
                            // Trigger a fresh recording after this sheet
                            // dismisses. Slight delay to let the animation
                            // settle.
                            try? await Task.sleep(nanoseconds: 200_000_000)
                            await viewModel.startRecording()
                        }
                    }
                )
            }
            
            actionButton(
                icon: "doc.on.doc",
                label: didCopy ? "Copied ✓" : "Copy",
                tint: didCopy ? AppColors.success : Color.appAccent,
                action: copyToClipboard
            )
            
            actionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                action: { showShareSheet = true }
            )
        }
    }
    
    /// Reusable icon+label action button.
    @ViewBuilder
    private func actionButton(
        icon: String,
        label: String,
        tint: Color = Color.appAccent,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundStyle(tint)
            .background(AppColors.surfaceDark)
            .clipShape(RoundedRectangle(cornerRadius: Sizing.cornerRadius))
        }
        .accessibilityLabel(label)
    }
    
    /// "Copied ✓" floating toast at the bottom of the screen.
    private var copiedToast: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
            Text("Copied")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(AppColors.success)
        .clipShape(Capsule())
        .shadow(radius: 8)
    }
    
    // MARK: - Actions
    
    private func copyToClipboard() {
        UIPasteboard.general.string = editableText
        // Subtle success haptic.
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            didCopy = true
        }
        
        // Auto-hide the toast after 1.5 s.
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    didCopy = false
                }
            }
        }
    }
    
    /// Save to history (SwiftData) and dismiss the sheet.
    private func saveAndDismiss() {
        // Write edits back to the VM so subsequent recordings don't lose them.
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

/// UIKit bridge for `UIActivityViewController`.
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
}