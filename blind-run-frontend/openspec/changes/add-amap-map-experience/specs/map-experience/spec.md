## ADDED Requirements
### Requirement: Volunteer Map Uses AMap
The system SHALL render volunteer-facing map surfaces with AMap on Android and iOS when valid native AMap keys are configured.

#### Scenario: Volunteer dashboard shows pending runs on AMap
- **WHEN** a volunteer opens the dashboard map tab and native AMap keys are available
- **THEN** the app displays an AMap map surface
- **AND** pending run markers are rendered using each run's stored latitude and longitude

#### Scenario: Volunteer run details center on run destination
- **WHEN** a volunteer opens a run detail page for a run with coordinates
- **THEN** the map centers on that run destination
- **AND** the destination marker remains visible in both active and completed states

### Requirement: Blind Runner Selects Place From Search Results
The system SHALL let blind runners search a destination by voice or text and choose from a candidate list before creating a run.

#### Scenario: Voice search returns a place candidate list
- **WHEN** the blind runner speaks a destination keyword on the place search page
- **THEN** the app performs a place search
- **AND** shows selectable candidate places with name and address

#### Scenario: Text search returns a place candidate list
- **WHEN** the blind runner enters a destination keyword in text
- **THEN** the app performs a place search
- **AND** shows selectable candidate places with name and address

#### Scenario: Selected place is used to create a run
- **WHEN** the blind runner selects a place and confirms the request
- **THEN** the created run stores the selected place name
- **AND** the created run stores the selected latitude and longitude instead of random mock coordinates

### Requirement: AMap Degrades Gracefully Without Runtime Configuration
The system SHALL provide a diagnosable fallback when AMap keys, privacy consent, or permissions are unavailable.

#### Scenario: Missing AMap native keys on map screen
- **WHEN** a map screen is opened without configured native AMap keys
- **THEN** the app does not attempt to create the native map view
- **AND** it shows a visible fallback message describing the missing configuration

#### Scenario: Search key is unavailable
- **WHEN** the blind runner searches for a place without a configured AMap Web Service key
- **THEN** the app falls back to local demo suggestions
- **AND** the blind runner can still complete the reservation flow
