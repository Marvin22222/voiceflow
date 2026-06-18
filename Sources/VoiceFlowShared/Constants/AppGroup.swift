//
//  AppGroup.swift
//  VoiceFlowShared
//
//  App Group identifier and shared container paths used to communicate
//  between the main app and the keyboard extension.
//

import Foundation

// MARK: - AppGroup

/// Constants for App Group-based communication between main app and extensions.
public enum AppGroup {
    
    // MARK: - Identifier
    
    /// App Group identifier (must match in Xcode Capabilities).
    /// Update in `project.yml` if you change this.
    public static let identifier = "group.de.marvinschwab.voiceflow"
    
    // MARK: - Shared Container
    
    /// URL to the App Group's shared container directory.
    /// Returns nil if the App Group is not properly configured.
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
    
    /// Shared UserDefaults instance for App Group communication.
    /// Returns the standard UserDefaults if App Group is unavailable.
    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
    
    // MARK: - Shared Keys
    
    /// Keys for data shared via UserDefaults.
    public enum SharedKey: String {
        /// Pending transcription text waiting to be inserted by keyboard.
        case pendingText = "voiceflow.pendingText"
        
        /// Current recording status (idle, recording, processing, done).
        case recordingStatus = "voiceflow.status"
        
        /// Timestamp of last update (used to detect new pending text).
        case lastUpdate = "voiceflow.lastUpdate"
        
        /// Currently active model id.
        case activeModelId = "voiceflow.activeModelId"
    }
    
    // MARK: - Recording Status
    
    /// Recording status communicated between app and extensions.
    public enum RecordingStatus: String, Codable, Sendable {
        case idle
        case recording
        case processing
        case done
        case error
    }
}

// MARK: - Shared Data Accessors

public extension AppGroup {
    
    /// Writes pending text to the shared container, signaling new content.
    static func setPendingText(_ text: String) {
        sharedDefaults.set(text, forKey: SharedKey.pendingText.rawValue)
        sharedDefaults.set(Date(), forKey: SharedKey.lastUpdate.rawValue)
        sharedDefaults.set(RecordingStatus.done.rawValue, forKey: SharedKey.recordingStatus.rawValue)
    }
    
    /// Reads pending text from the shared container.
    /// Does NOT clear the text — call ``clearPendingText()`` after consuming.
    static func pendingText() -> String? {
        sharedDefaults.string(forKey: SharedKey.pendingText.rawValue)
    }
    
    /// Clears pending text after it has been consumed.
    static func clearPendingText() {
        sharedDefaults.removeObject(forKey: SharedKey.pendingText.rawValue)
        sharedDefaults.set(RecordingStatus.idle.rawValue, forKey: SharedKey.recordingStatus.rawValue)
    }
    
    /// Records current recording status (for keyboard extension to query).
    static func setRecordingStatus(_ status: RecordingStatus) {
        sharedDefaults.set(status.rawValue, forKey: SharedKey.recordingStatus.rawValue)
        sharedDefaults.set(Date(), forKey: SharedKey.lastUpdate.rawValue)
    }
    
    /// Reads current recording status.
    static func recordingStatus() -> RecordingStatus {
        guard let raw = sharedDefaults.string(forKey: SharedKey.recordingStatus.rawValue),
              let status = RecordingStatus(rawValue: raw)
        else { return .idle }
        return status
    }
}
