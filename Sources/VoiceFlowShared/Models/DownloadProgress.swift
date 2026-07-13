//
//  DownloadProgress.swift
//  VoiceFlowShared
//
//  Progress information for model downloads.
//

import Foundation

// MARK: - DownloadProgress

/// Progress of a model download operation.
///
/// Reported via `AsyncThrowingStream` from ``ModelManager/download(_:)``.
public struct DownloadProgress: Equatable, Sendable {
    
    // MARK: - Properties
    
    /// Number of bytes downloaded so far.
    public let bytesDownloaded: Int64
    
    /// Total bytes to download (may be unknown mid-download).
    public let totalBytes: Int64
    
    /// Current download state.
    public let state: State
    
    /// Estimated time remaining (nil if unknown).
    public let estimatedTimeRemaining: TimeInterval?
    
    /// Download speed in bytes per second (nil if unknown).
    public let bytesPerSecond: Double?
    
    // MARK: - State
    
    /// State of the download.
    public enum State: String, Equatable, Sendable {
        /// Preparing to start (resolving URL, etc).
        case preparing
        /// Download is in progress.
        case downloading
        /// Download finished successfully.
        case completed
        /// Download was canceled by user.
        case canceled
        /// Download failed.
        case failed
    }
    
    // MARK: - Initialization
    
    public init(
        bytesDownloaded: Int64,
        totalBytes: Int64,
        state: State,
        estimatedTimeRemaining: TimeInterval? = nil,
        bytesPerSecond: Double? = nil
    ) {
        self.bytesDownloaded = bytesDownloaded
        self.totalBytes = totalBytes
        self.state = state
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.bytesPerSecond = bytesPerSecond
    }
}

// MARK: - Computed Properties

public extension DownloadProgress {
    
    /// Progress fraction in 0.0–1.0. Returns 0 if total is unknown.
    var fraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1.0, Double(bytesDownloaded) / Double(totalBytes))
    }
    
    /// Percentage as integer 0–100.
    var percentage: Int {
        Int(fraction * 100)
    }
    
    /// Human-readable bytes downloaded (e.g. "175 MB").
    var bytesDownloadedString: String {
        ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
    }
    
    /// Human-readable total bytes (e.g. "500 MB").
    var totalBytesString: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    /// Estimated time remaining as a human-readable string (e.g. "2 min").
    var timeRemainingString: String? {
        guard let seconds = estimatedTimeRemaining else { return nil }
        if seconds < 60 { return "\(Int(seconds)) sec" }
        let minutes = Int(seconds / 60)
        return "\(minutes) min"
    }
    
    /// Human-readable speed (e.g. "5.2 MB/s").
    var speedString: String? {
        guard let bps = bytesPerSecond, bps > 0 else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(bps), countStyle: .file) + "/s"
    }
}

// MARK: - Mock Helpers

#if DEBUG
public extension DownloadProgress {
    
    /// Sample progress at 65%.
    static let sample = DownloadProgress(
        bytesDownloaded: 325_000_000,
        totalBytes: 500_000_000,
        state: .downloading,
        estimatedTimeRemaining: 120,
        bytesPerSecond: 5_000_000
    )
}
#endif
