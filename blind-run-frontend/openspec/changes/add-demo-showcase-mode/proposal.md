## Why

The first pass of demo showcase mode solved stability, but it still looks visibly like a demo: the app shows a showcase launcher, a demo badge, and fallback map placeholders instead of believable real map visuals. That is good enough for internal debugging, but not good enough for a polished presentation or recording.

We now need the presentation branch to look and feel like the real product while still staying deterministic. That means replacing fake-looking map fallbacks with curated real AMap scenes, removing visible demo-only UI cues, and fixing the volunteer nearby-demand visual bug that currently shows up as a tiny black mark in the menu area.

## What Changes

- Refine the existing demo showcase path into a presentation-realistic mode that still seeds curated blind and volunteer scenarios without requiring live backend success.
- Keep simulation at the provider- and repository-level, but remove visible in-app cues that expose the branch as a demo.
- Replace fake-looking map fallback scenes with curated real AMap rendering based on fixed, presentation-safe coordinates and deterministic location input.
- Change startup flow so the presentation scenario is selected outside the visible product UI instead of through an in-app launcher page.
- Fix the volunteer nearby-demand menu rendering bug that currently shows as a small black mark and breaks visual polish.
- Keep real integration mode unchanged so backend-fix work can continue separately from the presentation branch.

## Capabilities

### New Capabilities
- `demo-showcase-mode`: Boot the app into deterministic simulated presentation scenarios without requiring live backend success.

### Modified Capabilities
- `auth-session`: Allow presentation mode to seed a prepared authenticated session and role instead of requiring live SMS verification and backend session restoration, without exposing demo-only setup UI in the visible product flow.
- `blind-order-flow`: Allow demo mode to present curated blind request and active-order flows from simulated repositories.
- `volunteer-order-flow`: Allow demo mode to present curated volunteer nearby-order, accept, and active-order flows from simulated repositories.
- `profile-sync`: Allow demo mode to surface curated blind and volunteer profile data without live backend profile dependencies.
- `map-experience`: Allow presentation mode to render deterministic but real-looking AMap scenes from curated fixed points instead of placeholder fallback visuals.

## Impact

- Affected code: `lib/main.dart`, `lib/app/providers.dart`, `lib/app/state/app_state_controller.dart`, routing/bootstrap flow, auth/session state, volunteer/blind repositories, profile repositories, location services, and map configuration/widgets.
- Affected systems: login/bootstrap flow, role routing, volunteer and blind order surfaces, profile/settings surfaces, map/location surfaces, and presentation-only scenario seeding.
- Affected dependencies: provider overrides, app-owned demo repositories/services, real AMap configuration on the presentation environment, and deterministic fixed-point scenario data.
- Backend impact: none required for the presentation path; real backend integration remains unchanged and isolated from this change.
