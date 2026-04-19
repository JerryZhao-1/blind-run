## Context

The current Flutter application was intentionally migrated as a backend-free demo. Its runtime assumes a locally stored role, mock users, in-memory runs, and simplified settings state. The deployed backend has since grown into the baseline source of truth for login, role selection, profiles, emergency contacts, and order status, but the frontend still reflects the earlier prototype contract.

This change is cross-cutting: routing, persistence, models, state management, blind and volunteer pages, and tests all depend on the current mock assumptions. The design needs to replace those assumptions without rewriting unrelated UI behavior or broadening scope into WebSocket, emergency, admin, or training workflows.

## Goals / Non-Goals

**Goals:**
- Introduce a backend client layer that can authenticate, restore sessions, and call the deployed REST API consistently.
- Replace local mock order/session flows with server-backed blind and volunteer baseline flows.
- Keep the current accessibility-focused screen structure and map integration while switching the underlying data source.
- Make the first integration operational with HTTP polling and deterministic time conversion rules for order creation.

**Non-Goals:**
- Do not implement WebSocket push, emergency workflows, training workflows, admin/cs workflows, or virtual-call features.
- Do not redesign unrelated UI surfaces such as the reward store.
- Do not depend on the local `blind-run-backend` code as the contract of record when it disagrees with production Swagger/runtime behavior.

## Decisions

### Decision: Use production REST behavior as the contract of record

The frontend will follow the deployed Swagger and observed runtime behavior at `47.114.113.171`, with `docs/frontend-guide.md` as supplemental context. The local backend code is treated as stale reference only when it aligns with production.

**Alternatives considered:**
- Use local backend source as the primary contract. Rejected because multiple live endpoints and token behaviors already diverge from the repo.
- Freeze to the hand-written frontend guide only. Rejected because some runtime details are only visible in the live OpenAPI/runtime behavior.

### Decision: Replace local demo stores with async repositories plus centralized error normalization

The app will add a thin HTTP client and async repositories for auth, orders, profiles, and emergency contacts. Errors will be normalized centrally so widgets do not need to understand multiple backend error shapes.

**Alternatives considered:**
- Keep local repositories and bolt live API calls into pages. Rejected because it would duplicate parsing, auth headers, and error handling across many screens.
- Introduce a heavier networking framework. Rejected because the current app already depends on `http`, and the baseline integration does not need a larger abstraction.

### Decision: Treat auth bootstrap as the root navigation gate

The app root will restore any saved token, validate it with `/api/auth/me`, and route users by real backend role. `RoleSelectionPage` will remain, but only as the post-login screen for `UNSET` users, where it writes role via `/api/user/role`.

**Alternatives considered:**
- Keep the current local role selector as the app root. Rejected because backend APIs require a real JWT and server-side role.
- Add a debug-only token injector as the main path. Rejected because the requested baseline explicitly includes real login.

### Decision: Use polling for baseline order freshness

Blind and volunteer pages will refresh from HTTP polling. Active order/detail pages poll more frequently than list pages. Volunteer nearby-order availability remains dependent on explicit location heartbeat updates.

**Alternatives considered:**
- Adopt WebSocket immediately. Rejected for the first cut because it adds connection-state and message-shape complexity before baseline REST parity exists.
- Rely on manual refresh only. Rejected because order acceptance and progress updates need basic freshness to be usable.

### Decision: Preserve current human-readable time labels, but derive backend datetimes deterministically

The blind request flow will keep the existing preset/voice-driven labels for the UI, but convert them into `plannedStartTime` and `plannedEndTime` using fixed defaults. This avoids redesigning the accessible flow while satisfying backend input requirements.

**Alternatives considered:**
- Replace the blind-side time UI with a full date-time picker immediately. Rejected because it would unnecessarily disturb an already accessibility-tuned interaction.
- Send raw voice text to the backend. Rejected because the backend requires explicit datetime fields.

### Decision: Reuse the volunteer availability toggle as the backend location-intake control

The existing volunteer settings/dashboard availability state will become a real online/offline control by posting `/api/volunteer/location` with `isOnline` and current coordinates on a heartbeat cadence.

**Alternatives considered:**
- Keep the toggle local and call `/api/orders/available` anyway. Rejected because the backend returns no nearby orders without recent volunteer location.
- Move location reporting to a separate hidden service immediately. Rejected because the current UI already exposes the correct user intent: whether the volunteer is accepting new work.

## Risks / Trade-offs

- Production/runtime drift may still exist beyond the documented endpoints → keep API parsing localized and prefer graceful fallbacks plus explicit logging.
- Polling increases request volume compared with push → use conservative intervals and scope polling to active pages.
- The current accessible blind flow uses coarse time labels, not exact times → document deterministic conversion rules so behavior is predictable and testable.
- Emergency contacts are a richer backend model than the current single-string setting → the blind settings screen must change shape, which may require test updates and minor UX copy changes.

## Migration Plan

1. Introduce session, API client, backend models, and async repositories alongside the existing UI.
2. Switch root routing and role selection to authenticated bootstrap behavior.
3. Rewire blind order pages to live API data and remove mock transition buttons.
4. Rewire volunteer list/detail flows and add location heartbeat behavior.
5. Rework profile/settings screens to use backend profile and emergency-contact resources.
6. Update tests and validate the OpenSpec change before implementation begins.

Rollback for implementation can disable the live backend path by reverting the new repository wiring and session bootstrap changes, because the UI structure itself is not being removed in this proposal.

## Open Questions

- Whether the production backend enforces additional create-order validation beyond “at least one emergency contact” still needs to be confirmed during implementation.
- Whether secure storage should replace shared preferences immediately or in a follow-up change depends on platform/runtime constraints discovered during implementation.
