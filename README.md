## MouseRec 🖱️⌨️

**MouseRec** is a macOS app that lets you **record** your mouse moves / clicks / keystrokes and **replay** them automatically, with control over speed and number of repetitions.

This repository contains:
- the Xcode project (`MouseRec.xcodeproj`)
- the application source code (`MouseRec/`)
- the tests (`MouseRecTests/`, `MouseRecUITests/`)

---

## Features

- **Global recording**
  - Captures mouse moves, clicks, drags and keyboard events
  - Works even when the app is in the background (with proper permissions)

- **Automatic playback**
  - Replays the recorded sequence exactly as captured
  - Playback **speed control**: x1, x2, x3, x5
  - **Repeat modes**: once, infinite loop, custom number of repetitions

- **Global hotkeys**
  - `⌘⇧R` – start / stop recording
  - `⌘⇧P` – start / stop playback
  - Hotkey events are **not** recorded in the sequence (to avoid infinite loops)

- **Menu bar integration**
  - Menu bar icon with visual state:
    - 🐭 – idle
    - 🔴 – recording
    - 🟢 – playing
  - Can hide the main window and run only from the menu bar

---

## Requirements

- **macOS**: 11.0 or later
- **Xcode**: 15+ (ideally the version used for this repo)
- Apple Developer account if you want to sign / distribute the app

---

## Quick start

1. **Clone the repository**

```bash
git clone https://github.com/IndieFear/MouseRec.git
cd MouseRec/MouseRec
```

2. **Open the project in Xcode**

Open `MouseRec.xcodeproj` and select the `MouseRec` target.

3. **Configure capabilities (entitlements)**

See `CONFIGURATION.md` for full details. In short:
- In **Signing & Capabilities**, remove or disable **App Sandbox**
- Make sure `MouseRec.entitlements` is attached to the target

4. **Check `Info.plist`**

Make sure:
- **Info.plist File** points to `MouseRec/Info.plist`
- `ITSAppUsesNonExemptEncryption` is set to `NO` (if you only use system‑provided crypto)

5. **Run the app**

- Select your Mac as the run destination
- Press `Cmd + R`
- On first launch, macOS will ask for **Accessibility** permissions (see below)

---

## Accessibility permissions (required)

To record and replay global events, MouseRec must be allowed under:
**System Settings → Privacy & Security → Accessibility**.

The app automates the flow (see also `CONFIGURATION.md`):

1. On first launch, MouseRec posts a small `CGEvent`
2. This forces macOS to **add MouseRec to the Accessibility list**
3. The app calls `AXIsProcessTrustedWithOptions` with the prompt option
4. You will see:
   - a system popup asking for permissions
   - an in‑app alert with an **Open Settings** button
5. Click **Open Settings**:
   - System Settings opens on the Accessibility page
   - enable the checkbox for **MouseRec**
   - restart the app

Without these permissions:
- recording / playback will not work
- global hotkeys may be blocked

---

## Usage

### Record a sequence

1. Launch the app
2. Click **Record** or press `⌘⇧R`
3. Perform your mouse + keyboard actions
4. Click **Record** again or press `⌘⇧R` to stop  
   → the number of recorded events appears in the UI / menu bar.

### Configure playback

- **Speed**: choose x1, x2, x3 or x5
- **Repeat**:
  - `Once`: single run
  - `Loop`: infinite loop (manual stop required)
  - `Custom`: set a number of repetitions (1–99)

### Start playback

1. Ensure you have at least one recording
2. Click **Play** or press `⌘⇧P`
3. To stop: click again or press `⌘⇧P` once more

### Menu bar mode

- Click the button at the top right of the window to hide it
- The Dock icon disappears and only the menu bar icon remains
- From the menu bar icon, you can:
  - start / stop recording
  - start / stop playback
  - show the window again
  - quit the app

---

## Code architecture

**App side (Swift / SwiftUI):**

- `MouseRecApp.swift`  
  Application entry point (`@main`), sets up `AppDelegate` and `MenuBarManager`.

- `ContentView.swift`  
  Main SwiftUI interface:
  - Record / Play buttons
  - speed and repeat controls
  - integration with `MenuBarManager` and `HotkeyManager`

- `EventRecorder.swift`  
  Core logic:
  - creates a **CGEventTap** via `CFMachPort` to capture global events
  - stores events as `RecordedEvent`
  - playback timing / speed / looping
  - filters hotkeys (`⌘⇧R`, `⌘⇧P`) so they are not replayed

- `HotkeyManager.swift`  
  Manages global keyboard shortcuts (Carbon / EventHotKey‑style APIs) and calls back into `ContentView`.

- `MenuBarManager.swift`  
  Handles the menu bar icon:
  - creates the status item
  - updates menus and state (recording / playing / idle)
  - shows / hides the main window

- `Info.plist`  
  Permission descriptions (Accessibility, Apple Events if needed), app category, etc.

- `MouseRec.entitlements`  
  App capabilities (sandbox disabled to allow global event tap, etc.).

Tests live in:
- `MouseRecTests/`
- `MouseRecUITests/`

---

## Development & contributions

- **Run tests** (from Xcode):
  - `Cmd + U` on the `MouseRecTests` or `MouseRecUITests` target
- **Code style**:
  - Swift 5, SwiftUI for UI
  - Prefer explicit types and clear names
  - Avoid redundant comments; use comments to explain non‑obvious choices (e.g. `CFMachPort` lifecycle, event tap behavior, etc.)

If you want to contribute:

- Open an **issue** to discuss a feature / bug
- Fork the repo, create a branch (`feature/...` or `fix/...`)
- Open a **Pull Request** with a clear description

---

## Security & responsibility

MouseRec records and replays global events, which can include:
- potentially sensitive keystrokes
- clicks in other apps

Recommended usage:
- only on machines you control
- avoid sharing recordings that contain sensitive data
- review the code / binary before running it in production environments

---

## License

Personal project by **Stanislas Peridy**.  
Use at your own risk.  
You may clone and use the project for personal use or learning; for redistribution or commercial use, please open an issue or contact the author first.
