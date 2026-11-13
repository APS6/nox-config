# Overhead Desk Rig & Noctalia Controller

A high-performance, seamless overhead desk phone controller built for Arch Linux / CachyOS (Niri Wayland compositor, Noctalia shell v5, PipeWire, and Scrcpy).

Mounted overhead: **Samsung Galaxy F22** (Android 13) connected via USB (preferred) or Wi-Fi (`192.168.1.8:5555`).

---

## 1. System Architecture

```
                      ┌──────────────────────────────────────────────┐
                      │    Overhead Samsung Galaxy F22 (Android 13)   │
                      │       Mounted Overhead • 180° Inverted       │
                      └──────────────────────┬───────────────────────┘
                                             │ ADB (USB / TCP:5555)
                      ┌──────────────────────┴───────────────────────┐
                      │           scrcpy 5.0.1 (Hardware Engine)      │
                      └──────┬──────────────────────┬─────────────┬──┘
                             │                      │             │
                    H.264 / Camera2               Audio          V4L2
                             │                      │             │
            ┌────────────────┴───────────┐          │      ┌──────┴──────────────┐
            │  Live 1080p Viewfinder     │          │      │  Virtual Webcam     │
            │  • Normal Tiled Window     │          │      │  • /dev/video9      │
            │  • 180° Orientation        │          │      │  • Headless (0 win) │
            │  • Bottom-Docked HUD       │          │      │  • Meet / Zoom / OBS│
            └──────────────┬─────────────┘          │      └─────────────────────┘
                           │                        │
            ┌──────────────┴─────────────┐   ┌──────┴──────────────────────┐
            │ Interactive Scanner HUD    │   │  PipeWire Dictation Routing │
            │ • Space: Snap Page         │   │  • PhoneMicSink (Null-sink) │
            │ • Enter: Multi-page PDF    │   │  • OverheadPhoneMic         │
            │ • Auto-Crop & Gamma 1.30   │   │  • Superwhisper & Hex sync  │
            │ • Systemd-run isolated     │   │  • Zero music interruptions │
            └────────────────────────────┘   └─────────────────────────────┘
```

---

## 2. Top Bar Widget & Indicator Color Guide

The widget sits on your Noctalia top bar (`📱 100%`) and automatically refreshes every **1.5 seconds** (or instantly when buttons in the panel are clicked):

| Indicator | Color | Hex Code | Meaning |
| :--- | :--- | :--- | :--- |
| **Offline Dot** | Red | `#f38ba8` | Phone disconnected from both USB and Wi-Fi |
| **Phone Mic Dot** | Peach / Orange | `#fab387` | Phone mic active for dictation (music will **not** pause) |
| **Torch Dot / Glyph** | Yellow | `#f9e2af` | Flashlight / Torch active |
| **Viewfinder Dot** | Soft Blue | `#89b4fa` | Desk camera preview is open |
| **Webcam Dot** | Cyan | `#89dceb` | Virtual webcam streaming to `/dev/video9` |
| **Recording Badge** | Red Box | `#f38ba8` | `REC` (1080p Video recording in progress) |
| **Voice Memo Badge**| Red Box | `#f38ba8` | `MIC` (Headless AAC voice memo recording) |

### Multi-Modality Display
When multiple features are running at once (e.g. **Phone Mic** + **Flashlight**):
* The phone outline glows **Yellow** (`#f9e2af`).
* Multi-colored indicator dots render side-by-side (`🟠 🟡`).
* The tooltip displays the full composite status:
  `Overhead Phone: 100% (USB) • Phone Mic Active • Torch ON`

---

## 3. Features & Usage Guide

### 📄 Document & Notebook Scanner
* **How to open:** Click **Scan Notebook** in the dropdown or run `phone-rig scan`.
* **Docked HUD:** Opens an isolated `phone-rig-hud.service` docked neatly at the screen bottom (never floating over your center workspace).
* **Controls:**
  * <kbd>Space</kbd>: Snap the current notebook page. The engine automatically analyzes column and row luminance profiles (>105 threshold) against the desk mat, crops the paper bounds, and applies a **1.30 gamma curve** (identical to `~/learning`).
  * <kbd>Space</kbd> (Again): Adds subsequent pages to the current session (Page 2, Page 3...).
  * <kbd>Enter</kbd>: Compiles all pages into a clean PDF in `~/Pictures/Scans/` and copies the file directly to your clipboard (`wl-copy`).
  * <kbd>t</kbd>: Toggle the physical flashlight on/off seamlessly.
  * <kbd>Esc</kbd> / <kbd>q</kbd> / **✕ Close**: Closes the scanner and turns off the camera preview.

### 🎙️ Dictation Microphone Switching
* **Phone Mic ON:** 
  * Audio from the overhead phone is streamed directly into PipeWire's `OverheadPhoneMic`.
  * Hex and Superwhisper are configured to `do_nothing` on recording.
  * **Your music keeps playing in high-fidelity stereo AAC (`a2dp-sink`) on your headphones while you dictate.**
* **Headphones Mic (Turning Phone Mic OFF):**
  * Automatically detects and selects your Bluetooth headphones (`bluez_input.B0:38:E2:68:29:25` — soundcore Q20i) as the default input.
  * Falls back to the built-in laptop mic only if your headphones are disconnected.
  * Restores Hex to pause music when dictating through headphones.

### 🎥 Virtual Headless Webcam
* **How to toggle:** Click **Virtual Webcam** in the dropdown or run `phone-rig webcam`.
* **Zero Windows:** Uses `--no-window` instead of `--no-playback`, eliminating the 256×256 Android icon window.
* **Audio-Safe:** Does not restart WirePlumber or BlueZ. Your music and Bluetooth headphones remain on high-fidelity `a2dp-sink` AAC throughout.
* **Compatible Apps:** `/dev/video9` is registered as `"Overhead Desk Cam (V4L2)"` and can be selected directly in Google Meet, Zoom, Zen browser, Chrome, Brave, and OBS.

### 💡 Camera Torch / Flashlight
* **While Camera Viewfinder is Open:** Injects exact physical keysym shortcuts (`Alt_L + t` for ON, `Shift_L + Alt_L + t` for OFF) into Scrcpy's Camera2 engine. The flashlight turns on/off instantly without crashing or freezing the video stream.
* **While Idle:** Toggles the flashlight tile via Android Quick Settings.

### 🎧 Audio & Dictation Recovery
* If Bluetooth audio ever gets trapped in the low-quality mono headset profile (`headset-head-unit` / mSBC) after external disconnects:
  * Click **Reset Audio** in the panel or run `phone-rig fix-audio`.
  * Re-authenticates BlueZ transport, locks `a2dp-sink` AAC, cleans up orphan null-sinks, and restarts `hex.service`.

---

## 4. CLI Quick Reference

```bash
phone-rig status            # Human-readable status (battery, mic, camera, torch)
phone-rig status --json     # Ultra-fast (~75ms) JSON status for Noctalia
phone-rig cam               # Toggle live 1080p camera preview
phone-rig scan              # Launch bottom-docked notebook scanner HUD
phone-rig mic [on|off]      # Toggle between Phone Mic and Headphones Mic
phone-rig torch [on|off]    # Toggle physical flashlight
phone-rig webcam [on|off]   # Toggle virtual webcam stream on /dev/video9
phone-rig record            # Record 1080p MP4 to ~/Videos/desk_recordings/
phone-rig voice             # Record headless AAC memo to ~/Audio/
phone-rig fix-audio         # Restore Bluetooth A2DP AAC & Hex dictation
phone-rig connect           # Force reconnection over USB or Wi-Fi
```
