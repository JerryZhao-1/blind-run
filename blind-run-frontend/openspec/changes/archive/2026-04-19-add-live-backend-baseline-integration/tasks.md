## 1. Session And API Foundation

- [x] 1.1 Add a centralized HTTP API client with Bearer token injection, base URL configuration, timeouts, and normalized error parsing.
- [x] 1.2 Replace local role-only persistence with a restorable auth session store for token, user ID, and backend role.
- [x] 1.3 Add auth repositories and controller logic for send-code, verify-code, session restore, `/api/auth/me` validation, logout, and `/api/user/role`.
- [x] 1.4 Update root routing so unauthenticated users see login, authenticated `UNSET` users see role selection, and authenticated role-bound users land in the correct home flow.

## 2. Backend-Aligned Domain Models

- [x] 2.1 Introduce backend-aligned models for current user, order summary/detail, order status, profile data, emergency contacts, and reviews.
- [x] 2.2 Remove demo-user and seeded-run assumptions from app state and replace them with async repository-backed state.
- [x] 2.3 Add deterministic blind-side time-label conversion utilities for backend `plannedStartTime` and `plannedEndTime`.

## 3. Blind-Side Live Flow

- [x] 3.1 Rework the blind request flow to verify emergency-contact readiness, create orders through `/api/orders`, and route into a live active-order screen.
- [x] 3.2 Rework the blind active-order screen to poll `/api/orders/{id}`, remove mock volunteer transitions, and reflect backend cancellation/review behavior.
- [x] 3.3 Update blind settings/profile surfaces to load and mutate `/api/blind/profile` plus emergency-contact CRUD and primary-contact actions.

## 4. Volunteer-Side Live Flow

- [x] 4.1 Rework the volunteer dashboard to load nearby opportunities from `/api/orders/available` and personal active/history state from `/api/orders/mine?role=VOLUNTEER`.
- [x] 4.2 Add volunteer availability and location-heartbeat behavior backed by `/api/volunteer/location`, including online/offline transitions.
- [x] 4.3 Rework the volunteer active-order flow so accept, en-route, arrived, and finish actions use the production order endpoints and refresh from backend state.
- [x] 4.4 Update volunteer profile surfaces to load and mutate `/api/volunteer/profile` instead of local hard-coded identity data.

## 5. Verification And Documentation

- [x] 5.1 Update widget and repository tests to cover auth bootstrap, blind order gating, volunteer heartbeat behavior, and backend-backed page rendering.
- [x] 5.2 Document the production API contract assumptions, excluded flows, and known runtime drifts that the implementation must tolerate.
- [x] 5.3 Validate the OpenSpec change with `openspec validate add-live-backend-baseline-integration --strict --no-interactive`.
