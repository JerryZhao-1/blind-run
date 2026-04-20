## Why

The current demo showcase branch is stable enough to present volunteer and blind flows separately, but it still does not provide a reliable way to produce a single reviewable video that shows both sides of the story together. Right now the presenter has to improvise with separate runs, loosely matched scenes, and manual editing decisions, which makes the output inconsistent and hard to reuse for external evaluation.

We need a repeatable demo-video workflow that treats the final deliverable as a first-class artifact: deterministic capture scenes, a shot plan that keeps both sides visually coherent, and a local composition/export path that can produce one polished side-by-side video on the desktop without pretending the two apps are truly live-synced.

## What Changes

- Add hidden capture-oriented startup scenes for volunteer and blind showcase runs so recordings can start from specific story checkpoints instead of only from the default demo entry scenes.
- Align curated places, statuses, and timeline checkpoints across the volunteer and blind demo stories so separately recorded clips can be composed into one believable narrative.
- Add a repo-owned demo video playbook that defines the required clips, recording order, file naming, timing expectations, and final reviewable story arc.
- Add a local composition/export workflow that combines the recorded blind and volunteer clips into a single side-by-side video and exports it to the desktop.
- Keep normal product mode and the existing showcase mode intact unless an explicit capture configuration is selected.

## Capabilities

### New Capabilities
- `demo-video-production`: Provide deterministic capture scenes and a repeatable local workflow for recording, composing, and exporting a side-by-side blind-and-volunteer demo video.

### Modified Capabilities
- None.

## Impact

- Affected code: `lib/demo/`, startup configuration parsing, app bootstrap/provider overrides, and any scene-selection glue needed for capture presets.
- Affected local tooling: repository documentation, local capture helpers/scripts, and composition/export utilities for generating a final MP4 on macOS.
- Affected systems: Xcode launch configuration, device/simulator capture workflow, curated demo-story data, and the local desktop export path.
- User impact: presenters gain a repeatable way to generate a polished evaluation video without relying on real-time cross-device synchronization.
