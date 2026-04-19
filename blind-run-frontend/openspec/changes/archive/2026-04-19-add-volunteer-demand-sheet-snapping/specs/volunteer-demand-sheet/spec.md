## ADDED Requirements

### Requirement: Volunteer Map Uses Three Snap States For The Demand Sheet
The system SHALL render the volunteer dashboard demand sheet as a persistent bottom sheet with exactly three snap states: lower at `0.22` of the available body height, middle at `0.56`, and upper at `0.86`.

#### Scenario: Dashboard opens in the middle state
- **WHEN** a volunteer opens the map tab on the dashboard
- **THEN** the demand sheet opens in the middle snap state
- **AND** the map remains visible above the sheet

#### Scenario: Sheet snaps only to defined states
- **WHEN** the volunteer drags or flings the demand sheet and releases it
- **THEN** the sheet settles only at the lower, middle, or upper snap state
- **AND** it does not remain at an arbitrary intermediate height

### Requirement: Each Snap State Exposes State-Specific Content Density
The system SHALL vary the demand sheet content by snap state so each state supports a distinct task mode instead of showing the same full layout at different heights.

#### Scenario: Lower state prioritizes map browsing
- **WHEN** the demand sheet is in the lower snap state
- **THEN** the sheet shows the drag handle and demand count header
- **AND** it shows exactly one compact status summary for either the active run or the highest-priority pending demand
- **AND** it does not expose the full scrollable demand list

#### Scenario: Middle state supports demand decisions
- **WHEN** the demand sheet is in the middle snap state
- **THEN** the sheet shows the demand count header
- **AND** it shows the active-run entry when an active run exists
- **AND** it shows the demand list with full demand cards and accept actions

#### Scenario: Upper state prioritizes list browsing
- **WHEN** the demand sheet is in the upper snap state
- **THEN** the sheet keeps the drag handle and demand count header visible as a sticky header
- **AND** it exposes the full scrollable demand list
- **AND** the map remains only as a narrow visible strip above the sheet

### Requirement: Sheet Dragging, List Scrolling, And Map Gestures Are Coordinated
The system SHALL coordinate gesture ownership between the demand sheet, its internal list, and the map so that drag behavior is deterministic.

#### Scenario: Header drag always moves the sheet
- **WHEN** the volunteer starts a drag on the sheet handle or header area
- **THEN** the gesture moves the sheet between snap states
- **AND** the gesture does not scroll the internal list or pan the map

#### Scenario: List does not scroll before the sheet reaches the upper state
- **WHEN** the volunteer drags upward inside the sheet content while the sheet is in the lower or middle state
- **THEN** the gesture raises the sheet toward the next snap state
- **AND** it does not start free scrolling of the demand list first

#### Scenario: Downward drag from upper state waits for list top
- **WHEN** the demand sheet is in the upper state and the internal demand list is scrolled away from the top
- **THEN** a downward drag scrolls the list upward toward offset zero
- **AND** the sheet does not collapse until the internal list returns to the top

#### Scenario: Map receives gestures only outside the sheet
- **WHEN** the volunteer starts a gesture inside the visible sheet bounds
- **THEN** the gesture is handled by the sheet or its internal content
- **AND** the underlying map does not receive that gesture

### Requirement: Map Markers And Sheet Content Stay In Sync
The system SHALL keep marker interaction and sheet content aligned without changing the existing navigation flow for demand cards or active runs.

#### Scenario: Marker tap expands the sheet to a decision-ready state
- **WHEN** the volunteer taps a pending-demand marker while the sheet is in the lower snap state
- **THEN** the sheet expands to the middle snap state
- **AND** the corresponding demand card is brought into view in the sheet

#### Scenario: Demand card tap keeps existing navigation behavior
- **WHEN** the volunteer taps a demand card or the active-run entry from any snap state where that control is visible
- **THEN** the app follows the existing navigation behavior for accepting or resuming that run
- **AND** the tap does not require an additional sheet state transition first
