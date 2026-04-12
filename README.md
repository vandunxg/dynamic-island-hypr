# Dynamic Island Standalone (Hyprland + Quickshell)

This repository now includes a **fully standalone Dynamic Island profile** that can run independently from the legacy top bar.

It is designed so users with older Quickshell setups (no Dynamic Island module/integration yet) can install and run it quickly.

## Highlights

- Standalone `PanelWindow` for Dynamic Island (not tied to `iiBar` hover/auto-hide).
- Dedicated shell profile: `shell.dynamic-island.qml`.
- One-command bootstrap script for install + run.
- IPC control target: `dynamicIslandStandalone`.
- Docs included for integration and publishing.

---

## One-command install and run (recommended)

From this repo root (`~/.config/quickshell/ii`):

```bash
bash ./scripts/dynamic-island/bootstrap-standalone.sh --autostart
```

This script is intended for users whose old Quickshell config has no Dynamic Island setup.

### What the bootstrap script does

1. Installs a self-contained config to:
   - `~/.config/quickshell/dynamic-island-standalone`
2. Sets entrypoint to standalone profile (`shell.qml` -> `shell.dynamic-island.qml`).
3. Ensures Dynamic Island config keys exist in:
   - `~/.config/illogical-impulse/config.json`
4. Optionally appends Hyprland autostart line (`--autostart`).
5. Starts Quickshell immediately (unless `--no-run`).

### Script options

```bash
./scripts/dynamic-island/bootstrap-standalone.sh --help
```

Common options:

- `--autostart`: add `exec-once` into `~/.config/hypr/hyprland.conf`
- `--no-run`: install only, do not launch now
- `--config-name <name>`: custom config name under `~/.config/quickshell/`
- `--target-dir <path>`: install to a specific absolute directory

---

## Manual run commands

Run the standalone profile directly:

```bash
quickshell -p ~/.config/quickshell/dynamic-island-standalone/shell.qml
```

Or run directly from this repo:

```bash
quickshell -p ~/.config/quickshell/ii/shell.dynamic-island.qml
```

---

## Hyprland autostart

Add this line to `~/.config/hypr/hyprland.conf`:

```ini
exec-once = quickshell -p ~/.config/quickshell/dynamic-island-standalone/shell.qml
```

Then reload:

```bash
hyprctl reload
```

---

## systemd --user auto-restart service

A user service unit is included at:

- `systemd/user/dynamic-island-standalone.service` (repo template)
- `~/.config/systemd/user/dynamic-island-standalone.service` (installed locally)

It runs Dynamic Island through:

- `scripts/dynamic-island/run-standalone.sh`

Enable and start it:

```bash
cp ~/.config/quickshell/ii/systemd/user/dynamic-island-standalone.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now dynamic-island-standalone.service
```

Check status/logs:

```bash
systemctl --user status dynamic-island-standalone.service
journalctl --user -u dynamic-island-standalone.service -f
```

Disable it:

```bash
systemctl --user disable --now dynamic-island-standalone.service
```

Notes:

- Service is configured with `Restart=on-failure` to recover from crashes.
- If Wayland env vars are missing, the runner script attempts `wayland-1` then `wayland-0` automatically.

---

## IPC controls

```bash
qs ipc call dynamicIslandStandalone toggle
qs ipc call dynamicIslandStandalone open
qs ipc call dynamicIslandStandalone close
qs ipc call dynamicIslandStandalone status
```

Suggested Hyprland keybinds:

```ini
bind = SUPER, I, exec, qs ipc call dynamicIslandStandalone toggle
bind = SUPER SHIFT, I, exec, qs ipc call dynamicIslandStandalone open
bind = SUPER CTRL, I, exec, qs ipc call dynamicIslandStandalone close
```

---

## File map

- Standalone scope:
  - `modules/ii/dynamicIslandStandalone/DynamicIslandStandalone.qml`
- Standalone host window:
  - `modules/ii/bar/dynamicIsland/StandaloneDynamicIslandHost.qml`
- Dynamic Island core:
  - `modules/ii/bar/dynamicIsland/**`
- Standalone shell profile:
  - `shell.dynamic-island.qml`
- Bootstrap installer:
  - `scripts/dynamic-island/bootstrap-standalone.sh`

---

## Requirements

- Hyprland
- Quickshell (Wayland + Hyprland support)
- Qt6 Wayland stack

Optional tools for file convert flow:

- `magick` or `convert`
- `pdftoppm`
- `ffmpeg`
- `zip`, `unzip`, `bsdtar`
- `libreoffice` (for office -> pdf)

---

## Troubleshooting

### Dynamic Island does not appear

- Check status:

```bash
qs ipc call dynamicIslandStandalone status
```

- Ensure `bar.dynamicIsland.enabled` is `true` in `~/.config/illogical-impulse/config.json`.
- Ensure monitor filters do not exclude your display (`bar.screenList`, `preferredMonitor`).

### Shell fails to load

Run verbose and inspect the first root cause:

```bash
quickshell -vv -p ~/.config/quickshell/dynamic-island-standalone/shell.qml
```

### Convert flow reports failed

Check dependencies:

```bash
for c in magick convert pdftoppm ffmpeg zip unzip bsdtar libreoffice; do command -v "$c" >/dev/null 2>&1 && echo "$c: ok" || echo "$c: missing"; done
```

---

## Publishing notes

If you plan to publish this on GitHub, push from:

- `~/.config/quickshell/ii`

Recommended include list:

- `README.md`
- `shell.dynamic-island.qml`
- `shell.qml`
- `GlobalStates.qml`
- `modules/ii/dynamicIslandStandalone/**`
- `modules/ii/bar/dynamicIsland/**`
- `services/FileTray.qml`
- `docs/dynamic-island-standalone/**`
- `docs/dynamic-feature-naming.md`

Do not include runtime logs/cache from `/run/user/...`.
