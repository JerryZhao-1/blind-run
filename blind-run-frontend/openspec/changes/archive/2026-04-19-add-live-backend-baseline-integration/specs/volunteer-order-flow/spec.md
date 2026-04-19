## ADDED Requirements

### Requirement: Volunteer availability drives backend intake readiness
The Flutter application SHALL treat volunteer availability as a live backend readiness state by reporting current location and online status while the volunteer is accepting new orders.

#### Scenario: Volunteer turns availability on
- **WHEN** the authenticated volunteer enables availability on the volunteer flow
- **THEN** the app obtains the current device location
- **AND** the app reports `/api/volunteer/location` with `isOnline=true`

#### Scenario: Volunteer remains available on the dashboard
- **WHEN** the volunteer stays on the volunteer home flow with availability enabled
- **THEN** the app continues a periodic location heartbeat
- **AND** the heartbeat cadence is sufficient for `/api/orders/available` to keep returning nearby orders when present

#### Scenario: Volunteer turns availability off or leaves the intake flow
- **WHEN** the volunteer disables availability or exits the volunteer intake context
- **THEN** the app reports `/api/volunteer/location` with `isOnline=false`
- **AND** the app stops the location heartbeat

### Requirement: Volunteer nearby-order intake uses the backend available-orders feed
The Flutter application SHALL populate the volunteer dashboard from live backend available-order and personal-order endpoints instead of local seeded runs.

#### Scenario: Volunteer loads the dashboard with availability enabled
- **WHEN** the volunteer dashboard refreshes
- **THEN** the app fetches `/api/orders/available` for nearby opportunities
- **AND** the app fetches `/api/orders/mine?role=VOLUNTEER` for the volunteer's active and historical orders

#### Scenario: Volunteer has not reported location yet
- **WHEN** `/api/orders/available` returns an empty list because no current location has been reported
- **THEN** the app keeps the volunteer dashboard usable
- **AND** the app does not misrepresent the empty result as proof that no orders exist anywhere

### Requirement: Volunteer order actions follow backend status endpoints
The Flutter application SHALL map volunteer order actions to the backend status endpoints that exist in production.

#### Scenario: Volunteer accepts an available order
- **WHEN** the volunteer chooses to take an available order
- **THEN** the app submits `POST /api/orders/{id}/accept`
- **AND** the volunteer flow refreshes from backend-confirmed order data

#### Scenario: Volunteer advances an accepted order toward service completion
- **WHEN** the volunteer marks progress on an accepted order
- **THEN** the app uses the production endpoints for en-route, arrived, and finish transitions
- **AND** the UI labels and active-order state reflect the backend-confirmed status after refresh

### Requirement: Volunteer pages refresh from backend data without local mock progression
The Flutter application SHALL remove local volunteer-side order simulation and SHALL use polling to keep active order details and history current.

#### Scenario: Volunteer opens an active order page
- **WHEN** the volunteer enters the active order screen
- **THEN** the app fetches live order detail for that order
- **AND** the action buttons available on the page match the current backend status

#### Scenario: Volunteer reviews completed work in history
- **WHEN** the volunteer opens the dashboard history tab
- **THEN** the app shows completed or cancelled orders sourced from `/api/orders/mine?role=VOLUNTEER`
- **AND** the list is ordered using refreshed backend data rather than seeded demo runs
