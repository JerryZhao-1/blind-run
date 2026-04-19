## ADDED Requirements

### Requirement: Volunteer accept action completes a backend-confirmed handoff
The Flutter application SHALL treat the volunteer accept flow as a backend-confirmed handoff from a nearby-order preview into a volunteer-owned active order rather than as an immediate local navigation step.

#### Scenario: Volunteer accepts an order and ownership becomes readable
- **WHEN** the volunteer chooses to accept an available order
- **AND** the backend accept call succeeds
- **AND** the app can confirm volunteer-readable owned-order state for the same order from `/api/orders/mine` or `/api/orders/{id}`
- **THEN** the app SHALL route the volunteer into the active-order detail screen
- **AND** the active-order screen SHALL reflect the confirmed owned-order state rather than the nearby-order preview state

#### Scenario: Volunteer accept cannot be confirmed as readable owned-order state
- **WHEN** the volunteer chooses to accept an available order
- **AND** the accept call fails or follow-up owned-order reads cannot confirm volunteer-readable ownership for that order
- **THEN** the app SHALL keep the volunteer in the nearby-order intake flow or return them there
- **AND** the app SHALL show an explicit failure state instead of opening a contradictory active-order detail screen

### Requirement: Accepted-order handoff preserves required pickup context
The Flutter application SHALL preserve accepted-order pickup context across the preview-to-owned handoff when later owned-order payloads are temporarily incomplete.

#### Scenario: Preview contains pickup coordinates but owned-order payload is thinner
- **WHEN** an available-order preview already includes pickup coordinates for an order
- **AND** the volunteer later confirms ownership of that order
- **AND** a follow-up owned-order or detail payload omits those coordinates
- **THEN** the active-order flow SHALL preserve the known pickup coordinates for continuity
- **AND** the map SHALL continue to use that accepted-order pickup context

#### Scenario: No accepted-order pickup context is known
- **WHEN** the volunteer has confirmed ownership of an order
- **AND** neither preview data nor owned-order/detail data provides pickup coordinates
- **THEN** the active-order screen SHALL present location as unavailable
- **AND** it SHALL not imply that a generic default city viewport is the confirmed pickup location

### Requirement: Accepted-order contact availability follows confirmed ownership
The Flutter application SHALL expose accepted-order contact only from a backend-confirmed ownership state and supported accepted-order contact contract.

#### Scenario: Confirmed accepted order has a supported contact path
- **WHEN** the volunteer has backend-confirmed ownership of an accepted order
- **AND** the accepted-order flow has a supported contact path for that order
- **THEN** the active-order screen SHALL expose a contact affordance for the volunteer

#### Scenario: Ownership is not yet confirmed
- **WHEN** the volunteer is still in a failed or ambiguous post-accept handoff state
- **THEN** the app SHALL not expose contact as though accepted-order ownership were already confirmed
