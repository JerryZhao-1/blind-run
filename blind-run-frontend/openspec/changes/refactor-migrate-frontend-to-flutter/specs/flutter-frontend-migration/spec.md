## ADDED Requirements
### Requirement: Flutter Dual-Platform Runtime
The system SHALL run as a Flutter application targeting Android and iOS, and SHALL replace the existing React/Vite runtime as the primary application entrypoint.

#### Scenario: Launch mobile app
- **WHEN** the project is built and launched with Flutter
- **THEN** the app starts from the Flutter entrypoint
- **AND** Android and iOS project targets are present in the repository

### Requirement: Local Session And Role Routing
The system SHALL persist the selected user role locally and route users into the correct blind-side or volunteer-side experience without requiring a backend.

#### Scenario: Restore role session
- **WHEN** a user previously selected a role and reopens the app
- **THEN** the app restores that role from local persistence
- **AND** navigates to the matching dashboard automatically

### Requirement: Local Run Lifecycle
The system SHALL manage run requests, acceptance, status transitions, completion, cancellation, and ratings using local repository state.

#### Scenario: Blind runner creates a request
- **WHEN** the blind-side user confirms a new run request
- **THEN** the local repository creates a pending run
- **AND** the blind dashboard shows an active run entry

#### Scenario: Volunteer accepts a request
- **WHEN** the volunteer-side user accepts an available run
- **THEN** the run is assigned locally to the volunteer profile
- **AND** both blind and volunteer experiences reflect the accepted state

#### Scenario: Run finishes
- **WHEN** a running trip is marked complete
- **THEN** the volunteer side shows a completion summary
- **AND** the blind side can submit a rating for the completed trip

### Requirement: Device Speech With Fallback
The system SHALL provide speech output and speech recognition on supported devices, and SHALL fall back to deterministic default behavior when those capabilities are unavailable or denied.

#### Scenario: Speech recognition unavailable
- **WHEN** speech recognition cannot start because of device support, permission, or runtime failure
- **THEN** the request flow uses a default parsed result
- **AND** the user can still complete the booking flow

### Requirement: Map-Based Volunteer Discovery
The system SHALL present volunteer-side nearby run discovery on a map-backed screen with a graceful fallback when map rendering is degraded.

#### Scenario: Map tiles fail
- **WHEN** the volunteer dashboard cannot render remote map tiles
- **THEN** the dashboard still shows nearby run cards and action controls
- **AND** the user can continue the accept flow
