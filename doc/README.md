# PinWindow

Keep any macOS window always on top using ScreenCaptureKit mirroring.

## How It Works

PinWindow creates a live pixel-perfect mirror of the target window in a floating overlay panel owned by the app. The overlay sits above all other windows and passes all mouse events through to the real window underneath.

```
┌─────────────────────────────────┐
│  Target Window (real, behind)   │  ← receives all mouse/keyboard input
├─────────────────────────────────┤
│  Mirror Panel (floating overlay)│  ← ignoresMouseEvents = true
│  SCStream capture @ 60fps       │     NSPanel.level = .floating
│  AXObserver syncs position      │     collectionBehavior: allSpaces
└─────────────────────────────────┘
```

This approach works on modern macOS (13+) because it doesn't try to modify another app's window level — it mirrors the window into a panel we own.

## Usage

### Menu Bar App (recommended)

```bash
./build.sh          # build & launch
```

- **Option+P** — Pin the frontmost window
- **Option+U** — Unpin the last pinned window
- 📌 menu bar icon for quick access

### CLI

```bash
./build.sh list              # list all visible windows
./build.sh list Chrome       # filter by app name
./build.sh pin Wyze          # pin an app's window (keeps running)
./build.sh unpin Wyze        # unpin
```

## Requirements

- **macOS 13 (Ventura)** or later
- **Screen Recording** permission — for ScreenCaptureKit window capture
- **Accessibility** permission — for AXObserver window tracking

Grant both in **System Settings → Privacy & Security**.

## Building

### Development (ad-hoc signed)

```bash
./build.sh
```

### Distribution DMG

```bash
./package.sh
# produces: dist/PinWindow-1.0.dmg
```

### Notarized release (requires Developer ID)

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARIZE_PROFILE="your-keychain-profile" \
./package.sh
```

## Architecture

```
pin.swift (single-file app)
├── CaptureManager      — SCStream wrapper, 60fps capture
├── MirrorPanel         — NSPanel overlay + AXObserver sync
├── PinManager          — pin/unpin state, window discovery
├── AppDelegate         — menu bar, CLI dispatch, permissions
└── Hotkey handler      — Carbon RegisterEventHotKey
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for API details and compatibility analysis.
