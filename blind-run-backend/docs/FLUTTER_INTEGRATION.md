# Blind Running Companion Flutter Integration Guide

## Summary

This document explains how a Flutter native app should integrate with the current backend implementation in this repository.

- Backend stack: Spring Boot 3.4.4, Java 17, MySQL, Redis, WebSocket
- Default base URL: `http://localhost:8081`
- Authentication: JWT Bearer token
- Real-time path for volunteers: `ws://<host>:8081/ws/volunteer?token=<jwt>`
- Primary client type: Flutter native app, not browser Web

This guide is intentionally based on the current code, not on an idealized API contract. Where the current implementation has quirks or inconsistencies, they are called out explicitly so the Flutter client can adapt safely.

## Local Backend Prerequisites

Before Flutter integration testing, the backend needs:

- Java 17
- MySQL on `localhost:3306`
- Database named `spring_demo`
- Redis on `localhost:6379`
- Backend port `8081`

Relevant runtime config is in `src/main/resources/application.properties`.

## Authentication Flow

### Login

1. Call `POST /api/auth/send-code`
2. Call `POST /api/auth/verify-code`
3. Persist `{ token, userId, role }`
4. On app launch, read the token from secure storage
5. Call `GET /api/auth/me` to verify the token is still valid

### Request Header

All protected REST endpoints require:

```http
Authorization: Bearer <token>
```

### Token Storage

Flutter should store the token with `flutter_secure_storage`.

Suggested client behavior:

- Persist token, `userId`, and `role`
- Treat `401` from `/api/auth/me` as session invalidation
- Clear local auth state when the session becomes invalid

### App Routing After Login

The backend returns a role in both `/api/auth/verify-code` and `/api/auth/me`.

- `UNSET`: route to role selection
- `BLIND`: route to blind user home flow
- `VOLUNTEER`: route to volunteer home flow

## API Contract by Feature

### 1. Role Setup

Endpoint:

- `POST /api/user/role`

Request:

```json
{
  "role": "BLIND"
}
```

Allowed values:

- `BLIND`
- `VOLUNTEER`

Important behavior:

- New users default to `UNSET`
- Role selection is one-time only
- Backend auto-creates an empty profile after role selection

### 2. Blind Profile

Endpoints:

- `GET /api/blind/profile`
- `PUT /api/blind/profile`

Model:

```json
{
  "name": "张三",
  "emergencyContactName": "李四",
  "emergencyContactPhone": "13800138000",
  "emergencyContactRelation": "家属",
  "runningPace": "慢跑",
  "specialNeeds": "需要口头方向提示"
}
```

Update response shape:

```json
{
  "success": true,
  "data": {
    "name": "张三",
    "emergencyContactName": "李四",
    "emergencyContactPhone": "13800138000",
    "emergencyContactRelation": "家属",
    "runningPace": "慢跑",
    "specialNeeds": "需要口头方向提示"
  }
}
```

### 3. Volunteer Profile

Endpoints:

- `GET /api/volunteer/profile`
- `PUT /api/volunteer/profile`

Model:

```json
{
  "name": "志愿者A",
  "verificationStatus": "NONE",
  "availableTimeSlots": [
    {
      "dayOfWeek": "MONDAY",
      "startTime": "09:00",
      "endTime": "11:00"
    }
  ]
}
```

Important behavior:

- `availableTimeSlots` is fully replaced on update
- It is not appended incrementally
- Flutter should submit the full intended schedule each time

Verification states exposed by the backend:

- `NONE`
- `PENDING`
- `APPROVED`
- `REJECTED`

Current implementation detail:

- Uploading a verification file immediately sets the volunteer to `APPROVED`
- Flutter should still model all four states so the UI remains compatible with future backend changes

### 4. Volunteer Verification Upload

Endpoint:

- `POST /api/volunteer/verification`

Content type:

- `multipart/form-data`

Field name:

- `file`

Example success response:

```json
{
  "success": true,
  "status": "APPROVED"
}
```

Current limitation:

- The backend stores the file and internal path
- It does not expose a public file URL
- It does not provide an API to fetch or preview the uploaded document

Flutter implication:

- Treat this endpoint as submit-only
- Do not build a "preview uploaded verification document" feature against the current backend

### 5. Volunteer Location Reporting

Endpoint:

- `POST /api/volunteer/location`

Request:

```json
{
  "latitude": 39.9042,
  "longitude": 116.4074,
  "isOnline": true
}
```

Success response:

```json
{
  "success": true
}
```

Runtime behavior:

- Backend writes the latest location to both MySQL and Redis
- Redis TTL is 30 seconds
- If the volunteer stops reporting, Redis entry expires and the volunteer is effectively offline for matching

Recommended Flutter behavior:

- Send a heartbeat every 10 to 15 seconds while the volunteer is available for orders
- Send `isOnline=false` when the volunteer leaves the order-taking screen, disables availability, or the app is about to stop its foreground availability flow

### 6. Orders

Endpoints:

- `POST /api/orders`
- `POST /api/orders/{id}/accept`
- `POST /api/orders/{id}/reject`
- `POST /api/orders/{id}/finish`
- `POST /api/orders/{id}/cancel`
- `GET /api/orders/{id}`
- `GET /api/orders/mine`
- `GET /api/orders/available`

Create order request:

```json
{
  "startLatitude": 39.9042,
  "startLongitude": 116.4074,
  "startAddress": "朝阳公园南门",
  "plannedStartTime": "2026-04-10T18:30:00",
  "plannedEndTime": "2026-04-10T19:30:00"
}
```

Create order response:

```json
{
  "id": 1001,
  "status": "PENDING_MATCH",
  "message": "订单已提交，正在匹配志愿者"
}
```

Order states:

- `PENDING_MATCH`
- `PENDING_ACCEPT`
- `IN_PROGRESS`
- `COMPLETED`
- `CANCELLED`

State progression in the current backend:

- `PENDING_MATCH -> PENDING_ACCEPT`
- `PENDING_ACCEPT -> IN_PROGRESS`
- `IN_PROGRESS -> COMPLETED`
- `PENDING_MATCH -> CANCELLED`
- `PENDING_ACCEPT -> CANCELLED`
- `IN_PROGRESS -> CANCELLED`

Important validation rules:

- `plannedEndTime` must be after `plannedStartTime`
- `plannedStartTime` must be after the current backend time
- A blind user cannot create a new order while another order is still active
- A volunteer must be verified before accepting an order

### 7. My Orders

Endpoint:

- `GET /api/orders/mine?role=<BLIND|VOLUNTEER>&status=<optional>&page=0&size=10`

Important behavior:

- `role` is mandatory
- Backend does not infer `role` from the JWT
- Flutter must send either `BLIND` or `VOLUNTEER`

Response type:

- Native Spring `Page` JSON

Flutter should map at least:

- `content`
- `totalElements`
- `totalPages`
- `number`
- `size`

### 8. Available Orders

Endpoint:

- `GET /api/orders/available`

Important behavior:

- The volunteer must have already reported an online location
- If not, backend returns an empty array rather than an error

Flutter implication:

- Do not assume an empty list means "no orders exist"
- It may also mean "this volunteer has not reported location yet"

### 9. Reviews

Endpoints:

- `POST /api/orders/{id}/review`
- `GET /api/orders/{id}/reviews`

Review create request:

```json
{
  "rating": 5,
  "comment": "很专业，很耐心"
}
```

Important behavior:

- Only the blind user of the order can create the review
- The order must be `COMPLETED`
- Each order can only be reviewed once

## WebSocket Integration

### Endpoint

```text
ws://<host>:8081/ws/volunteer?token=<jwt>
```

### Intended Client

- Volunteer app only

### Current Message Type

The backend currently pushes `NEW_ORDER` messages.

Example payload:

```json
{
  "type": "NEW_ORDER",
  "orderId": 1001,
  "blindUserPhone": "138****8000",
  "startAddress": "朝阳公园南门",
  "distanceKm": 1.8,
  "plannedStart": "2026-04-10T18:30:00",
  "plannedEnd": "2026-04-10T19:30:00"
}
```

### Recommended Flutter Behavior

- Use WebSocket as an event notifier, not as the only source of truth
- On `NEW_ORDER`, update local UI state and optionally refresh `GET /api/orders/available`
- Reconnect when the socket drops
- Treat WebSocket failure as non-fatal as long as HTTP polling remains available

## Error Handling Strategy for Flutter

The current backend does not have one fully consistent error format. Flutter should normalize errors into a single internal failure model.

Suggested client-side model:

```text
ApiFailure {
  httpStatus,
  businessCode,
  message,
  rawBody
}
```

### Error shape 1: legacy format

```json
{
  "error": "验证码错误或已过期"
}
```

### Error shape 2: newer format

```json
{
  "success": false,
  "code": 409,
  "message": "您有进行中的订单，请完成后再下单"
}
```

### Error shape 3: Spring Security 401

Possible body:

- plain text
- empty body

Recommended normalization rules:

- If JSON contains `message`, use it
- Else if JSON contains `error`, use it
- Else if HTTP status is `401`, surface a generic "登录已失效，请重新登录"
- Preserve the raw response body for debugging

## Time Handling

Current backend fields use Java `LocalDateTime` and serialize as strings like:

```text
2026-04-10T18:30:00
```

This means:

- No explicit timezone is embedded in the payload
- Flutter should not force UTC conversion on receipt
- Flutter should parse with local `DateTime.parse` behavior and treat these values as local business time

Product implication:

- Backend and device timezone should be aligned during testing
- If backend timezone policy changes later, the Flutter parser strategy should be revisited

## Current Backend Quirks the Client Must Handle

### Reject does not remove the order

`POST /api/orders/{id}/reject` currently logs the action but does not change order state.

Flutter implication:

- After a volunteer rejects an order, that same order may still appear in `/api/orders/available`
- Client UI should not assume rejection permanently removes the order from server results

### Order detail is restricted before acceptance

`GET /api/orders/{id}` only allows:

- the blind user who created the order
- the volunteer who has already accepted the order

Flutter implication:

- A volunteer cannot use this endpoint to inspect a new order before acceptance
- Pre-acceptance detail UI must rely on WebSocket payload and `/api/orders/available`

### Upload flow is submit-only

The backend stores a verification document path internally but does not expose a download URL.

Flutter implication:

- Show upload success and status
- Do not show server-backed preview for the uploaded verification document

## Suggested Flutter Client Modules

Recommended domain models:

- `AuthSession`
- `CurrentUser`
- `BlindProfile`
- `VolunteerProfile`
- `VolunteerAvailableTimeSlot`
- `OrderSummary`
- `OrderDetail`
- `AvailableOrder`
- `Review`
- `ApiFailure`

Recommended service boundaries:

- `AuthApi`
- `BlindApi`
- `VolunteerApi`
- `OrderApi`
- `ReviewApi`
- `VolunteerSocketService`

Recommended enums:

- `UserRole`
- `OrderStatus`
- `VerificationStatus`

These enums should map exactly to backend values to avoid translation ambiguity.

## Suggested Flutter App Flows

### Blind User

1. Login with SMS code
2. Set role if needed
3. Maintain blind profile
4. Create order
5. Show immediate `PENDING_MATCH`
6. Poll order detail or my-orders list for state updates
7. After completion, allow review submission

### Volunteer

1. Login with SMS code
2. Set role if needed
3. Maintain volunteer profile
4. Upload verification file
5. Start location heartbeat when available for orders
6. Open WebSocket connection
7. Use `/api/orders/available` as fallback and refresh source
8. Accept, finish, or cancel orders as allowed by state

## Minimum End-to-End Acceptance Checklist

For Flutter and backend integration, the minimum successful flow is:

1. Login with SMS code and receive token
2. Select role successfully for a new user
3. Read and update blind profile
4. Read and update volunteer profile
5. Upload volunteer verification successfully
6. Report volunteer location and remain online
7. Create an order as a blind user
8. Receive `NEW_ORDER` by WebSocket or find the order in `/api/orders/available`
9. Accept the order as a volunteer
10. Finish the order as a volunteer
11. Submit a review as the blind user

## Validation Status

This guide was derived from:

- controllers in `src/main/java/com/example/demo/controller`
- services in `src/main/java/com/example/demo/service`
- security and WebSocket config
- integration tests in `src/test/java/com/example/demo/integration`
- runtime config in `src/main/resources/application.properties`

At the time of writing:

- Repository structure and test coverage strongly support the contract described here
- Local `./gradlew test` could not be completed in this environment because Gradle dependency resolution failed during a remote TLS handshake
- That failure was environmental and did not indicate a known assertion failure in repository tests

## Related Docs

- `docs/API_REFERENCE.md`
- `docs/ARCHITECTURE.md`
- `docs/DIAGRAMS.md`
