//
//  ModelRegistry.swift
//  VoiceFlowShared
//
//  Catalog of all transcription models VoiceFlow knows about.
//  Single source of truth for the Models screen and ModelManager.
//

import Foundation

// MARK: - ModelRegistry

/// Catalog of all transcription models supported by VoiceFlow.
///
/// The registry is the single source of truth: the Models screen reads from
/// it, ``ModelManager`` uses it to download models, and the active model is
/// picked from it.
///
/// The registry ships with a curated list of ``builtInModels``. Additional
/// models can be registered at runtime via ``register(_:)``.
public final class ModelRegistry: @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// Shared registry instance.
    public static let shared = ModelRegistry()
    
    // MARK: - Properties
    
    /// All registered models, keyed by ``ModelDefinition/id``.
    private var models: [String: ModelDefinition]
    
    /// Lock for thread-safe access.
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    public init(models: [ModelDefinition] = ModelRegistry.builtInModels) {
        self.models = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }
    
    // MARK: - Query
    
    /// All registered models as an array (sorted by name).
    public var all: [ModelDefinition] {
        lock.lock()
        defer { lock.unlock() }
        return models.values.sorted { $0.displayName < $1.displayName }
    }
    
    /// Returns a model by its identifier, or nil if not registered.
    public func model(for id: String) -> ModelDefinition? {
        lock.lock()
        defer { lock.unlock() }
        return models[id]
    }
    
    /// Returns all models matching a backend type.
    public func models(forBackendType type: BackendType) -> [ModelDefinition] {
        all.filter { $0.backendType == type }
    }
    
    /// Returns all models that support a given language.
    public func models(supporting language: Language) -> [ModelDefinition] {
        all.filter { $0.supports(language) }
    }
    
    // MARK: - Mutation
    
    /// Registers a new model definition. Replaces any existing model with the same id.
    public func register(_ model: ModelDefinition) {
        lock.lock()
        defer { lock.unlock() }
        models[model.id] = model
    }
    
    /// Removes a model from the registry.
    public func unregister(id: String) {
        lock.lock()
        defer { lock.unlock() }
        models.removeValue(forKey: id)
    }
    
    // MARK: - Built-in Models
    
    /// Curated list of models shipped with VoiceFlow by default.
    public static let builtInModels: [ModelDefinition] = [
        // Whisper family (via WhisperKit)
        .whisperTiny,
        .whisperBase,
        .whisperSmall,
        
        // TODO Phase 1.5: Parakeet via FluidAudio
        // TODO Phase 2: Breeze ASR, GigaAM, Cohere Transcribe
    ]
}
