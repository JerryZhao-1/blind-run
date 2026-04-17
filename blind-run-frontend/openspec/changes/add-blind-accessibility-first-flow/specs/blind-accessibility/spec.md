## ADDED Requirements
### Requirement: Blind Core Flow Is Operable Without Vision
The system SHALL let blind users complete the blind-side booking, destination selection, departure time setup, active run tracking, and trip rating flow without depending on visual understanding.

#### Scenario: Blind runner completes a booking from the blind homepage
- **WHEN** the blind runner enters the blind homepage and starts a new booking
- **THEN** the primary action is announced with a clear non-visual description
- **AND** the runner can complete destination selection, departure time setup, and booking submission without relying on visual cues

#### Scenario: Blind runner continues from the active run page
- **WHEN** the blind runner opens the active run page during an ongoing trip
- **THEN** the current status is announced
- **AND** the runner can continue to the next relevant action without requiring visual tracking of the screen

### Requirement: Blind Screens Expose Complete Screen Reader Semantics
The system SHALL expose explicit screen reader semantics for blind-side titles, buttons, inputs, place candidates, and status cards in a stable navigation order.

#### Scenario: Homepage primary action is announced as an action
- **WHEN** the blind homepage is focused by a screen reader
- **THEN** the primary action is read as a meaningful booking action
- **AND** it is not described only by iconography or visual position

#### Scenario: Place results are readable and selectable
- **WHEN** the blind runner reviews place candidates on the place search page
- **THEN** each candidate reads its place name and address
- **AND** each candidate exposes a clear “select this place” action

#### Scenario: Active run status and actions remain understandable
- **WHEN** the blind runner uses the active run page with a screen reader
- **THEN** the current run status, trip details, and next actions remain understandable through semantics

### Requirement: Voice Input Has Guided States And Manual Fallback
The system SHALL expose guided voice input states for place search and departure time entry, and SHALL always provide a manual fallback path.

#### Scenario: Voice place search returns candidates
- **WHEN** the blind runner starts voice place search and a place name is recognized successfully
- **THEN** the system announces that search is in progress
- **AND** it returns a readable list of place candidates

#### Scenario: Voice time input fails but the runner can continue manually
- **WHEN** voice time entry fails because nothing is recognized
- **THEN** the system announces the failure
- **AND** the runner can still continue by selecting a manual preset time option

#### Scenario: Voice input is unavailable on the device
- **WHEN** speech recognition is unavailable because of permissions, device capability, or runtime state
- **THEN** the system announces that voice input is unavailable
- **AND** it directs the runner to continue with manual text or preset input

### Requirement: Critical State Changes Are Announced
The system SHALL announce blind-side status transitions for booking submission, volunteer acceptance, volunteer arrival, run start, run completion, cancellation, and other blocking errors.

#### Scenario: Runner hears the volunteer accepted state
- **WHEN** a pending trip transitions to accepted
- **THEN** the blind runner hears that a volunteer has accepted the trip without needing to look at the screen

#### Scenario: Runner hears the trip completion state
- **WHEN** the run transitions to completed
- **THEN** the blind runner hears that the run is complete
- **AND** the system directs the runner to the rating action

### Requirement: AI Voice Entry Is Consistent And Non-Blocking
The system SHALL render a fixed-position AI voice assistant placeholder entry on all blind-side core screens, and SHALL keep the current flow fully operable without that capability.

#### Scenario: AI entry appears in a consistent position
- **WHEN** the blind runner visits any blind-side core screen
- **THEN** the AI voice assistant placeholder entry appears in the same fixed bottom position

#### Scenario: AI entry announces a placeholder message
- **WHEN** the blind runner activates the AI voice assistant entry
- **THEN** the system announces that the feature is coming soon
- **AND** the runner remains on the current screen and can continue the existing task
