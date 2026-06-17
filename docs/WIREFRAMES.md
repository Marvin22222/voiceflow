# 📱 Wireframes

ASCII wireframes for all core screens. For Figma mockups, see [design/](design/) (coming soon).

---

## 1️⃣ Home Screen

The default landing screen. Big mic button, model selector, settings access.

```
┌──────────────────────────────────────┐
│                              ⚙️      │  ← Settings (top-right)
│                                      │
│                                      │
│                                      │
│           VoiceFlow                  │  ← App name (Title 2)
│   Tip & Speak, Release & Done        │  ← Subtitle (Subheadline, secondary)
│                                      │
│                                      │
│                                      │
│                                      │
│         ╭─────────────╮              │
│         │             │              │
│         │     🎤      │              │  ← Hero Mic Button
│         │             │              │     (200x200 pt, pulsing)
│         │             │              │     Primary color background
│         ╰─────────────╯              │
│                                      │
│         Press and hold               │  ← Hint (Footnote, secondary)
│                                      │
│                                      │
│                                      │
│                                      │
│  ⚡ Tiny  ◉ Base  🧠 Small           │  ← Model Selector (Segmented)
│  Fast  ◉ Balanced  Best              │  ← Active model description
│                                      │
└──────────────────────────────────────┘
```

**States:**
- **Idle:** Mic button at 100% scale, no animation
- **Pressed:** Mic button at 92% scale, haptic feedback
- **Recording:** Pulsing red border, "Recording..." text

---

## 2️⃣ Recording Screen

Active recording state. Live waveform, partial transcription, stop button.

```
┌──────────────────────────────────────┐
│                              ⚙️      │
│                                      │
│                                      │
│         ●  Recording...              │  ← Pulsing red dot + label
│                                      │
│                                      │
│                                      │
│      ╭───────────────────────╮       │
│      │                       │       │
│      │  ▁▃▆█▆▃▁▃▆█▆▃▁▃▆█   │       │  ← Live Waveform
│      │                       │       │     (60pt high, animated)
│      │                       │       │     Real-time amplitude bars
│      ╰───────────────────────╯       │
│                                      │
│                                      │
│                                      │
│         "Hallo, ich bin"             │  ← Live Partial Transcription
│                                      │     (Body, fades in/out as updates)
│                                      │
│                                      │
│                                      │
│                                      │
│         ╭─────────────╮              │
│         │     ⏹️       │              │  ← Stop Button (red, smaller)
│         ╰─────────────╯              │
│                                      │
│         Release to insert            │  ← Hint
│                                      │
│                                      │
│  00:08                                │  ← Recording duration (caption)
│                                      │
└──────────────────────────────────────┘
```

**States:**
- **Active:** Pulsing dot, live waveform animating
- **Processing:** Waveform freezes, "Transcribing..." text
- **Done:** Cross-fade to Result Screen

---

## 3️⃣ Result Screen

Transcribed text displayed. User can edit, copy, share, or insert.

```
┌──────────────────────────────────────┐
│                          ✕ Close     │  ← Close (top-right)
│                                      │
│                                      │
│           ✓ Transcribed              │  ← Success state
│                                      │
│                                      │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  │  Hallo, ich bin Marvin und     │  │  ← Editable Text Field
│  │  das ist eine Sprachnachricht  │  │     (multiline, monospace)
│  │  an dich Marvis.               │  │     Auto-focus for editing
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
│     📋 Copy        📤 Share          │  ← Action buttons (icon + label)
│                                      │
│                                      │
│       ╭───────────────────╮          │
│       │   ⏎ Insert →     │          │  ← Insert button (primary)
│       ╰───────────────────╯          │     Only shown if keyboard-triggered
│                                      │
│                                      │
└──────────────────────────────────────┘
```

**Actions:**
- **Copy:** Copies to clipboard, shows toast "Copied!"
- **Share:** iOS native share sheet
- **Insert:** Sends text to App Group, returns to source app
- **Edit:** Tap text field, modify content
- **Close:** Returns to Home Screen

---

## 4️⃣ Settings Screen

App configuration. List-based layout (iOS native).

```
┌──────────────────────────────────────┐
│  ← Back      Settings                │
│──────────────────────────────────────│
│                                      │
│  MODEL                               │
│  ┌────────────────────────────────┐  │
│  │ ⚡ Tiny (39 MB)            →   │  │  ← Model row
│  │   Fast, lower accuracy         │  │
│  ├────────────────────────────────┤  │
│  │ ◉ Base (74 MB)             →   │  │  ← Selected (checkmark)
│  │   Balanced (recommended)       │  │
│  ├────────────────────────────────┤  │
│  │ 🧠 Small (244 MB)          →   │  │
│  │   Best accuracy, slower        │  │
│  └────────────────────────────────┘  │
│                                      │
│  LANGUAGE                            │
│  ┌────────────────────────────────┐  │
│  │ Auto-detect             →   ✓ │  │  ← Current selection
│  ├────────────────────────────────┤  │
│  │ Deutsch (German)          →   │  │
│  ├────────────────────────────────┤  │
│  │ English                  →   │  │
│  ├────────────────────────────────┤  │
│  │ Français (French)        →   │  │
│  └────────────────────────────────┘  │
│                                      │
│  TRIGGER                             │
│  ┌────────────────────────────────┐  │
│  │ Hold to talk         [✓ ON  ] │  │
│  ├────────────────────────────────┤  │
│  │ Tap to toggle        [ OFF  ] │  │
│  ├────────────────────────────────┤  │
│  │ Keyboard Mic-Button  [✓ ON  ] │  │
│  ├────────────────────────────────┤  │
│  │ Action Button         [✓ ON  ] │  │
│  └────────────────────────────────┘  │
│                                      │
│  APPEARANCE                          │
│  ┌────────────────────────────────┐  │
│  │ Theme      ◉ Dark ○ Light ○ Auto│ │
│  ├────────────────────────────────┤  │
│  │ Accent     ◉ Indigo ○ Coral ○ ...│
│  └────────────────────────────────┘  │
│                                      │
│  ADVANCED                            │
│  ┌────────────────────────────────┐  │
│  │ Custom Vocabulary         →   │  │
│  ├────────────────────────────────┤  │
│  │ Auto-punctuation     [✓ ON  ] │  │
│  ├────────────────────────────────┤  │
│  │ Auto-capitalize       [✓ ON  ] │  │
│  ├────────────────────────────────┤  │
│  │ Storage Used           74 MB  │  │
│  ├────────────────────────────────┤  │
│  │ Clear Transcriptions      →   │  │
│  ├────────────────────────────────┤  │
│  │ About VoiceFlow         →   │  │
│  └────────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
```

**Sections:**
1. **Model** — Choose Whisper model size
2. **Language** — Transcription language
3. **Trigger** — How to activate recording
4. **Appearance** — Theme + accent color
5. **Advanced** — Power-user options

---

## 5️⃣ Onboarding Screen

First-launch experience. 5 screens introducing VoiceFlow.

### Screen 5.1: Welcome

```
┌──────────────────────────────────────┐
│                                      │
│                                      │
│                                      │
│          Welcome to                  │
│         VoiceFlow ✨                 │  ← Large Title
│                                      │
│                                      │
│   Voice-to-text, 100% local.         │  ← Subtitle
│   No subscriptions. No cloud.        │
│                                      │
│                                      │
│                                      │
│   ┌────────────────────────────┐    │
│   │                            │    │
│   │      [Animated GIF]        │    │  ← Animated demo
│   │      Press → Speak → Text  │    │     (loops)
│   │                            │    │
│   └────────────────────────────┘    │
│                                      │
│                                      │
│                                      │
│                                      │
│   ⚡ Privacy first                   │  ← Feature pills
│   🆓 Free forever                    │
│   🧠 On-device AI                    │
│                                      │
│                                      │
│                                      │
│                                      │
│      ╭─────────────────────╮         │
│      │  Get Started    →    │         │  ← Primary button
│      ╰─────────────────────╯         │
│                                      │
│                                      │
└──────────────────────────────────────┘
```

### Screen 5.2: Choose Model

```
┌──────────────────────────────────────┐
│  Step 1 of 3                         │  ← Progress indicator
│  ───────                             │
│                                      │
│  Choose your model                   │  ← Title 1
│                                      │
│  You can change this anytime in      │
│  Settings.                           │
│                                      │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ ⚡ Tiny                         │  │
│  │ 39 MB · Real-time · Lower acc. │  │  ← Model option
│  │                  [Select →]    │  │
│  ├────────────────────────────────┤  │
│  │ ◉ Base  (Recommended)           │  │
│  │ 74 MB · Real-time · Good acc.  │  │
│  │                  [Selected ✓]  │  │
│  ├────────────────────────────────┤  │
│  │ 🧠 Small                        │  │
│  │ 244 MB · Slower · Best acc.   │  │
│  │                  [Select →]    │  │
│  └────────────────────────────────┘  │
│                                      │
│  Models are downloaded once, then    │
│  cached for offline use.             │
│                                      │
│                                      │
│      ╭─────────────────────╮         │
│      │  Continue     →     │         │
│      ╰─────────────────────╯         │
│                                      │
└──────────────────────────────────────┘
```

### Screen 5.3: Permissions

```
┌──────────────────────────────────────┐
│  Step 2 of 3                         │
│  ──────────                          │
│                                      │
│  Permission needed                   │
│                                      │
│                                      │
│                                      │
│                                      │
│         ╭───────────╮               │
│         │    🎤     │               │  ← Mic icon
│         ╰───────────╯               │
│                                      │
│                                      │
│      Allow microphone access         │  ← Title 2
│                                      │
│                                      │
│   We need the microphone to capture  │
│   your voice. Audio is processed     │
│   100% on-device and never leaves    │
│   your phone.                        │
│                                      │
│                                      │
│      ╭─────────────────────╮         │
│      │  Allow Microphone   │         │  ← Triggers iOS permission
│      ╰─────────────────────╯         │
│                                      │
│                                      │
└──────────────────────────────────────┘
```

### Screen 5.4: Keyboard Setup (Optional)

```
┌──────────────────────────────────────┐
│  Step 3 of 3                         │
│  ─────────────                      │
│                                      │
│  Enable Keyboard (Optional)          │
│                                      │
│                                      │
│  Use VoiceFlow in any app:           │
│                                      │
│  1. Open Settings app                │  ← Numbered steps
│  2. Go to General → Keyboard         │
│  3. Tap Keyboards → Add New...       │
│  4. Select "VoiceFlow"               │
│                                      │
│                                      │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  │    [Settings app screenshot]   │  │  ← Visual aid
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
│                                      │
│                                      │
│      ╭─────────────────────╮         │
│      │  Skip for Now         │       │
│      ╰─────────────────────╯         │
│                                      │
│      ╭─────────────────────╮         │
│      │  Open Settings        │       │
│      ╰─────────────────────╯         │
│                                      │
└──────────────────────────────────────┘
```

---

## 📐 Design Tokens (SwiftUI)

```swift
// Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// Colors
enum AppColors {
    static let primary = Color(hex: "#5B5FE6")
    static let backgroundDark = Color(hex: "#0A0A0F")
    static let backgroundLight = Color.white
    static let surfaceDark = Color(hex: "#1C1C1E")
    static let surfaceLight = Color(hex: "#F2F2F7")
    static let recordingRed = Color(hex: "#FF3B30")
    static let success = Color(hex: "#34C759")
    // ...
}

// Typography
enum AppFonts {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let body = Font.system(size: 17, weight: .regular)
    // ...
}
```

---

## 🎯 Next Steps

1. Create Figma mockups based on these wireframes
2. Build component library in SwiftUI
3. Implement screens incrementally
4. User testing with 5 beta testers
5. Iterate based on feedback

---

*Last updated: 2026-06-17*
