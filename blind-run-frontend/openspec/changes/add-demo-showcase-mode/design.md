## Context

The current Flutter application is organized around Riverpod providers, repository abstractions, and an app-state bootstrap that restores persisted auth session state, validates that session against the backend, then refreshes role-specific data. This architecture is a good fit for live integration work, but it means demos are only as stable as the weakest live dependency: SMS login, backend role/bootstrap, order APIs, location reporting, and native map readiness.

The first demo-showcase implementation already introduced app-owned seeded state and a separate startup path, so the branch is now stable enough to rehearse. The remaining problem is presentation fidelity: the app still visibly announces itself as demo mode, and map screens no longer look like the real product because they intentionally fall back away from AMap. The volunteer nearby-demand area also has a rendering defect that draws attention during demos.

The next iteration should keep the deterministic seeded backend behavior, but visually converge on the real app. The target is a presentation branch that opens straight into a prepared scenario, renders believable real map content using curated fixed points, and removes any UI that breaks the illusion unless it is strictly needed outside the product surface.

## Goals / Non-Goals

**Goals:**
- Introduce a deterministic demo showcase mode that can present the intended blind and volunteer flows without requiring live backend success.
- Centralize simulation at the provider/repository/service layer instead of introducing feature-by-feature `if demo` logic.
- Make app startup deterministic in demo mode by bypassing live login/bootstrap blockers.
- Keep demo data internally consistent across auth, profile, order, and location surfaces so state transitions still look believable during presentation.
- Render map/location surfaces with real AMap visuals from curated fixed coordinates instead of placeholder fallback UI.
- Remove visible demo-only cues from the product UI so screenshots and recordings look like the real app.
- Fix the volunteer nearby-demand menu rendering bug that currently produces a tiny black artifact.

**Non-Goals:**
- Fixing the live backend integration issues covered by the existing volunteer changes.
- Creating a permanent offline-first product mode.
- Importing `test/test_doubles.dart` directly into app runtime code.
- Mixing live and simulated repositories in a single showcase session.
- Building a full internal admin or scenario authoring tool in this change.
- Building a generic hidden debug console for switching scenarios at runtime.

## Decisions

### Decision: Demo mode is an explicit startup mode, not a runtime fallback

The app will decide at startup whether it is running in normal integration mode or demo showcase mode. Demo mode will be selected through a dedicated runtime/build-time switch appropriate for the presentation branch, and the app will install a complete demo dependency graph from the root `ProviderScope`.

This avoids the failure-prone pattern of "try the live backend first, then quietly fall back to fake data." The current controller logic often refreshes multiple repositories together and assumes shared truth across them. Partial fallback would create contradictory state between auth, profile, and order flows.

**Alternatives considered:**
- Fallback to fake repositories only after live requests fail. Rejected because it would mix incompatible state sources inside the same controller flow.
- Add page-level demo booleans to short-circuit individual screens. Rejected because it would spread presentation logic across the UI and leave shared controller/bootstrap logic live.

### Decision: Use app-owned demo repositories and services under `lib/demo/`, derived from current test-double patterns

The showcase path will create runtime-safe demo implementations for auth, orders, profiles, settings/session helpers where needed, and location services. These implementations can borrow behavior and seeded data patterns from `test/test_doubles.dart`, but they will live in app-owned modules so the app does not depend on test-only code.

This keeps the architecture aligned with the existing provider boundaries and makes the demo mode understandable to future contributors.

**Alternatives considered:**
- Import test doubles directly into the app. Rejected because test helpers are not a stable runtime contract.
- Write one monolithic fake app-state controller. Rejected because it would bypass the existing architecture and make demo behavior diverge too far from the real app.

### Decision: Share a single in-memory showcase scenario store across demo repositories

Demo auth, order, profile, and location services should not each own isolated fake state. Instead, demo mode will use a single in-memory scenario store that seeds the current showcase user, role, profile data, available runs, active runs, and transitionable order state.

That shared store keeps cross-surface behavior coherent. For example, a volunteer accepting an order should update the active-order screen, history, and profile-facing summaries from the same source of truth, not from separate fake lists.

**Alternatives considered:**
- Independent fake repositories with hard-coded lists. Rejected because action flows would drift out of sync once the user mutates state.
- Persist demo state to the real session/preferences stores. Rejected because the presentation branch should be easy to reset and should not leak fake session state into normal mode.

### Decision: Presentation mode remains an explicit startup mode, but scenario selection moves out of the visible UI

The live login page is still the wrong first screen for presentations, but a visible showcase launcher also makes the branch look obviously fake. The presentation build should therefore stay explicitly configured at startup while selecting the seeded scenario outside the visible product surface, for example through a startup define or presentation-branch default.

That keeps the bootstrap deterministic without forcing the presenter through a launcher page that would never exist in production screenshots or demos.

**Alternatives considered:**
- Keep the current in-app launcher. Rejected because it signals "this is a demo build" before the product flow even begins.
- Reuse the existing login page with fake send-code/verify steps. Rejected because it still spends presentation time on a fake version of a flow the audience does not care about.

### Decision: Presentation map behavior prioritizes curated real AMap fidelity over fallback placeholders

The first implementation intentionally forced stable fallback rendering. That solved instability, but it also removed one of the most visually important parts of the product. The next iteration should keep deterministic location input while allowing the map stack itself to render through real AMap APIs using presentation-safe coordinates and known-good scenes.

The presentation dependency graph should therefore pin volunteer/blind scenarios to curated points, suppress live location drift, and keep AMap enabled in the presentation environment so the user sees a believable real map instead of a placeholder card.

**Alternatives considered:**
- Keep the current fallback-only behavior. Rejected because it looks unlike the real product in recordings and live demos.
- Use live device location with real AMap. Rejected because the presenter can drift to irrelevant places and lose the prepared story.

### Decision: Volunteer nearby-demand UI polish is part of the presentation scope

The volunteer nearby-demand menu currently shows a small black visual artifact. Even though this is a narrow UI bug, it materially harms the presentation because it sits in a primary volunteer surface. It should be treated as part of the presentation branch scope, not deferred as a generic polish issue.

**Alternatives considered:**
- Ignore the artifact because core flow still works. Rejected because the branch goal is now visual believability, not just functional stability.
- Hide the affected UI section during demos. Rejected because the nearby-demand area is part of the volunteer story and still needs to be shown.

## Risks / Trade-offs

- [Demo mode drifts away from real integration behavior] -> Keep simulation at provider/repository boundaries and reuse the same page/controller flows where feasible.
- [Adding a launcher and demo store expands scope] -> Limit the launcher to a small set of curated scenarios instead of building generic scenario editing.
- [Branch-only demo work becomes hard to merge or maintain] -> Keep demo modules isolated under explicit demo namespaces and avoid touching unrelated production behavior.
- [Presenters accidentally run the wrong seeded scenario] -> Make startup scenario selection explicit in launch configuration, not via visible in-app controls.
- [Real AMap rendering reintroduces environment instability] -> Constrain the presentation environment to valid AMap keys, curated fixed coordinates, and target-device rehearsal before the demo.
- [Removing visible demo cues makes internal debugging harder] -> Keep the presentation behavior controlled by startup config and branch context rather than on-screen labels.
- [Volunteer menu artifact has multiple root causes] -> Treat it as a scoped visual investigation tied to the nearby-demand surface instead of a broad dashboard refactor.

## Migration Plan

1. Keep the existing seeded demo dependency graph, but move scenario selection out of the visible launcher flow.
2. Reconfigure presentation map behavior to use real AMap rendering with curated fixed points and deterministic seeded locations.
3. Remove visible demo-only product cues such as badges or presentation labels from the on-screen UI.
4. Investigate and fix the volunteer nearby-demand menu artifact.
5. Re-validate the full presentation script on the target device/network with real AMap visuals enabled.

Rollback is straightforward: disable the demo startup path and provider overrides, leaving normal integration mode untouched.

## Open Questions

- Whether the presentation branch should choose volunteer vs blind through a build-time define, a branch-local default, or another non-visible startup mechanism.
- Whether the presentation path should keep a dev-only fallback to the old launcher for local debugging, or remove it entirely from the branch.
