## ADDED Requirements

### Requirement: Demo video capture scenes SHALL be selectable through startup configuration
The system SHALL support explicit startup configuration for demo video capture scenes so the app can boot directly into a deterministic volunteer or blind recording checkpoint without exposing recording controls in the visible product UI.

#### Scenario: Launch a volunteer capture scene
- **WHEN** the app is launched with a volunteer demo video capture scene selected
- **THEN** the app SHALL seed the volunteer-side state required for that checkpoint before feature routing begins
- **AND** the app SHALL open the existing volunteer product surface for that checkpoint without showing demo-only scene selectors on-screen

#### Scenario: Launch a blind capture scene
- **WHEN** the app is launched with a blind demo video capture scene selected
- **THEN** the app SHALL seed the blind-side state required for that checkpoint before feature routing begins
- **AND** the app SHALL open the existing blind product surface for that checkpoint without showing demo-only scene selectors on-screen

### Requirement: Demo video capture scenes SHALL remain story-aligned across both roles
The system SHALL keep volunteer-side and blind-side capture scenes aligned around the same curated story anchors so separately recorded clips can be composed into one believable narrative.

#### Scenario: Capture scenes reference the same destination story
- **WHEN** the recording workflow pairs a blind-side request clip with a volunteer-side intake clip
- **THEN** both scenes SHALL reference the same curated destination and address family
- **AND** both scenes SHALL avoid contradictory order details that would make the composed video look inconsistent

#### Scenario: Capture scenes reference compatible order progress states
- **WHEN** the recording workflow pairs later-stage blind and volunteer clips in the same story arc
- **THEN** the seeded statuses, contact visibility, and completion state SHALL be mutually compatible for that editorial pairing

### Requirement: The project SHALL provide a repeatable recording playbook for the final review video
The project SHALL define the clip list, recording order, file naming, and scene-to-story mapping required to capture the source footage for the composed demo video.

#### Scenario: Operator prepares to record the review video
- **WHEN** the operator follows the repository recording playbook
- **THEN** the playbook SHALL identify each required clip by role, capture scene, and expected file name
- **AND** the playbook SHALL describe the intended story order for assembling the final review video

#### Scenario: Operator re-records one broken clip
- **WHEN** a single captured segment needs to be replaced
- **THEN** the playbook SHALL make it possible to re-record that segment without redefining the rest of the video sequence

### Requirement: The project SHALL provide a local composition and export workflow
The project SHALL provide a repeatable local workflow that combines the recorded blind and volunteer clips into one side-by-side review video and exports the final MP4 to the desktop.

#### Scenario: Compose the final split-screen video
- **WHEN** the required source clips are available in the expected local layout
- **THEN** the workflow SHALL generate one composed video file containing both blind-side and volunteer-side panes in a single timeline
- **AND** the final export SHALL be written to a desktop-visible output path suitable for direct sharing

#### Scenario: Composition preserves the product illusion
- **WHEN** the final review video is exported
- **THEN** the composition workflow SHALL not rely on in-app demo labels or capture menus being visible inside the product viewport
