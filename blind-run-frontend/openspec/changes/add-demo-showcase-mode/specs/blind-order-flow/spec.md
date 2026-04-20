## ADDED Requirements

### Requirement: Demo showcase mode can present curated blind order journeys
The Flutter application SHALL support curated blind showcase scenarios that exercise the existing blind request and active-order surfaces from simulated repositories instead of live backend order dependencies.

#### Scenario: Blind showcase starts from a no-active-order scenario
- **WHEN** the presenter enters a blind showcase scenario without an active order
- **THEN** the blind home flow SHALL present a usable request-entry path from simulated data
- **AND** creating the showcase request SHALL advance the blind flow without requiring a live backend order

#### Scenario: Blind showcase starts from an active-order scenario
- **WHEN** the presenter enters a blind showcase scenario with a prepared active order
- **THEN** the blind home and active-order surfaces SHALL render that prepared order state
- **AND** the blind user SHALL be able to continue the presentation without polling the live backend

## MODIFIED Requirements

### Requirement: Blind users can create orders from the accessible request flow
The Flutter application SHALL let an authenticated blind user create an order from the existing accessible request flow by converting the chosen place and time label into backend order fields in normal integration mode, and SHALL preserve an equivalent simulated request flow in demo showcase mode.

#### Scenario: Blind user submits a request with a supported preset time in normal integration mode
- **WHEN** the user chooses a place and submits the request with a supported preset such as `现在出发`, `30分钟后`, `明天上午`, or `今天晚上`
- **THEN** the app converts that preset into `plannedStartTime` and `plannedEndTime`
- **AND** the app creates the order through `POST /api/orders`

#### Scenario: Blind user submits a request from voice-derived time text in normal integration mode
- **WHEN** the user submits a spoken time label outside the supported preset set
- **THEN** the app applies a deterministic fallback conversion rule for backend datetimes
- **AND** the app preserves the readable spoken label for display in the UI

#### Scenario: Blind user completes order creation successfully in normal integration mode
- **WHEN** the backend confirms the order was created successfully
- **THEN** the app returns the user to blind home
- **AND** the home page refreshes the user's orders before rendering the current-order summary

#### Scenario: Blind user completes a simulated request in demo showcase mode
- **WHEN** the presenter submits a blind showcase request
- **THEN** the app SHALL update the prepared showcase order state
- **AND** the blind flow SHALL continue without requiring a live backend response

### Requirement: Blind order creation is gated by emergency-contact readiness
The Flutter application SHALL verify that a blind user has at least one emergency contact before allowing order creation in normal integration mode, and SHALL seed any required contact readiness through the selected showcase scenario in demo showcase mode.

#### Scenario: Blind user has no emergency contacts in normal integration mode
- **WHEN** the request flow is about to submit an order and the backend reports no emergency contacts for the current user
- **THEN** the app blocks order creation
- **AND** the app directs the user to complete emergency-contact setup first

#### Scenario: Blind showcase scenario includes required contact readiness
- **WHEN** the presenter enters a showcase scenario that allows blind request creation
- **THEN** the app SHALL provide the contact state required by that scenario
- **AND** the showcase request flow SHALL not fail solely because live backend emergency contacts were not loaded

### Requirement: Blind active-order status is refreshed from backend order data
The Flutter application SHALL display blind-side active order state from live backend order data in normal integration mode, and SHALL display the selected scenario's simulated order state in demo showcase mode.

#### Scenario: Blind user opens an active order page in normal integration mode
- **WHEN** the blind user enters the active order screen for a backend order
- **THEN** the app fetches the order from `/api/orders/{id}`
- **AND** the screen renders the current backend order status rather than a locally simulated status

#### Scenario: Backend order status changes while the page is open in normal integration mode
- **WHEN** the backend order status changes during polling
- **THEN** the active order screen updates its status presentation and announcements to the new backend state
- **AND** the user does not need a mock testing action to see the transition

#### Scenario: Blind showcase active order changes state
- **WHEN** the presenter advances or re-enters a blind showcase scenario
- **THEN** the active-order screen SHALL reflect the current simulated order state
- **AND** the blind flow SHALL not require live polling to remain usable

### Requirement: Blind home shows the current active order summary from backend data
The Flutter application SHALL treat the blind home page as the primary landing page after order creation and SHALL present the current active order summary from refreshed backend data in normal integration mode, while using the selected showcase scenario state in demo showcase mode.

#### Scenario: Blind user returns to home with an active order in normal integration mode
- **WHEN** the blind user enters the home page and the backend has an active order for that user
- **THEN** the app refreshes `/api/orders/mine`
- **AND** the home page shows the active order status, place, and time summary
- **AND** the home page exposes a primary action that opens the current order detail page

#### Scenario: Blind user enters home without an active order in normal integration mode
- **WHEN** the blind user enters the home page and the backend has no active orders for that user
- **THEN** the app shows that there is no current trip
- **AND** the primary action remains the accessible order creation entry point

#### Scenario: Blind showcase enters home with prepared state
- **WHEN** the presenter opens the blind home flow in demo showcase mode
- **THEN** the home page SHALL show the current simulated trip state for that scenario
- **AND** the primary action path SHALL remain usable without live backend refresh

### Requirement: Blind users can cancel and review orders through live APIs
The Flutter application SHALL let blind users cancel eligible orders and submit a post-run review through live backend APIs in normal integration mode, and SHALL support equivalent simulated showcase actions in demo showcase mode.

#### Scenario: Blind user cancels an active order in normal integration mode
- **WHEN** the current order is still in a cancellable backend state and the user chooses to cancel it
- **THEN** the app submits `POST /api/orders/{id}/cancel`
- **AND** the blind flow refreshes to the backend-confirmed cancelled state

#### Scenario: Blind user reviews a completed order in normal integration mode
- **WHEN** the backend order is completed and no review exists yet
- **THEN** the app submits `POST /api/orders/{id}/review`
- **AND** the completed blind flow reflects that the review has been recorded

#### Scenario: Blind showcase performs a cancel or review action
- **WHEN** the presenter uses a blind showcase action that cancels or completes the simulated trip
- **THEN** the blind flow SHALL update the simulated order and review state consistently
- **AND** the showcase SHALL not require a live backend mutation
