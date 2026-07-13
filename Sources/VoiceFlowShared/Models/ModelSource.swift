//
//  ModelSource.swift
//  VoiceFlowShared
//
//  Describes where to download a transcription model from.
//

import Foundation

// MARK: - ModelSource

/// Describes where a transcription model can be downloaded from.
///
/// Use ``ModelSource/resolveURL()`` to get a concrete download URL.
public enum ModelSource: Codable, Equatable, Hashable, Sendable {
    
    /// WhisperKit's built-in model variants (downloaded via WhisperKit).
    /// - Parameter model: Whisper model variant name (e.g. "tiny", "base", "small").
    case whisperKit(model: String)
    
    /// HuggingFace Hub repository.
    /// - Parameters:
    ///   - repo: Repository ID (e.g. "nvidia/parakeet-tdt-0.6b-v3").
    ///   - file: File path within the repo (e.g. "model.mlmodelc/data").
    case huggingFace(repo: String, file: String)
    
    /// GitHub release asset.
    /// - Parameters:
    ///   - owner: Repository owner.
    ///   - repo: Repository name.
    ///   - tag: Release tag (e.g. "v1.0.0").
    ///   - asset: Asset filename within the release.
    case githubRelease(owner: String, repo: String, tag: String, asset: String)
    
    /// Direct URL to a downloadable file.
    case direct(URL)
    
    /// Model is bundled with the app (no download needed).
    case bundled
}

// MARK: - URL Resolution

public extension ModelSource {
    
    /// Resolves this source to a concrete download URL, if applicable.
    /// - Returns: A URL, or nil if the source is `.bundled` (no download needed).
    func resolveURL() -> URL? {
        switch self {
        case .whisperKit:
            // WhisperKit handles its own downloads internally
            return nil
            
        case .huggingFace(let repo, let file):
            // HuggingFace Hub URL format
            return URL(string: "https://huggingface.co/\(repo)/resolve/main/\(file)")
            
        case .githubRelease(let owner, let repo, let tag, let asset):
            return URL(string: "https://github.com/\(owner)/\(repo)/releases/download/\(tag)/\(asset)")
            
        case .direct(let url):
            return url
            
        case .bundled:
            return nil
        }
    }
    
    /// Human-readable description of the source for UI display.
    var displayDescription: String {
        switch self {
        case .whisperKit(let model):
            return "WhisperKit (\(model))"
        case .huggingFace(let repo, _):
            return "HuggingFace · \(repo)"
        case .githubRelease(let owner, let repo, let tag, _):
            return "GitHub · \(owner)/\(repo)@\(tag)"
        case .direct(let url):
            return url.host ?? url.absoluteString
        case .bundled:
            return "Bundled with app"
        }
    }
}
