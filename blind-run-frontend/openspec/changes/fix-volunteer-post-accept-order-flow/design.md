## Context

The volunteer dashboard now uses live backend data for nearby opportunities and owned orders, but the accept-to-detail handoff is still shaped like the earlier demo flow. A nearby-order preview from `/api/orders/available` can contain pickup coordinates and runner contact preview fields, while `/api/orders/mine` and `/api/orders/{id}` currently provide a narrower detail shape. After a volunteer taps accept, the app posts `/api/orders/{id}/accept`, refreshes order state, and navigates into the active-order page, but the current controller flow does not require backend-confirmed readable ownership before routing.

This creates a contradictory runtime:
- the detail screen can still render a `pendingAccept` presentation sourced from stale available-order preview data
- the same screen can simultaneously show a backend error such as `您无权查看此订单`
- later owned-order/detail payloads can overwrite richer preview fields and drop pickup coordinates, causing the active-order map to fall back to the default Beijing viewport

The change is cross-cutting because it touches accept sequencing, state merging, status interpretation, active-order rendering, and the contract boundary between preview data and volunteer-owned order data.

## Goals / Non-Goals

**Goals:**
- Make the volunteer accept action behave as a backend-confirmed handoff from nearby-order preview to volunteer-owned active order.
- Prevent contradictory post-accept states where the app opens an active-order page that is not yet readable for the volunteer.
- Preserve accepted-order pickup context across refreshes so the active-order map does not regress to a misleading generic fallback.
- Ensure volunteer action buttons and any contact affordance derive from backend-confirmed ownership state rather than stale preview assumptions.
- Keep the fix compatible with current production endpoints while documenting where the backend contract remains incomplete.

**Non-Goals:**
- Redesigning volunteer intake-readiness, location heartbeat, or dashboard current-location behavior.
- Adding new backend endpoints or implementing real-time push updates.
- Reworking blind-side order creation or blind-side accepted-order announcements.
- Implementing a full call experience beyond selecting the supported accepted-order contact entry point.

## Decisions

### Decision: Treat accept-to-detail as an explicit backend-confirmed handoff

The accept button flow should no longer behave as "post, then navigate regardless." Instead, the controller should model a short-lived post-accept handoff state and only route into the active-order detail screen after one of the owned-order reads (`/api/orders/mine` or `/api/orders/{id}`) confirms that the same order is readable for the volunteer.

The expected handoff sequence is:
1. submit `POST /api/orders/{id}/accept`
2. refresh volunteer-owned order state
3. confirm that the accepted order is readable as a volunteer-owned order
4. only then navigate into the active-order page

If the accept call fails, or follow-up reads cannot confirm readable ownership, the volunteer should remain on the dashboard with actionable failure feedback rather than entering a contradictory detail screen.

**Alternatives considered:**
- Keep navigating immediately and rely on the detail page to recover. Rejected because it is the source of the current contradictory `待接单 + 无权查看` experience.
- Introduce a purely optimistic local accepted state before any backend read. Rejected because status and ownership are exactly what is in doubt after accept.

### Decision: Keep `Run` as the main order model, but add a field-preserving merge policy for accepted-order context

The codebase already centers volunteer and blind flows on the shared `Run` model. This change should keep that model, but stop treating every later payload as a complete replacement for every field. Instead, the app should preserve preview-only accepted-order context when a later owned-order/detail payload omits fields that were already known and are still required for continuity, especially:
- pickup latitude/longitude
- pickup address/time label if later payload is thinner
- any temporary accepted-order metadata explicitly marked as preview-derived

Backend-confirmed ownership fields such as status and action eligibility must still override preview assumptions. The preservation rule applies only to fields that maintain continuity when later payloads are incomplete.

**Alternatives considered:**
- Add a second screen-specific view model just for the volunteer active-order page. Rejected because it would fork order logic and increase surface area across controller and tests.
- Continue blindly overwriting runs with the latest payload. Rejected because the current issue is caused by later thinner payloads erasing essential accepted-order context.

### Decision: Separate canonical action state from supplemental map/contact context

After accept, the volunteer active-order screen should derive status labels, next-step buttons, and ownership gating only from backend-confirmed owned-order state. Available-order preview data may help fill map or continuity gaps, but it must not be treated as canonical proof that the volunteer owns the order or may perform next actions.

This split means:
- backend-confirmed owned-order state decides whether the screen is active, blocked, or terminal
- preserved preview context may temporarily support map centering and continuity
- contact entry points must be gated to confirmed ownership rather than raw preview fields surviving by accident

**Alternatives considered:**
- Let any cached `Run` with the same id fully drive the active-order page. Rejected because it lets stale preview data masquerade as owned-order truth.
- Hide all supplemental context until the backend returns a richer detail payload. Rejected because it would keep the active-order map and continuity broken even when the app had already shown valid pickup context before accept.

### Decision: Replace generic Beijing fallback on accepted orders with accepted-order-specific location handling

The volunteer active-order page should prefer accepted-order pickup context over a hard-coded city fallback. If the app has known pickup coordinates from preview or later owned/detail payloads, the map should use them. If no accepted-order coordinates are known from any source, the screen should show an explicit "location unavailable" state instead of implying that Beijing is the confirmed pickup point.

This change is intentionally scoped to accepted-order maps. It does not redefine the volunteer dashboard's current-location map behavior.

**Alternatives considered:**
- Keep the Beijing fallback for all null-coordinate orders. Rejected because it creates a false concrete location that looks like a real pickup point.
- Center the accepted-order page on the volunteer's current device location. Rejected because the active-order page is about the trip pickup context, not dashboard intake location.

### Decision: Leave exact accepted-order contact transport as a contract clarification, but gate it to confirmed ownership

The design should not assume that `blindUserPhone` from `/api/orders/available` remains the long-term accepted-order contract. The backend already exposes `/api/orders/{orderId}/call/initiate`, and owned-order/detail responses may later grow richer contact data. This change therefore treats contact as a confirmed-ownership concern:
- if the supported accepted-order contact path is available for a confirmed owned order, expose it
- if ownership is not yet confirmed, do not expose contact as though it were safe and final

**Alternatives considered:**
- Always carry preview phone fields directly into the active-order flow. Rejected because preview data is not a trustworthy ownership contract.
- Defer all contact decisions to a separate future change. Rejected because the current post-accept flow already blocks an important next step and needs at least a safe gating rule now.

## Risks / Trade-offs

- [Preserved preview fields could outlive their validity] -> Restrict preservation to continuity fields that fill backend payload gaps, and always let backend-confirmed ownership/status override preview assumptions.
- [Backend runtime may return a status shape that still does not match the frontend's `PENDING_ACCEPT`/`IN_PROGRESS` assumption] -> Centralize post-accept status interpretation in the controller/repository layer and validate against production before final rollout.
- [Accepted-order contact may remain underspecified even after this change] -> Gate contact to confirmed ownership and keep the exact transport decision explicit in design/specs instead of letting it happen implicitly through stale fields.
- [Removing the Beijing fallback may reveal more "location unavailable" states] -> Prefer truthful missing-location feedback over a false concrete map position.

## Migration Plan

1. Add the spec deltas that define post-accept handoff, owned-order refresh behavior, and accepted-order map continuity.
2. Update volunteer order repository/controller logic so accept returns a backend-confirmed handoff result rather than only mutating global error state.
3. Introduce the field-preserving merge behavior needed to keep accepted-order pickup context when later payloads are incomplete.
4. Rework volunteer dashboard accept navigation and active-order rendering to use confirmed ownership state for gating and preserved pickup context for continuity.
5. Validate manual flows for accept success, accept rejection, unreadable follow-up detail, incomplete owned-order payloads, and accepted-order contact readiness.

Rollback can remove the explicit handoff gating and field-preserving merge logic while leaving existing intake-readiness and dashboard current-location work intact. The change does not depend on new backend endpoints or data migrations.

## Open Questions

- Does production return `IN_PROGRESS`, `PENDING_ACCEPT`, or another transition shape immediately after a successful volunteer accept, and does that differ between `/api/orders/mine` and `/api/orders/{id}`?
- Can production owned-order/detail responses be expanded to include pickup coordinates and accepted-order contact context, or must the frontend preserve preview-derived continuity fields indefinitely?
- Should the first accepted-order contact affordance use `/api/orders/{orderId}/call/initiate`, direct phone exposure, or both once ownership is confirmed?
