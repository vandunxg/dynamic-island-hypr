# Dynamic Feature Naming Standard

Use this file as the single source of truth for naming Dynamic Island features.

## 1) Naming format

- Canonical ID: `DI.<Group>.<Feature>[.<SubFeature>]`
- Short code: `DI-<GROUP>-<SHORT>`
- Use Canonical ID in docs/specs.
- Use Short code in chat, issue title, commit prefix, and quick status updates.
- UI text can change, Canonical ID must stay stable.

## 2) Hard rules

- One feature = one Canonical ID.
- Do not reuse an existing ID for a different behavior.
- `DI.File.DragPicker` is not the same as `DI.CC.Page.FileTray`.
- If behavior changes but purpose is same, keep the same ID.
- If purpose changes, create a new ID and mark old one deprecated.

## 3) Core registry

### Core states

| Canonical ID | Short code | Meaning |
| --- | --- | --- |
| `DI.Core.State.Idle` | `DI-CORE-IDLE` | Default resting capsule |
| `DI.Core.State.ControlCenter` | `DI-CORE-CC` | Control center state |
| `DI.Core.State.Notification` | `DI-CORE-NOTI` | Notification capsule state |
| `DI.Core.State.ExpandedMedia` | `DI-CORE-EXP` | Expanded media state |

### Control center pages

| Canonical ID | Short code | Meaning |
| --- | --- | --- |
| `DI.CC.Page.FileTray` | `DI-CC-FILE` | File tray page in control center |
| `DI.CC.Page.Weather` | `DI-CC-WEATHER` | Weather/time page |
| `DI.CC.Page.System` | `DI-CC-SYSTEM` | System/performance page |

### File flow

| Canonical ID | Short code | Meaning |
| --- | --- | --- |
| `DI.File.DragPicker` | `DI-FILE-PICKER` | Picker shown while dragging file over Dynamic Island |
| `DI.File.DropTarget.Tray` | `DI-FILE-TARGET-TRAY` | Left drop zone, save file into tray |
| `DI.File.DropTarget.Convert` | `DI-FILE-TARGET-CONVERT` | Right drop zone, convert file flow |
| `DI.File.Tray.List` | `DI-FILE-LIST` | File chips/list view in tray page |
| `DI.File.Tray.DragOutRemove` | `DI-FILE-DRAGOUT` | Remove file after drag-out |
| `DI.File.Tray.ClearAll` | `DI-FILE-CLEAR` | Clear all files action |
| `DI.File.Convert.Pipeline` | `DI-FILE-CONVERT` | Conversion backend process |
| `DI.File.Convert.OutputDir` | `DI-FILE-OUTDIR` | Conversion output directory |

## 4) Reporting template

Use this format for bug report or QA note:

```text
[DI-FILE-PICKER]
actual: <what is happening>
expect: <what should happen>
steps: <step 1> -> <step 2> -> <step 3>
```

Examples:

```text
[DI-FILE-PICKER] actual: weather flashes when cancel drag
expect: only picker fades out, no other feature visible
```

```text
[DI-FILE-TARGET-CONVERT] actual: wrong target highlight near center split
expect: 50/50 split, stable highlight
```

## 5) Change policy

- Add new row when a new feature is introduced.
- Never silently rename existing Canonical IDs.
- If rename is required, keep old ID in a deprecated section for one release cycle.
- Keep this file updated in the same PR that changes behavior.
