## Why

The volunteer flow can surface available nearby orders, but the handoff after tapping accept is not stable. In the current runtime, volunteers can enter a contradictory post-accept state where the detail page still shows a pending-accept presentation, displays a backend error such as `您无权查看此订单`, and loses the order's pickup coordinates so the map falls back to the default Beijing viewport. This blocks the next real volunteer actions, including confirming ownership of the order, contacting the runner, and advancing the trip state.

This issue is adjacent to recent volunteer intake-readiness and dashboard-map work, but it is a separate problem. Those changes make it easier to become intake-ready and see nearby orders; this change focuses on what happens after a volunteer chooses one of those orders.

## What Changes

- Make the volunteer post-accept flow wait for backend-confirmed readable order state before routing into the active-order detail screen.
- Preserve or rehydrate accepted-order pickup context so the volunteer active-order map does not drop to the Beijing fallback when the order already had known coordinates before accept.
- Align volunteer-side accepted-order status presentation and action gating with backend-confirmed state, especially around the `PENDING_ACCEPT` versus `IN_PROGRESS` handoff.
- Clarify the field contract across available-order data, volunteer-owned order data, and order-detail data so the accepted-order screen has the information needed to continue the trip.
- Scope any volunteer contact affordance to the backend-confirmed accepted-order state instead of assuming available-order preview fields remain valid after accept.

## Capabilities

### New Capabilities

- `volunteer-post-accept-handoff`: Represent the volunteer accept-to-detail transition as an explicit backend-confirmed handoff rather than a purely local navigation step.

### Modified Capabilities

- `volunteer-order-flow`: Change how volunteer accept actions, owned-order refresh, accepted-order status copy, and next-step actions behave after an order is taken.
- `map-experience`: Volunteer active-order maps must preserve accepted-order pickup context instead of falling back to a generic default viewport when detail data is incomplete.

## Impact

- Affected code: `lib/app/state/app_state_controller.dart`, `lib/app/state/app_state.dart`, `lib/core/repositories/order_repository.dart`, `lib/core/models/run.dart`, `lib/core/models/run_status.dart`, `lib/features/volunteer/volunteer_dashboard_page.dart`, and `lib/features/volunteer/volunteer_active_run_page.dart`.
- Affected APIs: existing `/api/orders/available`, `/api/orders/mine`, `/api/orders/{id}`, and `/api/orders/{id}/accept` flows; the change may also need to clarify whether existing accepted-order contact should rely on `/api/orders/{orderId}/call/initiate` or on fields already returned by owned-order/detail responses.
- Affected systems: volunteer post-accept navigation, state-merging policy between available and owned orders, accepted-order map centering, volunteer action-button gating, and accepted-order contact readiness.
