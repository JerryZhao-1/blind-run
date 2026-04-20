## MODIFIED Requirements

### Requirement: Blind profile screens use backend profile and emergency-contact data
The Flutter application SHALL present blind profile-related settings from backend blind profile and emergency-contact resources in normal integration mode, and SHALL present the selected scenario's curated blind profile and emergency-contact data in demo showcase mode.

#### Scenario: Blind user opens settings in normal integration mode
- **WHEN** the blind user enters the settings flow
- **THEN** the app loads `/api/blind/profile`
- **AND** the app loads the current user's emergency contacts from `/api/users/{userId}/emergency-contacts`

#### Scenario: Blind user updates emergency-contact records in normal integration mode
- **WHEN** the blind user creates, edits, deletes, or marks a primary emergency contact
- **THEN** the app uses the corresponding backend emergency-contact endpoint
- **AND** the settings flow refreshes to show the backend-confirmed contact list

#### Scenario: Blind showcase opens settings
- **WHEN** the presenter enters blind settings in demo showcase mode
- **THEN** the page SHALL render the curated blind profile and emergency-contact state for the selected scenario
- **AND** the showcase SHALL not require live backend profile resources before becoming usable

### Requirement: Volunteer profile screens use backend volunteer profile data
The Flutter application SHALL present volunteer profile state from the backend volunteer profile in normal integration mode, and SHALL present the selected scenario's curated volunteer profile state in demo showcase mode.

#### Scenario: Volunteer opens the profile tab in normal integration mode
- **WHEN** the volunteer enters the profile surface
- **THEN** the app loads `/api/volunteer/profile`
- **AND** the UI renders the backend name, verification status, and other profile-backed fields that are available in production

#### Scenario: Volunteer updates editable profile information in normal integration mode
- **WHEN** the volunteer submits editable profile changes supported by the current UI
- **THEN** the app sends those changes to `/api/volunteer/profile`
- **AND** the visible profile state refreshes from the backend response

#### Scenario: Volunteer showcase opens the profile surface
- **WHEN** the presenter enters the volunteer profile or settings surface in demo showcase mode
- **THEN** the page SHALL render the curated volunteer name, verification status, and related profile state for the selected scenario
- **AND** the showcase SHALL not require live backend profile loading before becoming usable
