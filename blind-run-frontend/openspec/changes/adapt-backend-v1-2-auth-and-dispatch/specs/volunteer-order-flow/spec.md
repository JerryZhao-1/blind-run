## MODIFIED Requirements

### Requirement: Volunteer order actions follow backend status endpoints
The Flutter application SHALL map volunteer order actions to the backend status endpoints that exist in production, and SHALL use backend v1.2.0 `/respond` actions for serial-dispatch accept and decline decisions.

#### Scenario: Volunteer accepts a serially dispatched order
- **WHEN** the volunteer chooses to accept a `NEW_ORDER` dispatch
- **THEN** the app submits `POST /api/orders/{id}/respond` with `{"action":"ACCEPT"}`
- **AND** the volunteer flow refreshes from backend-confirmed order data

#### Scenario: Volunteer declines a serially dispatched order
- **WHEN** the volunteer chooses not to accept a `NEW_ORDER` dispatch
- **THEN** the app submits `POST /api/orders/{id}/respond` with `{"action":"DECLINE"}`
- **AND** the app removes or dismisses the declined dispatch opportunity from the active volunteer intake surface

#### Scenario: Volunteer uses compatibility accept path during migration
- **WHEN** the app is operating against a backend path where the deprecated accept endpoint is still required
- **THEN** the app may submit `POST /api/orders/{id}/accept`
- **AND** the volunteer flow still refreshes from backend-confirmed order data before opening active-order actions

#### Scenario: Volunteer advances an accepted order toward service completion
- **WHEN** the volunteer marks progress on an accepted order
- **THEN** the app uses the production endpoints for en-route, arrived, and finish transitions
- **AND** the UI labels and active-order state reflect the backend-confirmed status after refresh

## ADDED Requirements

### Requirement: Volunteer dispatch responses preserve post-accept handoff safety
The Flutter application SHALL apply the same backend-confirmed ownership checks after a successful `/respond` accept that it applies after the deprecated accept endpoint.

#### Scenario: Accepted dispatch becomes readable
- **WHEN** the volunteer accepts a dispatch through `/api/orders/{id}/respond`
- **AND** a follow-up owned-order or detail read confirms the order is readable for the volunteer
- **THEN** the app may route to the volunteer active-order page
- **AND** the active-order page exposes next-step actions according to backend-confirmed status

#### Scenario: Accepted dispatch is not yet readable
- **WHEN** the volunteer accepts a dispatch through `/api/orders/{id}/respond`
- **AND** follow-up reads cannot confirm readable volunteer ownership
- **THEN** the app keeps the volunteer on the intake surface
- **AND** the app presents a clear failure or retry message instead of opening an unreadable active-order page
