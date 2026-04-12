# Integration and Publish Guide

This document explains how to integrate Dynamic Island Standalone into another setup and how to publish it cleanly.

## 1) Integration into an existing `ii` shell

### Required shell import

In `shell.qml` ensure this import exists:

```qml
import qs.modules.ii.dynamicIslandStandalone
```

### Required loader entry

Add (or keep) this loader:

```qml
PanelLoader { identifier: "iiDynamicIslandStandalone"; component: DynamicIslandStandalone {} }
```

### Enable panel in config

Update `~/.config/illogical-impulse/config.json`:

- Add `iiDynamicIslandStandalone` to `enabledPanels`.
- Remove `iiBar` if you want Dynamic Island only.

Example:

```json
{
  "enabledPanels": [
    "iiDynamicIslandStandalone",
    "iiBackground",
    "iiOverlay",
    "iiPolkit"
  ]
}
```

## 2) Run as dedicated profile

Use the standalone profile file:

```bash
quickshell -p ~/.config/quickshell/default/shell.dynamic-island.qml
```

This launches only Dynamic Island (+ reload popup).

## 3) Minimal files to publish

If target users already use this `ii` framework, publish these files:

- `modules/ii/dynamicIslandStandalone/DynamicIslandStandalone.qml`
- `modules/ii/bar/dynamicIsland/StandaloneDynamicIslandHost.qml`
- `modules/ii/bar/dynamicIsland/**` (current Dynamic Island implementation)
- `shell.dynamic-island.qml`
- `GlobalStates.qml` (contains `dynamicIslandStandaloneOpen` state)

## 4) Cross-repo integration checklist

When integrating into another Quickshell repo:

1. Ensure these singletons/services exist or are adapted:
   - `Config`, `GlobalStates`, `Appearance`
   - `Audio`, `Battery`, `Brightness`, `Weather`, `ResourceUsage`, `Notifications`, `HyprlandData`
2. Ensure icon assets used by Dynamic Island are present:
   - `assets/icons/lucide-*.svg`
3. Ensure weather/system/media dependencies are available in target distro.
4. Verify layer shell setup:
   - `WlrLayershell.layer = Top`
   - keyboard focus set to OnDemand only when needed.

## 5) Suggested publish structure

```text
dynamic-island-standalone/
  shell.dynamic-island.qml
  modules/ii/dynamicIslandStandalone/DynamicIslandStandalone.qml
  modules/ii/bar/dynamicIsland/...
  docs/
    README.md
    INTEGRATION.md
```

## 6) Validation commands

```bash
qmllint modules/ii/dynamicIslandStandalone/DynamicIslandStandalone.qml
qmllint modules/ii/bar/dynamicIsland/StandaloneDynamicIslandHost.qml
quickshell -p ~/.config/quickshell/default/shell.dynamic-island.qml
```

## 7) Recommended UX defaults

- Keep only one active container at a time:
  - old bar **or** standalone Dynamic Island.
- Expose IPC in docs for quick support:
  - `dynamicIslandStandalone open/close/toggle/status`.
- Keep Dynamic Island naming standard in sync:
  - `docs/dynamic-feature-naming.md`.
