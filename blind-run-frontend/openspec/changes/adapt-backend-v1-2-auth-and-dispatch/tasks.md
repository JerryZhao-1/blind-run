## 1. Auth Session Compatibility

- [x] 1.1 Update auth session/role-selection models so `POST /api/user/role` can return and persist the backend replacement token.
- [x] 1.2 Rework `AppStateController.submitRole` to save the renewed session before fetching role-scoped profile/order data.
- [x] 1.3 Add focused tests proving role selection replaces the stored token and subsequent requests use the renewed token.
- [x] 1.4 Add login phone-number validation matching `^1[3-9]\d{9}$` before send-code and verify-code requests.
- [x] 1.5 Add user logout API support with deterministic local session clearing when backend logout fails.
- [x] 1.6 Verify 401 clears the session while 403 preserves the session and surfaces the backend permission message.

## 2. Volunteer Serial Dispatch API

- [x] 2.1 Add order repository support for `POST /api/orders/{id}/respond` with `ACCEPT` and `DECLINE` actions.
- [x] 2.2 Preserve deprecated `/accept` behavior as an explicit compatibility fallback while making `/respond` the primary serial-dispatch path.
- [x] 2.3 Reuse the existing post-accept handoff confirmation after successful `/respond` accept so unreadable orders do not open the active-order page.
- [x] 2.4 Add tests for `/respond` accept success, decline dismissal, and unreadable follow-up handling.

## 3. Role-Scoped Realtime Dispatch

- [x] 3.1 Decide and wire the WebSocket adapter approach (`web_socket_channel` or a narrow `dart:io` adapter) behind injectable providers.
- [x] 3.2 Implement a realtime dispatch service that connects to `/ws/blind` or `/ws/volunteer` using the current persisted token for the authenticated role.
- [x] 3.3 Parse volunteer `NEW_ORDER` messages into typed dispatch opportunities with order id, address, planned time, distance, timeout, and priority.
- [x] 3.4 Add reconnect and shutdown behavior so dispatch reconnects while intake is active and closes cleanly on logout.
- [x] 3.5 Support backend v1.2.0 `LOCATION_UPDATE` messages when realtime dispatch is connected while preserving REST location heartbeat compatibility.

## 4. Volunteer UI Integration

- [x] 4.1 Surface realtime dispatch opportunities on the volunteer intake dashboard with accept and decline actions.
- [x] 4.2 Route accept actions through `/respond` and keep the volunteer on the dashboard when ownership cannot be confirmed.
- [x] 4.3 Show recoverable realtime connection states without claiming online dispatch readiness when WebSocket connection fails.
- [x] 4.4 Keep existing polling available as fallback during migration without letting stale poll results override active dispatch state.

## 5. Verification

- [x] 5.1 Run unit/widget tests covering auth token renewal, phone validation, logout, 401/403 handling, dispatch event parsing, and `/respond` actions.
- [x] 5.2 Run `flutter analyze` on touched Dart files.
- [ ] 5.3 Manually validate against backend v1.2.0: SMS login, role selection token replacement, volunteer profile access without stale-token 403, logout, and volunteer dispatch accept path.
- [ ] 5.4 Document any backend gaps found during manual validation, especially `/respond` response shape and WebSocket location-update requirements.
