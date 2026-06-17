# 🧠 Model Registry

Multi-model architecture for VoiceFlow. Inspired by [Handy](https://handy.computer)'s approach of supporting multiple transcription backends.

---

## 🎯 Vision

VoiceFlow is **model-agnostic**. Instead of locking users into one transcription engine, we support multiple open-source models, each with different strengths:

- 🌐 **Whisper** (OpenAI) — Best multilingual coverage, 99+ languages
- ⚡ **Parakeet TDT v3** (NVIDIA) — Fastest, English + 25 EU languages
- 🀄 **Breeze ASR** (MediaTek) — Best for Mandarin + Code-switching
- 🇷🇺 **GigaAM v3** (SberDevices) — Best for Russian
- 🎯 **Cohere Transcribe** — Highest accuracy (5.42% WER, beats Whisper Large v3)
- 🌟 **Moonshine** (Useful Sensors) — Tiny model, ultra-fast for low-power devices

Users pick the model that fits their needs: language, accuracy, speed, storage.

---

## 📊 Model Matrix

| Model | Maintainer | Size | Speed (iPhone 15 Pro) | Accuracy (WER) | Languages | iOS Library | Status |
|---|---|---|---|---|---|---|---|
| **Whisper Tiny** | OpenAI | 39 MB | ⚡⚡⚡⚡⚡ Real-time | ~7-10% | 99 | WhisperKit | ✅ Phase 1 |
| **Whisper Base** | OpenAI | 74 MB | ⚡⚡⚡⚡ Real-time | ~5-7% | 99 | WhisperKit | ✅ Phase 1 |
| **Whisper Small** | OpenAI | 244 MB | ⚡⚡⚡ Slight delay | ~3-5% | 99 | WhisperKit | ✅ Phase 1 |
| **Whisper Large-v3 Turbo** | OpenAI | 809 MB | ⚡⚡ Delayed | ~3% | 99 | WhisperKit | 🔜 Phase 1.5 |
| **Parakeet TDT 0.6B v3** | NVIDIA | ~500 MB | ⚡⚡⚡⚡⚡ Real-time | ~5% (EU langs) | 25 EU | FluidAudio | 🔜 Phase 1.5 |
| **Breeze ASR 25** | MediaTek Research | ~1.0 GB | ⚡⚡⚡⚡ Real-time | ~4% (zh-TW) | Mandarin + EN | CoreML (custom) | 🟡 Phase 2 |
| **GigaAM v3** | SberDevices | 151 MB | ⚡⚡⚡⚡⚡ Real-time | ~6% (RU) | Russian only | ONNX Runtime | 🟡 Phase 2 |
| **Cohere Transcribe** | Cohere | ~1.7 GB | ⚡⚡ Slow | **5.42%** (best!) | 100+ | Custom (TBD) | 🟡 Phase 2 |
| **Moonshine** | Useful Sensors | ~50 MB | ⚡⚡⚡⚡⚡ Real-time | ~10% | 5 (EN, ES, etc.) | WhisperKit or custom | 🟡 Phase 3 |
| **Parakeet V2** | NVIDIA | ~250 MB | ⚡⚡⚡⚡ Real-time | ~7% (EU) | 25 EU | FluidAudio | 🟡 Phase 2 |

---

## 🏗️ Architecture: Pluggable Model Backend

```
┌────────────────────────────────────────────────────────┐
│                  VoiceFlow App                         │
│                                                        │
│  ┌────────────────────────────────────────────────┐   │
│  │           Transcription Service                │   │
│  │  (unified API for all models)                  │   │
│  │                                                │   │
│  │  interface TranscriptionBackend {              │   │
│  │    func transcribe(audio: AVAudioPCMBuffer)    │   │
│  │      async throws -> String                    │   │
│  │    var name: String                            │   │
│  │    var sizeBytes: Int                          │   │
│  │    var supportedLanguages: [Language]          │   │
│  │  }                                             │   │
│  └────────────┬───────────────────────────────────┘   │
│               │                                        │
│       ┌───────┼────────┬──────────┬──────────┐         │
│       ▼       ▼        ▼          ▼          ▼         │
│  ┌──────┐ ┌──────┐ ┌──────┐  ┌──────┐  ┌──────┐       │
│  │Whisper│ │Parakeet│ │Breeze│  │GigaAM│  │Cohere│      │
│  │  Kit  │ │ (Fluid │ │ ASR  │  │  v3  │  │Trans-│      │
│  │       │ │Audio) │ │(CoreML│  │(ONNX)│  │ cribe│      │
│  └──────┘ └──────┘ └──────┘  └──────┘  └──────┘       │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 🧩 Backend Implementation

### Whisper Backend (WhisperKit)

```swift
import WhisperKit

final class WhisperBackend: TranscriptionBackend {
    let name = "Whisper"
    let sizeBytes: Int  // depends on model variant
    let supportedLanguages: [Language]  // 99+
    
    private let whisperKit: WhisperKit
    
    init(modelVariant: WhisperModel) async throws {
        self.whisperKit = try await WhisperKit(
            model: modelVariant.rawValue
        )
    }
    
    func transcribe(audio: AVAudioPCMBuffer) async throws -> String {
        let result = try await whisperKit.transcribe(
            audioFrame: audio
        )
        return result.text
    }
}
```

### Parakeet Backend (FluidAudio)

```swift
import FluidAudio

final class ParakeetBackend: TranscriptionBackend {
    let name = "Parakeet TDT v3"
    let sizeBytes = 500_000_000  // ~500 MB
    let supportedLanguages: [Language] = [
        .english, .german, .french, .spanish,
        .italian, .portuguese, .dutch, .polish,
        // ... 25 European languages
    ]
    
    private let asrManager: AsrManager
    
    init() async throws {
        self.asrManager = try await AsrManager(
            model: .parakeetTDT
        )
    }
    
    func transcribe(audio: AVAudioPCMBuffer) async throws -> String {
        let result = try await asrManager.process(audio)
        return result.text
    }
}
```

### Breeze ASR Backend (Custom CoreML)

```swift
final class BreezeASRBackend: TranscriptionBackend {
    let name = "Breeze ASR 25"
    let sizeBytes = 1_000_000_000  // 1.0 GB
    let supportedLanguages: [Language] = [
        .mandarinTraditional, .english  // + code-switching
    ]
    
    private let model: MLModel
    private let tokenizer: BreezeTokenizer
    
    init() async throws {
        // Load CoreML model from bundle
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        self.model = try Breeze_ASR_25(configuration: config).model
        
        // Load BPE tokenizer
        self.tokenizer = try BreezeTokenizer()
    }
    
    func transcribe(audio: AVAudioPCMBuffer) async throws -> String {
        // 1. Convert audio to mel spectrogram
        let mel = try AudioFeatures.melSpectrogram(from: audio)
        
        // 2. Run encoder + decoder
        let input = try BreezeASR25Input(features: mel)
        let output = try await model.prediction(from: input)
        
        // 3. Decode tokens to text
        let tokenIds = output.tokenIds
        return tokenizer.decode(tokenIds)
    }
}
```

### Cohere Transcribe Backend

```swift
// Note: Cohere Transcribe might require custom integration
// depending on its runtime format (ONNX, PyTorch, CoreML)
final class CohereTranscribeBackend: TranscriptionBackend {
    let name = "Cohere Transcribe"
    let sizeBytes = 1_700_000_000  // 1.7 GB
    let supportedLanguages: [Language] = .allKnown  // 100+
    
    // Implementation depends on Cohere's distribution format
    // See https://huggingface.co/cohere for model files
}
```

---

## 📦 Model Management

### Storage Layout

```
~/Library/Application Support/VoiceFlow/Models/
├── whisper-tiny/
│   ├── model.mlmodelc/
│   ├── tokenizer.json
│   └── config.json
├── whisper-base/
├── whisper-small/
├── whisper-large-v3-turbo/
├── parakeet-tdt-v3/
│   ├── coreml/
│   └── tokenizer.json
├── breeze-asr-25/
│   ├── coreml/
│   └── tokenizer/
├── gigaam-v3/
│   ├── model.onnx
│   └── tokenizer/
└── cohere-transcribe/
    └── ...
```

### Download Strategy

```swift
final class ModelManager {
    enum ModelSource {
        case bundled           // Shipped with app
        case huggingFace(repo: String, file: String)
        case githubRelease(owner: String, repo: String, asset: String)
        case direct(URL: URL)
    }
    
    func download(_ model: ModelDefinition) async throws -> URL {
        switch model.source {
        case .bundled:
            return Bundle.main.url(forResource: model.id, withExtension: nil)!
        case .huggingFace(let repo, let file):
            return try await downloadFromHuggingFace(repo: repo, file: file)
        // ...
        }
    }
}
```

### Model Download UI

Handy-style "Modelle" page (see `docs/WIREFRAMES.md` Screen 6):

```
┌──────────────────────────────────────┐
│  ← Back       Models                 │
│──────────────────────────────────────│
│                                      │
│  DOWNLOADED                          │
│  ┌────────────────────────────────┐  │
│  │ ⚡ Whisper Base         [✓]   │  │  ← Active
│  │   74 MB · Multilingual         │  │
│  │   Acc ████░  Speed █████       │  │
│  │   [Delete]                     │  │
│  ├────────────────────────────────┤  │
│  │ ⚡ Parakeet TDT v3     [ ]   │  │
│  │   500 MB · 25 EU languages     │  │
│  └────────────────────────────────┘  │
│                                      │
│  AVAILABLE FOR DOWNLOAD              │
│  ┌────────────────────────────────┐  │
│  │ 🌟 Cohere Transcribe           │  │
│  │   1.7 GB · 100+ languages      │  │
│  │   Acc █████  Speed ██░░░       │  │
│  │   [Download ↓]                 │  │
│  ├────────────────────────────────┤  │
│  │ 🀄 Breeze ASR 25               │  │
│  │   1.0 GB · Mandarin + EN       │  │
│  │   [Download ↓]                 │  │
│  ├────────────────────────────────┤  │
│  │ 🇷🇺 GigaAM v3                  │  │
│  │   151 MB · Russian only        │  │
│  │   [Download ↓]                 │  │
│  └────────────────────────────────┘  │
│                                      │
│  STORAGE: 74 MB / 5 GB available     │
│                                      │
└──────────────────────────────────────┘
```

---

## 🎯 Model Selection Logic

### User Choice (Settings)

User can:
1. **Pick one model** as default
2. **Pin models** for specific languages (e.g., "GigaAM for Russian, Whisper for everything else")
3. **Auto-select** based on detected language (e.g., auto-switch to Breeze when Mandarin detected)

### Auto-Selection Algorithm (Future)

```swift
func selectBestModel(for language: Language) -> ModelDefinition {
    // 1. User-pinned model for this language?
    if let pinned = settings.pinnedModel(for: language) {
        return pinned
    }
    
    // 2. Best accuracy model that supports the language?
    let candidates = availableModels.filter { $0.supports(language) }
    return candidates.max { $0.accuracy > $1.accuracy } ?? .whisperBase
}
```

---

## 📈 Roadmap (Updated)

### Phase 1.0 (MVP — Current)
- [x] Whisper backend (Tiny/Base/Small) via WhisperKit
- [x] Single model selection
- [ ] Multi-model UI (download/select/delete)

### Phase 1.5 (Month 2-3)
- [ ] Parakeet TDT v3 via FluidAudio
- [ ] Whisper Large-v3 Turbo
- [ ] Model Manager refactor (pluggable backends)
- [ ] Multi-language support improved

### Phase 2.0 (Month 4-6)
- [ ] Breeze ASR 25 (CoreML port)
- [ ] GigaAM v3 (ONNX)
- [ ] Cohere Transcribe
- [ ] Auto-language detection with model switching

### Phase 3.0 (Month 6-12)
- [ ] Moonshine (tiny model for low-power devices)
- [ ] Custom model upload (advanced users)
- [ ] Model benchmark suite
- [ ] Community model contributions

---

## 🛠️ Adding a New Model

To add a new model backend:

1. **Create a Swift class** conforming to `TranscriptionBackend`
2. **Add it to `ModelRegistry`**
3. **Specify download source** (HuggingFace, GitHub, etc.)
4. **Add UI metadata** (name, size, accuracy, speed, languages)
5. **Test on iPhone 15 Pro** and older devices
6. **Document in this file**

Template:

```swift
struct ModelDefinition: Identifiable, Codable {
    let id: String
    let displayName: String
    let description: String
    let sizeBytes: Int
    let accuracyScore: Int  // 1-5
    let speedScore: Int     // 1-5
    let supportedLanguages: [Language]
    let source: ModelSource
    let backendFactory: () throws -> TranscriptionBackend
}
```

---

## 📚 References

- [Handy App — Modelle](https://handy.computer) (UI inspiration)
- [WhisperKit](https://github.com/argmaxinc/WhisperKit)
- [FluidAudio](https://github.com/FluidInference/FluidAudio)
- [Parakeet TDT 0.6B v3](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3)
- [Breeze-ASR-25 CoreML](https://huggingface.co/aoiandroid/Breeze-ASR-25_coreml)
- [GigaAM v3](https://github.com/salute-developers/GigaAM)
- [Cohere Transcribe (open source)](https://cohere.com/blog/transcribe)
- [Moonshine](https://github.com/useful-sensors/moonshine)

---

*Last updated: 2026-06-17*
