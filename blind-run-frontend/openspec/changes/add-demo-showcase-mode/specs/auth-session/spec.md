## ADDED Requirements

### Requirement: Demo showcase mode can seed a prepared authenticated session
The Flutter application SHALL allow demo showcase mode to bootstrap a prepared authenticated session and role without requiring live SMS verification.

#### Scenario: Demo mode starts before any live login
- **WHEN** the app starts in demo showcase mode
- **THEN** the app SHALL create the prepared session, current-user, and role state from the selected showcase scenario
- **AND** the app SHALL not block on `/api/auth/send-code`, `/api/auth/verify-code`, or `/api/auth/me`

## MODIFIED Requirements

### Requirement: Backend role drives post-login routing
The Flutter application SHALL route users according to the backend role returned by the live session in normal integration mode, and according to the prepared showcase role selected by the presenter in demo showcase mode.

#### Scenario: User has not selected a role yet in normal integration mode
- **WHEN** the verified or restored live session reports role `UNSET`
- **THEN** the app routes the user to the role-selection flow
- **AND** the role-selection flow writes the chosen role through `/api/user/role`

#### Scenario: User already has a bound role in normal integration mode
- **WHEN** the verified or restored live session reports role `BLIND` or `VOLUNTEER`
- **THEN** the app routes the user directly to the corresponding home flow
- **AND** the app does not ask the user to re-select a local role

#### Scenario: Presenter selects a blind showcase role
- **WHEN** demo showcase mode seeds a blind scenario
- **THEN** the app routes directly to the blind flow
- **AND** the router SHALL not require a live backend role lookup before entering that flow

#### Scenario: Presenter selects a volunteer showcase role
- **WHEN** demo showcase mode seeds a volunteer scenario
- **THEN** the app routes directly to the volunteer flow
- **AND** the router SHALL not require a live backend role lookup before entering that flow
