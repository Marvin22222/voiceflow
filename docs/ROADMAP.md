# 🗺️ Roadmap

Phased development plan for VoiceFlow.

---

## 🎯 Vision

Ship a **free, open source, on-device voice-to-text app for iPhone** that:
- Works anywhere (keyboard extension + action button)
- Costs nothing (free forever, MIT licensed)
- Respects privacy (100% on-device, no cloud)
- Looks beautiful (modern iOS design)

---

## 📅 Timeline Overview

```
2026 Q3: Phase 1 + 2 (MVP + Keyboard)
2026 Q4: Phase 3 + 4 (Action Button + Launch)
2027 Q1: Phase 5 (Android + Pro Features)
```

**Total:** ~6 months to App Store launch, ongoing after.

---

## Phase 1: MVP — Core App + Whisper (4-6 weeks)

**Goal:** Functional voice-to-text app with Whisper support and basic UI.

### Week 1: Setup
- [ ] Xcode project structure (Main App + Keyboard Ext. + Shared)
- [ ] App Group configuration
- [ ] SwiftUI app skeleton with TabView (Home, Models, History, Settings)
- [ ] GitHub Actions CI (build + lint + test)

### Week 2: Audio + WhisperKit
- [ ] AVAudioEngine integration (capture, 16kHz mono PCM)
- [ ] WhisperKit Swift Package dependency
- [ ] Model download on first launch (tiny/base/small)
- [ ] Model cache management

### Week 3: Recording Flow
- [ ] Hold-to-talk mic button (with pulse animation + haptics)
- [ ] Live audio waveform (AVAudioEngine tap → SwiftUI Canvas)
- [ ] Silero VAD integration (via WhisperKit)
- [ ] Streaming partial transcription

### Week 4: Transcription + Display
- [ ] Final transcription result
- [ ] Result View (editable text field)
- [ ] Copy / Share actions
- [ ] Save transcription to SwiftData

### Week 5: Models Screen (Handy-style)
- [ ] Models screen with downloaded + available models
- [ ] Model download UI (progress, cancel, pause)
- [ ] Model delete / free up storage
- [ ] Activate model (set as default)
- [ ] Visual accuracy/speed indicators
- [ ] Storage usage display

### Week 6: Settings + Onboarding + Beta
- [ ] Settings screen (model, language, theme, trigger options)
- [ ] Theme switching (dark/light/auto)
- [ ] Accent color picker
- [ ] 5-screen onboarding flow
- [ ] TestFlight upload
- [ ] Internal testing

**Deliverable:** MVP with Whisper + Models management UI.

---



---

## Phase 1.5: Multi-Model Foundation (2-3 weeks)

**Goal:** Add Parakeet as second backend, refactor for pluggable architecture.

### Week 7-8: Pluggable Backend Architecture
- [ ] Define `TranscriptionBackend` protocol
- [ ] Refactor WhisperKit into `WhisperBackend` conforming to protocol
- [ ] Create `ModelRegistry` (catalog of all models)
- [ ] Model download manager (HuggingFace, GitHub, direct URLs)
- [ ] Update Models screen to show pluggable backends

### Week 9: Add Parakeet TDT v3
- [ ] Add [FluidAudio](https://github.com/FluidInference/FluidAudio) Swift Package
- [ ] Implement `ParakeetBackend` (NVIDIA Parakeet TDT 0.6B v3)
- [ ] Add to Models screen as download option
- [ ] Test on iPhone 15 Pro + older devices
- [ ] Document performance benchmarks

**Deliverable:** Pluggable architecture + 2 working backends (Whisper + Parakeet).

---

## Phase 2: More Models + Auto-Detection (4-6 weeks)

**Goal:** Add Breeze ASR, GigaAM, Cohere Transcribe. Language-aware auto-switching.

### Week 10-11: Breeze ASR 25
- [ ] Port [Breeze-ASR-25_coreml](https://huggingface.co/aoiandroid/Breeze-ASR-25_coreml) to iOS
- [ ] Implement `BreezeASRBackend` (Mandarin + English, code-switching)
- [ ] Test on iPhone 15 Pro
- [ ] Add to Models screen

### Week 12-13: GigaAM v3 + Cohere Transcribe
- [ ] Port GigaAM v3 to ONNX Runtime for iOS
- [ ] Implement `GigaAMBackend` (Russian)
- [ ] Integrate Cohere Transcribe (highest accuracy)
- [ ] Add both to Models screen

### Week 14-15: Language Auto-Detection
- [ ] Implement language detection (first 5 seconds of audio)
- [ ] Auto-select best model for detected language
- [ ] User can pin models to specific languages
- [ ] Settings → "Auto-select model" toggle

**Deliverable:** 5 backends (Whisper, Parakeet, Breeze, GigaAM, Cohere) + auto-detection.

---

## Phase 2: Keyboard Extension (2-3 weeks)

**Goal:** Use VoiceFlow in any app via custom keyboard.

### Week 7: Extension Setup
- [ ] Custom Keyboard target in Xcode
- [ ] Keyboard view controller
- [ ] Mic button in keyboard layout
- [ ] Info.plist configuration (RequestsOpenAccess = YES)

### Week 8: App Group Bridge
- [ ] App Group container shared between app + extension
- [ ] Main app writes pending text to container
- [ ] Keyboard polls container for new text
- [ ] `insertText()` into active input field

### Week 9: UX Polish
- [ ] Keyboard height customization
- [ ] Haptic feedback in keyboard
- [ ] Toggle between full keyboard and mic-only mode
- [ ] Visual indicator when recording is active

**Deliverable:** Working custom keyboard that inserts transcribed text.

---

## Phase 3: Action Button + Live Activity (1-2 weeks)

**Goal:** Hardware integration + background recording indicator.

### Week 10: Action Button
- [ ] SiriKit / Shortcuts integration
- [ ] App intent for "Start Recording"
- [ ] Deep link from Action Button
- [ ] Auto-start recording on launch via intent

### Week 11: Live Activity
- [ ] ActivityKit setup
- [ ] Dynamic Island recording indicator
- [ ] Lock Screen Live Activity widget
- [ ] Background audio session

**Deliverable:** Hardware shortcut + beautiful background recording UI.

---

## Phase 4: App Store Launch (1-2 weeks)

**Goal:** Public release on App Store.

### Week 12: App Store Prep
- [ ] App Store Connect listing (name, description, screenshots)
- [ ] App icon design (1024x1024 + all sizes)
- [ ] Screenshots for all device sizes (6.5", 6.7", 5.5")
- [ ] Privacy nutrition labels
- [ ] Privacy policy URL
- [ ] App Review information

### Week 13: Submission + Marketing
- [ ] App Store submission (review takes 1-3 days)
- [ ] Product Hunt launch prep
- [ ] Reddit posts (r/iOSProgramming, r/sideproject, r/apple)
- [ ] Hacker News "Show HN" post
- [ ] GitHub repo polish (badges, demo GIF, contributing guide)
- [ ] Twitter/X launch thread

### Week 14: Post-Launch
- [ ] Bug fixes from user feedback
- [ ] Respond to App Store reviews
- [ ] Monitor crash reports
- [ ] v1.0.1 hotfix release

**Deliverable:** Live on App Store, public awareness.

---

## Phase 5: Post-Launch (Ongoing)

### Android Version (Q1 2027)
- [ ] Evaluate: React Native vs native Kotlin vs Flutter
- [ ] Recommendation: native Kotlin (best ANE equivalent — Android NNAPI)
- [ ] Whisper via whisper.cpp compiled for Android
- [ ] Android keyboard extension
- [ ] Cross-platform sync (optional, via Firebase or custom)

### Pro Features (Q2 2027)
- [ ] Large-v3-turbo model (requires subscription or one-time purchase)
- [ ] Custom vocabulary (boost specific words/phrases)
- [ ] Cloud sync via iCloud (opt-in)
- [ ] Export transcriptions (Markdown, PDF, TXT)
- [ ] Advanced settings (audio quality, transcription temperature)

### Growth (Q3 2027+)
- [ ] macOS version (Mac Catalyst or SwiftUI native)
- [ ] Apple Watch companion (quick dictation from wrist)
- [ ] Translation mode (Whisper's translate task)
- [ ] Multi-speaker diarization
- [ ] Browser extension (Chrome, Safari)
- [ ] Public API for developers

---

## 🎯 Success Metrics

### 3 Months Post-Launch
- [ ] 1,000+ downloads
- [ ] 100+ GitHub stars
- [ ] 4.5+ star rating on App Store
- [ ] Featured in 1+ Apple newsletter/blog

### 6 Months
- [ ] 10,000+ downloads
- [ ] 500+ GitHub stars
- [ ] 5+ contributors
- [ ] Android version in beta

### 12 Months
- [ ] 50,000+ downloads
- [ ] 1,000+ GitHub stars
- [ ] Top 50 in Utilities category (US/DE)
- [ ] $1,000+ revenue (if Pro tier launched)
- [ ] Sustainable contributor community

---

## 💰 Monetization Strategy

**Primary:** Free, MIT-licensed open source app. No monetization for core features.

**Optional future:**
- **Pro Tier** ($4.99 one-time or $0.99/month)
  - Larger models (small, large-v3)
  - Custom vocabulary
  - Cloud sync (iCloud)
  - Advanced themes
- **Donations** (GitHub Sponsors, Ko-fi, Buy Me a Coffee)
- **Tip jar** in app (one-time donations)

**Will NOT do:**
- ❌ Ads (contradicts privacy-first mission)
- ❌ Selling user data (we don't collect any)
- ❌ Forced subscriptions

---

## 🚧 Risks & Mitigation

| Risk | Impact | Mitigation |
|---|---|---|
| **Apple rejects app** | High | Follow HIG strictly, test on TestFlight first, have backup plan |
| **WhisperKit breaks iOS update** | Medium | Pin Swift Package versions, maintain own fork as backup |
| **Model download fails** | Medium | Retry logic, offline fallback to bundled tiny model |
| **Keyboard extension crashes** | High | Extensive testing, fallback to "open app" pattern |
| **Battery drain complaints** | Medium | Optimize for ANE, profile with Instruments |
| **Competition (Apple adds native)** | Medium | Differentiate via open source + customization |
| **Low adoption** | Medium | Strong marketing (HN, Reddit, Product Hunt) |

---

## 🤝 How to Contribute

See [CONTRIBUTING.md](../CONTRIBUTING.md). Most needed:

- [ ] SwiftUI/Swift developers (especially with iOS audio experience)
- [ ] Designers (Figma mockups, icon design)
- [ ] Technical writers (documentation, tutorials)
- [ ] Translators (i18n)
- [ ] Beta testers (TestFlight)

---

## 📞 Feedback

Have ideas for the roadmap? Open a [Feature Request](../../issues/new?template=feature_request.md) or start a [Discussion](../../discussions).

---

*Last updated: 2026-06-17*
