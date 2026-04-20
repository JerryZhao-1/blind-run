## ADDED Requirements

### Requirement: Demo showcase mode can present curated volunteer order journeys
The Flutter application SHALL support curated volunteer showcase scenarios that exercise nearby-order intake, accept, and active-order progression from simulated repositories instead of live backend dependencies.

#### Scenario: Volunteer showcase starts with nearby opportunities
- **WHEN** the presenter enters a volunteer showcase scenario with available runs
- **THEN** the volunteer dashboard SHALL render the prepared nearby-order data
- **AND** the presenter SHALL be able to continue into accept and active-order flows without a live backend refresh

#### Scenario: Volunteer showcase starts with an active order
- **WHEN** the presenter enters a volunteer showcase scenario with a prepared owned order
- **THEN** the volunteer active-order surfaces SHALL render that simulated owned order state
- **AND** progress actions SHALL update the showcase state without requiring live backend mutations

## MODIFIED Requirements

### Requirement: Volunteer availability drives backend intake readiness
The Flutter application SHALL treat volunteer availability as a live backend readiness state in normal integration mode by reporting current location and online status while the volunteer is accepting new orders, and SHALL support equivalent simulated readiness in demo showcase mode.

#### Scenario: Volunteer turns availability on in normal integration mode
- **WHEN** the authenticated volunteer enables availability on the volunteer flow
- **THEN** the app obtains the current device location
- **AND** the app reports `/api/volunteer/location` with `isOnline=true`

#### Scenario: Volunteer remains available on the dashboard in normal integration mode
- **WHEN** the volunteer stays on the volunteer home flow with availability enabled
- **THEN** the app continues a periodic location heartbeat
- **AND** the heartbeat cadence is sufficient for `/api/orders/available` to keep returning nearby orders when present

#### Scenario: Volunteer turns availability off or leaves the intake flow in normal integration mode
- **WHEN** the volunteer disables availability or exits the volunteer intake context
- **THEN** the app reports `/api/volunteer/location` with `isOnline=false`
- **AND** the app stops the location heartbeat

#### Scenario: Volunteer showcase enables availability
- **WHEN** the presenter enables volunteer availability in demo showcase mode
- **THEN** the dashboard SHALL reflect the prepared simulated readiness state
- **AND** the showcase SHALL not require live location reporting before nearby orders can be demonstrated

### Requirement: Volunteer nearby-order intake uses the backend available-orders feed
The Flutter application SHALL populate the volunteer dashboard from live backend available-order and personal-order endpoints in normal integration mode, and SHALL populate the dashboard from curated simulated state in demo showcase mode.

#### Scenario: Volunteer loads the dashboard with availability enabled in normal integration mode
- **WHEN** the volunteer dashboard refreshes
- **THEN** the app fetches `/api/orders/available` for nearby opportunities
- **AND** the app fetches `/api/orders/mine?role=VOLUNTEER` for the volunteer's active and historical orders

#### Scenario: Volunteer has not reported location yet in normal integration mode
- **WHEN** `/api/orders/available` returns an empty list because no current location has been reported
- **THEN** the app keeps the volunteer dashboard usable
- **AND** the app does not misrepresent the empty result as proof that no orders exist anywhere

#### Scenario: Volunteer showcase renders nearby orders
- **WHEN** the presenter opens the volunteer dashboard in demo showcase mode
- **THEN** the nearby-order list SHALL come from the selected showcase scenario
- **AND** the dashboard SHALL remain usable even when the live backend is unavailable

### Requirement: Volunteer order actions follow backend status endpoints
The Flutter application SHALL map volunteer order actions to the backend status endpoints that exist in production in normal integration mode, and SHALL preserve equivalent order-progress actions against simulated state in demo showcase mode.

#### Scenario: Volunteer accepts an available order in normal integration mode
- **WHEN** the volunteer chooses to take an available order
- **THEN** the app submits `POST /api/orders/{id}/accept`
- **AND** the volunteer flow refreshes from backend-confirmed order data

#### Scenario: Volunteer advances an accepted order toward service completion in normal integration mode
- **WHEN** the volunteer marks progress on an accepted order
- **THEN** the app uses the production endpoints for en-route, arrived, and finish transitions
- **AND** the UI labels and active-order state reflect the backend-confirmed status after refresh

#### Scenario: Volunteer showcase advances an accepted order
- **WHEN** the presenter marks progress on a simulated accepted order in demo showcase mode
- **THEN** the volunteer flow SHALL update the scenario's simulated order state
- **AND** the next active-order actions SHALL reflect that updated simulated status

### Requirement: Volunteer pages refresh from backend data without local mock progression
The Flutter application SHALL use live backend data to keep volunteer active-order details and history current in normal integration mode, and SHALL use the selected showcase scenario state as the canonical volunteer data source in demo showcase mode.

#### Scenario: Volunteer opens an active order page in normal integration mode
- **WHEN** the volunteer enters the active order screen
- **THEN** the app fetches live order detail for that order
- **AND** the action buttons available on the page match the current backend status

#### Scenario: Volunteer reviews completed work in history in normal integration mode
- **WHEN** the volunteer opens the dashboard history tab
- **THEN** the app shows completed or cancelled orders sourced from `/api/orders/mine?role=VOLUNTEER`
- **AND** the list is ordered using refreshed backend data rather than seeded demo runs

#### Scenario: Volunteer showcase re-enters dashboard after an action
- **WHEN** the presenter returns to the volunteer dashboard or history after a simulated action in demo showcase mode
- **THEN** the volunteer surfaces SHALL read the current simulated state from the shared showcase source of truth
- **AND** the app SHALL not regress to unrelated seeded data

### Requirement: Volunteer nearby-demand presentation remains visually clean in showcase mode
The Flutter application SHALL render the volunteer nearby-demand menu and its surrounding dashboard controls without stray visual artifacts in presentation showcase mode.

#### Scenario: Presenter opens the volunteer nearby-demand surface
- **WHEN** the volunteer showcase dashboard renders the nearby-demand menu and demand list
- **THEN** the menu area SHALL not show stray black dots, lines, or other unintended artifacts
- **AND** the volunteer presentation surface SHALL remain visually consistent with the real product design
