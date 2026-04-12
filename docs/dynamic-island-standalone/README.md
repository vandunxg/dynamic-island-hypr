# Dynamic Island Standalone

This profile separates Dynamic Island from the old top bar so it can run as an independent panel and be shared more easily.

## What this gives you

- Dynamic Island runs in its own `PanelWindow` (no dependency on `iiBar` visibility/hover state).
- Existing bar can stay disabled.
- Compatible with the current Dynamic Island feature set (media, control center, file tray, convert flow, overview integration).
- Dedicated IPC target: `dynamicIslandStandalone`.

## Runtime requirements

- Quickshell with Hyprland layer shell support.
- Existing `ii` core modules/services available (`qs.modules.common`, `qs.services`).
- Config file: `~/.config/illogical-impulse/config.json`.

## Quick start (standalone shell profile)

One-command bootstrap (install + run now):

```bash
bash ~/.config/quickshell/ii/scripts/dynamic-island/bootstrap-standalone.sh --autostart
```

Manual run only Dynamic Island:

```bash
quickshell -p ~/.config/quickshell/default/shell.dynamic-island.qml
```

Alternative path if you run the `ii` tree directly:

```bash
quickshell -p ~/.config/quickshell/ii/shell.dynamic-island.qml
```

## Quick start (integrated into normal shell)

The main shell now includes a new panel loader id: `iiDynamicIslandStandalone`.

1. Open config file:
   - `~/.config/illogical-impulse/config.json`
2. In `enabledPanels`:
   - add `"iiDynamicIslandStandalone"`
   - remove `"iiBar"` if you want only Dynamic Island
3. Keep Dynamic Island enabled:
   - `bar.dynamicIsland.enabled = true`
4. Reload Quickshell.

## IPC controls

```bash
qs ipc call dynamicIslandStandalone toggle
qs ipc call dynamicIslandStandalone open
qs ipc call dynamicIslandStandalone close
qs ipc call dynamicIslandStandalone status
```

## Behavior notes

- The standalone panel respects `bar.dynamicIsland` settings (size, animation, monitor preference, etc.).
- It does not depend on the old bar auto-hide logic.
- It still respects lock state (`GlobalStates.screenLocked`).

## File map

- Standalone scope loader:
  - `modules/ii/dynamicIslandStandalone/DynamicIslandStandalone.qml`
- Standalone host window:
  - `modules/ii/bar/dynamicIsland/StandaloneDynamicIslandHost.qml`
- Dedicated shell profile:
  - `shell.dynamic-island.qml`

## Troubleshooting

- If nothing appears:
  - verify `bar.dynamicIsland.enabled` is `true`
  - verify `dynamicIslandStandalone` is open (`qs ipc call dynamicIslandStandalone status`)
  - verify selected monitor is allowed by your config (`bar.screenList`, `preferredMonitor`)
- If both old bar and standalone appear:
  - remove `iiBar` from `enabledPanels`
- If shell fails to load:
  - run `quickshell -vv` and check the first `Type ... unavailable` cause.
