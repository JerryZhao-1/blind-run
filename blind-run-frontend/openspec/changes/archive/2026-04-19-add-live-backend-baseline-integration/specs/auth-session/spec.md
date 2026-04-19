## ADDED Requirements

### Requirement: SMS login establishes a restorable authenticated session
The Flutter application SHALL allow a user to request an SMS verification code, verify that code, and persist the returned backend session so the app can restore it on the next launch.

#### Scenario: User completes SMS login
- **WHEN** the user submits a valid phone number and verification code
- **THEN** the app sends requests to `/api/auth/send-code` and `/api/auth/verify-code`
- **AND** the app persists the returned token, user identifier, and role for future launches

#### Scenario: Existing session is restored on app launch
- **WHEN** the app starts and a previously saved token exists
- **THEN** the app validates the session with `/api/auth/me`
- **AND** the app restores the authenticated state when the token is still valid

### Requirement: Invalid sessions are cleared and routed back to login
The Flutter application SHALL treat a failed backend session validation as an authentication loss and clear local session state before presenting the login flow.

#### Scenario: Saved token is no longer valid
- **WHEN** `/api/auth/me` returns `401` for a persisted token
- **THEN** the app clears the saved session
- **AND** the user is routed to the unauthenticated login flow

### Requirement: Backend role drives post-login routing
The Flutter application SHALL route authenticated users according to the backend role returned by the live session rather than a locally chosen demo mode.

#### Scenario: User has not selected a role yet
- **WHEN** the verified or restored session reports role `UNSET`
- **THEN** the app routes the user to the role-selection flow
- **AND** the role-selection flow writes the chosen role through `/api/user/role`

#### Scenario: User already has a bound role
- **WHEN** the verified or restored session reports role `BLIND` or `VOLUNTEER`
- **THEN** the app routes the user directly to the corresponding home flow
- **AND** the app does not ask the user to re-select a local role
