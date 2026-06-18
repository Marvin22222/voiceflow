//
//  TranscriptionServiceTests.swift
//  VoiceFlowTests
//
//  Unit tests for TranscriptionService.
//

import XCTest
import AVFoundation
@testable import VoiceFlow
import VoiceFlowShared

@MainActor
final class TranscriptionServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: TranscriptionService!
    
    // MARK: - Setup / Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = TranscriptionService(backendFactory: .mock)
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests: Active Model
    
    func test_setActiveModel_loadsBackend() async throws {
        try await sut.setActiveModel(.whisperBase)
        
        XCTAssertEqual(sut.activeModel?.id, ModelDefinition.whisperBase.id)
        XCTAssertTrue(sut.activeBackend?.isLoaded ?? false)
    }
    
    func test_setActiveModel_sameModelIsNoop() async throws {
        try await sut.setActiveModel(.whisperBase)
        let firstBackend = sut.activeBackend
        
        try await sut.setActiveModel(.whisperBase)
        let secondBackend = sut.activeBackend
        
        XCTAssertTrue(firstBackend === secondBackend)
    }
    
    func test_setActiveModel_switchingUnloadsPrevious() async throws {
        try await sut.setActiveModel(.whisperTiny)
        try await sut.setActiveModel(.whisperBase)
        
        XCTAssertEqual(sut.activeModel?.id, ModelDefinition.whisperBase.id)
    }
    
    // MARK: - Tests: Transcription
    
    func test_transcribe_withoutActiveModel_throws() async {
        do {
            _ = try await sut.transcribe(makeMockBuffer())
            XCTFail("Should throw")
        } catch TranscriptionError.notLoaded {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_transcribe_withActiveModel_returnsResult() async throws {
        try await sut.setActiveModel(.whisperBase)
        
        let result = try await sut.transcribe(makeMockBuffer())
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.backendName, ModelDefinition.whisperBase.displayName)
    }
    
    // MARK: - Helpers
    
    private func makeMockBuffer() -> AVAudioPCMBuffer {
        let format = StandardAudioFormat.pcmFormat
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024
        return buffer
    }
}
