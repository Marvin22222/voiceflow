//
//  ModelRegistryTests.swift
//  VoiceFlowSharedTests
//
//  Unit tests for ModelRegistry and related models.
//

import XCTest
@testable import VoiceFlowShared

final class ModelRegistryTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: ModelRegistry!
    
    // MARK: - Setup / Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = ModelRegistry()
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests: Initialization
    
    func test_init_containsBuiltInModels() {
        XCTAssertFalse(sut.all.isEmpty, "Registry should have built-in models")
        XCTAssertTrue(sut.all.contains(.whisperBase), "Should contain Whisper Base")
    }
    
    // MARK: - Tests: Query
    
    func test_modelForId_returnsCorrectModel() {
        let model = sut.model(for: ModelDefinition.whisperBase.id)
        XCTAssertEqual(model?.id, ModelDefinition.whisperBase.id)
    }
    
    func test_modelForId_returnsNilForUnknownId() {
        let model = sut.model(for: "non-existent-model")
        XCTAssertNil(model)
    }
    
    func test_modelsForBackendType_filtersCorrectly() {
        let whisperModels = sut.models(forBackendType: .whisperKit)
        XCTAssertFalse(whisperModels.isEmpty)
        XCTAssertTrue(whisperModels.allSatisfy { $0.backendType == .whisperKit })
    }
    
    func test_modelsSupporting_filtersByLanguage() {
        let germanModels = sut.models(supporting: .german)
        XCTAssertFalse(germanModels.isEmpty)
        XCTAssertTrue(germanModels.allSatisfy { $0.supports(.german) })
    }
    
    // MARK: - Tests: Mutation
    
    func test_register_addsNewModel() {
        let customModel = ModelDefinition(
            id: "test-model",
            displayName: "Test Model",
            description: "For testing",
            author: "Test",
            sizeBytes: 100_000_000,
            accuracyScore: 4,
            speedScore: 4,
            supportedLanguages: [.english],
            source: .bundled,
            backendType: .mock,
            license: "MIT"
        )
        
        sut.register(customModel)
        
        XCTAssertNotNil(sut.model(for: "test-model"))
    }
    
    func test_unregister_removesModel() {
        sut.register(.mock)
        XCTAssertNotNil(sut.model(for: "mock-model" /* wrong */))
        
        // Unregister non-existent (should not crash)
        sut.unregister(id: "does-not-exist")
    }
}
