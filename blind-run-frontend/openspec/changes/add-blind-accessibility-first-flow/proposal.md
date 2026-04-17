# Change: add-blind-accessibility-first-flow

## Why
当前盲人端虽有 TTS 与语音输入 demo，但核心流程仍依赖视觉理解与普通触屏操作。页面缺少系统性读屏语义、焦点顺序、状态播报、语音失败回退与一致入口布局，不能证明盲人用户在“看不见”的前提下可独立完成操作。需要先建立“盲人优先”的交互规范，再接入后续 AI 语音能力。

## What Changes
- 为盲人主流程建立“读屏优先 + 语音辅助 + 触控回退”的无障碍交互规范
- 统一盲人端页面结构：单主任务、全宽大按钮、稳定读屏顺序、避免纯视觉提示
- 为地点搜索与时间输入增加完整语音状态流：开始收听、识别中、成功、失败、不可用、手动回退
- 为行程状态变化增加统一播报策略，确保用户无需盯屏即可获知接单、到达、开始、结束等关键事件
- 为 AI 语音助手预留固定入口，但本期不接入真实 AI，仅保留可点击占位能力与语义说明
- 补充无障碍 widget tests，验证语义标签、主操作可达性、失败回退和占位按钮存在

## Impact
- Affected specs: `blind-accessibility`
- Affected code: `lib/features/blind`, `lib/core/services/speech_service.dart`, `lib/core/services/speech_recognition_service.dart`, `lib/core/widgets/common_widgets.dart`, `lib/app/providers.dart`, `test/widget_test.dart`
