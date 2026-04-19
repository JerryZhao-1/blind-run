# map-experience Specification

## Purpose
TBD - created by archiving change refactor-amap-key-loading. Update Purpose after archive.
## Requirements
### Requirement: Map and Search Features Use Unified AMap Runtime Configuration
The system SHALL drive volunteer map rendering, native location usage, and blind-runner place search from the unified AMap runtime configuration instead of a script-only startup path.

#### Scenario: Volunteer map uses configured native key
- **WHEN** the app runs on Android or iOS with the platform's native AMap key configured through the supported runtime configuration
- **THEN** volunteer-facing map surfaces are eligible to initialize the native AMap SDK

#### Scenario: Place search uses configured Web Service key
- **WHEN** the app has `AMAP_WEB_KEY` configured through the supported runtime configuration
- **THEN** blind-runner place search requests use that key for AMap Web Service calls

### Requirement: Map and Search Continue to Degrade Gracefully When Keys Are Missing
The system SHALL preserve the current diagnosable fallback behavior when AMap runtime configuration is incomplete.

#### Scenario: Native map key is unavailable
- **WHEN** a map screen is opened without the required native AMap key for the current platform
- **THEN** the app does not create the native map view
- **AND** it shows a visible fallback message describing the missing configuration

#### Scenario: Web Service key is unavailable
- **WHEN** a blind runner searches for a place without `AMAP_WEB_KEY`
- **THEN** the app falls back to local demo suggestions
- **AND** the reservation flow remains usable

### Requirement: AMap Documentation Defines Supported Launch Paths and Security Direction
The system SHALL document the supported AMap launch flows after the refactor and SHALL state that client-side Web Service key usage is transitional rather than the long-term security model.

#### Scenario: README explains non-script configuration flow
- **WHEN** a developer follows the AMap setup instructions in the project README
- **THEN** the documented primary flow uses the supported runtime/build configuration without requiring `./scripts/flutter_run_with_amap.sh`
- **AND** any remaining helper script is documented only as compatibility or transition behavior if it still exists

#### Scenario: README explains Web Service security direction
- **WHEN** a developer reads the AMap security guidance in the project README
- **THEN** it states that current client-side `AMAP_WEB_KEY` usage is a short-term implementation choice
- **AND** it identifies server-side proxying as the long-term direction instead of server-issued client keys

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

