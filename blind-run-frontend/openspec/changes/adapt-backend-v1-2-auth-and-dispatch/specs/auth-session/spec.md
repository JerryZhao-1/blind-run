## ADDED Requirements

### Requirement: SMS login validates backend phone format
The Flutter application SHALL validate SMS login phone numbers against the backend v1.2.0 China mobile format before sending verification-code requests.

#### Scenario: Valid phone number is submitted
- **WHEN** the user submits a phone number matching `^1[3-9]\d{9}$`
- **THEN** the app allows `/api/auth/send-code` and `/api/auth/verify-code` requests to be sent

#### Scenario: Invalid phone number is submitted
- **WHEN** the user submits a phone number that does not match `^1[3-9]\d{9}$`
- **THEN** the app blocks the request locally
- **AND** the app presents an actionable validation message

### Requirement: User logout invalidates backend session
The Flutter application SHALL call the backend user logout endpoint when an authenticated user logs out.

#### Scenario: Authenticated user logs out
- **WHEN** the authenticated user chooses logout
- **THEN** the app sends `POST /api/auth/logout` with the current bearer token
- **AND** the app clears the locally persisted session
- **AND** the app returns to the unauthenticated login flow

#### Scenario: Backend logout request fails
- **WHEN** the user chooses logout and the backend logout request fails
- **THEN** the app still clears the locally persisted session
- **AND** the app returns to the unauthenticated login flow

### Requirement: Authorization failures remain visible without clearing valid sessions
The Flutter application SHALL distinguish backend 403 authorization failures from 401 authentication failures.

#### Scenario: Backend returns 401
- **WHEN** an authenticated request returns HTTP 401
- **THEN** the app treats the session as invalid
- **AND** the app clears local session state before returning to login

#### Scenario: Backend returns 403
- **WHEN** an authenticated request returns HTTP 403 with a backend JSON message
- **THEN** the app preserves the current session
- **AND** the app surfaces the backend permission message to the user

## MODIFIED Requirements

### Requirement: Backend role drives post-login routing
The Flutter application SHALL route authenticated users according to the backend role returned by the live session rather than a locally chosen demo mode, and SHALL persist the replacement role-bearing token returned by backend role selection.

#### Scenario: User has not selected a role yet
- **WHEN** the verified or restored session reports role `UNSET`
- **THEN** the app routes the user to the role-selection flow
- **AND** the role-selection flow writes the chosen role through `/api/user/role`

#### Scenario: User selects a role
- **WHEN** `/api/user/role` succeeds and returns a replacement token
- **THEN** the app replaces the locally persisted token with the returned token
- **AND** subsequent authenticated requests use the replacement token
- **AND** the app routes according to the backend-confirmed role

#### Scenario: User already has a bound role
- **WHEN** the verified or restored session reports role `BLIND` or `VOLUNTEER`
- **THEN** the app routes the user directly to the corresponding home flow
- **AND** the app does not ask the user to re-select a local role
