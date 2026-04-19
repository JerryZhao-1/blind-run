## Why

The volunteer dashboard currently treats the local availability toggle as proof that the volunteer is online and ready to receive nearby orders. In practice, the backend only returns available orders after the app has successfully acquired location and reported `/api/volunteer/location`, so the UI can claim "online" while the volunteer is not actually intake-ready.

## What Changes

- Refine volunteer-side intake readiness so the dashboard distinguishes local availability intent from real backend-ready online state.
- Surface volunteer intake failures on the dashboard when location permission, location acquisition, or backend location reporting fails.
- Update the volunteer empty state and online/offline messaging so an empty list is not presented as proof that no orders exist when readiness has not been established.
- Clarify volunteer map behavior so the dashboard does not imply the initial fixed camera position is the volunteer's confirmed current location.

## Capabilities

### New Capabilities
- `volunteer-intake-readiness`: Represent and communicate volunteer intake readiness as an explicit UI state driven by location/report success instead of the local toggle alone.

### Modified Capabilities
- `volunteer-order-flow`: Change how volunteer availability, nearby-order intake, and empty-state messaging behave when location or location reporting has not succeeded.

## Impact

- Affected code: `lib/app/state/app_state.dart`, `lib/app/state/app_state_controller.dart`, `lib/features/volunteer/volunteer_dashboard_page.dart`, and volunteer-side location/map helpers.
- Affected APIs: existing `/api/volunteer/location` and `/api/orders/available` flows only; no new backend endpoints required.
- Affected systems: volunteer dashboard status copy, location heartbeat behavior, dashboard error visibility, and map readiness cues.
