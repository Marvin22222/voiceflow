//
//  KeyboardViewController.swift
//  VoiceFlowKeyboard
//
//  Custom keyboard extension with VoiceFlow mic button + Stop & Insert flow (Issue #27).
//

import UIKit
import VoiceFlowShared

// MARK: - KeyboardViewController

/// Custom keyboard extension for VoiceFlow.
///
/// Implements the **Stop & Insert flow** (Issue #27):
///
/// 1. User taps the mic button → main app opens via URL scheme to start recording
/// 2. Main app finishes transcription, writes pending text + status to the App Group
/// 3. Keyboard polls App Group and detects a new result
/// 4. Keyboard shows a text preview + Insert / Discard buttons
/// 5. User taps Insert → `textDocumentProxy.insertText()` + success haptic + auto-dismiss
///
/// The keyboard itself does NOT record audio — that runs in the main app
/// for now (a future Issue #26 will move it to a background-audio service).
class KeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private var containerStack: UIStackView!
    private var statusLabel: UILabel!
    private var activityIndicator: UIActivityIndicatorView!
    private var previewLabel: UILabel!
    private var actionStack: UIStackView!
    private var micButton: UIButton!
    private var insertButton: UIButton!
    private var discardButton: UIButton!
    
    /// Timestamp of the last App Group update we've already reacted to.
    /// Prevents duplicate inserts if the poll fires multiple times between updates.
    private var lastSeenUpdate: Date?
    
    /// Polling timer for the App Group.
    private var pollTimer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startPolling()
    }
    
    deinit {
        pollTimer?.invalidate()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0)
        
        // Top: status label + activity indicator
        statusLabel = UILabel()
        statusLabel.text = "VoiceFlow"
        statusLabel.textColor = .lightGray
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .systemOrange
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Middle: text preview (hidden until done)
        previewLabel = UILabel()
        previewLabel.text = ""
        previewLabel.textColor = .white
        previewLabel.font = .systemFont(ofSize: 16)
        previewLabel.numberOfLines = 3
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.textAlignment = .left
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.isHidden = true
        previewLabel.accessibilityLabel = "Transcribed text preview"
        
        // Action buttons (Insert + Discard)
        insertButton = UIButton(type: .system)
        insertButton.setTitle("Insert", for: .normal)
        insertButton.setImage(UIImage(systemName: "arrow.right.circle.fill"), for: .normal)
        insertButton.tintColor = .white
        insertButton.backgroundColor = UIColor(red: 0.36, green: 0.37, blue: 0.90, alpha: 1.0)
        insertButton.layer.cornerRadius = 12
        insertButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        insertButton.addTarget(self, action: #selector(insertTapped), for: .touchUpInside)
        insertButton.translatesAutoresizingMaskIntoConstraints = false
        insertButton.isHidden = true
        insertButton.accessibilityLabel = "Insert transcribed text"
        
        discardButton = UIButton(type: .system)
        discardButton.setTitle("Discard", for: .normal)
        discardButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        discardButton.tintColor = .lightGray
        discardButton.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        discardButton.layer.cornerRadius = 12
        discardButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        discardButton.addTarget(self, action: #selector(discardTapped), for: .touchUpInside)
        discardButton.translatesAutoresizingMaskIntoConstraints = false
        discardButton.isHidden = true
        discardButton.accessibilityLabel = "Discard transcribed text"
        
        actionStack = UIStackView(arrangedSubviews: [discardButton, insertButton])
        actionStack.axis = .horizontal
        actionStack.distribution = .fillEqually
        actionStack.spacing = 8
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        actionStack.isHidden = true
        
        // Bottom: mic button
        micButton = UIButton(type: .system)
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = UIColor(red: 0.36, green: 0.37, blue: 0.90, alpha: 1.0)
        micButton.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        micButton.layer.cornerRadius = 30
        micButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
        micButton.translatesAutoresizingMaskIntoConstraints = false
        micButton.accessibilityLabel = "Start voice recording"
        
        // Compose
        containerStack = UIStackView(arrangedSubviews: [statusLabel, activityIndicator, previewLabel, actionStack, micButton])
        containerStack.axis = .vertical
        containerStack.alignment = .fill
        containerStack.spacing = 8
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        containerStack.setCustomSpacing(4, after: statusLabel)
        containerStack.setCustomSpacing(12, after: previewLabel)
        view.addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            activityIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            previewLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            micButton.heightAnchor.constraint(equalToConstant: 60),
            micButton.widthAnchor.constraint(equalToConstant: 60),
            micButton.centerXAnchor.constraint(equalTo: containerStack.centerXAnchor),
            
            insertButton.heightAnchor.constraint(equalToConstant: 44),
            discardButton.heightAnchor.constraint(equalToConstant: 44),
            
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 280)
        ])
    }
    
    // MARK: - Polling
    
    /// Start polling the App Group for status updates and new pending text.
    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }
    
    /// Single poll tick — checks status + lastUpdate, then updates UI.
    private func poll() {
        let status = AppGroup.recordingStatus()
        let lastUpdate = AppGroup.sharedDefaults.object(forKey: AppGroup.SharedKey.lastUpdate.rawValue) as? Date
        
        // Skip if we already processed this update.
        if lastUpdate == lastSeenUpdate { return }
        lastSeenUpdate = lastUpdate
        
        // Refresh UI based on the latest status.
        renderStatus(status)
        
        // When we transition to .done, fetch the pending text and reveal the preview.
        if status == .done, let text = AppGroup.pendingText(), !text.isEmpty {
            showPreview(text)
        }
    }
    
    /// Render the keyboard UI for a given recording status.
    private func renderStatus(_ status: AppGroup.RecordingStatus) {
        switch status {
        case .idle:
            statusLabel.text = "VoiceFlow"
            statusLabel.textColor = .lightGray
            activityIndicator.stopAnimating()
            // Hide preview + actions; show mic.
            previewLabel.isHidden = true
            actionStack.isHidden = true
            micButton.isHidden = false
            
        case .recording:
            statusLabel.text = "● Recording in VoiceFlow..."
            statusLabel.textColor = .systemRed
            activityIndicator.stopAnimating()
            // Hide preview; show mic (as a stop button — main app handles it).
            previewLabel.isHidden = true
            actionStack.isHidden = true
            micButton.isHidden = false
            
        case .processing:
            statusLabel.text = "Transcribing..."
            statusLabel.textColor = .systemOrange
            activityIndicator.startAnimating()
            // Hide preview; show mic disabled.
            previewLabel.isHidden = true
            actionStack.isHidden = true
            micButton.isHidden = false
            micButton.isEnabled = false
            
        case .done:
            statusLabel.text = "✓ Transcribed"
            statusLabel.textColor = .systemGreen
            activityIndicator.stopAnimating()
            micButton.isEnabled = true
            // Preview + actions will be shown by `showPreview(_:)`.
            
        case .error:
            statusLabel.text = "⚠️ Error — try again"
            statusLabel.textColor = .systemRed
            activityIndicator.stopAnimating()
            micButton.isEnabled = true
            previewLabel.isHidden = true
            actionStack.isHidden = true
            micButton.isHidden = false
        }
    }
    
    /// Reveal the text preview and Insert/Discard buttons.
    private func showPreview(_ text: String) {
        previewLabel.text = text
        previewLabel.isHidden = false
        actionStack.isHidden = false
        micButton.isHidden = true
        
        // Light haptic so the user knows text is ready.
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Actions
    
    @objc private func micButtonTapped() {
        // Issue #27: opening the main app via URL scheme starts a new
        // recording session. While the main app is recording, the keyboard
        // polls and shows the "Recording..." status. After stop, it
        // transcribes, writes pending text, and the keyboard transitions
        // to the .processing → .done state automatically.
        guard let url = URL(string: "voiceflow://record") else { return }
        
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url)
                return
            }
            responder = r.next
        }
        
        // Fallback: just call extensionContext.open
        extensionContext?.open(url)
    }
    
    @objc private func insertTapped() {
        // Pull the pending text and insert it into the active input field.
        guard let text = AppGroup.pendingText(), !text.isEmpty else {
            return
        }
        
        textDocumentProxy.insertText(text)
        AppGroup.clearPendingText()
        lastSeenUpdate = nil
        
        // Success haptic — Issue #27 acceptance criterion.
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Auto-dismiss the keyboard — Issue #27 acceptance criterion.
        dismissKeyboard()
    }
    
    @objc private func discardTapped() {
        // User discarded the transcription; clear App Group state and return
        // to idle.
        AppGroup.clearPendingText()
        lastSeenUpdate = nil
        renderStatus(.idle)
    }
}