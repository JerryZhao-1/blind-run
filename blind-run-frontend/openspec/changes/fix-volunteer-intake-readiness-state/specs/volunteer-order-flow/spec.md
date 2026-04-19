## MODIFIED Requirements

### Requirement: Volunteer availability drives backend intake readiness
The Flutter application SHALL treat volunteer availability as a local intake preference that becomes backend-ready only after the app successfully reports current location and online status while the volunteer is accepting new orders.

#### Scenario: Volunteer turns availability on
- **WHEN** the authenticated volunteer enables availability on the volunteer flow
- **THEN** the app obtains the current device location
- **AND** the app reports `/api/volunteer/location` with `isOnline=true`
- **AND** the volunteer dashboard SHALL not claim the volunteer is fully online for nearby intake until that report succeeds

#### Scenario: Volunteer remains available on the dashboard
- **WHEN** the volunteer stays on the volunteer home flow with availability enabled
- **THEN** the app continues a periodic location heartbeat
- **AND** the heartbeat cadence is sufficient for `/api/orders/available` to keep returning nearby orders when present
- **AND** heartbeat failures SHALL downgrade the volunteer readiness state so the dashboard no longer misrepresents intake readiness

#### Scenario: Volunteer turns availability off or leaves the intake flow
- **WHEN** the volunteer disables availability or exits the volunteer intake context
- **THEN** the app reports `/api/volunteer/location` with `isOnline=false`
- **AND** the app stops the location heartbeat

### Requirement: Volunteer nearby-order intake uses the backend available-orders feed
The Flutter application SHALL populate the volunteer dashboard from live backend available-order and personal-order endpoints instead of local seeded runs, and SHALL explain empty nearby-order results according to current intake readiness.

#### Scenario: Volunteer loads the dashboard with availability enabled
- **WHEN** the volunteer dashboard refreshes
- **THEN** the app fetches `/api/orders/available` for nearby opportunities
- **AND** the app fetches `/api/orders/mine?role=VOLUNTEER` for the volunteer's active and historical orders

#### Scenario: Volunteer has not reported location yet
- **WHEN** `/api/orders/available` returns an empty list because no current location has been reported
- **THEN** the app keeps the volunteer dashboard usable
- **AND** the dashboard SHALL indicate that location-based intake readiness is still unresolved instead of presenting the empty result as proof that no nearby orders exist

#### Scenario: Volunteer has reported location and no nearby orders are available
- **WHEN** the volunteer dashboard has successfully established intake readiness and `/api/orders/available` returns an empty list
- **THEN** the dashboard SHALL present the empty state as a true "no nearby orders" result
