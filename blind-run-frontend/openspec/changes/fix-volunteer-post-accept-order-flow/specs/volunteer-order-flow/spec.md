## MODIFIED Requirements

### Requirement: Volunteer order actions follow backend status endpoints
The Flutter application SHALL map volunteer order actions to the backend status endpoints that exist in production and SHALL only advance volunteer UI after backend-confirmed accepted-order state is readable.

#### Scenario: Volunteer accepts an available order
- **WHEN** the volunteer chooses to take an available order
- **THEN** the app submits `POST /api/orders/{id}/accept`
- **AND** the volunteer flow SHALL confirm backend-readable owned-order state for that order before routing into the active-order detail screen

#### Scenario: Volunteer accept cannot be confirmed as an owned readable order
- **WHEN** the volunteer chooses to take an available order
- **AND** the backend rejects the accept attempt or follow-up owned-order reads do not confirm readable volunteer ownership for that order
- **THEN** the app SHALL keep the volunteer in the nearby-order intake flow or return them there
- **AND** the UI SHALL show failure feedback instead of opening a contradictory accepted-order page

#### Scenario: Volunteer advances an accepted order toward service completion
- **WHEN** the volunteer marks progress on an accepted order
- **THEN** the app uses the production endpoints for en-route, arrived, and finish transitions
- **AND** the UI labels and action-button gating SHALL reflect the backend-confirmed status after refresh

### Requirement: Volunteer pages refresh from backend data without local mock progression
The Flutter application SHALL remove local volunteer-side order simulation and SHALL use polling to keep active order details and history current, while preventing stale nearby-order preview data from becoming the canonical accepted-order state.

#### Scenario: Volunteer opens an active order page
- **WHEN** the volunteer enters the active order screen
- **THEN** the app fetches live order detail for that order
- **AND** the action buttons available on the page match the current backend status
- **AND** the screen SHALL not treat an available-order preview snapshot by itself as proof of accepted-order ownership

#### Scenario: Owned-order refresh is temporarily incomplete
- **WHEN** the volunteer has already confirmed ownership of an accepted order
- **AND** a later owned-order or detail response omits fields that were already known from the accepted-order preview
- **THEN** the active-order flow SHALL preserve the continuity fields needed to keep the accepted-order screen usable
- **AND** the UI SHALL not regress to a misleading pending-accept or generic-location state solely because the later payload is thinner

#### Scenario: Volunteer reviews completed work in history
- **WHEN** the volunteer opens the dashboard history tab
- **THEN** the app shows completed or cancelled orders sourced from `/api/orders/mine?role=VOLUNTEER`
- **AND** the list is ordered using refreshed backend data rather than seeded demo runs
