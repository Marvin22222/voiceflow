# 🎨 Design System

UI/UX guidelines for VoiceFlow.

---

## 🎯 Design Principles

1. **Minimal** — Every element earns its place
2. **Native** — Follow iOS conventions, don't reinvent
3. **Beautiful** — Modern aesthetic, attention to detail
4. **Fast** — Instant feedback, smooth animations
5. **Accessible** — Works for everyone (VoiceOver, Dynamic Type)

---

## 🌈 Color Palette

### Primary Colors

| Name | Hex | Usage |
|---|---|---|
| **Indigo (Primary)** | `#5B5FE6` | Buttons, highlights, brand |
| **Background Dark** | `#0A0A0F` | Main background (dark mode) |
| **Background Light** | `#FFFFFF` | Main background (light mode) |
| **Surface Dark** | `#1C1C1E` | Cards, sheets (dark mode) |
| **Surface Light** | `#F2F2F7` | Cards, sheets (light mode) |

### Accent Colors (User-Selectable)

| Name | Hex | Vibe |
|---|---|---|
| **Coral** | `#FF4D6D` | Bold, attention-grabbing |
| **Mint** | `#3DD68C` | Fresh, calming |
| **Amber** | `#FFB340` | Warm, friendly |
| **Sky** | `#4DA8FF` | Cool, trustworthy |

### Semantic Colors

| Name | Hex | Usage |
|---|---|---|
| **Success** | `#34C759` | Recording success, save confirmations |
| **Warning** | `#FF9500` | Low storage, model download warnings |
| **Error** | `#FF3B30` | Recording errors, permission denied |
| **Recording Red** | `#FF3B30` | Recording indicator (pulsing) |

### Text Colors

| Name | Dark Mode | Light Mode | Usage |
|---|---|---|---|
| **Primary** | `#FFFFFF` | `#000000` | Headlines, body text |
| **Secondary** | `#8E8E93` | `#3C3C43` | Subtitles, captions |
| **Tertiary** | `#48484A` | `#8E8E93` | Disabled, hints |

---

## ✍️ Typography

We use **SF Pro** (system font) for all text, following iOS HIG.

### Type Scale

| Style | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| **Large Title** | 34 pt | Bold | 41 pt | Onboarding titles |
| **Title 1** | 28 pt | Bold | 34 pt | Section titles |
| **Title 2** | 22 pt | Bold | 28 pt | Screen titles |
| **Title 3** | 20 pt | Semibold | 25 pt | Card titles |
| **Headline** | 17 pt | Semibold | 22 pt | Emphasized body |
| **Body** | 17 pt | Regular | 22 pt | Default text |
| **Callout** | 16 pt | Regular | 21 pt | Smaller body |
| **Subheadline** | 15 pt | Regular | 20 pt | Captions |
| **Footnote** | 13 pt | Regular | 18 pt | Tiny text |
| **Caption 1** | 12 pt | Regular | 16 pt | Labels |
| **Caption 2** | 11 pt | Regular | 13 pt | Smallest text |

### Special Cases

- **Recording Timer** — SF Pro Rounded, 48pt, tabular numbers
- **Transcribed Text Preview** — SF Pro, 17pt, monospaced for code-like display

---

## 📏 Spacing

8pt grid system.

| Token | Value | Usage |
|---|---|---|
| **xs** | 4 pt | Icon padding |
| **sm** | 8 pt | Inline spacing |
| **md** | 16 pt | Default spacing |
| **lg** | 24 pt | Section spacing |
| **xl** | 32 pt | Large gaps |
| **xxl** | 48 pt | Major sections |

### Safe Areas
- Always respect top safe area (notch/Dynamic Island)
- Always respect bottom safe area (home indicator)
- Tab bars: 49pt + bottom safe area

---

## 🔘 Components

### Buttons

#### Primary Button
- **Height:** 50 pt
- **Padding:** 16pt horizontal
- **Background:** Primary color (Indigo)
- **Text:** White, 17pt Semibold
- **Corner radius:** 12 pt
- **Shadow:** subtle drop shadow on press
- **Haptic:** `.medium` on tap

#### Secondary Button
- **Height:** 50 pt
- **Padding:** 16pt horizontal
- **Background:** Transparent
- **Border:** 1.5pt primary color
- **Text:** Primary color, 17pt Semibold
- **Corner radius:** 12 pt
- **Haptic:** `.light` on tap

#### Mic Button (Hero)
- **Diameter:** 200 pt (large state) / 140 pt (compact state)
- **Background:** Primary color
- **Icon:** Microphone SF Symbol, 64pt white
- **Pulse animation:** Concentric circles, 0.8s loop
- **Haptic:** `.medium` on press, `.success` on release
- **Scale:** 0.92 on press (visual feedback)

### Cards

- **Corner radius:** 16 pt
- **Padding:** 16 pt
- **Background:** Surface color
- **Shadow:** 0 4pt 12pt rgba(0,0,0,0.08)

### List Rows

- **Height:** 56 pt minimum
- **Padding:** 16 pt horizontal, 12 pt vertical
- **Separator:** 0.5pt, tertiary text color
- **Tap target:** Full row width

### Settings Toggles

- **iOS native Switch** component
- **Label:** Body text (17pt)
- **Haptic:** `.light` on toggle

### Sliders

- **iOS native Slider** component
- **Min track:** Primary color
- **Max track:** Tertiary text color
- **Thumb:** White with shadow

---

## 🎬 Animations

### Timing Curves

| Name | Curve | Usage |
|---|---|---|
| **Default** | `.easeInOut` | Most UI transitions |
| **Spring** | `.spring(response: 0.3, dampingFraction: 0.7)` | Bouncy elements |
| **Quick** | `.easeOut(duration: 0.15)` | Button presses |
| **Smooth** | `.easeInOut(duration: 0.25)` | Screen transitions |

### Specific Animations

#### Mic Button Pulse
```swift
// Concentric circles, 0.8s loop
withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
    pulseScale = 1.2
}
```

#### Recording Indicator (Red Dot)
```swift
// Pulsing red dot
withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
    opacity = 0.4
}
```

#### Text Type-out
```swift
// Live transcription appears with slight delay
.transition(.opacity.combined(with: .move(edge: .top)))
```

#### Model Switch
```swift
// Crossfade + slight scale
withAnimation(.easeInOut(duration: 0.3)) {
    selectedModel = newModel
}
```

---

## 🔊 Sound Design

We use **subtle haptics** instead of sounds (more iOS-native).

| Action | Haptic |
|---|---|
| Tap button | `.light` |
| Hold mic | `.medium` |
| Recording start | `.heavy` |
| Recording success | `.success` |
| Recording error | `.error` |
| Toggle setting | `.light` |
| Model download complete | `.success` |
| Insert text | `.soft` |

---

## 📱 Screen Sizes

Designed for iPhone first. We support:

| Device | Screen Size | Notes |
|---|---|---|
| iPhone SE (3rd gen) | 4.7" | Compact layout |
| iPhone 15 / 14 | 6.1" | Standard |
| iPhone 15 Pro Max / 16 Pro Max | 6.7" | Large, more content |
| iPad (10th gen) | 10.9" | Stretched layout, basic support |

**Min iOS:** 17.0

---

## ♿ Accessibility

### VoiceOver
- All buttons have descriptive labels
- Recording state announced clearly
- Transcribed text is readable as a single label
- Custom actions for: Start, Stop, Copy, Share

### Dynamic Type
- All text uses semantic styles (`.title`, `.body`, etc.)
- Layouts reflow gracefully up to `.accessibility5`

### Reduce Motion
- Pulse animations disabled when `UIAccessibility.isReduceMotionEnabled`
- Crossfade transitions instead

### High Contrast
- Colors meet WCAG AA contrast ratios
- Text remains readable in High Contrast mode

### Voice Control
- Buttons have voice control labels
- "Tap Mic" works as expected

---

## 🎨 Dark Mode

**Default theme is dark.** Light mode is opt-in.

Dark mode uses:
- Background: `#0A0A0F` (true black, OLED-friendly)
- Surfaces: `#1C1C1E` (iOS standard dark gray)
- Text: White / Off-white
- Accents: Slightly desaturated for less eye strain

---

## 🖼️ Iconography

We use **SF Symbols** (Apple's icon library) where possible.

| Icon | SF Symbol | Usage |
|---|---|---|
| Microphone | `mic.fill` | Mic button |
| Stop | `stop.fill` | Stop button |
| Copy | `doc.on.doc` | Copy button |
| Share | `square.and.arrow.up` | Share button |
| Settings | `gearshape.fill` | Settings button |
| Delete | `trash.fill` | Delete confirmation |
| Download | `arrow.down.circle.fill` | Model download |
| Check | `checkmark.circle.fill` | Success states |
| Warning | `exclamationmark.triangle.fill` | Warning states |
| Info | `info.circle.fill` | Info tooltips |

**App Icon:** Custom designed. Concept: Sound wave → text transformation.

---

## 📐 Layout Patterns

### Navigation
- **Root:** TabView with 3 tabs (Home, History, Settings)
- **Modals:** Sheet for onboarding, settings (from iPad)
- **Stack:** NavigationStack for History → Detail

### Home Screen Layout
- Vertical stack, centered
- Mic button in middle (60% of vertical space)
- Model selector at bottom

### Settings Screen Layout
- List-based (iOS native)
- Grouped by section (Model, Language, Trigger, Appearance, Advanced)

---

## 🎯 Component Library

We use a custom component library, but stay close to SwiftUI primitives.

**Custom Components:**
- `MicButton` — Hero record button
- `WaveformView` — Live audio waveform
- `TranscriptionCard` — Display transcribed text
- `ModelSelector` — Choose Whisper model
- `AccentColorPicker` — Pick app accent color
- `LanguagePicker` — Choose transcription language

**SwiftUI Primitives Used:**
- `Button`, `Toggle`, `Slider`, `Picker`, `Stepper`
- `List`, `Section`, `NavigationStack`
- `Sheet`, `Alert`, `ConfirmationDialog`
- `ActivityKit` for Live Activities

---

## 📚 References

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [iOS Design Inspiration — Mobbin](https://mobbin.com/ios)
- [iOS 18 Design Resources](https://developer.apple.com/design/resources/)

---

*Last updated: 2026-06-17*
