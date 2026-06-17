# 🏗️ Architecture

Technical architecture overview for VoiceFlow.

---

## 🎯 Design Goals

1. **Local-first** — All audio processing on-device, no network calls for transcription
2. **Low latency** — Streaming transcription, real-time feedback
3. **Battery-efficient** — Use Apple Neural Engine (ANE) when possible
4. **Privacy-preserving** — Zero telemetry, zero analytics
5. **Modular** — Easy to swap components (e.g., whisper.cpp vs WhisperKit)
6. **Testable** — Dependency injection, mockable services

---

## 🧱 Tech Stack

| Layer | Technology | Why |
|---|---|---|
| **Language** | Swift 5.9+ | Native iOS, best performance |
| **UI** | SwiftUI | Modern, declarative, iOS 17+ |
| **Transcription** | [WhisperKit](https://github.com/argmaxinc/WhisperKit) (Argmax) | MIT, Swift-native, CoreML/ANE |
| **Audio** | AVAudioEngine | Apple native, low-level access |
| **VAD** | Silero VAD (via WhisperKit) | State-of-the-art accuracy |
| **Storage** | SwiftData | Modern Apple-native ORM |
| **Concurrency** | Swift Concurrency (async/await) | Modern, safe |
| **Distribution** | App Store + TestFlight | Official channels |

---

## 📐 High-Level Architecture

```
┌──────────────────────────────────────────────────────────┐
│                       iPhone                             │
│                                                          │
│  ┌──────────────────┐    ┌──────────────────┐            │
│  │   Main App       │    │   Keyboard Ext.  │            │
│  │  (SwiftUI)       │    │                  │            │
│  │                  │    │  ┌────────────┐  │            │
│  │  ┌────────────┐  │    │  │  Mic-Btn   │  │            │
│  │  │   UI       │  │    │  └─────┬──────┘  │            │
│  │  └─────┬──────┘  │    │        │         │            │
│  │        │         │    │        ▼         │            │
│  │  ┌─────▼──────┐  │    │  ┌────────────┐  │            │
│  │  │  ViewModel │  │    │  │ Read Text  │  │            │
│  │  └─────┬──────┘  │    │  └─────┬──────┘  │            │
│  │        │         │    │        │         │            │
│  │  ┌─────▼──────┐  │    │        ▼         │            │
│  │  │  Services  │  │    │  insertText()    │            │
│  │  └─────┬──────┘  │    │  into field      │            │
│  │        │         │    └────────┬─────────┘            │
│  └────────┼─────────┘             │                      │
│           │                       │                      │
│           ▼                       ▼                      │
│  ┌──────────────────────────────────────────┐            │
│  │       App Group (Shared Container)       │            │
│  │  - pendingText: String                   │            │
│  │  - status: enum {idle, recording, done}  │            │
│  │  - modelState: enum {loading, ready}     │            │
│  └──────────────┬───────────────────────────┘            │
│                 │                                        │
│                 ▼                                        │
│  ┌──────────────────────────────────────────┐            │
│  │         Native iOS APIs                  │            │
│  │  - AVAudioEngine (mic capture)           │            │
│  │  - WhisperKit (local transcription)      │            │
│  │  - ActivityKit (live activity)           │            │
│  │  - SiriKit (action button)               │            │
│  └──────────────────────────────────────────┘            │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 🧩 Components

### 1. Main App (`VoiceFlow/`)

The user-facing SwiftUI application.

**Responsibilities:**
- Display UI (Home, Recording, Result, Settings, Onboarding)
- Capture audio (AVAudioEngine)
- Transcribe audio (WhisperKit)
- Manage settings (model size, language, theme)
- Handle App Group communication
- Show onboarding on first launch
- Download models on demand

**Key Files:**
```
VoiceFlow/
├── App/
│   ├── VoiceFlowApp.swift           # @main entry point
│   ├── AppDelegate.swift            # Lifecycle, permissions
│   └── ContentView.swift            # Root view
├── Views/
│   ├── HomeView.swift               # Main capture screen
│   ├── RecordingView.swift          # Active recording UI
│   ├── ResultView.swift             # Transcribed text view
│   ├── SettingsView.swift           # Settings
│   └── OnboardingView.swift         # First-launch flow
├── Models/
│   ├── Transcription.swift          # @Model SwiftData
│   ├── AppSettings.swift            # @Model SwiftData
│   └── WhisperModel.swift           # Enum: tiny/base/small/large
├── Services/
│   ├── AudioCaptureService.swift    # AVAudioEngine wrapper
│   ├── TranscriptionService.swift   # WhisperKit wrapper
│   ├── ModelManager.swift           # Download/cache models
│   ├── AppGroupBridge.swift         # Shared container I/O
│   └── HapticManager.swift          # Haptic feedback
└── Resources/
    ├── Assets.xcassets              # Icons, colors
    └── Localizable.strings          # i18n
```

### 2. Keyboard Extension (`VoiceFlowKeyboard/`)

Custom iOS keyboard with a microphone button.

**Responsibilities:**
- Display standard keyboard layout (QWERTY, etc.)
- Add a Mic button (e.g., bottom-left, next to spacebar)
- Trigger main app via URL scheme or App Group signal
- Read transcribed text from App Group
- Insert text into current input field

**⚠️ Apple Limitation:** Keyboard extensions **cannot access the microphone** for privacy reasons. Workaround:
- Companion app handles recording
- Keyboard polls App Group for pending text
- Or: keyboard opens main app, user records, app writes back

**Key Files:**
```
VoiceFlowKeyboard/
├── KeyboardViewController.swift     # Main entry
├── MicButtonView.swift              # Custom mic button
├── AppGroupReader.swift             # Read pending text
└── Info.plist                       # Extension config
```

### 3. Shared Module (`VoiceFlowShared/`)

Code shared between main app and keyboard extension.

**Contents:**
- `AppGroup.swift` — App Group identifier, paths
- `PendingText.swift` — Codable struct for shared text
- `Status.swift` — Enum for current state
- `Constants.swift` — Shared constants

### 4. Whisper Models

**Download on first launch** (not bundled with app — keeps app size small).

| Model | Size | Speed (iPhone 15 Pro) | Use Case |
|---|---|---|---|
| `tiny` | 39 MB | Real-time | Quick notes, low-power devices |
| `base` | 74 MB | Real-time | Default, balanced |
| `small` | 244 MB | Slightly delayed | Better accuracy |
| `large-v3-turbo` | 809 MB | Slow | Best accuracy, Pro feature |

**Storage:** `~/Library/Application Support/WhisperModels/`

---

## 🔄 Data Flow

### Standard Flow: Recording via App

```
1. User opens app
2. User taps & holds Mic button
3. AVAudioEngine starts capturing (PCM 16kHz mono)
4. Silero VAD detects speech start
5. WhisperKit transcribes streaming (partial results every ~500ms)
6. UI updates with live partial text
7. User releases Mic button
8. WhisperKit finalizes transcription
9. Result displayed in ResultView
10. User taps "Copy" or "Share"
```

### Keyboard Flow: Insert Anywhere

```
1. User is in another app (WhatsApp, Notes, etc.)
2. User switches to VoiceFlow keyboard
3. User taps Mic button in keyboard
4. Main app opens via URL scheme (`voiceflow://record`)
5. Main app auto-starts recording (full-screen UI)
6. User speaks
7. User taps "Insert" (or app auto-inserts)
8. Text written to App Group
9. User switches back to original app
10. Keyboard extension polls App Group, inserts text
```

### Action Button Flow: Hardware Shortcut

```
1. User configures Action Button → "VoiceFlow: Start Recording"
2. User holds Action Button
3. SiriKit triggers VoiceFlow
4. App opens, auto-starts recording
5. User speaks
6. User releases Action Button (or taps Done)
7. Text auto-copied to clipboard
8. User pastes anywhere
```

---

## 🔐 Privacy & Security

### Permissions

| Permission | Purpose | Required? |
|---|---|---|
| Microphone | Audio capture | ✅ Yes (essential) |
| Speech Recognition | iOS native (optional fallback) | ❌ No (WhisperKit is enough) |
| Siri | Action Button integration | ❌ Optional |

### Privacy Guarantees

- ✅ **Zero network calls** — WhisperKit runs entirely on-device
- ✅ **No telemetry** — We don't track anything
- ✅ **No analytics** — No Firebase, no Mixpanel, etc.
- ✅ **No ads** — App is free, no ad SDKs
- ✅ **No third-party SDKs** — Only Apple frameworks + WhisperKit
- ✅ **Open source** — Anyone can audit the code

### Data Storage

- **Transcriptions** — Stored locally via SwiftData (optional, can be disabled)
- **Audio recordings** — Never persisted, processed in-memory only
- **Settings** — Stored in UserDefaults
- **Models** — Cached in `~/Library/Application Support/WhisperModels/`

### Sandbox

iOS apps are sandboxed by default. VoiceFlow:
- Cannot access other apps' data
- Cannot make network calls without explicit permission
- Cannot record audio in background (only when foregrounded or via Live Activity)

---

## 🧪 Testing Strategy

### Unit Tests
- `AudioCaptureService` — Mock AVAudioEngine
- `TranscriptionService` — Mock WhisperKit
- `AppGroupBridge` — Test with in-memory storage

### Integration Tests
- End-to-end recording → transcription flow
- App Group write/read
- Keyboard extension text insertion

### UI Tests
- Tap Mic button → recording starts
- Hold Mic → release → transcription appears
- Settings change → reflects in UI

### Manual Testing Checklist
- [ ] First launch (onboarding)
- [ ] Model download (WiFi)
- [ ] Recording in quiet environment
- [ ] Recording in noisy environment
- [ ] Long recording (5+ minutes)
- [ ] Background recording (Live Activity)
- [ ] Keyboard insertion in Notes, WhatsApp, Safari
- [ ] Action Button trigger
- [ ] Low battery mode
- [ ] Airplane mode (offline)

---

## 🚀 Performance Considerations

### Latency Targets
- **Tap to recording start:** < 100ms
- **Recording to first partial result:** < 1s
- **Release to final transcription:** < 2s (for 30s recording)

### Optimization Strategies
1. **Use ANE** — WhisperKit compiles models to CoreML for ANE execution
2. **Stream partial results** — Don't wait for full recording to finish
3. **Lazy model loading** — Load model on first recording, cache in memory
4. **Background queue** — Audio capture on dedicated thread
5. **Reduce UI updates** — Throttle partial transcription updates to 5Hz

### Battery Impact
- **Recording:** ~5-10% per hour (similar to phone call)
- **Idle:** < 1% per hour
- **Model inference:** ~3-5% per hour of active transcription

---

## 🔮 Future Enhancements

- **Multi-speaker diarization** — Identify different speakers
- **Custom vocabulary** — Boost specific words/phrases
- **Translation** — Whisper supports translation mode
- **Cloud sync (opt-in)** — iCloud sync of transcriptions
- **Apple Watch app** — Record from wrist
- **macOS Catalyst** — Run on Mac via Catalyst
- **Live translation** — Translate speech in real-time

---

## 📚 References

- [WhisperKit Documentation](https://github.com/argmaxinc/WhisperKit)
- [Apple HIG — Custom Keyboards](https://developer.apple.com/design/human-interface-guidelines/text-input-and-display)
- [AVAudioEngine Programming Guide](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [Whisper Paper](https://arxiv.org/abs/2212.04356)

---

*Last updated: 2026-06-17*
