# 后端 v1.2.0 变更通知 — 前端必读

> **版本**: 2026-04-24 更新
> **对接人**: 如有疑问联系后端 Jayden

---

## 一、本次变更摘要

| 类别 | 变更 | 是否需要前端改动 |
|------|------|-----------------|
| 登出接口 | 新增 `POST /api/auth/logout` 和 `POST /api/cs/auth/logout` | **需要** |
| 设置角色返回新 token | `POST /api/user/role` 响应新增 `token` 字段 | **必须改** |
| RBAC 角色鉴权 | 所有接口按角色限制，无权限返回 403 | 需要处理 403 |
| 401/403 统一 JSON 格式 | 不再返回 HTML，统一返回 `{success, code, message}` | 建议适配 |
| WebSocket 角色校验 | 盲人只能连 `/ws/blind`，志愿者只能连 `/ws/volunteer` | **必须改** |
| 手机号格式校验 | 登录/发验证码只接受 1 开头 11 位中国手机号 | 需要前端也加校验 |
| 串行派单 | 志愿者通过 WebSocket 收到 NEW_ORDER 后需主动响应 | **需要** |
| Swagger 生产关闭 | 生产环境无法访问 Swagger UI | 无需改动 |

---

## 二、必须立即修改的点

### 2.1 设置角色后必须替换 token（重要）

之前 `POST /api/user/role` 只返回 `{success, role}`，现在多返回一个 `token` 字段：

```json
// POST /api/user/role
// 请求: { "role": "BLIND" }

// 新的响应（注意 token 字段）
{
  "success": true,
  "role": "BLIND",
  "token": "eyJhbGciOiJIUzUxMiJ9..."   // ← 新增！
}
```

**前端必须把 localStorage 里的旧 token 替换成新 token**，否则后续所有请求都会因为 token 中没有角色信息而被 403 拒绝。

```javascript
// 正确做法
const res = await fetch('/api/user/role', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${oldToken}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ role: 'BLIND' })
});
const data = await res.json();
if (data.success && data.token) {
  localStorage.setItem('token', data.token);  // 替换！
}
```

### 2.2 新增登出接口

```
POST /api/auth/logout        — 用户登出
POST /api/cs/auth/logout     — 客服登出
```

请求头带上 `Authorization: Bearer <token>` 即可，不需要请求体。

```json
// 响应
{ "success": true }
```

登出后 token 立即失效，建议前端在登出成功后清除本地存储的 token。

### 2.3 WebSocket 角色校验

后端现在校验 WebSocket 连接的角色：
- 盲人用户只能连接 `ws://host/ws/blind?token=xxx`
- 志愿者只能连接 `ws://host/ws/volunteer?token=xxx`

如果角色不匹配，WebSocket 握手会被拒绝（连接失败）。

**前端需要确保**：
- 盲人页面的 WebSocket 连接地址用 `/ws/blind`
- 志愿者页面的 WebSocket 连接地址用 `/ws/volunteer`
- 不要用错 token（例如盲人的 token 去连 volunteer 端点）

### 2.4 RBAC 角色鉴权 — 403 错误处理

后端现在严格按角色限制 API 访问：

| 端点前缀 | 允许的角色 | 说明 |
|----------|-----------|------|
| `/api/blind/**` | BLIND | 盲人专属 |
| `/api/volunteer/**` | VOLUNTEER | 志愿者专属 |
| `/api/admin/**` | CS_ADMIN | 管理员专属 |
| `/api/cs/**` | CS_CS, CS_ADMIN | 客服/管理员 |
| `/api/users/*/emergency-contacts/**` | BLIND | 紧急联系人管理 |
| `POST /api/orders` | BLIND | 创建订单 |
| `POST /api/orders/*/accept` 等 | VOLUNTEER | 接单/完成/出发/到达 |
| `GET /api/orders/mine` 等 | BLIND 或 VOLUNTEER | 查询类 |
| `POST /api/orders/*/review` | BLIND | 评价 |

如果角色不匹配，返回：

```json
// HTTP 403
{ "success": false, "code": 403, "message": "无权访问" }
```

**前端建议**：统一拦截 403 响应，提示用户"无权访问该功能"。

### 2.5 手机号格式校验

`POST /api/auth/send-code` 和 `POST /api/auth/verify-code` 现在校验手机号格式：

```
规则: 以1开头，第二位3-9，共11位数字
正则: ^1[3-9]\d{9}$
合法: 13800138000, 19912345678
非法: 23800138000, 1380013800, 138001380001
```

前端建议在输入框也加上同样的校验，避免提交后才发现格式错误。

---

## 三、串行派单流程（志愿者端对接）

当前版本使用串行派单，志愿者通过 WebSocket 接收 NEW_ORDER 后需要主动响应：

### 3.1 接收新订单通知

```json
// WebSocket 推送给志愿者的消息
{
  "type": "NEW_ORDER",
  "orderId": 123,
  "startAddress": "朝阳公园南门",
  "distanceKm": 2.5,
  "plannedStart": "2026-04-20T14:00:00",
  "plannedEnd": "2026-04-20T15:00:00",
  "dispatchTimeoutSeconds": 30,
  "priority": "HIGH"
}
```

### 3.2 志愿者响应（30秒内）

```json
// 接受
POST /api/orders/123/respond
{ "action": "ACCEPT" }

// 拒绝
POST /api/orders/123/respond
{ "action": "DECLINE" }
```

**注意**: 旧的 `POST /api/orders/{id}/accept` 和 `/reject` 仍然可用（@Deprecated），但建议使用新的 `/respond` 端点。

---

## 四、401/403 统一 JSON 格式

之前未登录返回的是 Spring 默认的 HTML 错误页，现在统一返回 JSON：

```json
// HTTP 401 — 未登录或 token 无效
{ "success": false, "code": 401, "message": "未认证" }

// HTTP 403 — 角色不匹配
{ "success": false, "code": 403, "message": "无权访问" }
```

前端可以统一通过 `response.code === 401` 判断跳转登录页。

---

## 五、CS 管理员（Admin）使用指南

### 5.1 登录

```
POST /api/cs/auth/login
请求: { "username": "admin", "password": "你的密码" }
响应: { "token": "eyJhbGciOi...", "role": "ADMIN" }
```

> 账号密码由后端直接在数据库 `cs_users` 表中创建，不通过前端注册。

### 5.2 认证方式

所有管理端接口请求头加：`Authorization: Bearer <token>`

### 5.3 管理员功能列表

#### 通知模板管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/admin/notification-templates` | 获取所有通知模板 |
| PUT | `/api/admin/notification-templates/{id}` | 更新模板内容 |

#### 志愿者审核

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/admin/volunteers/review/id` | 获取待审核身份证列表 |
| POST | `/api/admin/volunteers/review/id` | 审核通过/拒绝 |

审核请求：
```json
// POST /api/admin/volunteers/review/id
{
  "userId": 42,
  "approved": true                    // true=通过, false=拒绝
  "rejectionReason": "照片模糊"        // 拒绝时必填
}
```

#### 培训课程管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/admin/volunteers/training/stats` | 培训统计 |
| POST | `/api/admin/volunteers/training/courses` | 创建课程 |
| PUT | `/api/admin/volunteers/training/courses/{id}` | 更新课程 |
| DELETE | `/api/admin/volunteers/training/courses/{id}` | 删除课程 |
| POST | `/api/admin/volunteers/training/questions` | 创建题目 |
| PUT | `/api/admin/volunteers/training/questions/{id}` | 更新题目 |
| DELETE | `/api/admin/volunteers/training/questions/{id}` | 删除题目 |

#### 客服事件处理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/cs/emergency-events` | 获取紧急事件列表 |
| PUT | `/api/cs/emergency-events/{id}/accept` | 接手处理 |
| PUT | `/api/cs/emergency-events/{id}/notify-contact` | 通知紧急联系人 |
| PUT | `/api/cs/emergency-events/{id}/resolve` | 标记已解决 |
| PUT | `/api/cs/emergency-events/{id}/false-alarm` | 标记误报 |

### 5.4 管理员登出

```
POST /api/cs/auth/logout
Authorization: Bearer <token>
响应: { "success": true }
```

---

## 六、完整测试流程（前端跑通全链路）

### 6.1 盲人用户流程

```
1. 发送验证码
   POST /api/auth/send-code { "phone": "13800010001" }

2. 验证码登录
   POST /api/auth/verify-code { "phone": "13800010001", "code": "看日志" }
   → 拿到 token

3. 设置角色（重要：保存返回的新 token！）
   POST /api/user/role { "role": "BLIND" }
   → 响应里有新 token，替换 localStorage

4. 完善盲人资料
   PUT /api/blind/profile { "name": "测试盲人", "runningPace": "6:00" }

5. 添加紧急联系人（至少1个才能下单）
   POST /api/users/1/emergency-contacts
   { "name": "紧急人", "phone": "13900139000", "relationship": "家人" }

6. 创建订单
   POST /api/orders
   { "startLatitude": 39.9, "startLongitude": 116.4, "startAddress": "朝阳公园",
     "plannedStartTime": "2099-06-01T18:00:00", "plannedEndTime": "2099-06-01T19:00:00" }

7. 连接盲人 WebSocket
   ws://47.114.113.171/ws/blind?token=<token>
   → 接收志愿者位置更新、订单状态变更

8. 登出
   POST /api/auth/logout
```

### 6.2 志愿者用户流程

```
1-2. 同盲人，登录拿 token

3. 设置角色（保存新 token）
   POST /api/user/role { "role": "VOLUNTEER" }

4. 连接志愿者 WebSocket（先连接才能收新订单）
   ws://47.114.113.171/ws/volunteer?token=<token>

5. 通过 WebSocket 上报位置
   { "type": "LOCATION_UPDATE", "lat": 39.92, "lng": 116.47, "isOnline": true }

6. 收到 NEW_ORDER 后响应
   POST /api/orders/{id}/respond { "action": "ACCEPT" }

7. 确认出发
   POST /api/orders/{id}/en-route

8. 确认到达
   POST /api/orders/{id}/arrived

9. 完成订单
   POST /api/orders/{id}/finish

10. 登出
    POST /api/auth/logout
```

### 6.3 CS 管理员流程

```
1. 登录
   POST /api/cs/auth/login { "username": "admin", "password": "xxx" }

2. 查看待审核志愿者身份证
   GET /api/admin/volunteers/review/id

3. 审核通过
   POST /api/admin/volunteers/review/id { "userId": 42, "approved": true }

4. 查看培训统计
   GET /api/admin/volunteers/training/stats

5. 查看通知模板
   GET /api/admin/notification-templates

6. 处理紧急事件
   GET /api/cs/emergency-events
   PUT /api/cs/emergency-events/{id}/accept
   PUT /api/cs/emergency-events/{id}/resolve

7. 登出
   POST /api/cs/auth/logout
```

---

## 七、注意事项

1. **Swagger 在生产环境不可用** — 开发环境仍可通过 `http://localhost:8081/swagger-ui/index.html` 查看接口文档
2. **手机号只能用中国手机号** — 11位数字，1开头，第二位3-9
3. **token 替换** — 设置角色后务必用新 token 替换旧 token
4. **WebSocket 重连** — 如果 WebSocket 断开需要自动重连（建议3秒间隔）
5. **登出后 token 立即失效** — 登出操作会使该用户所有设备的 token 失效
6. **测试验证码** — 测试环境下验证码会打印在后端控制台日志中，查看方式：`sudo journalctl -u blindrun -f`
