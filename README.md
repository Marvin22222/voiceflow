# 🎤 VoiceFlow

> **Free, open source, on-device voice-to-text for iPhone.**
> Press to talk. Release to insert. 100% local. No cloud. No subscription.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: iOS](https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg)]()
[![Swift: 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)]()
[![Status: Pre-Alpha](https://img.shields.io/badge/Status-Pre--Alpha-red.svg)]()

---

## ✨ Why VoiceFlow?

Every good voice-to-text app on iOS costs money. **Wispr Flow** charges ~$80/year. **WhisperFlow** and **Superwhisper** also have paywalls. Meanwhile, the open-source alternative [Handy](https://github.com/cjpais/handy) only runs on desktop.

**VoiceFlow fills the gap:** A free, open source, mobile voice-to-text app that runs **entirely on-device** using [WhisperKit](https://github.com/argmaxinc/WhisperKit). No cloud, no subscription, no data leaving your phone.

### Features (planned)

- 🎤 **Hold to talk** — Press, speak, release, done
- ⌨️ **Custom Keyboard** — Insert text into any app
- 🔘 **iPhone Action Button** — Hardware shortcut (iPhone 15 Pro+)
- 🧠 **Whisper Models** — tiny (39 MB) → large-v3 (1.5 GB)
- 🔇 **Silero VAD** — Smart silence detection
- 🎨 **Dark/Light Theme** — iOS 18 HIG-compliant design
- 🌍 **Multi-language** — Auto-detect, supports 99+ languages
- 🔒 **Privacy first** — Your voice never leaves your device

---

## 🚧 Status

**Pre-alpha.** Planning phase complete, implementation starting.

See [docs/ROADMAP.md](docs/ROADMAP.md) for the full timeline.

| Phase | Status | ETA |
|---|---|---|
| 1. MVP (Core App) | 🔴 Not started | Q3 2026 |
| 2. Keyboard Extension | 🔴 Not started | Q3 2026 |
| 3. Action Button + Live Activity | 🔴 Not started | Q4 2026 |
| 4. App Store Launch | 🔴 Not started | Q4 2026 |
| 5. Android Version | 🔴 Not started | 2027 |

---

## 🏗️ Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (iOS 17+)
- **Transcription:** [WhisperKit](https://github.com/argmaxinc/WhisperKit) by Argmax (MIT)
- **Audio:** AVAudioEngine (Apple native)
- **VAD:** Silero VAD (via WhisperKit)
- **Storage:** SwiftData
- **Distribution:** App Store + TestFlight
- **License:** MIT

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full details.

---

## 🎨 Design

[docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) — Colors, typography, components.

[docs/WIREFRAMES.md](docs/WIREFRAMES.md) — All 5 core screens (Home, Recording, Result, Settings, Onboarding).

---

## 🌍 Inspiration

VoiceFlow is heavily inspired by [Handy](https://handy.computer) — a free, open source, offline speech-to-text app for desktop. We're bringing that philosophy to mobile.

Other inspirations:
- [Whisperboard](https://github.com/Saik0s/Whisperboard) — iOS Whisper reference implementation
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) — The transcription engine
- Wispr Flow, WhisperFlow, Superwhisper — UX/UI patterns

---

## 🤝 Contributing

We welcome contributions! Whether it's code, design, documentation, or testing — see [CONTRIBUTING.md](CONTRIBUTING.md).

**Good first issues:** Check the [Issues](../../issues?q=is%3Aopen+label%3A%22good+first+issue%22) page.

---

## 📜 License

MIT © Marvin Schwab. See [LICENSE](LICENSE).

---

## 👤 Maintainer

**Marvin Schwab** ([@Marvin22222](https://github.com/Marvin22222))
- Discord: Marvin#0001
- Project Lead + Sole Maintainer (currently)

---

## ⭐ Star History

If VoiceFlow is useful to you, consider starring the repo — it helps others discover the project!

---

*Made with ❤️ in Bavaria, Germany. Whisper-flowing since 2026.*
