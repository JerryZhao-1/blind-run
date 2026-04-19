## 1. OpenSpec

- [x] 1.1 完成 `add-volunteer-demand-sheet-snapping` 的 proposal、design、tasks 与 `volunteer-demand-sheet` spec delta
- [x] 1.2 通过 `openspec validate add-volunteer-demand-sheet-snapping --strict --no-interactive`

## 2. Sheet Skeleton

- [x] 2.1 将志愿者地图首页的固定底部面板重构为三档吸附的常驻需求抽屉，并定义下/中/上三档比例与默认中档状态
- [x] 2.2 移除地图区域对固定底部高度的硬编码让位，使地图可见区随抽屉状态动态变化
- [x] 2.3 为抽屉引入明确的档位状态、滚动控制和吸附逻辑，限制释放后只落到相邻合法档位

## 3. Content And Interaction

- [x] 3.1 实现下档的摘要模式，只展示 handle、需求标题和一条紧凑状态摘要
- [x] 3.2 实现中档的默认决策模式，展示当前行程入口和完整需求卡片列表
- [x] 3.3 实现上档的列表浏览模式，保留 sticky 标题区并允许完整需求列表滚动
- [x] 3.4 实现抽屉 header、内容区、内部列表与地图之间的手势接管规则
- [x] 3.5 实现 marker 点选与抽屉联动：下档点 marker 自动升到中档并滚动到对应需求卡

## 4. Verification

- [x] 4.1 为默认档位、三档吸附和内容层级增加 widget tests
- [x] 4.2 为列表滚动边界、下拉收起规则和 marker 联动增加 widget tests
- [x] 4.3 确认志愿者地图首页现有接单与当前行程跳转行为保持可用
