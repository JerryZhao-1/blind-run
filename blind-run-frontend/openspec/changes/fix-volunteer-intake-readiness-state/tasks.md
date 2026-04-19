## 1. Volunteer Readiness State

- [x] 1.1 Add volunteer intake readiness state to app state/controller logic and separate it from the persisted `volunteerAvailable` preference.
- [x] 1.2 Rework volunteer dashboard startup and heartbeat sequencing so successful location reporting is what marks the volunteer as intake-ready.

## 2. Dashboard Messaging

- [x] 2.1 Update volunteer dashboard top status, empty-state copy, and error rendering to reflect readiness, location failure, and report failure states truthfully.
- [x] 2.2 Ensure heartbeat or refresh failures can downgrade readiness and stop the dashboard from continuing to claim the volunteer is online-ready.

## 3. Map Cues And Verification

- [x] 3.1 Adjust volunteer dashboard map behavior or explanatory copy so the initial fixed viewport is not mistaken for confirmed current-location readiness.
- [ ] 3.2 Verify the volunteer flow manually for permission denied, location timeout, report failure, successful readiness with no nearby orders, and successful readiness with nearby orders.
