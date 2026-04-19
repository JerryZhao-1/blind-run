# blind-order-flow Specification

## Purpose
TBD - created by archiving change add-live-backend-baseline-integration. Update Purpose after archive.
## Requirements
### Requirement: Blind users can create orders from the accessible request flow
The Flutter application SHALL let an authenticated blind user create a live backend order from the existing accessible request flow by converting the chosen place and time label into backend order fields, and SHALL return the user to blind home after a successful submission.

#### Scenario: Blind user submits a request with a supported preset time
- **WHEN** the user chooses a place and submits the request with a supported preset such as `现在出发`, `30分钟后`, `明天上午`, or `今天晚上`
- **THEN** the app converts that preset into `plannedStartTime` and `plannedEndTime`
- **AND** the app creates the order through `POST /api/orders`

#### Scenario: Blind user submits a request from voice-derived time text
- **WHEN** the user submits a spoken time label outside the supported preset set
- **THEN** the app applies a deterministic fallback conversion rule for backend datetimes
- **AND** the app preserves the readable spoken label for display in the UI

#### Scenario: Blind user completes order creation successfully
- **WHEN** the backend confirms the order was created successfully
- **THEN** the app returns the user to blind home
- **AND** the home page refreshes the user's orders before rendering the current-order summary

### Requirement: Blind order creation is gated by emergency-contact readiness
The Flutter application SHALL verify that a blind user has at least one backend emergency contact before allowing live order creation.

#### Scenario: Blind user has no emergency contacts
- **WHEN** the request flow is about to submit an order and the backend reports no emergency contacts for the current user
- **THEN** the app blocks order creation
- **AND** the app directs the user to complete emergency-contact setup first

### Requirement: Blind active-order status is refreshed from backend order data
The Flutter application SHALL display blind-side active order state from live backend order data and SHALL remove local mock transitions that simulate volunteer actions.

#### Scenario: Blind user opens an active order page
- **WHEN** the blind user enters the active order screen for a backend order
- **THEN** the app fetches the order from `/api/orders/{id}`
- **AND** the screen renders the current backend order status rather than a locally simulated status

#### Scenario: Backend order status changes while the page is open
- **WHEN** the backend order status changes during polling
- **THEN** the active order screen updates its status presentation and announcements to the new backend state
- **AND** the user does not need a mock testing action to see the transition

### Requirement: Blind home shows the current active order summary from backend data
The Flutter application SHALL treat the blind home page as the primary landing page after order creation and SHALL present the current active order summary from refreshed backend order data.

#### Scenario: Blind user returns to home with an active order
- **WHEN** the blind user enters the home page and the backend has an active order for that user
- **THEN** the app refreshes `/api/orders/mine`
- **AND** the home page shows the active order status, place, and time summary
- **AND** the home page exposes a primary action that opens the current order detail page

#### Scenario: Blind user enters home without an active order
- **WHEN** the blind user enters the home page and the backend has no active orders for that user
- **THEN** the app shows that there is no current trip
- **AND** the primary action remains the accessible order creation entry point

### Requirement: Blind users can cancel and review orders through live APIs
The Flutter application SHALL let blind users cancel eligible live orders and submit a post-run review through the backend APIs.

#### Scenario: Blind user cancels an active order
- **WHEN** the current order is still in a cancellable backend state and the user chooses to cancel it
- **THEN** the app submits `POST /api/orders/{id}/cancel`
- **AND** the blind flow refreshes to the backend-confirmed cancelled state

#### Scenario: Blind user reviews a completed order
- **WHEN** the backend order is completed and no review exists yet
- **THEN** the app submits `POST /api/orders/{id}/review`
- **AND** the completed blind flow reflects that the review has been recorded
