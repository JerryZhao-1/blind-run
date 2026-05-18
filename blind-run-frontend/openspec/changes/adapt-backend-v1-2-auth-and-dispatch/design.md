## Context

Backend v1.2.0 changes the live contract that the current Flutter frontend was built against. The new changelog is now stored at `docs/frontend-changelog-1.2.0.md` and should be treated as the primary contract because production Swagger is not reliably available.

The most immediate compatibility issue is authentication. The current app logs in through SMS, stores the token returned by `/api/auth/verify-code`, and after role selection calls `/api/user/role` but ignores the response body. Backend v1.2.0 now returns a replacement token from `/api/user/role`; that token carries the chosen role. If the app keeps using the old token, backend RBAC rejects role-scoped endpoints with 403.

The dispatch model also changed. The current volunteer dashboard relies on REST polling via `/api/orders/available` and accepts with deprecated `POST /api/orders/{id}/accept`. Backend v1.2.0 introduces role-scoped WebSocket connections and serial dispatch: volunteers receive `NEW_ORDER` events and respond with `POST /api/orders/{id}/respond`.

## Goals / Non-Goals

**Goals:**
- Treat role selection as session renewal by persisting the replacement token returned by `/api/user/role`.
- Preserve route decisions and profile refresh behavior while ensuring all later requests use the current role-bearing token.
- Validate SMS phone numbers on the client with the backend's `^1[3-9]\d{9}$` format before sending login requests.
- Call backend logout for normal user logout and still clear local state deterministically.
- Normalize 401 and 403 handling so authentication loss and authorization denial are visible and recoverable.
- Add role-scoped realtime dispatch support for backend v1.2.0, including volunteer `NEW_ORDER` events and `/respond` actions.

**Non-Goals:**
- Building the CS/admin frontend.
- Completing the volunteer identity verification UI.
- Removing all polling immediately; polling may remain as a fallback while realtime dispatch is introduced.
- Implementing a production call/notification center beyond the dispatch events required for v1.2.0 compatibility.

## Decisions

### Decision: Model `/api/user/role` as returning a renewed session

`AuthRepository.setRole` should no longer return only `UserRole`. It should parse the response body and return enough session data for the controller to replace the saved token, user id, and role. If the backend omits a token in a non-v1.2 environment, the implementation can fall back to preserving the existing token only as a compatibility path.

**Alternatives considered:**
- Continue storing the old token and only update local role. Rejected because backend RBAC now depends on the token's role claim.
- Re-run SMS login after role selection. Rejected because `/api/user/role` already returns the correct replacement token.

### Decision: Keep API error normalization in `ApiClient`

The backend now returns JSON for 401 and 403. `ApiClient` already parses `message`, `code`, and status, so the implementation should build on that central normalization rather than adding per-screen parsing. Controller logic should use `ApiFailure.isUnauthorized` for 401 and surface 403 messages as authorization failures without clearing valid sessions.

**Alternatives considered:**
- Parse 403 separately in each feature screen. Rejected because authorization behavior is cross-cutting and should be consistent.
- Treat all 403s as logout. Rejected because 403 is a role/permission denial, not necessarily an invalid session.

### Decision: Make logout best-effort against the backend and deterministic locally

User logout should call `POST /api/auth/logout` with the current token, then clear local session. If the backend call fails because the token is already invalid or the network is unavailable, the local session should still be cleared so the user is not trapped.

**Alternatives considered:**
- Only clear local state. Rejected because backend v1.2.0 invalidates tokens server-side and expects clients to call logout.
- Block local logout until backend logout succeeds. Rejected because logout must remain reliable from the user's point of view.

### Decision: Introduce a realtime dispatch service behind providers

Realtime dispatch should be isolated in a service/repository boundary rather than embedded directly in the volunteer dashboard widget. The service owns the role-scoped WebSocket URL, connection lifecycle, incoming event parsing, and reconnect timing. App/controller code consumes typed dispatch events and decides how to update dashboard state or prompt the volunteer.

Because Flutter's standard SDK does not provide a high-level cross-platform test-friendly WebSocket client abstraction, the implementation should either add a narrow adapter around `dart:io` WebSocket for mobile or add a small dependency such as `web_socket_channel` if tests and platform support justify it. The final implementation should keep the adapter injectable so widget/controller tests can use fakes.

**Alternatives considered:**
- Put WebSocket code directly in `VolunteerDashboardPage`. Rejected because it would make lifecycle, reconnection, and tests harder.
- Keep REST polling as the only intake source. Rejected because backend v1.2.0 serial dispatch requires WebSocket-based `NEW_ORDER` handling for the intended flow.

### Decision: Prefer `/respond` for new volunteer accept/decline flows, retain `/accept` only as compatibility fallback

The order repository should expose the v1.2.0 response action (`ACCEPT`/`DECLINE`) as the main volunteer dispatch decision. Existing post-accept handoff protections from `fix-volunteer-post-accept-order-flow` still apply after an accepted dispatch: the app should confirm readable owned-order state before routing into the active order page.

**Alternatives considered:**
- Replace every accept path immediately and remove `/accept`. Rejected because the changelog states `/accept` remains available but deprecated, and compatibility helps during migration.
- Keep `/accept` as the primary path. Rejected because it ignores the backend's new serial dispatch semantics.

## Risks / Trade-offs

- [Token replacement touches login, role routing, and session restore] -> Keep the model change small and add focused tests around role selection and subsequent authenticated requests.
- [Realtime dispatch adds async lifecycle complexity] -> Keep WebSocket handling in an injectable service and preserve polling as a fallback during rollout.
- [Production Swagger is unavailable] -> Use `docs/frontend-changelog-1.2.0.md` as the source of truth and verify critical requests against the live server manually during implementation.
- [401 and 403 may look similar to users] -> Route 401 to login/session recovery and display 403 as a permission message without clearing the session.
- [Volunteer verification is still a separate blocker] -> Do not treat this change as replacing Step 2 ID upload and admin review; authentication/dispatch compatibility only makes the role and order APIs reachable when the account is otherwise eligible.

## Migration Plan

1. Update auth models/repositories/controller code so role selection persists the replacement token and tests cover the saved session.
2. Add phone validation and backend logout support without changing the login screen's core flow.
3. Verify 401/403 JSON behavior through existing `ApiClient` normalization and add missing tests for 403 message handling.
4. Add realtime dispatch service abstractions and typed event parsing.
5. Update volunteer dispatch intake to connect to `/ws/volunteer`, surface `NEW_ORDER`, and use `/api/orders/{id}/respond` for accept/decline while preserving current post-accept confirmation behavior.
6. Keep `/available` polling and deprecated `/accept` only as compatibility fallback until the realtime path is stable.

Rollback can keep the copied changelog document and revert the auth/dispatch code changes. If realtime dispatch needs to be paused, the app can retain the role-token fix and use the existing polling/accept path temporarily.

## Open Questions

- Should the first implementation add `web_socket_channel`, or should it wrap `dart:io` WebSocket directly for the mobile targets?
- Does backend v1.2.0 require WebSocket `LOCATION_UPDATE` for volunteer online state, or can the existing `POST /api/volunteer/location` heartbeat coexist as a compatibility path?
- What exact status/body does `POST /api/orders/{id}/respond` return after `ACCEPT`, and does it immediately make `/api/orders/{id}` readable for the volunteer?
- Should blind-side WebSocket support be implemented in this change, or only the shared service and volunteer path needed for serial dispatch?
