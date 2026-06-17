# Contributing to VoiceFlow

🎉 Thanks for your interest in contributing! VoiceFlow is a community-driven project and we welcome contributions of all kinds.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guide](#style-guide)
- [Commit Messages](#commit-messages)

---

## 📜 Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code. Please report unacceptable behavior to the maintainers.

---

## 🚀 Getting Started

1. **Star the repo** ⭐ — helps others discover the project
2. **Check the [Issues](../../issues)** — find something to work on
3. **Join discussions** — share ideas, ask questions
4. **Read the docs** — especially [ARCHITECTURE.md](docs/ARCHITECTURE.md) and [DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)

### Good First Issues

Look for issues labeled `good first issue` — these are beginner-friendly tasks.

---

## 💡 How to Contribute

### 🐛 Bug Reports
- Use the [Bug Report](../../issues/new?template=bug_report.md) template
- Include iOS version, device model, app version, and reproduction steps
- Attach logs/screenshots if possible

### ✨ Feature Requests
- Use the [Feature Request](../../issues/new?template=feature_request.md) template
- Describe the use case, not just the solution
- Check existing issues first to avoid duplicates

### 💻 Code Contributions
- Fork the repo
- Create a feature branch (`feature/your-feature`)
- Make your changes
- Add tests if applicable
- Submit a Pull Request

### 📝 Documentation
- Fix typos, clarify unclear sections
- Add examples
- Translate to other languages (German, French, etc.)

### 🎨 Design Contributions
- Propose UI/UX improvements
- Mockup screens (Figma, Sketch, ASCII)
- Suggest color/typography changes

### 🌍 Translations
- Help translate the app UI
- Add Whisper model support for new languages

---

## 🛠️ Development Setup

### Prerequisites

- **macOS 14+** (Sonoma or later)
- **Xcode 15+** with iOS 17+ SDK
- **Swift 5.9+**
- **Apple Developer Account** (free tier is fine for local dev, paid for App Store)
- **iPhone 15 Pro or later** (for Action Button testing — older devices work for everything else)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/Marvin22222/voiceflow.git
cd voiceflow

# 2. Open in Xcode (when project is ready)
open VoiceFlow.xcodeproj

# 3. Build & Run on simulator
# Select scheme → iPhone 15 Pro → ⌘R
```

### Project Structure (planned)

```
voiceflow/
├── VoiceFlow/                  # Main app target
│   ├── App/                    # App entry, lifecycle
│   ├── Views/                  # SwiftUI views
│   ├── Models/                 # Data models (SwiftData)
│   ├── Services/               # Audio, Transcription, Settings
│   └── Resources/              # Assets, strings, models
├── VoiceFlowKeyboard/          # Keyboard extension
├── VoiceFlowShared/            # Shared code (App Group)
└── docs/                       # Documentation
```

### Running Tests

```bash
swift test
# or in Xcode: ⌘U
```

---

## 🔄 Pull Request Process

1. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes**:
   - Follow the [Style Guide](#style-guide)
   - Add tests if applicable
   - Update docs if needed

3. **Commit your changes**:
   - Use [Conventional Commits](#commit-messages)
   - Keep commits focused and atomic

4. **Push and open a PR**:
   ```bash
   git push origin feature/my-feature
   ```
   - Use the [PR template](../../pulls)
   - Link related issues (`Fixes #123`)
   - Add screenshots/videos for UI changes

5. **Wait for review** — the maintainer will review within a few days

6. **Address feedback** — push new commits to your branch

7. **Merge** — once approved, the maintainer will merge

---

## 🎨 Style Guide

### Swift

- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use SwiftLint (config in `.swiftlint.yml` when added)
- 4-space indentation
- Line length: 120 chars max
- Use meaningful names (`userName`, not `un`)
- Prefer composition over inheritance
- Document public APIs with `///` doc comments

### SwiftUI

- Use `@State`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject` appropriately
- Keep views small and composable
- Use `@ViewBuilder` for complex view hierarchies
- Follow Apple's [SwiftUI Style Guide](https://developer.apple.com/documentation/swiftui)

### Documentation

- Use Markdown for `.md` files
- Use ASCII wireframes for UI mockups (or link to Figma)
- Document architecture decisions in [docs/DECISION_LOG.md](docs/DECISION_LOG.md)

---

## 📝 Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat` — New feature
- `fix` — Bug fix
- `docs` — Documentation only
- `style` — Code style (formatting, no logic change)
- `refactor` — Code refactoring (no feature/bug change)
- `perf` — Performance improvement
- `test` — Adding tests
- `chore` — Build/CI/tooling changes

### Examples

```bash
git commit -m "feat(recording): add hold-to-talk button with haptic feedback"
git commit -m "fix(keyboard): resolve text insertion in third-party apps"
git commit -m "docs(readme): add screenshots section"
git commit -m "refactor(audio): extract AVAudioEngine setup into service"
```

---

## ❓ Questions?

- Open a [Question](../../issues/new?template=question.md) issue
- Check existing [Discussions](../../discussions)
- Reach out to the maintainer (see [README.md](README.md))

---

## 🏆 Recognition

Contributors will be:
- Added to the README contributors section
- Credited in the App Store listing (for significant contributions)
- Eligible for GitHub Sponsors (if/when set up)

---

Thank you for making VoiceFlow better! 🎤✨
