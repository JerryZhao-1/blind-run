## ADDED Requirements

### Requirement: Blind profile screens use backend profile and emergency-contact data
The Flutter application SHALL present blind profile-related settings from the backend blind profile and emergency-contact resources instead of a single locally stored emergency-contact string.

#### Scenario: Blind user opens settings
- **WHEN** the blind user enters the settings flow
- **THEN** the app loads `/api/blind/profile`
- **AND** the app loads the current user's emergency contacts from `/api/users/{userId}/emergency-contacts`

#### Scenario: Blind user updates emergency-contact records
- **WHEN** the blind user creates, edits, deletes, or marks a primary emergency contact
- **THEN** the app uses the corresponding backend emergency-contact endpoint
- **AND** the settings flow refreshes to show the backend-confirmed contact list

### Requirement: Volunteer profile screens use backend volunteer profile data
The Flutter application SHALL present volunteer profile state from the backend volunteer profile instead of locally hard-coded volunteer identity data.

#### Scenario: Volunteer opens the profile tab
- **WHEN** the volunteer enters the profile surface
- **THEN** the app loads `/api/volunteer/profile`
- **AND** the UI renders the backend name, verification status, and other profile-backed fields that are available in production

#### Scenario: Volunteer updates editable profile information
- **WHEN** the volunteer submits editable profile changes supported by the current UI
- **THEN** the app sends those changes to `/api/volunteer/profile`
- **AND** the visible profile state refreshes from the backend response

### Requirement: Profile synchronization coexists with the existing UI structure
The Flutter application SHALL preserve the current page-level flow where feasible while replacing only the data model and actions that previously depended on local mock profile state.

#### Scenario: Existing settings/profile page shells remain in use
- **WHEN** profile synchronization is introduced
- **THEN** the app keeps the current settings and profile entry points
- **AND** the pages replace mock values and local-only actions with backend-backed content and mutations
