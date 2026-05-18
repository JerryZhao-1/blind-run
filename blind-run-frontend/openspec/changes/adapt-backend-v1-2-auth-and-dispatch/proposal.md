## Why

Backend v1.2.0 changed the authentication and dispatch contract in ways that directly affect the Flutter app's current live flow. The most urgent issue is that `/api/user/role` now returns a replacement JWT containing role claims; if the app keeps the old token, RBAC rejects later blind or volunteer requests with 403, which matches the current "unauthorized" volunteer symptoms.

## What Changes

- Persist the replacement token returned by `POST /api/user/role` and use it for all subsequent authenticated requests.
- Add client-side validation for the backend's China mobile-number format before sending SMS login requests.
- Add backend logout calls for normal user logout while still clearing local session state.
- Treat backend 401/403 JSON responses as first-class auth and authorization outcomes with clearer routing and user feedback.
- Introduce the backend v1.2.0 serial-dispatch flow for volunteers: role-scoped WebSocket connection, `NEW_ORDER` dispatch events, and `POST /api/orders/{id}/respond`.
- Keep deprecated `POST /api/orders/{id}/accept` as a temporary fallback only where needed for compatibility, while making `/respond` the intended volunteer accept/decline contract.

## Capabilities

### New Capabilities

- `role-scoped-realtime-dispatch`: Role-scoped WebSocket connections and volunteer `NEW_ORDER` dispatch handling for backend v1.2.0 serial dispatch.

### Modified Capabilities

- `auth-session`: Role binding must persist the backend's replacement token, logout must invalidate backend sessions, phone input must match the backend format, and 401/403 responses must be handled explicitly.
- `volunteer-order-flow`: Volunteer intake and order acceptance must align with v1.2.0 serial dispatch and `/api/orders/{id}/respond` while preserving safe compatibility with deprecated accept endpoints during migration.

## Impact

- Affected code: `lib/core/repositories/auth_repository.dart`, `lib/core/repositories/auth_session_store.dart`, `lib/core/network/api_client.dart`, `lib/app/state/app_state_controller.dart`, `lib/features/auth/login_page.dart`, `lib/core/repositories/order_repository.dart`, volunteer dashboard/order flow code, and any new realtime dispatch service/provider.
- Affected docs: `docs/frontend-changelog-1.2.0.md` is the source backend v1.2.0 contract; production Swagger may not be available.
- Affected APIs: `/api/user/role`, `/api/auth/logout`, `/api/auth/send-code`, `/api/auth/verify-code`, role-scoped WebSocket endpoints `/ws/blind` and `/ws/volunteer`, and `POST /api/orders/{id}/respond`.
- Affected behavior: post-role-selection requests should stop failing due to stale role-less tokens; volunteers should eventually receive serial dispatch opportunities through WebSocket instead of depending only on polling `/api/orders/available`.
