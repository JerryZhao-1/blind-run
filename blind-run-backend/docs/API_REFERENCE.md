# Blind Running Companion (助盲跑) API Reference

**Version:** 1.0.0  
**Base URL:** `http://localhost:8081`  
**Content Type:** `application/json`  
**Character Set:** `UTF-8`

**Related Guide:** `docs/FLUTTER_INTEGRATION.md`

## Table of Contents

1. [Authentication](#authentication)
2. [Role Management](#role-management)
3. [User Management](#user-management)
4. [Blind Profile](#blind-profile)
5. [Volunteer Profile](#volunteer-profile)
6. [Volunteer Verification](#volunteer-verification)
7. [Volunteer Location](#volunteer-location)
8. [Order Management](#order-management)
9. [Reviews](#reviews)
10. [Error Responses](#error-responses)
11. [WebSocket Protocol](#websocket-protocol)

---

## Authentication

### Overview

The API uses JWT (JSON Web Token) based authentication. All protected endpoints require a valid JWT token in the `Authorization` header.

**Authorization Header Format:**
```
Authorization: Bearer <token>
```

**Token Payload:**
- `sub`: User ID (Long)
- `exp`: Expiration timestamp

### Send Verification Code

Send a 6-digit SMS verification code to the user's phone number.

**Endpoint:** `POST /api/auth/send-code`  
**Authentication:** None (Public)  
**Rate Limit:** 5 minutes TTL, max 5 attempts

**Request Body:**

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| phone | string | Yes | @NotBlank | Mobile phone number |

**Example Request:**
```json
{
  "phone": "13800138000"
}
```

**Response:** `200 OK`

```json
{
  "success": true
}
```

**Notes:**
- Verification code is stored in Redis with key pattern `sms:code:{phone}`
- Code format: 6-digit number
- TTL: 5 minutes
- Max attempts: 5
- In development, check logs for `【模拟短信】` to extract the code

---

### Verify Code and Login

Verify the SMS code and receive a JWT token for authenticated requests.

**Endpoint:** `POST /api/auth/verify-code`  
**Authentication:** None (Public)

**Request Body:**

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| phone | string | Yes | @NotBlank | Mobile phone number |
| code | string | Yes | @NotBlank | 6-digit verification code |

**Example Request:**
```json
{
  "phone": "13800138000",
  "code": "123456"
}
```

**Response:** `200 OK`

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": 1,
  "role": "UNSET"
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 400 | - | Invalid phone or code format |
| 400 | - | Verification code expired or invalid |
| 400 | - | Maximum attempts exceeded |

**Notes:**
- Returns existing user if phone already registered
- Creates new user with `role=UNSET` if phone not found
- Token is valid for JWT expiration period (check JwtUtil configuration)

---

### Get Current User

Get information about the currently authenticated user.

**Endpoint:** `GET /api/auth/me`  
**Authentication:** Required (JWT)

**Response:** `200 OK`

```json
{
  "userId": 1,
  "phone": "138****8000",
  "role": "BLIND",
  "createdAt": "2026-04-10T10:30:00"
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 401 | - | 未登录 (Not logged in) |

**Notes:**
- Phone number is masked: first 3 digits + `****` + last 4 digits
- Role can be: `UNSET`, `BLIND`, `VOLUNTEER`

---

## Role Management

### Set User Role

Set the user's role (BLIND or VOLUNTEER). This is a one-time operation and cannot be changed once set.

**Endpoint:** `POST /api/user/role`  
**Authentication:** Required (JWT)

**Request Body:**

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| role | string | Yes | @NotNull | User role: `BLIND` or `VOLUNTEER` |

**Example Request:**
```json
{
  "role": "BLIND"
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "role": "BLIND"
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 409 | 409 | 身份已设定，不可修改 (Role already set, cannot be modified) |

**Notes:**
- Setting role automatically creates an empty profile record:
  - `BLIND` → creates `BlindProfile` record
  - `VOLUNTEER` → creates `VolunteerProfile` record
- Role cannot be changed after setting
- Default role for new users is `UNSET`

---

## User Management

### Get User by ID

Get user information by user ID. Users can only query their own information.

**Endpoint:** `GET /api/users/{id}`  
**Authentication:** Required (JWT)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | long | Yes | User ID |

**Response:** `200 OK`

```json
{
  "userId": 1,
  "phone": "138****8000",
  "role": "BLIND",
  "createdAt": "2026-04-10T10:30:00"
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 403 | 403 | 无权限查询其他用户信息 (No permission to query other users) |
| 404 | - | 用户不存在 (User not found) |

---

### Delete User Account

Soft delete the current user's account. The JWT user ID must match the path parameter.

**Endpoint:** `DELETE /api/users/{id}`  
**Authentication:** Required (JWT)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | long | Yes | User ID to delete |

**Response:** `200 OK`

```json
{
  "success": true
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 403 | 403 | 无权限删除其他用户 (No permission to delete other users) |

**Notes:**
- Performs soft delete (user is marked as deleted, not actually removed)
- User can only delete their own account
- All associated orders and reviews remain in the system

---

## Blind Profile

### Get Blind Profile

Get the blind user's profile information.

**Endpoint:** `GET /api/blind/profile`  
**Authentication:** Required (JWT, BLIND role)

**Response:** `200 OK`

```json
{
  "name": "张三",
  "emergencyContactName": "李四",
  "emergencyContactPhone": "139****0000",
  "emergencyContactRelation": "配偶",
  "runningPace": "6:00/km",
  "specialNeeds": "需要扶手辅助"
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 403 | 403 | 无权限访问 (No permission) |
| 404 | - | Blind profile not found |

---

### Update Blind Profile

Update the blind user's profile information.

**Endpoint:** `PUT /api/blind/profile`  
**Authentication:** Required (JWT, BLIND role)

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | No | User's name |
| emergencyContactName | string | No | Emergency contact name |
| emergencyContactPhone | string | No | Emergency contact phone |
| emergencyContactRelation | string | No | Relationship to emergency contact |
| runningPace | string | No | Running pace (e.g., "6:00/km") |
| specialNeeds | string | No | Special needs or requirements |

**Example Request:**
```json
{
  "name": "张三",
  "emergencyContactName": "李四",
  "emergencyContactPhone": "13900000000",
  "emergencyContactRelation": "配偶",
  "runningPace": "6:00/km",
  "specialNeeds": "需要扶手辅助，喜欢晨跑"
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "name": "张三",
    "emergencyContactName": "李四",
    "emergencyContactPhone": "139****0000",
    "emergencyContactRelation": "配偶",
    "runningPace": "6:00/km",
    "specialNeeds": "需要扶手辅助，喜欢晨跑"
  }
}
```

**Notes:**
- Only provided fields are updated (partial update)
- Phone numbers are automatically masked in response

---

## Volunteer Profile

### Get Volunteer Profile

Get the volunteer's profile information.

**Endpoint:** `GET /api/volunteer/profile`  
**Authentication:** Required (JWT, VOLUNTEER role)

**Response:** `200 OK`

```json
{
  "name": "王五",
  "verificationStatus": "APPROVED",
  "availableTimeSlots": [
    {
      "dayOfWeek": "MONDAY",
      "startTime": "06:00:00",
      "endTime": "08:00:00"
    },
    {
      "dayOfWeek": "SATURDAY",
      "startTime": "07:00:00",
      "endTime": "09:00:00"
    }
  ]
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 403 | 403 | 无权限访问 (No permission) |
| 404 | - | Volunteer profile not found |

**Verification Status Values:**
- `NONE` - Not applied
- `PENDING` - Under review
- `APPROVED` - Approved
- `REJECTED` - Rejected

---

### Update Volunteer Profile

Update the volunteer's profile information.

**Endpoint:** `PUT /api/volunteer/profile`  
**Authentication:** Required (JWT, VOLUNTEER role)

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | No | Volunteer's name |
| availableTimeSlots | array | No | List of available time slots |

**AvailableTimeSlot Structure:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| dayOfWeek | string | Yes | Day of week (MONDAY, TUESDAY, etc.) |
| startTime | string | Yes | Start time (HH:mm:ss format) |
| endTime | string | Yes | End time (HH:mm:ss format) |

**Example Request:**
```json
{
  "name": "王五",
  "availableTimeSlots": [
    {
      "dayOfWeek": "MONDAY",
      "startTime": "06:00:00",
      "endTime": "08:00:00"
    },
    {
      "dayOfWeek": "SATURDAY",
      "startTime": "07:00:00",
      "endTime": "09:00:00"
    }
  ]
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "data": {
    "name": "王五",
    "verificationStatus": "APPROVED",
    "availableTimeSlots": [
      {
        "dayOfWeek": "MONDAY",
        "startTime": "06:00:00",
        "endTime": "08:00:00"
      },
      {
        "dayOfWeek": "SATURDAY",
        "startTime": "07:00:00",
        "endTime": "09:00:00"
      }
    ]
  }
}
```

---

## Volunteer Verification

### Submit Verification Document

Upload verification document (e.g., ID card, certificate) for volunteer account approval.

**Endpoint:** `POST /api/volunteer/verification`  
**Authentication:** Required (JWT, VOLUNTEER role)  
**Content Type:** `multipart/form-data`

**Form Data:**

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| file | file | Yes | Max 10MB | Verification document file |

**Example Request (curl):**
```bash
curl -X POST http://localhost:8081/api/volunteer/verification \
  -H "Authorization: Bearer <token>" \
  -F "file=@/path/to/document.jpg"
```

**Response:** `200 OK`

```json
{
  "success": true,
  "status": "PENDING"
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 400 | 400 | File validation failed |
| 413 | 413 | File too large (max 10MB) |

**Notes:**
- File upload limit: 10MB
- Uploaded files are stored in `uploads/` directory
- Verification status changes to `PENDING` after submission
- Admin approval required to change status to `APPROVED`

---

### Get Verification Status

Get the current verification status of the volunteer.

**Endpoint:** `GET /api/volunteer/verification/status`  
**Authentication:** Required (JWT, VOLUNTEER role)

**Response:** `200 OK`

```json
{
  "status": "PENDING"
}
```

**Status Values:**
- `NONE` - Not applied
- `PENDING` - Under review
- `APPROVED` - Approved
- `REJECTED` - Rejected

---

## Volunteer Location

### Update Volunteer Location

Report volunteer's real-time location for order matching and availability.

**Endpoint:** `POST /api/volunteer/location`  
**Authentication:** Required (JWT, VOLUNTEER role)

**Request Body:**

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| latitude | number | Yes | @NotNull, @Min(-90), @Max(90) | Latitude coordinate |
| longitude | number | Yes | @NotNull, @Min(-180), @Max(180) | Longitude coordinate |
| isOnline | boolean | No | Default: true | Whether volunteer is available for orders |

**Example Request:**
```json
{
  "latitude": 39.9042,
  "longitude": 116.4074,
  "isOnline": true
}
```

**Response:** `200 OK`

```json
{
  "success": true
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 400 | 400 | Invalid coordinates (latitude must be -90 to 90, longitude -180 to 180) |

**Notes:**
- Location is stored in Redis with key pattern `vol:loc:{userId}`
- TTL: 30 seconds (configurable via `app.volunteer.location-ttl-seconds`)
- Volunteers must update location at least every 30 seconds to remain online
- Only online volunteers (`isOnline=true`) are eligible for order matching
- Location is used for distance-based matching with blind users' orders

---

## Order Management

### Order Status Flow

```
PENDING_MATCH → PENDING_ACCEPT → IN_PROGRESS → COMPLETED
     ↓              ↓                ↓
     └────────────→ CANCELLED ←──────┘
```

**Status Descriptions:**
- `PENDING_MATCH` - Order created, waiting for system to match volunteers
- `PENDING_ACCEPT` - Matched with volunteers, waiting for volunteer acceptance
- `IN_PROGRESS` - Volunteer accepted, service in progress
- `COMPLETED` - Service completed successfully
- `CANCELLED` - Order cancelled (by blind user or volunteer)

**Cancellation Rules:**
- Blind users can cancel at `PENDING_MATCH` or `PENDING_ACCEPT` stages
- Volunteer cancellation at `IN_PROGRESS` is marked as "no-show" (爽约)

---

### Create Order

Create a new running companion order (blind user only).

**Endpoint:** `POST /api/orders`  
**Authentication:** Required (JWT, BLIND role)

**Request Body:**

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| startLatitude | number | Yes | @NotNull | Starting point latitude |
| startLongitude | number | Yes | @NotNull | Starting point longitude |
| startAddress | string | Yes | @NotNull | Starting point address description |
| plannedStartTime | string | Yes | @NotNull | Planned start time (ISO 8601) |
| plannedEndTime | string | Yes | @NotNull | Planned end time (ISO 8601) |

**Example Request:**
```json
{
  "startLatitude": 39.9042,
  "startLongitude": 116.4074,
  "startAddress": "朝阳公园南门",
  "plannedStartTime": "2026-04-11T06:30:00",
  "plannedEndTime": "2026-04-11T07:30:00"
}
```

**Response:** `201 Created`

```json
{
  "id": 123,
  "status": "PENDING_MATCH",
  "message": "订单创建成功，正在匹配志愿者"
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 400 | 400 | Validation error (check required fields) |
| 409 | 409 | You already have an active order |
| 403 | 403 | Only BLIND users can create orders |

**Notes:**
- Validates that user doesn't already have an active order
- System automatically matches with nearby volunteers (max 3 candidates)
- Matched volunteers receive WebSocket notification
- Matching radius: 10 km (configurable via `app.matching.max-distance-km`)

---

### Accept Order

Accept an order (volunteer only). Uses optimistic locking to prevent race conditions.

**Endpoint:** `POST /api/orders/{id}/accept`  
**Authentication:** Required (JWT, VOLUNTEER role)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | long | Yes | Order ID |

**Response:** `200 OK`

```json
{
  "success": true,
  "orderId": 123
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 404 | 404 | Order not found |
| 409 | 409 | Order already accepted by another volunteer |
| 409 | 409 | Invalid order status for acceptance |
| 403 | 403 | No permission to accept this order |

**Notes:**
- Only volunteers in `PENDING_ACCEPT` status can accept
- Uses optimistic locking (`@Version` field) to prevent concurrent accepts
- If multiple volunteers accept simultaneously, only one succeeds (others get 409)
- Order status changes to `IN_PROGRESS` upon acceptance
- Blind user receives volunteer's masked phone number

---

### Reject Order

Reject an order that was offered to the volunteer.

**Endpoint:** `POST /api/orders/{id}/reject`  
**Authentication:** Required (JWT, VOLUNTEER role)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | long | Yes | Order ID |

**Response:** `200 OK`

```json
{
  "success": true
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 404 | 404 | Order not found |
| 409 | 409 | Cannot reject order in current status |
| 403 | 403 | No permission to reject this order |

**Notes:**
- Can only reject orders in `PENDING_ACCEPT` status
- System may offer the order to other volunteers
- Order returns to `PENDING_MATCH` if all candidates reject

---

### Finish Order

Mark an order as completed (volunteer only).

**Endpoint:** `POST /api/orders/{id}/finish`  
**Authentication:** Required (JWT, VOLUNTEER role)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | long | Yes | Order ID |

**Response:** `200 OK`

```json
{
  "success": true,
  "orderId": 123
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 404 | 404 | Order not found |
| 409 | 409 | Cannot finish order in current status |
| 403 | 403 | No permission to finish this order |

**Notes:**
- Only the volunteer who accepted the order can finish it
- Order must be in `IN_PROGRESS` status
- Status changes to `COMPLETED`
- Blind user can then leave a review

---

### Cancel Order

Cancel an order (blind user or volunteer).

**Endpoint:** `POST /api/orders/{id}/cancel`  
**Authentication:** Required (JWT)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | long | Yes | Order ID |

**Response:** `200 OK`

```json
{
  "success": true
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 404 | 404 | Order not found |
| 409 | 409 | Cannot cancel order in current status |
| 403 | 403 | No permission to cancel this order |

**Cancellation Rules:**
- **Blind users**: Can cancel at `PENDING_MATCH` or `PENDING_ACCEPT`
- **Volunteers**: Can cancel at `IN_PROGRESS` (marked as "no-show")
- `COMPLETED` orders cannot be cancelled
- Cancellation is tracked via `CancelledBy` enum (`BLIND` or `VOLUNTEER`)

---

### Get Order Details

Get detailed information about a specific order.

**Endpoint:** `GET /api/orders/{id}`  
**Authentication:** Required (JWT)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | long | Yes | Order ID |

**Response:** `200 OK`

```json
{
  "orderId": 123,
  "status": "IN_PROGRESS",
  "startAddress": "朝阳公园南门",
  "plannedStart": "2026-04-11T06:30:00",
  "plannedEnd": "2026-04-11T07:30:00",
  "volunteerPhone": "139****0000",
  "acceptedAt": "2026-04-11T06:15:00",
  "createdAt": "2026-04-10T10:00:00"
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 404 | 404 | Order not found |
| 403 | 403 | No permission to view this order |

**Notes:**
- Users can only view orders they are involved in (as blind user or volunteer)
- Volunteer phone is only visible when order is accepted
- Phone numbers are masked for privacy

---

### Get Available Orders

Get list of orders available for the volunteer to accept (nearby orders in `PENDING_ACCEPT` status).

**Endpoint:** `GET /api/orders/available`  
**Authentication:** Required (JWT, VOLUNTEER role)

**Response:** `200 OK`

```json
[
  {
    "orderId": 123,
    "blindUserId": 5,
    "startAddress": "朝阳公园南门",
    "plannedStartTime": "2026-04-11T06:30:00",
    "distanceKm": 2.5,
    "blindUserName": "张三"
  }
]
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 400 | 400 | Volunteer location not found |

**Notes:**
- Only returns orders within matching radius (10 km)
- Volunteer must have reported location within last 30 seconds
- Orders are in `PENDING_ACCEPT` status (already matched)
- Sorted by distance (nearest first)
- Returns empty array if no available orders

---

### Get My Orders

Get paginated list of orders for the current user (as blind user or volunteer).

**Endpoint:** `GET /api/orders/mine`  
**Authentication:** Required (JWT)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| role | string | Yes | - | Filter by role: `BLIND` or `VOLUNTEER` |
| status | string | No | - | Filter by status (e.g., `PENDING_MATCH`, `IN_PROGRESS`) |
| page | integer | No | 0 | Page number (0-indexed) |
| size | integer | No | 10 | Page size |

**Example Request:**
```
GET /api/orders/mine?role=BLIND&status=COMPLETED&page=0&size=10
```

**Response:** `200 OK`

```json
{
  "content": [
    {
      "orderId": 123,
      "status": "COMPLETED",
      "startAddress": "朝阳公园南门",
      "plannedStart": "2026-04-11T06:30:00",
      "plannedEnd": "2026-04-11T07:30:00",
      "volunteerPhone": "139****0000",
      "acceptedAt": "2026-04-11T06:15:00",
      "createdAt": "2026-04-10T10:00:00"
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 10,
    "totalPages": 1,
    "totalElements": 1
  }
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 400 | 400 | Invalid role parameter |

**Notes:**
- `role` parameter determines whether to return orders where user is blind or volunteer
- Results are sorted by `createdAt` in descending order (newest first)
- Pagination follows Spring Data conventions
- Status filtering is optional (returns all statuses if not provided)

---

## Reviews

### Create Review

Submit a review for a completed order (blind user only).

**Endpoint:** `POST /api/orders/{id}/review`  
**Authentication:** Required (JWT, BLIND role)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | long | Yes | Order ID |

**Request Body:**

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| rating | integer | Yes | @Min(1), @Max(5) | Rating from 1 to 5 stars |
| comment | string | No | - | Optional review comment |

**Example Request:**
```json
{
  "rating": 5,
  "comment": "志愿者非常耐心，服务很棒！"
}
```

**Response:** `201 Created`

```json
{
  "success": true
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 400 | 400 | Rating must be between 1 and 5 |
| 404 | 404 | Order not found |
| 409 | 409 | Can only review completed orders |
| 409 | 409 | Review already exists for this order |

**Notes:**
- Only the blind user can review the volunteer
- Order must be in `COMPLETED` status
- One review per order (duplicate reviews rejected)
- Reviews cannot be modified after submission

---

### Get Order Reviews

Get the review for a specific order.

**Endpoint:** `GET /api/orders/{id}/reviews`  
**Authentication:** Required (JWT)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | long | Yes | Order ID |

**Response:** `200 OK`

```json
{
  "data": {
    "orderId": 123,
    "rating": 5,
    "comment": "志愿者非常耐心，服务很棒！",
    "createdAt": "2026-04-11T08:00:00"
  }
}
```

**Error Responses:**

| Status | Code | Message |
|--------|------|---------|
| 404 | 404 | Review not found |

**Notes:**
- Returns the review if it exists
- Returns null if no review has been submitted yet
- Both blind user and volunteer can view the review

---

## Error Responses

### Error Response Formats

The API uses two error response formats:

**Legacy Format** (Authentication endpoints):
```json
{
  "error": "Error message in Chinese"
}
```

**Standard Format** (Order and Volunteer endpoints):
```json
{
  "success": false,
  "code": 409,
  "message": "Error message in Chinese"
}
```

### Common HTTP Status Codes

| Status | Description |
|--------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Validation error or invalid parameters |
| 401 | Unauthorized - Missing or invalid JWT token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource does not exist |
| 409 | Conflict - Business logic violation (duplicate, status conflict, etc.) |
| 413 | Payload Too Large - File upload exceeds size limit |
| 500 | Internal Server Error - Unexpected server error |

### Validation Error Format

When `@Valid` annotation fails (e.g., missing required fields):

**Status:** `400 Bad Request`

```json
{
  "success": false,
  "code": 400,
  "message": "phone: 手机号不能为空, code: 验证码不能为空"
}
```

### Common Error Scenarios

| Scenario | Status | Code | Message |
|----------|--------|------|---------|
| Invalid JWT token | 401 | - | 未登录 (Not logged in) |
| Expired JWT token | 401 | - | 未登录 (Not logged in) |
| Missing Authorization header | 401 | - | 未登录 (Not logged in) |
| User not found | 404 | 404 | 用户不存在 (User not found) |
| Order not found | 404 | 404 | 订单不存在 (Order not found) |
| Review not found | 404 | - | Review not found |
| Role already set | 409 | 409 | 身份已设定，不可修改 (Role already set) |
| Duplicate active order | 409 | 409 | You already have an active order |
| Invalid order status transition | 409 | 409 | Invalid order status for this operation |
| Concurrent order acceptance | 409 | 409 | 订单已被其他志愿者接单 (Order already accepted) |
| No permission for resource | 403 | 403 | 无权限访问 (No permission) |
| Invalid coordinates | 400 | 400 | Invalid coordinates (latitude/longitude out of range) |
| File too large | 413 | 413 | File too large (max 10MB) |

---

## WebSocket Protocol

### Overview

WebSocket is used for real-time order notifications to volunteers. When a new order is matched with a volunteer, the server pushes a notification immediately.

### Connection

**Endpoint:** `ws://localhost:8081/ws/volunteer?token=<jwt_token>`

**Authentication:**
- JWT token is passed via URL query parameter (not header)
- Token is validated during WebSocket handshake
- Invalid or expired tokens result in connection refusal

**Example Connection (JavaScript):**
```javascript
const token = 'your-jwt-token';
const ws = new WebSocket(`ws://localhost:8081/ws/volunteer?token=${token}`);

ws.onopen = () => {
  console.log('WebSocket connected');
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('WebSocket disconnected');
};
```

### Message Format

**NEW_ORDER Notification:**

When a new order is matched with the volunteer, the server sends:

```json
{
  "type": "NEW_ORDER",
  "orderId": 123,
  "blindUserId": 5,
  "startAddress": "朝阳公园南门",
  "plannedStartTime": "2026-04-11T06:30:00",
  "plannedEndTime": "2026-04-11T07:30:00",
  "distanceKm": 2.5,
  "blindUserName": "张三"
}
```

**Message Fields:**

| Field | Type | Description |
|-------|------|-------------|
| type | string | Message type (currently only "NEW_ORDER") |
| orderId | long | Order ID |
| blindUserId | long | Blind user's ID |
| startAddress | string | Starting point address |
| plannedStartTime | string | Planned start time (ISO 8601) |
| plannedEndTime | string | Planned end time (ISO 8601) |
| distanceKm | number | Distance from volunteer's current location |
| blindUserName | string | Blind user's name |

### Connection Management

**Connection Lifecycle:**
1. Volunteer connects with JWT token
2. Server validates token and extracts user ID
3. Connection is registered in `VolunteerSessionRegistry`
4. Volunteer can receive real-time notifications
5. On disconnect, connection is automatically removed from registry

**Automatic Reconnection:**
Implement automatic reconnection in client:

```javascript
let ws;
let reconnectInterval;

function connect() {
  ws = new WebSocket(`ws://localhost:8081/ws/volunteer?token=${token}`);
  
  ws.onclose = () => {
    console.log('Disconnected, reconnecting in 3 seconds...');
    reconnectInterval = setTimeout(connect, 3000);
  };
  
  ws.onopen = () => {
    clearTimeout(reconnectInterval);
  };
}

connect();
```

### Best Practices

1. **Keep-Alive**: Implement ping/pong to detect stale connections
2. **Reconnection**: Always implement automatic reconnection with exponential backoff
3. **Error Handling**: Handle connection errors gracefully
4. **Token Refresh**: If token expires, close connection and reconnect with new token
5. **Location Updates**: Regularly update volunteer location via REST API to stay eligible for matching

---

## Data Types and Enums

### UserRole Enum

| Value | Description |
|-------|-------------|
| UNSET | New user, role not yet set |
| BLIND | Blind user (can create orders) |
| VOLUNTEER | Volunteer (can accept orders) |

### OrderStatus Enum

| Value | Description |
|-------|-------------|
| PENDING_MATCH | Order created, waiting for volunteer matching |
| PENDING_ACCEPT | Matched with volunteers, waiting for acceptance |
| IN_PROGRESS | Volunteer accepted, service in progress |
| COMPLETED | Service completed |
| CANCELLED | Order cancelled |

### CancelledBy Enum

| Value | Description |
|-------|-------------|
| BLIND | Cancelled by blind user |
| VOLUNTEER | Cancelled by volunteer |

### VerificationStatus Enum

| Value | Description |
|-------|-------------|
| NONE | Not applied for verification |
| PENDING | Verification under review |
| APPROVED | Verification approved |
| REJECTED | Verification rejected |

---

## Phone Number Masking

All phone numbers in API responses are masked for privacy:

**Format:** `XXX****XXXX`

**Example:** `13800138000` → `138****8000`

- First 3 digits: Visible
- Middle 4 digits: Masked with `****`
- Last 4 digits: Visible

---

## Configuration

### Application Properties

| Property | Default | Description |
|----------|---------|-------------|
| `server.port` | 8081 | Server port |
| `app.matching.max-distance-km` | 10 | Maximum matching distance (km) |
| `app.matching.max-candidates` | 3 | Maximum volunteers to notify per order |
| `app.websocket.endpoint` | /ws/volunteer | WebSocket endpoint path |
| `app.volunteer.location-ttl-seconds` | 30 | Volunteer location TTL (seconds) |
| `sms.code.length` | 6 | Verification code length |
| `sms.code.ttl-minutes` | 5 | Verification code TTL (minutes) |
| `sms.code.max-attempts` | 5 | Max verification attempts |
| `spring.servlet.multipart.max-file-size` | 10MB | Max file upload size |

---

## Testing

### SMS Verification (Development)

In development mode, verification codes are logged to console:

```
【模拟短信】发送验证码到手机 13800138000: 123456
```

Extract the code from logs for testing.

### Test Data

Use the following test data for manual testing:

**Blind User:**
- Phone: `13800000001`
- Password/Code: Any 6-digit code in dev mode
- Role: `BLIND`

**Volunteer:**
- Phone: `13800000002`
- Password/Code: Any 6-digit code in dev mode
- Role: `VOLUNTEER`

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-04-10 | Initial API release |

---

## Support

For issues or questions, please contact the development team.

**Server:** Spring Boot 3.4.4  
**Java Version:** 17  
**Database:** MySQL  
**Cache:** Redis

---

*This API reference is automatically generated from the source code. For the most up-to-date information, always refer to the actual implementation.*
