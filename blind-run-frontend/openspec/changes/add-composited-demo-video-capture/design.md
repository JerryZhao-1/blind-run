## Context

The repository already contains a strong demo showcase foundation: deterministic startup flags, curated volunteer and blind data, and a presentation-safe AMap configuration. That is enough to validate individual flows, but it is not enough to reliably produce a single polished review video. The current demo scenes are optimized for "open the app and show one role," not for "record multiple clips that can later be stitched into one believable two-sided story."

The main constraint is architectural, not visual. Volunteer and blind showcase runs do not live inside one shared runtime, so the final video cannot depend on real-time cross-device synchronization. The video pipeline therefore needs to treat the app as a clip source: boot into a deterministic capture checkpoint, record a bounded scene, then compose that clip with another separately recorded clip.

The local environment also matters. Xcode and native Apple media tools are available, but the simulator path is unreliable for AMap-heavy validation, and the machine does not currently have a repo-managed video compositor such as ffmpeg. The design should therefore prefer real-device-friendly capture plus a repository-owned macOS composition path that does not introduce a large external dependency.

## Goals / Non-Goals

**Goals:**
- Add deterministic capture checkpoints for both roles so recordings can start from specific moments in the story rather than only from the default demo home scenes.
- Keep blind-side and volunteer-side recordings narratively aligned through shared places, statuses, and timing assumptions.
- Provide a repeatable shot plan so anyone on the team can capture the same clip set without guessing the order or file names.
- Provide a local composition/export path that turns recorded clips into one side-by-side MP4 saved to the desktop.
- Preserve the current product illusion by keeping demo/capture controls out of the visible app UI.

**Non-Goals:**
- Building true cross-device live synchronization between the blind and volunteer demo apps.
- Replacing Xcode or QuickTime with a fully autonomous end-to-end media automation stack.
- Building a general-purpose video editor inside the repository.
- Changing normal login, backend integration, or non-demo production behavior.

## Decisions

### Decision: Model the deliverable as a sequence of capture checkpoints, not a single live session

The video should be produced from a defined set of short scenes such as `blind-request`, `blind-active`, `blind-review`, `volunteer-nearby`, `volunteer-enroute`, and `volunteer-complete`. Each scene will boot the app into one deterministic state so the recorder can capture a short, intentional segment without waiting for another app instance to mutate that state live.

This fits the real architecture. The current demo store is in-memory per process, so pretending the final video is one synchronized session would create fragile capture choreography and constant mismatch risk.

**Alternatives considered:**
- Force both roles to share one live simulated backend during recording. Rejected because it adds unnecessary runtime complexity just to create a video artifact.
- Record only the current default blind and volunteer entry scenes. Rejected because that does not cover a believable full narrative.

### Decision: Keep capture scene selection in startup configuration and out of visible product UI

Capture checkpoints should be selected through build-time or launch-time configuration, similar to the existing showcase switches, rather than through a visible in-app menu. That keeps recordings visually clean and avoids contaminating the product surface with tooling-specific controls.

**Alternatives considered:**
- Add an in-app "recording scene chooser." Rejected because it weakens the product illusion and invites accidental capture mistakes.
- Hard-code one global capture scene per branch. Rejected because video production needs multiple checkpoints, not one default state.

### Decision: Treat story alignment as shared seed data plus a shot manifest

The app-side capture scenes and the recording workflow should both point to the same small set of curated story anchors: place names, addresses, status labels, and recommended clip ordering. The code owns the data that appears on-screen; the shot manifest owns the order and timing in which those scenes are recorded.

That split keeps responsibilities clear:
- app code guarantees that each scene is visually correct and deterministic;
- the playbook guarantees that separately recorded scenes still form one coherent story when composed.

**Alternatives considered:**
- Let the operator freestyle place selection and recording order. Rejected because the final split-screen will drift and look fake.
- Encode the entire editorial sequence in app code. Rejected because recording order and export behavior are operational concerns, not UI concerns.

### Decision: Compose the final video with a repository-owned macOS exporter instead of relying on manual timeline assembly

Manual editing in iMovie can work once, but it is hard to repeat precisely. The repository should instead own a small local composition/export utility, likely using native macOS media frameworks, that takes a defined set of source clips and renders one side-by-side MP4 to the desktop.

This keeps the workflow reproducible without introducing a heavy external dependency that is not already present on the machine.

**Alternatives considered:**
- Require iMovie-only manual editing. Rejected because it is slow to repeat and hard to document at task-level precision.
- Depend on ffmpeg. Rejected because it is not currently available in the environment and would add setup overhead.

### Decision: Recording remains operator-driven, while naming and export become scripted

Launching scenes, interacting through the flow, and recording the raw clip should remain an operator action using Xcode and native recording tools. The brittle part of the process is not "press record," but "did we use the correct scene, clip name, and final composition settings." The workflow should therefore script the deterministic parts and document the human parts.

**Alternatives considered:**
- Full GUI automation for Xcode, recording, and editing. Rejected because it is too fragile for the immediate goal.
- Fully manual workflow with no scripts. Rejected because the final deliverable needs to be repeatable.

## Risks / Trade-offs

- [Capture scenes drift away from the real app story] -> Reuse the existing showcase repositories and seed structures instead of inventing a separate video-only state model.
- [Blind and volunteer clips look mismatched when composed] -> Centralize story anchors in shared demo seed data and require a shot manifest that maps clip pairs explicitly.
- [Real-device recording introduces timing or notification noise] -> Constrain the recording guide to a known device/network setup and keep each capture checkpoint short.
- [Native export utility becomes too ambitious] -> Limit composition scope to deterministic side-by-side layout, simple trimming/alignment, and a single desktop export target.
- [Too many capture checkpoints make recording tedious] -> Favor a small set of editorially useful scenes over exhaustive state coverage.

## Migration Plan

1. Extend the demo startup surface with capture-scene configuration that can boot specific volunteer and blind checkpoints.
2. Add or refine seeded demo data so the clip checkpoints share one believable story arc.
3. Add a shot manifest and recording guide to the repository, including source clip names and expected sequence.
4. Add a local composition/export utility that reads the captured clips and renders a final side-by-side MP4 to the desktop.
5. Validate the workflow by producing at least one fresh review-ready output from the current demo branch.

Rollback is simple: stop using the capture-scene flags and local video tooling. Normal app runtime and the existing demo showcase mode remain available.

## Open Questions

- What exact final canvas should the export target use: landscape 1920x1080, a taller review layout, or a phone-first vertical composition?
- Whether the final composition should include editorial labels such as `盲人端` / `志愿者端` outside the app viewport.
- Whether raw captured clips should stay under a gitignored local directory inside the repo or live entirely outside the repository.
