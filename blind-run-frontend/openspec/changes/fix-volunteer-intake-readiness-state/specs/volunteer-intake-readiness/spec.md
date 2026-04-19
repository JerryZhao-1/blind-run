## ADDED Requirements

### Requirement: Volunteer dashboard exposes truthful intake readiness state
The Flutter application SHALL represent volunteer intake readiness as a distinct frontend state that is not inferred from the persisted availability toggle alone.

#### Scenario: Volunteer enables intake and readiness is still being established
- **WHEN** the volunteer has enabled availability and the dashboard is still acquiring location or reporting it to the backend
- **THEN** the dashboard SHALL present a transitional readiness state instead of claiming the volunteer is already online and intake-ready

#### Scenario: Volunteer becomes intake-ready after a successful location report
- **WHEN** the volunteer dashboard successfully reports the current location to `/api/volunteer/location` with `isOnline=true`
- **THEN** the dashboard SHALL transition to a readiness state that represents confirmed nearby-order intake readiness

#### Scenario: Volunteer cannot become intake-ready because location is unavailable
- **WHEN** the volunteer has enabled availability but the app cannot obtain a usable current location because permission was denied, location timed out, or location acquisition otherwise failed
- **THEN** the dashboard SHALL present a readiness failure state that explains location is required before nearby-order intake can be confirmed

#### Scenario: Volunteer cannot become intake-ready because backend reporting failed
- **WHEN** the volunteer dashboard obtains a device location but `/api/volunteer/location` fails
- **THEN** the dashboard SHALL present a readiness failure state that distinguishes backend reporting failure from "no nearby orders"

### Requirement: Volunteer dashboard empty states distinguish no-orders from not-ready
The Flutter application SHALL use volunteer intake readiness state when explaining why the nearby-order list is empty.

#### Scenario: Volunteer is intake-ready and there are no nearby orders
- **WHEN** the volunteer dashboard is in the confirmed intake-ready state and `/api/orders/available` returns an empty list
- **THEN** the dashboard SHALL describe the state as "no nearby orders right now" rather than suggesting readiness is still unknown

#### Scenario: Volunteer is not intake-ready and nearby orders cannot be trusted yet
- **WHEN** the volunteer dashboard is not in the confirmed intake-ready state and the nearby-order list is empty
- **THEN** the dashboard SHALL explain that nearby orders cannot yet be confirmed because readiness has not been established

### Requirement: Volunteer dashboard does not use map position as proof of readiness
The Flutter application SHALL avoid implying that the volunteer dashboard's initial map position is equivalent to confirmed current-location readiness.

#### Scenario: Dashboard map starts from a fixed initial viewport
- **WHEN** the volunteer dashboard first renders with a fixed default camera position
- **THEN** the dashboard SHALL avoid using that viewport as evidence that the volunteer has or has not completed location-based intake readiness

#### Scenario: Volunteer inspects map while readiness is unresolved
- **WHEN** the volunteer dashboard has not yet reached confirmed intake readiness
- **THEN** the UI SHALL communicate readiness using explicit status messaging instead of relying on the map's visible center position
