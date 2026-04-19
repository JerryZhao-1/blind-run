## Why

The Flutter app is still structured as a local demo: role selection is stored only on-device, orders are seeded in memory, and settings pages do not match the live backend model. The deployed backend at `http://47.114.113.171` now exposes the baseline blind/volunteer workflow, so the frontend needs a first real integration pass to remove product drift and support basic end-to-end usage.

## What Changes

- Add real SMS login, JWT session restore, `/api/auth/me` validation, and server-backed role binding for authenticated users.
- Replace local blind and volunteer run state with live order data from the deployed backend, using HTTP polling for the first integration baseline.
- Align blind-side booking, active order tracking, cancellation, and post-run review with the backend order lifecycle.
- Align volunteer-side availability, location reporting, nearby order intake, order acceptance, and progress updates with the backend order lifecycle.
- Replace local settings-only profile assumptions with server-backed blind profile, volunteer profile, and emergency-contact management.
- Preserve current accessibility and map experience where possible, but remove mock-only testing actions and data shapes that conflict with backend behavior.

## Capabilities

### New Capabilities
- `auth-session`: SMS login, JWT persistence, token validation, and role-based bootstrap routing for the Flutter app.
- `blind-order-flow`: Blind-side order creation, active order refresh, cancellation, and review against the live backend.
- `volunteer-order-flow`: Volunteer-side availability, location heartbeat, nearby order intake, acceptance, and order progress updates against the live backend.
- `profile-sync`: Server-backed blind profile, volunteer profile, and emergency-contact management needed for the baseline user flow.

### Modified Capabilities

None.

## Impact

- Affected code: `lib/app`, `lib/core/models`, `lib/core/navigation`, `lib/core/repositories`, `lib/features/blind`, `lib/features/volunteer`, `lib/features/settings`, and related tests.
- Affected APIs: `/api/auth/*`, `/api/user/role`, `/api/blind/profile`, `/api/volunteer/profile`, `/api/volunteer/location`, `/api/orders/*`, `/api/users/{userId}/emergency-contacts*`.
- Affected dependencies and systems: shared session persistence, HTTP client layer, location reporting cadence, and Flutter widget/state tests that currently assume local mock data.
