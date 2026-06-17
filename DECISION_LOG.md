# 📋 Decision Log

Why we chose what we chose. Documented for transparency.

---

## Decision 001: App Name "VoiceFlow"

**Date:** 2026-06-17
**Status:** ✅ Decided (work in progress, can change)

**Options considered:**
- `VoiceFlow` ✅ — Short, memorable, descriptive
- `FlowType` — Cute but unclear
- `Talkr` — Modern, but vague
- `WhisprFree` — Too long, references competitor
- `VoiceKey` — Technical, but sounds like a product key
- `Handy-iOS` — Direct port of inspiration, but name already taken (cjpais/Handy)

**Decision:** `VoiceFlow` — best balance of brevity, clarity, and brandability.

**Rationale:**
- "Voice" → what it does (transcribes voice)
- "Flow" → implies smooth, natural, continuous
- Short, easy to type, easy to remember
- Available on App Store (need to verify at submission)

---

## Decision 002: Whisper Engine = WhisperKit (Argmax)

**Date:** 2026-06-17
**Status:** ✅ Decided

**Options considered:**
- WhisperKit (Argmax) ✅ — Swift-native, CoreML/ANE
- whisper.cpp (C/C++) — Cross-platform, but requires more Swift bridging
- OpenAI Whisper (Python) — Cloud-based, NOT allowed (privacy)
- iOS Speech Recognition — Apple's native, cloud-based, NOT ideal

**Decision:** WhisperKit

**Rationale:**
- ✅ MIT licensed (commercial use allowed)
- ✅ Swift-native (no FFI overhead)
- ✅ CoreML-compiled → runs on Apple Neural Engine (6x faster than CPU)
- ✅ Actively maintained by Argmax (commercial backing)
- ✅ Streaming + real-time capable
- ✅ Easy to integrate via Swift Package Manager
- ❌ Requires iOS 17+ (acceptable trade-off)

---

## Decision 003: License = MIT

**Date:** 2026-06-17
**Status:** ✅ Decided

**Options considered:**
- MIT ✅ — Permissive, commercial-friendly
- Apache 2.0 — Permissive + patent grant
- GPL v3 — Copyleft (would prevent proprietary forks)

**Decision:** MIT

**Rationale:**
- Maximum freedom for users and contributors
- Allows commercial use, modification, private use
- Short and easy to understand
- Compatible with most other licenses (including WhisperKit's MIT)
- Encourages adoption

---

## Decision 004: Platform = iOS First, Android Later

**Date:** 2026-06-17
**Status:** ✅ Decided

**Rationale:**
- iOS has WhisperKit (best on-device Whisper)
- iOS has Action Button (hardware shortcut)
- iOS users more willing to pay / value privacy
- Smaller market to start, easier to dominate
- Android version can come later with whisper.cpp + NNAPI

---

## Decision 005: Min iOS = 17

**Date:** 2026-06-17
**Status:** ✅ Decided

**Rationale:**
- Live Activities require iOS 16.1+
- ActivityKit improvements in iOS 17
- SwiftData requires iOS 17+
- Market share: iOS 17+ covers ~85% of active iPhones (mid-2026)
- Acceptable trade-off for modern features

---

## Decision 006: Default Model = Base

**Date:** 2026-06-17
**Status:** ✅ Decided

**Options:**
- Tiny (39 MB) — Fastest, lower accuracy
- Base (74 MB) ✅ — Balanced
- Small (244 MB) — Better accuracy, slower

**Decision:** Base

**Rationale:**
- Sweet spot between speed and accuracy
- 74 MB is acceptable download size
- Real-time transcription on iPhone 15 Pro
- User can upgrade to Small in settings if needed

---

## Decision 007: No Analytics, No Telemetry

**Date:** 2026-06-17
**Status:** ✅ Decided

**Rationale:**
- Privacy-first mission
- Open source = users can verify no tracking
- We don't need analytics to make decisions
- Saves battery + reduces app size
- Builds trust

---

## Decision 008: UI Framework = SwiftUI

**Date:** 2026-06-17
**Status:** ✅ Decided

**Rationale:**
- Modern declarative framework (less code)
- iOS 17+ has mature SwiftUI
- Easier to maintain than UIKit
- Better Live Activity support
- Reactive paradigm fits streaming transcription

---

## Decision 009: Storage = SwiftData

**Date:** 2026-06-17
**Status:** ✅ Decided

**Rationale:**
- Apple's modern replacement for Core Data
- iOS 17+ native
- SwiftUI-friendly (@Model, @Query)
- Less boilerplate than Core Data
- Good performance for our use case (small datasets)

---

## Decision 010: Distribution = App Store (not TestFlight-only)

**Date:** 2026-06-17
**Status:** ✅ Decided

**Rationale:**
- Maximum reach (2 billion+ active iPhones)
- Discoverability via App Store search
- Trust signal (Apple's review)
- $99/year is manageable cost
- Can later add TestFlight for beta testers

---

## Decision 011: Monorepo Structure

**Date:** 2026-06-17
**Status:** ✅ Decided

**Structure:**
```
voiceflow/
├── VoiceFlow/           # Main app target
├── VoiceFlowKeyboard/   # Keyboard extension target
├── VoiceFlowShared/     # Shared code (App Group)
└── docs/                # Documentation
```

**Rationale:**
- Shared code between app and extension (App Group types, constants)
- Easier to keep targets in sync
- Standard Xcode multi-target setup
- Not complex enough to need separate repos

---

## Decision 012: Conventional Commits

**Date:** 2026-06-17
**Status:** ✅ Decided

**Rationale:**
- Clear commit history
- Auto-generate changelogs
- Easier code review
- Standard in open source

---

## Future Decisions (TBD)

- [ ] App icon design (who? when?)
- [ ] Website (GitHub Pages? custom domain?)
- [ ] Discord / community chat?
- [ ] Translation strategy (when to add i18n?)
- [ ] Pro tier features (when? what?)
- [ ] Android: native Kotlin vs React Native vs Flutter?

---

*Last updated: 2026-06-17*
