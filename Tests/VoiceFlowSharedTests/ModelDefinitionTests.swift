//
//  ModelDefinitionTests.swift
//  VoiceFlowSharedTests
//
//  Unit tests for ModelDefinition computed properties.
//

import XCTest
@testable import VoiceFlowShared

final class ModelDefinitionTests: XCTestCase {
    
    // MARK: - Tests: Size Formatting
    
    func test_sizeString_megabytes() {
        let model = ModelDefinition.whisperBase  // 74 MB
        XCTAssertTrue(model.sizeString.contains("MB"))
    }
    
    func test_sizeString_gigabytes() {
        let model = ModelDefinition(
            id: "big",
            displayName: "Big",
            description: "",
            author: "",
            sizeBytes: 1_500_000_000,  // 1.5 GB
            accuracyScore: 5,
            speedScore: 2,
            supportedLanguages: [.english],
            source: .bundled,
            backendType: .mock,
            license: "MIT"
        )
        XCTAssertTrue(model.sizeString.contains("GB"))
    }
    
    // MARK: - Tests: Score Bars
    
    func test_accuracyBars_rendersCorrectly() {
        XCTAssertEqual(ModelDefinition.whisperTiny.accuracyBars, "███░░")
        XCTAssertEqual(ModelDefinition.whisperBase.accuracyBars, "████░")
        XCTAssertEqual(ModelDefinition.whisperSmall.accuracyBars, "█████")
    }
    
    // MARK: - Tests: Language Support
    
    func test_supports_returnsTrueForSupportedLanguage() {
        XCTAssertTrue(ModelDefinition.whisperBase.supports(.english))
        XCTAssertTrue(ModelDefinition.whisperBase.supports(.german))
        XCTAssertTrue(ModelDefinition.whisperBase.supports(.french))
    }
    
    func test_supports_returnsTrueForAuto() {
        XCTAssertTrue(ModelDefinition.whisperBase.supports(.auto))
    }
    
    func test_isMultilingual_trueForManyLanguages() {
        XCTAssertTrue(ModelDefinition.whisperBase.isMultilingual)
    }
}

final class LanguageTests: XCTestCase {
    
    func test_displayName_returnsCorrectNames() {
        XCTAssertEqual(Language.english.displayName, "English")
        XCTAssertEqual(Language.german.displayName, "Deutsch")
        XCTAssertEqual(Language.french.displayName, "Français")
    }
    
    func test_flagEmoji_returnsFlagsForMajorLanguages() {
        XCTAssertEqual(Language.english.flagEmoji, "🇬🇧")
        XCTAssertEqual(Language.german.flagEmoji, "🇩🇪")
    }
    
    func test_isConcrete_excludesAutoAndUnknown() {
        XCTAssertFalse(Language.auto.isConcrete)
        XCTAssertFalse(Language.unknown.isConcrete)
        XCTAssertTrue(Language.english.isConcrete)
        XCTAssertTrue(Language.german.isConcrete)
    }
}

final class TranscriptionResultTests: XCTestCase {
    
    func test_isEmpty_trueForWhitespaceOnly() {
        let result = TranscriptionResult(text: "   \n  ", backendName: "x", audioDuration: 1)
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_isEmpty_falseForActualText() {
        let result = TranscriptionResult.mock
        XCTAssertFalse(result.isEmpty)
    }
    
    func test_wordCount_countsCorrectly() {
        let result = TranscriptionResult(text: "Hello world this is a test", backendName: "x", audioDuration: 1)
        XCTAssertEqual(result.wordCount, 6)
    }
    
    func test_confidence_clampedToRange() {
        let high = TranscriptionResult(text: "x", confidence: 1.5, backendName: "x", audioDuration: 1)
        XCTAssertEqual(high.confidence, 1.0)
        
        let low = TranscriptionResult(text: "x", confidence: -0.5, backendName: "x", audioDuration: 1)
        XCTAssertEqual(low.confidence, 0.0)
    }
    
    func test_isHighConfidence_trueAbove70Percent() {
        let high = TranscriptionResult(text: "x", confidence: 0.8, backendName: "x", audioDuration: 1)
        XCTAssertTrue(high.isHighConfidence)
        
        let low = TranscriptionResult(text: "x", confidence: 0.5, backendName: "x", audioDuration: 1)
        XCTAssertFalse(low.isHighConfidence)
    }
}

final class DownloadProgressTests: XCTestCase {
    
    func test_fraction_calculatesCorrectly() {
        let progress = DownloadProgress(
            bytesDownloaded: 50,
            totalBytes: 100,
            state: .downloading
        )
        XCTAssertEqual(progress.fraction, 0.5, accuracy: 0.001)
    }
    
    func test_fraction_zeroWhenTotalUnknown() {
        let progress = DownloadProgress(
            bytesDownloaded: 50,
            totalBytes: 0,
            state: .downloading
        )
        XCTAssertEqual(progress.fraction, 0)
    }
    
    func test_percentage_roundsCorrectly() {
        let progress = DownloadProgress(
            bytesDownloaded: 325_000_000,
            totalBytes: 500_000_000,
            state: .downloading
        )
        XCTAssertEqual(progress.percentage, 65)
    }
}

final class ModelSourceTests: XCTestCase {
    
    func test_huggingFace_resolvesCorrectURL() {
        let source = ModelSource.huggingFace(repo: "nvidia/parakeet", file: "model.bin")
        let url = source.resolveURL()
        XCTAssertEqual(
            url?.absoluteString,
            "https://huggingface.co/nvidia/parakeet/resolve/main/model.bin"
        )
    }
    
    func test_githubRelease_resolvesCorrectURL() {
        let source = ModelSource.githubRelease(
            owner: "user",
            repo: "model",
            tag: "v1.0",
            asset: "model.mlmodelc.zip"
        )
        let url = source.resolveURL()
        XCTAssertEqual(
            url?.absoluteString,
            "https://github.com/user/model/releases/download/v1.0/model.mlmodelc.zip"
        )
    }
    
    func test_bundled_returnsNil() {
        XCTAssertNil(ModelSource.bundled.resolveURL())
    }
}
