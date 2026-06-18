//
//  ModelManager.swift
//  VoiceFlow
//
//  Manages model downloads, installation, and storage.
//

import Foundation
import VoiceFlowShared

// MARK: - ModelManagerError

/// Errors thrown by ``ModelManager``.
enum ModelManagerError: LocalizedError {
    case insufficientDiskSpace(required: Int64, available: Int64)
    case downloadFailed(reason: String)
    case checksumMismatch(expected: String, actual: String)
    case modelNotInstalled(id: String)
    case alreadyInstalled(id: String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientDiskSpace(let required, let available):
            return "Not enough disk space. Need \(required) bytes, have \(available)."
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .checksumMismatch(let expected, let actual):
            return "Downloaded file is corrupted (checksum mismatch)."
        case .modelNotInstalled(let id):
            return "Model '\(id)' is not installed."
        case .alreadyInstalled(let id):
            return "Model '\(id)' is already installed."
        }
    }
}

// MARK: - ModelManager

/// Manages transcription model downloads, installation, and storage.
///
/// Responsibilities:
/// - Download models from their ``ModelSource``
/// - Verify integrity (SHA-256 checksum)
/// - Track which models are installed
/// - Delete models to free up storage
/// - Report storage usage
@MainActor
final class ModelManager {
    
    // MARK: - Properties
    
    private let modelRegistry: ModelRegistry
    private let fileManager = FileManager.default
    private let activeDownloads = ActiveDownloads()
    
    // MARK: - Initialization
    
    init(modelRegistry: ModelRegistry = .shared) {
        self.modelRegistry = modelRegistry
        createModelsDirectoryIfNeeded()
    }
    
    // MARK: - Public API: Query
    
    /// All models in the registry.
    var allModels: [ModelDefinition] {
        modelRegistry.all
    }
    
    /// All installed models (files present on disk).
    var installedModels: [ModelDefinition] {
        allModels.filter { isInstalled($0) }
    }
    
    /// Whether a model is installed (file present at expected path).
    func isInstalled(_ model: ModelDefinition) -> Bool {
        let path = installPath(for: model)
        return fileManager.fileExists(atPath: path.path)
    }
    
    /// Total disk space used by installed models, in bytes.
    func storageUsed() -> Int64 {
        let modelsDir = modelsDirectory
        guard let enumerator = fileManager.enumerator(
            at: modelsDir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        var total: Int64 = 0
        for case let url as URL in enumerator {
            let attrs = try? url.resourceValues(forKeys: [.fileSizeKey])
            total += Int64(attrs?.fileSize ?? 0)
        }
        return total
    }
    
    /// Available disk space on the volume containing the models directory, in bytes.
    func storageAvailable() -> Int64 {
        let url = modelsDirectory
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return Int64(values?.volumeAvailableCapacityForImportantUsage ?? 0)
    }
    
    // MARK: - Public API: Download
    
    /// Downloads a model from its ``ModelSource``.
    /// - Parameter model: The model to download.
    /// - Returns: An async stream of progress updates.
    func download(_ model: ModelDefinition) -> AsyncThrowingStream<DownloadProgress, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                do {
                    guard !self.isInstalled(model) else {
                        throw ModelManagerError.alreadyInstalled(id: model.id)
                    }
                    
                    // Check disk space
                    let available = self.storageAvailable()
                    let required = model.sizeBytes * 2  // 2x for safety
                    if available < required {
                        throw ModelManagerError.insufficientDiskSpace(
                            required: required,
                            available: available
                        )
                    }
                    
                    continuation.yield(DownloadProgress(
                        bytesDownloaded: 0,
                        totalBytes: model.sizeBytes,
                        state: .preparing
                    ))
                    
                    // WhisperKit models are downloaded automatically by WhisperKit itself
                    // when the backend is loaded. So if source is .whisperKit, we
                    // just need to instantiate the backend and call load().
                    switch model.source {
                    case .whisperKit:
                        try await self.installWhisperKitModel(model)
                        
                    case .huggingFace, .githubRelease, .direct:
                        try await self.downloadRemoteFile(for: model) { progress in
                            continuation.yield(progress)
                        }
                        
                    case .bundled:
                        // Nothing to download
                        break
                    }
                    
                    continuation.yield(DownloadProgress(
                        bytesDownloaded: model.sizeBytes,
                        totalBytes: model.sizeBytes,
                        state: .completed
                    ))
                    continuation.finish()
                    
                } catch {
                    continuation.yield(DownloadProgress(
                        bytesDownloaded: 0,
                        totalBytes: model.sizeBytes,
                        state: .failed
                    ))
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Cancels an in-progress download.
    func cancelDownload(_ model: ModelDefinition) {
        activeDownloads.cancel(modelId: model.id)
    }
    
    // MARK: - Public API: Delete
    
    /// Deletes a model from disk.
    func delete(_ model: ModelDefinition) throws {
        let path = installPath(for: model)
        guard fileManager.fileExists(atPath: path.path) else {
            throw ModelManagerError.modelNotInstalled(id: model.id)
        }
        try fileManager.removeItem(at: path)
    }
    
    // MARK: - Private: Paths
    
    /// Directory where models are stored.
    private var modelsDirectory: URL {
        let support = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return support
            .appendingPathComponent("VoiceFlow", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
    }
    
    /// Path where a specific model should be installed.
    private func installPath(for model: ModelDefinition) -> URL {
        modelsDirectory.appendingPathComponent(model.id, isDirectory: true)
    }
    
    /// Creates the models directory if it doesn't exist.
    private func createModelsDirectoryIfNeeded() {
        try? fileManager.createDirectory(
            at: modelsDirectory,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Private: Download Helpers
    
    private func installWhisperKitModel(_ model: ModelDefinition) async throws {
        // For WhisperKit models, we just need to instantiate the backend
        // and load it (WhisperKit handles its own download).
        let backend = try WhisperKitBackend(definition: model)
        try await backend.load()
        await backend.unload()
    }
    
    private func downloadRemoteFile(
        for model: ModelDefinition,
        progressHandler: (DownloadProgress) -> Void
    ) async throws {
        guard let url = model.source.resolveURL() else {
            throw ModelManagerError.downloadFailed(
                reason: "Model source '\(model.source)' doesn't have a downloadable URL"
            )
        }
        
        let destination = installPath(for: model)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        
        // TODO: Implement URLSession download with progress reporting
        // For now, this is a stub that would need implementation
        throw ModelManagerError.downloadFailed(
            reason: "Remote downloads not yet implemented in MVP"
        )
    }
}

// MARK: - ActiveDownloads

/// Tracks active downloads so they can be canceled.
private final class ActiveDownloads: @unchecked Sendable {
    
    private var tasks: [String: Task<Void, Never>] = [:]
    private let lock = NSLock()
    
    func register(modelId: String, task: Task<Void, Never>) {
        lock.lock()
        defer { lock.unlock() }
        tasks[modelId]?.cancel()
        tasks[modelId] = task
    }
    
    func unregister(modelId: String) {
        lock.lock()
        defer { lock.unlock() }
        tasks[modelId] = nil
    }
    
    func cancel(modelId: String) {
        lock.lock()
        defer { lock.unlock() }
        tasks[modelId]?.cancel()
        tasks[modelId] = nil
    }
}
