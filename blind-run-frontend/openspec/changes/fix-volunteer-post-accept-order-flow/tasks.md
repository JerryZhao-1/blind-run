## 1. Post-Accept State And Data Contract

- [x] 1.1 Verify the production runtime shapes for `POST /api/orders/{id}/accept`, `/api/orders/mine?role=VOLUNTEER`, and `/api/orders/{id}` so the volunteer handoff logic maps the real accepted-order status sequence.
- [x] 1.2 Update volunteer order parsing and merge behavior so backend-confirmed ownership fields override preview assumptions while accepted-order continuity fields such as pickup coordinates are preserved when later payloads are thinner.
- [x] 1.3 Rework the controller accept flow to return a backend-confirmed handoff result instead of navigating purely through global error side effects.

## 2. Volunteer Handoff And Active-Order UI

- [x] 2.1 Update the volunteer dashboard accept interaction so the app only routes into the active-order screen after readable owned-order confirmation and otherwise keeps the volunteer in the nearby-order flow with explicit failure feedback.
- [x] 2.2 Update the volunteer active-order screen so status copy and next-step buttons derive from backend-confirmed accepted-order state rather than stale nearby-order preview state.
- [x] 2.3 Replace the accepted-order Beijing fallback with preserved pickup context or an explicit location-unavailable state when no accepted-order coordinates are known.
- [x] 2.4 Gate any accepted-order contact affordance to backend-confirmed ownership and the supported accepted-order contact path.

## 3. Verification

- [x] 3.1 Add or update tests for accept success, accept rejection or unreadable follow-up detail, preserved pickup coordinates across thinner owned-order payloads, and accepted-order status gating.
- [ ] 3.2 Manually validate volunteer flows for accept success, accept failure, ambiguous ownership after accept, incomplete detail payloads, contact readiness, and the absence of Beijing fallback on accepted orders with known pickup context.
