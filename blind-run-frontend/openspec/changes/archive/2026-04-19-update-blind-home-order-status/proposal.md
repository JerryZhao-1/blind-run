## Why

盲人端当前在创建订单成功后会直接进入订单详情页，而主页只依赖内存中的活动订单状态进行展示。这样会让用户缺少一个稳定的“返回主页查看当前状态”的入口，也无法保证回到主页时看到的是后端最新订单状态。

## What Changes

- 调整盲人端下单成功后的默认落点，从订单详情页改为盲人主页。
- 让盲人主页在进入时主动刷新当前用户的订单列表，并展示活动订单的状态、地点和时间摘要。
- 在盲人主页为活动订单提供明确的“查看当前订单”入口；无活动订单时仍保留“发起预约”主入口。
- 在盲人订单详情页增加显式返回主页入口，确保无障碍用户可以随时回到主页。

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `blind-order-flow`: 更新盲人端下单后的默认导航，并要求主页在返回后展示后端最新的当前订单状态摘要。

## Impact

- Affected specs: `blind-order-flow`
- Affected code: `lib/features/blind`, `lib/app/state/app_state_controller.dart`, `lib/core/navigation/app_router.dart`
- Affected tests: `test/blind_accessibility_test.dart`, blind flow widget/navigation coverage
- APIs: 继续复用现有 `/api/orders`, `/api/orders/mine`, `/api/orders/{id}`，不新增后端接口
