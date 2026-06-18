//
//  KeyboardViewController.swift
//  VoiceFlowKeyboard
//
//  Custom keyboard extension with VoiceFlow mic button.
//

import UIKit
import VoiceFlowShared

// MARK: - KeyboardViewController

/// Custom keyboard extension for VoiceFlow.
///
/// Displays a standard QWERTY keyboard with an additional mic button.
/// When the mic button is tapped, signals the main app to start recording.
/// Once the main app writes transcribed text to the App Group, this
/// controller inserts it into the active input field.
class KeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private var micButton: UIButton!
    private var statusLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeAppGroup()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0)
        
        // Status label
        statusLabel = UILabel()
        statusLabel.text = "VoiceFlow ready"
        statusLabel.textColor = .lightGray
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Mic button
        micButton = UIButton(type: .system)
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = UIColor(red: 0.36, green: 0.37, blue: 0.90, alpha: 1.0)
        micButton.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        micButton.layer.cornerRadius = 16
        micButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
        micButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(micButton)
        
        // Layout
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            micButton.widthAnchor.constraint(equalToConstant: 60),
            micButton.heightAnchor.constraint(equalToConstant: 60),
            
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 280)
        ])
    }
    
    // MARK: - App Group Observation
    
    private func observeAppGroup() {
        // Poll for new pending text every 0.5 seconds
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForPendingText()
            self?.updateStatus()
        }
    }
    
    private func checkForPendingText() {
        guard let text = AppGroup.pendingText(), !text.isEmpty else { return }
        
        // Insert into current input field
        textDocumentProxy.insertText(text)
        
        // Clear so we don't insert again
        AppGroup.clearPendingText()
    }
    
    private func updateStatus() {
        switch AppGroup.recordingStatus() {
        case .idle:
            statusLabel.text = "VoiceFlow ready"
            statusLabel.textColor = .lightGray
        case .recording:
            statusLabel.text = "● Recording..."
            statusLabel.textColor = .systemRed
        case .processing:
            statusLabel.text = "Processing..."
            statusLabel.textColor = .systemOrange
        case .done:
            statusLabel.text = "✓ Transcribed (inserting...)"
            statusLabel.textColor = .systemGreen
        case .error:
            statusLabel.text = "⚠️ Error"
            statusLabel.textColor = .systemRed
        }
    }
    
    // MARK: - Actions
    
    @objc private func micButtonTapped() {
        // Open main app via URL scheme
        // The main app will detect this via .onOpenURL and start recording
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
}
