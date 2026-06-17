# 🎯 Coding Conventions

Swift coding conventions for VoiceFlow. Following Apple's Swift API Design Guidelines + community best practices.

---

## 🎯 Guiding Principles

1. **Clarity > Brevity** — Read code like prose
2. **Explicit > Implicit** — Type signatures should be clear
3. **Composition > Inheritance** — Protocols + structs over class hierarchies
4. **Small, focused units** — Each type/file does ONE thing well
5. **Test-driven where it matters** — Services tested, views smoke-tested

---

## 📁 File Organization

### One Type Per File
Each public type lives in its own file, named exactly after the type.

```swift
// ✅ Good
Sources/Services/AudioCaptureService.swift  → class AudioCaptureService
Sources/Models/TranscriptionResult.swift     → struct TranscriptionResult

// ❌ Bad
Sources/Helpers.swift  →  AudioCaptureService, TranscriptionResult, Logger
```

### MARK Sections (Xcode Jump Bar)

Use `// MARK: -` to organize files. Xcode uses them for the jump bar.

```swift
import Foundation

// MARK: - Type Definition

struct TranscriptionResult: Codable, Equatable {
    // MARK: - Properties
    
    let text: String
    let confidence: Double
    let language: Language
    let timestamp: Date
    
    // MARK: - Initialization
    
    init(text: String, confidence: Double = 1.0, language: Language, timestamp: Date = Date()) {
        // ...
    }
}

// MARK: - Factory Methods

extension TranscriptionResult {
    static let empty = TranscriptionResult(text: "", language: .unknown)
}

// MARK: - Computed Properties

extension TranscriptionResult {
    var wordCount: Int {
        text.split(separator: " ").count
    }
}

// MARK: - Testing Helpers

#if DEBUG
extension TranscriptionResult {
    static let mock = TranscriptionResult(
        text: "Hello world",
        language: .english
    )
}
#endif
```

---

## 🏷️ Naming Conventions

### Types

| Kind | Convention | Example |
|---|---|---|
| **Class** | PascalCase | `AudioCaptureService`, `TranscriptionService` |
| **Struct** | PascalCase | `TranscriptionResult`, `ModelDefinition` |
| **Protocol** | PascalCase, often ends in `-able`, `-ible`, or noun | `TranscriptionBackend`, `AudioSampleable` |
| **Enum** | PascalCase | `Language`, `ModelSource` |
| **Enum Case** | camelCase | `.english`, `.parakeetTDT`, `.huggingFace` |
| **Type Alias** | PascalCase | `typealias AudioBuffer = AVAudioPCMBuffer` |

### Variables & Functions

```swift
// camelCase
var isRecording: Bool
var transcriptionResult: TranscriptionResult?

func transcribe(audio: AVAudioPCMBuffer) async throws -> TranscriptionResult

// Boolean properties read like assertions
var isEmpty: Bool { get }
var hasFinished: Bool { get }
var canTranscribe: Bool { get }

// Factory methods: begin with `make`
func makeWhisperBackend(model: WhisperModel) throws -> TranscriptionBackend

// Mutating methods: use verb form
func append(_ chunk: AudioChunk)
func startRecording()
func stopRecording()
```

### Acronyms

Treat acronyms as words. Initialism rule: capitalize only the first letter.

```swift
// ✅ Good
var url: URL
var id: UUID
var htmlContent: String
var apiKey: String

// ❌ Bad
var URL: URL
var HtmlContent: String
```

---

## 📝 Documentation

### Public APIs Get DocC Comments

```swift
/// Captures audio from the device microphone and streams PCM buffers.
///
/// `AudioCaptureService` is responsible for:
/// - Requesting microphone permission
/// - Configuring the audio session
/// - Streaming PCM buffers at 16 kHz mono Float32
///
/// Use `start()` to begin capture and `stop()` to end. Subscribe to
/// `audioBufferPublisher` to receive buffers in real-time.
///
/// ## Example
///
/// ```swift
/// let service = AudioCaptureService()
/// service.audioBufferPublisher
///     .sink { buffer in print("Got \(buffer.frameLength) samples") }
///     .store(in: &cancellables)
///
/// try await service.start()
/// ```
public final class AudioCaptureService {
    // ...
}
```

### MARK Comments for Sections

```swift
public final class AudioCaptureService {
    // MARK: - Public Properties
    
    var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> { ... }
    
    // MARK: - Initialization
    
    public init() throws { ... }
    
    // MARK: - Public Methods
    
    public func start() async throws { ... }
    public func stop() async { ... }
    
    // MARK: - Private Properties
    
    private let audioEngine = AVAudioEngine()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private Methods
    
    private func configureAudioSession() throws { ... }
}
```

---

## 🔒 Access Control

Default to `private` or `fileprivate`. Only mark `public` what needs to be public.

```swift
// ✅ Good
final class AudioCaptureService {
    private let audioEngine = AVAudioEngine()
    private(set) var isRecording = false
    
    func start() async throws { ... }
}

// ❌ Bad — everything is internal by default but unnecessary
final class AudioCaptureService {
    let audioEngine = AVAudioEngine()
    var isRecording = false
    func start() async throws { ... }
}
```

---

## ⚡ Async/Await

### Prefer async/await over Combine for new code

```swift
// ✅ Good — async/await
func transcribe(_ audio: AVAudioPCMBuffer) async throws -> TranscriptionResult

// ⚠️ OK for SwiftUI — Combine bindings
@Published var transcriptionResult: TranscriptionResult?

// ❌ Bad — callback hell
func transcribe(_ audio: AVAudioPCMBuffer, completion: @escaping (Result<TranscriptionResult, Error>) -> Void)
```

### Error Handling

```swift
// Define domain-specific errors
enum AudioCaptureError: LocalizedError {
    case permissionDenied
    case audioSessionConfigurationFailed(underlying: Error)
    case engineStartFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied. Enable it in Settings."
        case .audioSessionConfigurationFailed(let err):
            return "Could not configure audio: \(err.localizedDescription)"
        case .engineStartFailed(let err):
            return "Could not start audio engine: \(err.localizedDescription)"
        }
    }
}
```

---

## 🧪 Testing

### Test File Naming

```
Tests/Services/AudioCaptureServiceTests.swift  → class AudioCaptureServiceTests
```

### Test Structure (Given-When-Then)

```swift
import XCTest
@testable import VoiceFlow

final class AudioCaptureServiceTests: XCTestCase {
    // MARK: - Properties
    
    private var sut: AudioCaptureService!
    private var mockPermission: MockPermissionService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockPermission = MockPermissionService()
        sut = AudioCaptureService(permissionService: mockPermission)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockPermission = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests: Start
    
    func test_start_whenPermissionGranted_startsEngine() async throws {
        // Given
        mockPermission.grantPermission()
        
        // When
        try await sut.start()
        
        // Then
        XCTAssertTrue(sut.isRecording)
    }
    
    func test_start_whenPermissionDenied_throws() async {
        // Given
        mockPermission.denyPermission()
        
        // When/Then
        await assertThrowsError(try await sut.start()) { error in
            XCTAssertEqual(error as? AudioCaptureError, .permissionDenied)
        }
    }
}
```

---

## 🎨 SwiftUI Conventions

### View Structure

```swift
struct HomeView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var settings: AppSettings
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            header
            micButton
            modelSelector
        }
        .background(Color.appBackground)
        .task { await viewModel.onAppear() }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack {
            Text("VoiceFlow")
                .font(.title)
            Text("Tip & Speak, Release & Done")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var micButton: some View {
        MicButton(isRecording: viewModel.isRecording) {
            await viewModel.toggleRecording()
        }
    }
    
    private var modelSelector: some View {
        ModelSelector(selection: $viewModel.selectedModel)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(AppSettings.preview)
}
```

### ViewModel Pattern (MVVM)

```swift
@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var isRecording = false
    @Published var selectedModel: ModelDefinition = .whisperBase
    @Published private(set) var availableModels: [ModelDefinition] = []
    
    // MARK: - Dependencies (injected)
    
    private let audioService: AudioCaptureService
    private let modelRegistry: ModelRegistry
    
    // MARK: - Initialization
    
    init(
        audioService: AudioCaptureService = .live,
        modelRegistry: ModelRegistry = .live
    ) {
        self.audioService = audioService
        self.modelRegistry = modelRegistry
    }
    
    // MARK: - Lifecycle
    
    func onAppear() async {
        await loadAvailableModels()
    }
    
    // MARK: - Actions
    
    func toggleRecording() async {
        if isRecording {
            await stopRecording()
        } else {
            await startRecording()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadAvailableModels() async {
        availableModels = await modelRegistry.allAvailable()
    }
    
    private func startRecording() async {
        do {
            try await audioService.start()
            isRecording = true
        } catch {
            // Handle error
        }
    }
    
    private func stopRecording() async {
        await audioService.stop()
        isRecording = false
    }
}
```

---

## 🛠️ Tooling

### SwiftLint

A `.swiftlint.yml` config will be added. Key rules:

- `identifier_name` — No single-letter names except in loops
- `line_length` — 120 chars warning, 200 error
- `function_body_length` — 40 lines warning, 100 error
- `cyclomatic_complexity` — 10 warning, 20 error
- `force_cast` — Error
- `force_try` — Error

### SwiftFormat

A `.swiftformat` config will be added for consistent formatting.

### Git Hooks

Pre-commit hook runs SwiftLint + SwiftFormat on changed files.

---

## 📦 Dependencies (Swift Package Manager)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.7.0"),
    .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.1.0"),
],
```

All dependencies declared centrally in `Package.swift`, **not** via Xcode UI.

---

## 🏛️ Architecture: Clean Architecture Lite

```
┌─────────────────────────────────────────┐
│              SwiftUI Views              │  ← UI Layer
│  (HomeView, RecordingView, etc.)        │
└──────────────┬──────────────────────────┘
               │ @StateObject / @EnvironmentObject
               ▼
┌─────────────────────────────────────────┐
│              ViewModels                 │  ← Presentation Layer
│  (HomeViewModel, etc.)                  │
└──────────────┬──────────────────────────┘
               │ async/await
               ▼
┌─────────────────────────────────────────┐
│              Services                   │  ← Domain Layer
│  (AudioCaptureService,                  │
│   TranscriptionService,                │
│   ModelManager)                        │
└──────────────┬──────────────────────────┘
               │ protocol-based
               ▼
┌─────────────────────────────────────────┐
│           Models / Repositories         │  ← Data Layer
│  (TranscriptionBackend, ModelRegistry,  │
│   SwiftData Models)                    │
└─────────────────────────────────────────┘
```

**Rules:**
- Views depend on ViewModels (not directly on Services)
- ViewModels depend on Services (via protocols)
- Services depend on Models + Backend protocols
- No upward dependencies
- All dependencies injected via initializer

---

## 🔍 Code Search & Navigation Tips

### Xcode Jump Bar
- Use `// MARK: -` for top-level sections
- Use `// MARK: <subsection>` for subsections

### Find Symbol
- `⌘⇧O` (Open Quickly) — type class/struct name
- `⌘⌃⇧O` (Open Symbol) — type member name

### Code Folding
- `⌘⌥←` / `⌘⌥→` — fold/unfold code blocks

### Documentation
- `⌥` + click on symbol — show DocC popover
- `⌘` + click on symbol — jump to definition

---

## 📚 References

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Apple SwiftUI Style Guide](https://developer.apple.com/documentation/swiftui)
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [DocC Documentation](https://www.swift.org/documentation/docc/)

---

*Last updated: 2026-06-17*
