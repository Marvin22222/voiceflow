# 🛠️ Setup Guide

How to set up the VoiceFlow Xcode project from scratch on a Mac.

---

## 📋 Prerequisites

| Requirement | Min Version | Notes |
|---|---|---|
| **macOS** | Sonoma (14.0) | For Xcode 15 |
| **Xcode** | 15.0 | With iOS 17+ SDK |
| **Swift** | 5.9 | Ships with Xcode 15 |
| **Homebrew** | Latest | For installing XcodeGen |
| **XcodeGen** | Latest | For generating Xcode project |
| **Git** | 2.30+ | For cloning the repo |

---

## 🚀 Quick Start (5 minutes)

```bash
# 1. Clone the repo
git clone https://github.com/Marvin22222/voiceflow.git
cd voiceflow
git checkout dev   # work on dev branch

# 2. Install XcodeGen
brew install xcodegen

# 3. Generate the Xcode project
xcodegen generate

# 4. Open the project
open VoiceFlow.xcodeproj

# 5. Select the "VoiceFlow" scheme and an iPhone 15 simulator
# 6. Press ⌘R (Cmd+R) to build and run
```

That's it! The app should build and launch in the simulator.

---

## 📁 Project Structure

After running `xcodegen generate`, you'll have:

```
voiceflow/
├── VoiceFlow.xcodeproj/        ← Generated Xcode project
├── Sources/
│   ├── VoiceFlow/              ← Main app target
│   │   ├── App/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── Resources/
│   ├── VoiceFlowKeyboard/      ← Keyboard extension target
│   └── VoiceFlowShared/        ← Shared framework (App Group)
├── Tests/
│   ├── VoiceFlowTests/
│   ├── VoiceFlowSharedTests/
│   └── VoiceFlowUITests/
├── Resources/
│   └── Assets.xcassets/
├── docs/                       ← All documentation
├── project.yml                 ← XcodeGen config (source of truth)
├── Package.swift               ← SPM dependencies
├── .swiftlint.yml              ← Linting rules
└── .swiftformat                ← Formatting rules
```

---

## ⚙️ Apple Developer Setup

### For Local Development (No Paid Account Needed)

Xcode can build and run on simulators without a paid Apple Developer account. Skip to "Running" below.

### For Real Device Testing

1. Sign up for a free Apple Developer account at [developer.apple.com](https://developer.apple.com)
2. In Xcode: **VoiceFlow target → Signing & Capabilities → Team → Add your account**
3. Repeat for the **VoiceFlowKeyboard** target
4. The bundle IDs are pre-configured in `project.yml`:
   - Main app: `de.marvinschwab.voiceflow`
   - Keyboard: `de.marvinschwab.voiceflow.keyboard`

### For App Store Submission

You'll need a **paid Apple Developer account** ($99/year):
1. Enroll at [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/)
2. Set up App Store Connect
3. Update `project.yml` with your Team ID
4. Run `xcodegen generate` again

---

## 🏃 Running

### iOS Simulator

1. Open `VoiceFlow.xcodeproj`
2. Select scheme: **VoiceFlow**
3. Select destination: **iPhone 15 Pro** (or any iOS 17+ simulator)
4. Press **⌘R** (or click the Play button)

### Real Device

1. Connect your iPhone via USB
2. Trust the Mac on the iPhone
3. Select your iPhone as the destination in Xcode
4. Press **⌘R**
5. On the iPhone: Settings → General → VPN & Device Management → Trust your developer cert

### Keyboard Extension

To test the keyboard:
1. Run the app once to install it
2. iOS Settings → General → Keyboard → Keyboards → Add New Keyboard…
3. Select **VoiceFlow Keyboard**
4. Tap and hold the 🌐 globe icon in any text field → select VoiceFlow

---

## 🧪 Testing

### Run All Tests

```bash
# From command line
xcodebuild test \
  -project VoiceFlow.xcodeproj \
  -scheme VoiceFlow \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or in Xcode
⌘U
```

### Test Coverage

```bash
# Generate coverage report
xcodebuild test \
  -project VoiceFlow.xcodeproj \
  -scheme VoiceFlow \
  -enableCodeCoverage YES \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## 🎨 Linting & Formatting

### SwiftLint

```bash
# Install
brew install swiftlint

# Run on all files
swiftlint

# Auto-fix what's possible
swiftlint --fix
```

### SwiftFormat

```bash
# Install
brew install swiftformat

# Format all files
swiftformat .

# Check without modifying
swiftformat --lint .
```

### Pre-Commit Hook (Recommended)

```bash
# Install git hook
cp scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Now `git commit` will automatically run SwiftLint + SwiftFormat
```

---

## 🔄 Regenerating the Xcode Project

Whenever you change `project.yml` or add new files:

```bash
xcodegen generate
```

Then re-open `VoiceFlow.xcodeproj`.

**Tip:** Add this to your shell:

```bash
# ~/.zshrc or ~/.bash_profile
alias xregen="xcodegen generate && echo '✅ Project regenerated'"
```

---

## 🐛 Troubleshooting

### "Xcode project out of sync"

```bash
# Regenerate
xcodegen generate

# In Xcode: File → Close Workspace, then reopen
```

### "WhisperKit not found"

Make sure `Package.swift` is being picked up:
1. In Xcode: File → Add Package Dependencies…
2. Confirm `https://github.com/argmaxinc/WhisperKit` is listed
3. Version: 0.7.0 or later

### "App Group not configured"

1. Open `VoiceFlow.xcodeproj`
2. Select **VoiceFlow** target → **Signing & Capabilities**
3. Click **+ Capability** → **App Groups**
4. Add: `group.de.marvinschwab.voiceflow`
5. Repeat for **VoiceFlowKeyboard** target

### "Microphone permission denied"

1. iOS Settings → Privacy & Security → Microphone
2. Enable for VoiceFlow
3. Restart the app

### "Keyboard not appearing"

1. iOS Settings → General → Keyboard → Keyboards
2. Make sure VoiceFlow is listed
3. If yes: Tap VoiceFlow → Allow Full Access (required for App Group sharing)

---

## 🔄 Updating Dependencies

```bash
# Open Package.swift in Xcode
open Package.swift

# Update the version in dependencies array:
#   .package(url: "...", from: "0.7.0")
# Then in Xcode: File → Packages → Update to Latest Versions
```

---

## 📚 Useful Commands

```bash
# List all schemes
xcodebuild -list -project VoiceFlow.xcodeproj

# Clean build folder
xcodebuild clean -project VoiceFlow.xcodeproj

# Show build settings
xcodebuild -showBuildSettings -project VoiceFlow.xcodeproj

# Archive for App Store
xcodebuild archive \
  -project VoiceFlow.xcodeproj \
  -scheme VoiceFlow \
  -archivePath ./build/VoiceFlow.xcarchive
```

---

## 🆘 Getting Help

- 📖 [docs/CODING_CONVENTIONS.md](docs/CODING_CONVENTIONS.md) — How we write Swift
- 🏗️ [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — How the code is organized
- 🧠 [docs/MODEL_REGISTRY.md](docs/MODEL_REGISTRY.md) — Multi-model architecture
- 🗺️ [docs/ROADMAP.md](docs/ROADMAP.md) — Where we're headed
- 💬 [GitHub Issues](https://github.com/Marvin22222/voiceflow/issues) — Ask questions

---

*Last updated: 2026-06-17*
