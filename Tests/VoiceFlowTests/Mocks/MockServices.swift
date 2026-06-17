//
//  MockServices.swift
//  VoiceFlowTests
//
//  Mock implementations for testing.
//

import AVFoundation
import Foundation
import VoiceFlowShared

#if canImport(VoiceFlow)
@testable import VoiceFlow
#endif

// MARK: - MockAudioCaptureService

/// Mock audio capture service for testing.
@MainActor
final class MockAudioCaptureService {
    
    // MARK: - Properties
    
    private(set) var isRecording = false
    
    var shouldThrowOnStart = false
    var shouldGrantPermission = true
    var startCallCount = 0
    var stopCallCount = 0
    
    // MARK: - Methods
    
    func start() async throws {
        startCallCount += 1
        guard shouldGrantPermission else {
            throw NSError(domain: "Mock", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
        }
        if shouldThrowOnStart {
            throw NSError(domain: "Mock", code: 2)
        }
        isRecording = true
    }
    
    func stop() async {
        stopCallCount += 1
        isRecording = false
    }
}
