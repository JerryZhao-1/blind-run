## ADDED Requirements

### Requirement: Demo showcase mode provides deterministic map and location behavior
The system SHALL allow presentation showcase mode to keep map and location surfaces deterministic while still rendering believable real AMap visuals from curated fixed points.

#### Scenario: Presentation showcase mode starts on the prepared demo environment
- **WHEN** the app runs in presentation showcase mode with valid AMap configuration
- **THEN** map surfaces SHALL render through real AMap APIs using the curated fixed-point scenario data
- **AND** the presenter SHALL see believable map tiles and markers instead of placeholder fallback content

#### Scenario: Volunteer showcase needs current-location context
- **WHEN** a volunteer showcase scenario includes prepared current-location context
- **THEN** the dashboard and active-order surfaces SHALL use the selected scenario's deterministic fixed location data
- **AND** the showcase SHALL not depend on live device location drift before rendering that flow

#### Scenario: Blind showcase needs place-search and map context
- **WHEN** a blind showcase scenario includes curated destination points
- **THEN** place search, order summary, and map surfaces SHALL resolve to the prepared fixed points for that scenario
- **AND** the visual output SHALL remain consistent across repeated rehearsals on the same demo environment
