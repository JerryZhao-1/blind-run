## ADDED Requirements

### Requirement: Accepted-order maps preserve known pickup coordinates
The Flutter application SHALL preserve known accepted-order pickup coordinates across the volunteer post-accept handoff even when later owned-order payloads are temporarily incomplete.

#### Scenario: Nearby-order preview already contains pickup coordinates
- **WHEN** an available-order preview includes pickup coordinates for an order
- **AND** the volunteer later confirms ownership of that order
- **AND** the first owned-order or detail payload does not include coordinates
- **THEN** the active-order map SHALL continue to use the known pickup coordinates from the accepted-order handoff context

#### Scenario: Backend later provides accepted-order coordinates
- **WHEN** the volunteer has preserved pickup coordinates from the post-accept handoff
- **AND** a later backend-owned order payload provides explicit pickup coordinates for the same order
- **THEN** the active-order map SHALL use the backend-provided accepted-order coordinates after refresh

### Requirement: Accepted-order maps avoid misleading generic fallback viewports
The Flutter application SHALL avoid presenting a generic default map viewport as though it were the confirmed pickup point for an accepted order.

#### Scenario: Accepted-order pickup location is unavailable
- **WHEN** the volunteer has confirmed ownership of an order
- **AND** the app has no pickup coordinates from either preview or owned-order data
- **THEN** the active-order screen SHALL indicate that pickup location is unavailable
- **AND** it SHALL not imply that a generic Beijing fallback is the confirmed accepted-order location

#### Scenario: Accepted-order pickup context is known
- **WHEN** the volunteer active-order flow has known pickup coordinates for the accepted order
- **THEN** the active-order map SHALL center on that pickup context
- **AND** it SHALL not replace it with a generic default city viewport during normal accepted-order refreshes
