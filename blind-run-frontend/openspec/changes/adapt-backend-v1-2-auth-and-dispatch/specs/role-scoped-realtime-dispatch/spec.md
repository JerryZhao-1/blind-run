## ADDED Requirements

### Requirement: Realtime connections use role-scoped backend endpoints
The Flutter application SHALL connect authenticated users to the backend WebSocket endpoint that matches their backend role.

#### Scenario: Blind user opens a realtime-enabled flow
- **WHEN** the authenticated user role is `BLIND`
- **THEN** the app connects to `/ws/blind?token=<token>` when realtime updates are needed
- **AND** the app uses the current persisted bearer token in the connection URL

#### Scenario: Volunteer user opens a realtime-enabled flow
- **WHEN** the authenticated user role is `VOLUNTEER`
- **THEN** the app connects to `/ws/volunteer?token=<token>` when volunteer dispatch intake is enabled
- **AND** the app uses the current persisted bearer token in the connection URL

#### Scenario: User role and WebSocket endpoint do not match
- **WHEN** the backend rejects a WebSocket connection because the role does not match the endpoint
- **THEN** the app treats the realtime connection as unavailable
- **AND** the app surfaces a recoverable connection state without crashing the current screen

### Requirement: Volunteer intake receives serial dispatch events
The Flutter application SHALL parse backend v1.2.0 volunteer `NEW_ORDER` WebSocket messages into visible dispatch opportunities.

#### Scenario: Volunteer receives a new order event
- **WHEN** the volunteer WebSocket receives a `NEW_ORDER` message with an order id, start address, planned time, distance, timeout, and priority
- **THEN** the volunteer intake surface presents the order as an actionable dispatch opportunity
- **AND** the opportunity remains associated with the dispatch timeout when the backend provides one

#### Scenario: Volunteer receives an unknown WebSocket message
- **WHEN** the volunteer WebSocket receives a message type the app does not understand
- **THEN** the app ignores the message safely
- **AND** the realtime connection remains active

### Requirement: Realtime dispatch connection recovers from transient disconnects
The Flutter application SHALL attempt to reconnect role-scoped WebSocket connections after transient disconnects while the relevant realtime flow remains active.

#### Scenario: Volunteer WebSocket disconnects during intake
- **WHEN** the volunteer realtime connection closes unexpectedly while intake remains enabled
- **THEN** the app schedules a reconnect attempt
- **AND** the volunteer intake surface indicates that realtime dispatch is reconnecting or temporarily unavailable

#### Scenario: User logs out while realtime connection is active
- **WHEN** the authenticated user logs out
- **THEN** the app closes any active role-scoped WebSocket connection
- **AND** the app does not attempt to reconnect using the invalidated token

### Requirement: Volunteer location updates support backend v1.2.0 realtime dispatch
The Flutter application SHALL support the backend v1.2.0 volunteer location-update message contract for realtime dispatch readiness while preserving compatibility with the existing REST location heartbeat during migration.

#### Scenario: Volunteer is online with realtime dispatch connected
- **WHEN** volunteer intake is enabled and the app has a current location
- **THEN** the app can send a WebSocket `LOCATION_UPDATE` message with latitude, longitude, and online status when required by the backend contract

#### Scenario: Realtime location update is unavailable
- **WHEN** the realtime connection is not available during migration
- **THEN** the app may continue using the REST `/api/volunteer/location` heartbeat as a compatibility path
- **AND** the volunteer intake surface does not claim realtime dispatch readiness solely from a failed WebSocket connection
