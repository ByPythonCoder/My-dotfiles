# Quickshell Hyprland Bar

> **Note:** Screenshots coming soon.

A modular, feature-rich status bar for [Hyprland](https://hypr.land/), built with [Quickshell](https://quickshell.org/docs/v0.3.0/guide/install-setup/) — a Qt Quick / QML desktop shell framework.

## Features

**Two layout styles** — switch layouts with a single keybind via `./switch-layout.sh`:

| Layout | Description |
|--------|-------------|
| **Bar** (`shell-bar.qml`) | Traditional full-width single strip, anchored to the top |
| **Pills** (`shell-pills.qml`) | Floating pill capsules — a left capsule (logo + workspaces + media) and a right capsule (clock + stats + audio + battery + network) |

**8 modular widgets:**

| Widget | File | Description |
|--------|------|-------------|
| Workspaces | `modules/Workspaces.qml` | Hyprland workspace switcher with dot indicators, scroll-to-switch |
| Clock | `modules/Clock.qml` | Time/date display, tap for calendar OSD, long-press cycles formats |
| Media | `modules/Media.qml` | MPRIS media player pill with auto-hide, opens full player OSD |
| SysStats | `modules/SysStats.qml` | CPU sparkline + RAM usage + uptime from `/proc` |
| Volume | `modules/Volume.qml` | Pipewire volume control, scroll-to-adjust, tap-to-mute |
| Brightness | `modules/Brightness.qml` | Backlight control via `brightnessctl`, scroll-to-adjust |
| Battery | `modules/Battery.qml` | Battery level + time remaining, low-battery pulse animation |
| Network | `modules/Network.qml` | WiFi SSID + signal strength via `nmcli` |

**Popup dialogs and panels:**

| Dialog | File | Description |
|--------|------|-------------|
| Network | `popups/NetworkPopup.qml` | WiFi network list with scan, connect, disconnect |
| WiFi Connect | `popups/WifiConnectDialog.qml` | Password entry dialog for secured networks |
| Bluetooth | `popups/BtDevicePopup.qml` | Bluetooth device scanning and pairing |
| Media | `popups/MediaPopup.qml` | Full media player with album art and scrubbing |
| Audio | `popups/AudioPopup.qml` | Volume slider with per-app audio device list |
| Calendar | `OSD/CalendarOSD.qml` | Interactive month calendar |
| Power Menu | `popups/PowerMenu.qml` | Suspend/reboot/shutdown controls |
| Workspace Overview | `popups/WorkspaceOverview.qml` | Hyprland workspace grid overview |

**Reusable components:**

| Component | File | Description |
|-----------|------|-------------|
| GlassPanel | `components/GlassPanel.qml` | Frosted-glass panel with radius, border, and content slot |
| PopupManager | `components/PopupManager.qml` | Popup lifecycle and placement controller |
| PillButton | `components/PillButton.qml` | Styled pill-shaped button |
| AudioDeviceRow | `components/AudioDeviceRow.qml` | Per-audio-device row with icon, name, port selector |
| MediaPlayerContent | `components/MediaPlayerContent.qml` | Shared MPRIS player layout |

**Popup panels** — anchored pill popups in `OSD/` and full dialogs in `popups/`:

- AudioPopup, MediaPopup, NetworkPopup — interactive panels with scrolled lists
- WifiConnectDialog — password entry overlay for secured networks (embedded inside NetworkPopup)
- BtDevicePopup — Bluetooth scanning and pairing list
- PowerMenu — suspend/reboot/shutdown controls
- WorkspaceOverview — multi-monitor workspace grid
- VolumeOSD, BrightnessOSD — auto-dismiss sliders (1.4–1.6s)
- NetworkOSD — auto-dismiss status (2.2s)
- BatteryOSD — hover-toggle detail panel
- CalendarOSD — interactive month calendar
- MediaOSD — full player with album art, scrubbing, prev/play-pause/next
- StatPill — reusable CPU/RAM mini progress bar component

## Layout Switcher

The layout is switched at runtime via `switch-layout.sh`. The mechanism uses two simple pieces of state:

1. **`shell.qml`** is a **symlink** — it points to either `shell-pills.qml` or `shell-bar.qml`
2. **`.layout`** is a plain text file containing the current layout name (`pills` or `bar`)

When you run `switch-layout.sh`:

1. Kills any running `quickshell` process
2. Reads `.layout` to find the current layout
3. Flips the state (bar → pills, pills → bar) and writes it back
4. Updates `shell.qml` to point to the new layout file
5. Relaunches quickshell with `-c ~/.config/quickshell`

This makes it trivial to bind to a keybind in the hyprland.lua:

```
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/quickshell/switch-layout.sh"))
```

and for the depricated hyperland.conf

```
bind = $mod, B, exec, ~/.config/quickshell/switch-layout.sh
```


## Dependencies

| Runtime | Purpose |
|---------|---------|
| [quickshell](https://quickshell.org/docs/v0.3.0/guide/install-setup/) | QML shell framework |
| [Hyprland](https://hypr.land/) | Wayland compositor |
| Pipewire + wireplumber | Audio backend |
| NetworkManager (`nmcli`) | WiFi scanning |
| `brightnessctl` | Backlight control |
| Linux `/sys`, `/proc` | Battery, backlight, CPU/RAM/uptime |

## Tested On

- Arch Linux
- [Hyprland](https://hypr.land/)
- [Quickshell](https://quickshell.org/docs/v0.3.0/guide/install-setup/)
- Pipewire + WirePlumber
- NetworkManager

## Installation

```bash
# Clone into your quickshell config directory
git clone https://github.com/HappyGreenTurtle/quickshell-config ~/.config/quickshell

# Launch
quickshell -c ~/.config/quickshell/shell.qml
```

> **Tip:** Add to your Hyprland config (`~/.config/hypr/hyprland.conf`):
> ```
> exec-once = quickshell -c ~/.config/quickshell/shell.qml
> ```

## Switching Layouts

Toggle between bar and pill layouts on the fly:

```bash
~/.config/quickshell/switch-layout.sh
```

This kills the running quickshell process, updates the `shell.qml` symlink, and relaunches.

## Theme

All colors, spacing, animation durations, and device paths are centralized in [`Theme.qml`](Theme.qml). Use the singleton in any component:

```qml
Theme { id: theme }
color: theme.archBlue
```

Key design tokens:

- **Arch Linux palette** — blues and cyans (`#1793d1`, `#00b4d8`)
- **Dark surfaces** — layered backgrounds (`#0d1117` → `#161b22`)
- **320ms OutCubic** — consistent animation curve across all transitions
- **Monospace font** — swap to "JetBrains Mono" in `Theme.qml:88`

## Project Structure

```
~/.config/quickshell/
├── shell.qml              # Entry point (symlink → shell-pills.qml or shell-bar.qml)
├── shell-bar.qml          # Traditional full-width bar layout
├── shell-pills.qml        # Floating pill-cluster layout
├── Theme.qml              # Design tokens (colors, sizing, animations)
├── switch-layout.sh       # Layout toggle script
├── .layout                # Current layout state
├── components/
│   ├── GlassPanel.qml     # Frosted-glass panel with radius, border, content slot
│   ├── PopupManager.qml   # Popup lifecycle and placement controller
│   ├── PillButton.qml     # Styled pill-shaped button
│   ├── AudioDeviceRow.qml # Per-audio-device row with port selector
│   └── MediaPlayerContent.qml  # Shared MPRIS player layout
├── modules/
│   ├── BarSep.qml         # Thin vertical separator
│   ├── Battery.qml        # Battery status widget
│   ├── Brightness.qml     # Backlight control widget
│   ├── Clock.qml          # Time/date display
│   ├── Media.qml          # MPRIS media player pill
│   ├── Network.qml        # WiFi status widget
│   ├── SysStats.qml       # CPU/RAM/uptime monitor
│   ├── Volume.qml         # Pipewire volume widget
│   └── Workspaces.qml     # Hyprland workspace switcher
├── OSD/
│   ├── BatteryOSD.qml     # Battery detail popup
│   ├── BrightnessOSD.qml  # Brightness OSD popup
│   ├── CalendarOSD.qml    # Interactive calendar popup
│   ├── MediaOSD.qml       # Full media player OSD
│   ├── NetworkOSD.qml     # Network detail popup
│   ├── StatPill.qml       # Reusable stat pill component
│   └── VolumeOSD.qml      # Volume slider OSD popup
├── popups/
│   ├── NetworkPopup.qml   # WiFi network list with scan/connect/disconnect
│   ├── NetworkRow.qml     # Single network row in the list
│   ├── WifiConnectDialog.qml  # Password entry overlay for secured networks
│   ├── AudioPopup.qml     # Volume + per-app audio device list
│   ├── BtDevicePopup.qml  # Bluetooth device scanning and pairing
│   ├── BtDeviceRow.qml    # Single Bluetooth device row
│   ├── MediaPopup.qml     # Full media player popup
│   ├── PowerMenu.qml      # Suspend/reboot/shutdown controls
│   ├── QuickControls.qml  # Quick toggle controls panel
│   ├── QuickToggle.qml    # Single toggle switch component
│   └── WorkspaceOverview.qml  # Workspace grid overview
```

## Why?

I wanted a bar that could switch between a traditional full-width layout and a more minimal floating pill design without maintaining separate Quickshell configurations.

The project focuses on:
- modular widgets
- smooth animations (320ms OutCubic)
- clean QML architecture
- easy customization via [`Theme.qml`](Theme.qml)

## Roadmap

- [ ] Workspace previews
- [x] Bluetooth widget
- [ ] Server Uptime widget
- [ ] Weather widget
- [ ] Runtime layout switching without restart
- [ ] Multi-monitor support improvements

## About

This is my first Quickshell project and an ongoing experiment in building desktop UI with QML and Hyprland.

## License

Licensed under the MIT License.
