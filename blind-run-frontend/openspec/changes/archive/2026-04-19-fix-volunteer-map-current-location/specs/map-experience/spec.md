## ADDED Requirements

### Requirement: Volunteer map centers on app-confirmed current location
The Flutter application SHALL allow the volunteer dashboard map to center on the same current location that was successfully acquired for volunteer intake readiness.

#### Scenario: First successful volunteer location fix
- **WHEN** the volunteer dashboard obtains a usable current location for intake readiness
- **THEN** the volunteer map SHALL move its camera to that location
- **AND** the map SHALL not remain on the fixed default Beijing viewport

#### Scenario: Native map controller becomes available after location is known
- **WHEN** the volunteer dashboard has a latest app-level current location before the native map controller is ready
- **THEN** the map SHALL center on that location once the controller is available

### Requirement: Volunteer map exposes latest app-level current location
The Flutter application SHALL show the latest app-level volunteer location on the dashboard map independently of the native blue-dot tracking layer.

#### Scenario: Latest location is available
- **WHEN** the volunteer dashboard has a latest app-level current location
- **THEN** the map SHALL display a current-location marker or equivalent visual cue at that coordinate

#### Scenario: Native blue-dot layer fails independently
- **WHEN** the map plugin's native user-location layer fails but app-level volunteer location succeeds
- **THEN** the dashboard map SHALL still be able to show and center on the app-level current location

### Requirement: Volunteer map avoids heartbeat camera hijacking
The Flutter application SHALL avoid repeatedly moving the volunteer map camera during background heartbeat updates.

#### Scenario: Heartbeat updates location after initial centering
- **WHEN** the volunteer map has already auto-centered for the current page lifetime
- **AND** a later heartbeat obtains a fresh current location
- **THEN** the dashboard SHALL update the latest location data
- **AND** the map SHALL not automatically move the camera again

#### Scenario: Volunteer requests return to current location
- **WHEN** the volunteer selects the dashboard control to return to the latest current location
- **THEN** the map SHALL move its camera to the latest app-level volunteer location
