## ADDED Requirements

### Requirement: Demo showcase mode boots from explicit startup configuration
The system SHALL support an explicit demo showcase mode that is selected at startup and does not depend on live backend bootstrap success before the app becomes usable.

#### Scenario: App starts in demo showcase mode
- **WHEN** the app is launched with demo showcase mode enabled
- **THEN** the app SHALL install the demo dependency graph before feature routing begins
- **AND** the app SHALL not require live SMS verification, live backend bootstrap, or live map readiness before the presenter can enter a curated scenario

#### Scenario: App starts in normal integration mode
- **WHEN** the app is launched without demo showcase mode enabled
- **THEN** the app SHALL continue using the normal live dependency graph
- **AND** the existing live integration flows SHALL remain unchanged

### Requirement: Demo showcase mode exposes curated blind and volunteer entry points
The system SHALL provide curated entry points for at least one blind showcase journey and at least one volunteer showcase journey.

#### Scenario: Startup configuration selects a volunteer scenario
- **WHEN** the presentation build is launched with the volunteer showcase scenario selected
- **THEN** the app SHALL seed the prepared volunteer session, profile, order, and location state for that scenario
- **AND** the app SHALL route into the existing volunteer product flow without requiring a live login
- **AND** the presenter SHALL not need to go through a visible in-app showcase chooser before the product UI appears

#### Scenario: Startup configuration selects a blind scenario
- **WHEN** the presentation build is launched with the blind showcase scenario selected
- **THEN** the app SHALL seed the prepared blind session, profile, order, and contact state for that scenario
- **AND** the app SHALL route into the existing blind product flow without requiring a live login
- **AND** the presenter SHALL not need to go through a visible in-app showcase chooser before the product UI appears

### Requirement: Presentation showcase UI does not visibly disclose demo mode
The system SHALL allow the presentation branch to run seeded showcase flows without placing explicit demo-only labels, badges, or launcher copy inside the visible product surfaces.

#### Scenario: Presenter records or screenshots the presentation build
- **WHEN** the app is running in the presentation showcase configuration
- **THEN** the visible product UI SHALL not display explicit labels such as `演示模式`
- **AND** the seeded scenario behavior SHALL still remain controlled by startup configuration rather than visible in-app controls

### Requirement: Demo showcase mode uses internally consistent simulated state
The system SHALL keep demo auth, profile, order, and location behavior consistent through a shared simulated state source instead of unrelated hard-coded lists.

#### Scenario: Presenter mutates demo order state
- **WHEN** a showcase action changes the simulated order state, such as volunteer accept or status advancement
- **THEN** all affected demo surfaces SHALL read the updated state from the same simulated source of truth
- **AND** the app SHALL not show contradictory order ownership or status across dashboard, active-order, and history surfaces
