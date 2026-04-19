## Context

The current volunteer dashboard stores volunteer intent in `settings.volunteerAvailable` and directly uses that boolean to render the top-of-screen "在线 - 正在寻找附近需求" state. The dashboard then separately attempts to obtain a device location, report that location to `/api/volunteer/location`, and refresh `/api/orders/available`. Any failure in the location or reporting steps can leave the dashboard showing "online" while the backend still considers the volunteer unavailable for nearby intake.

At the same time, the volunteer map starts from a fixed Beijing camera position and does not recenter after a successful location fix. This makes it easy to confuse "map is not centered on me" with "location is definitely wrong", even though the more immediate product problem is that the app does not truthfully expose whether the volunteer has actually become intake-ready.

## Goals / Non-Goals

**Goals:**
- Represent volunteer intake readiness as explicit frontend state rather than inferring it from the persisted availability toggle.
- Make the volunteer dashboard communicate why nearby orders are unavailable when location acquisition or backend location reporting has not succeeded.
- Preserve the existing backend contract while sequencing volunteer intake state around the current location heartbeat flow.
- Reduce false debugging signals from the volunteer dashboard map.

**Non-Goals:**
- Changing backend matching, distance filtering, or order lifecycle endpoints.
- Replacing polling with push updates.
- Reworking the blind-side order creation flow.
- Building a full volunteer location diagnostics screen beyond what is needed for truthful dashboard status.

## Decisions

### Decision: Separate volunteer availability intent from intake readiness state

The persisted `volunteerAvailable` flag will remain the user's local preference, but the dashboard status and empty-state behavior will be driven by a new explicit readiness state owned by app state/controller logic.

This readiness state should minimally cover:
- `offline`: volunteer is not accepting work
- `connecting`: volunteer wants to accept work and the app is acquiring/reporting location
- `onlineReady`: location has been successfully reported and nearby intake can be trusted
- `locationUnavailable`: readiness failed because location was unavailable, denied, or timed out
- `reportFailed`: readiness failed because backend location reporting did not succeed

**Alternatives considered:**
- Keep using `volunteerAvailable` for UI status and only tweak copy. Rejected because it preserves the core false-positive state.
- Infer readiness from whether `/api/orders/available` returns an empty list. Rejected because an empty list can mean either "no nearby orders" or "not ready yet".

### Decision: Only mark the volunteer as truly online after a successful location report

The volunteer dashboard should transition to `connecting` when intake is enabled, attempt `locateOnce()`, then call `/api/volunteer/location`, and only after a successful report move to `onlineReady` and treat empty available-order results as meaningful.

**Alternatives considered:**
- Mark the volunteer ready immediately after local location acquisition. Rejected because backend intake still depends on `/api/volunteer/location`.
- Treat any dashboard entry with the toggle enabled as online-ready. Rejected because it is the source of the current bug.

### Decision: Surface readiness failures directly on the volunteer dashboard

The dashboard will reuse the existing error presentation pattern already used on settings and active-run pages so the volunteer can see why intake failed without navigating away. The empty-state copy will branch by readiness state:
- `onlineReady` + empty list: no nearby orders right now
- `connecting`: still preparing nearby intake
- `locationUnavailable`: location is required before nearby orders can load
- `reportFailed`: location was acquired but backend intake readiness could not be confirmed

**Alternatives considered:**
- Hide all errors behind logs only. Rejected because the current issue is specifically that testers cannot tell whether readiness failed.
- Show a single generic "refresh later" message for all empty states. Rejected because it does not distinguish no-orders from not-ready.

### Decision: Treat the volunteer map as supporting context, not the readiness source of truth

The map should not imply that its initial camera position represents confirmed volunteer location. The implementation may either recenter after the first successful location fix or keep the fixed initial view but add explicit explanatory copy. In both cases, readiness state must come from the new intake-state model, not from visual map position.

**Alternatives considered:**
- Leave the current fixed camera without explanation. Rejected because it amplifies debugging confusion.
- Block dashboard rendering until the map centers on the current location. Rejected because the map is not the only UI surface needed to explain readiness.

## Risks / Trade-offs

- [Additional controller state adds complexity] -> Keep the readiness model small and confine transitions to volunteer dashboard and location-report helpers.
- [Transient network/location failures may cause status flicker] -> Use stable state transitions and only downgrade readiness when the current attempt actually fails.
- [Map recenter behavior may vary by platform/plugin] -> Keep the requirement focused on removing misleading cues, not on a specific animation implementation.
- [Dashboard copy changes may expose backend/reporting failures more often] -> Prefer truthful messaging; this is necessary to debug intake issues and reduce false "no orders" reports.

## Migration Plan

1. Add the readiness state model to app state and controller logic.
2. Rework volunteer dashboard startup and heartbeat sequencing to update readiness state around locate/report attempts.
3. Update volunteer dashboard status, error, and empty-state rendering to use readiness state instead of `volunteerAvailable` directly.
4. Adjust map behavior or explanatory copy so the initial fixed camera no longer implies confirmed volunteer location.
5. Validate manual flows: permission denied, location timeout, report failure, successful readiness, and successful readiness with zero nearby orders.

Rollback can remove the new readiness state and restore the previous boolean-driven UI because backend endpoints and persisted availability settings remain unchanged.

## Open Questions

- Whether the volunteer map should actively recenter after the first successful fix or simply explain that the initial viewport is static.
- Whether the backend can return a more specific business error for stale or missing volunteer location that the dashboard should map separately from generic report failure.
