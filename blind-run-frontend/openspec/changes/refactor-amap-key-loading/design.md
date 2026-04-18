## Context

当前项目的 AMap 配置横跨 Dart、Android Gradle、iOS xcconfig 与本地启动脚本四层。Dart 侧通过 `String.fromEnvironment` 读取 `AMAP_ANDROID_KEY`、`AMAP_IOS_KEY`、`AMAP_WEB_KEY`，Android 原生层会从 `dart-defines` 或进程环境变量读取 `AMAP_ANDROID_KEY`，iOS 则依赖 `scripts/flutter_run_with_amap.sh` 从 `.env` 生成 `ios/Flutter/Amap.local.xcconfig`。这让“本地 `.env` 是真实配置源”只在脚本路径下成立，直接运行 `flutter run`、IDE 启动或原生构建时都存在行为分叉。

该变更涉及 Flutter 运行时配置、Android 构建脚本、iOS 构建设置、README 和 AMap Web Service 使用边界，属于跨层重构且带有安全与迁移复杂度，因此需要单独设计。

## Goals / Non-Goals

**Goals:**
- 让开发期 AMap key 以未跟踪的本地环境文件作为单一配置源，不再要求通过专用启动脚本才能完成注入
- 保证 Flutter、Android、iOS 从一致的构建时配置中获取各自所需 key，避免 Dart 层和原生层来源不一致
- 保持现有地图缺 key 降级、地点搜索 fallback、验证文档与排障能力不退化
- 明确 `AMAP_WEB_KEY` 的短期职责与长期迁移方向，为后续服务端代理方案预留边界

**Non-Goals:**
- 本次不实现后端代理、高德签名服务或新的服务端接口
- 本次不改变地图展示、定位、地点搜索的产品流程
- 本次不引入新的秘密管理平台或 CI/CD 密钥托管方案

## Decisions

### 1. 本地环境文件作为开发期单一来源
- 决策：将 `.env` / `.env.local` / `.env.amap.local` 视为开发期唯一权威来源，构建层负责从该来源映射到 Flutter、Android、iOS 所需配置。
- 原因：项目 README 已将 `.env` 作为本地敏感配置入口，继续沿用这一习惯成本最低，也能避免脚本、手工 xcconfig、命令行 `--dart-define` 三套入口并存。
- 备选方案：
  - 保留 `flutter_run_with_amap.sh` 作为唯一入口：实现最少，但会继续把 IDE 运行和脚本运行分成两套行为。
  - 完全改为手工 `--dart-define`：对 Flutter CLI 友好，但 iOS 原生层仍需额外注入，且开发者体验更差。

### 2. 原生平台按各自构建机制注入，不强求单一技术手段
- 决策：Android 继续通过 Gradle 在构建期解析环境并产出 `BuildConfig` / manifest placeholder；iOS 通过 Xcode 构建设置读取环境并注入 `Info.plist`，不再依赖运行前生成本地 xcconfig 文件。
- 原因：Android 与 iOS 的原生注入模型本就不同，追求“完全同一种注入技术”会引入额外胶水层，反而降低可维护性。目标应是“同一配置源”，不是“同一实现手段”。
- 备选方案：
  - 将所有 key 都改成 `--dart-define`：Flutter 层简单，但 iOS 原生仍无法天然消费 Dart 常量。
  - 继续保留生成式 `Amap.local.xcconfig`：可用，但需要额外脚本和文件生命周期管理。

### 3. Dart 配置模型从“只读编译常量”改为“可承接构建注入结果”
- 决策：`AMapConfig` 需要支持从统一运行时注入结果构建，而不能继续只依赖 `String.fromEnvironment`。
- 原因：如果取消脚本并允许原生构建层直接读取 `.env`，Dart 侧若仍只读编译常量，就会与原生层脱节。配置对象必须成为“统一出口”，而不是“编译期常量薄封装”。
- 备选方案：
  - 保持 `String.fromEnvironment` 不变：会迫使所有启动方式继续传 `--dart-define`，与去脚本目标冲突。
  - 在页面层分别读取平台配置：会把配置细节扩散到 UI 和 service 层。

### 4. Web Service key 短期保留客户端直连，长期迁移到服务端代理
- 决策：本次保留 `AMAP_WEB_KEY` 的客户端直连行为以避免扩大范围，但在设计、规格和文档中明确其长期目标是迁移到后端代理；禁止将“后端下发 key 给客户端”定义为目标方案。
- 原因：当前地点搜索直接请求 `restapi.amap.com`，重构 key 加载不应顺手引入未设计的后端接口；但安全方向必须明确，否则会固化客户端持钥模式。
- 备选方案：
  - 本次直接实现服务端代理：安全收益最高，但超出当前变更范围。
  - 后端按会话下发 key 给客户端：看似更安全，实质仍会把 key 暴露在客户端。

### 5. 文档需要区分“当前实现”与“后续安全演进”
- 决策：README 与变更文档分别说明当前支持的启动/构建方式、缺 key 行为，以及 Web Service key 的长期代理化方向。
- 原因：项目现在兼具运行说明和排障说明功能，如果不明确区分当前实现与未来方向，开发者会误以为客户端直连已经是最终方案。

## Risks / Trade-offs

- [不同平台构建入口差异] → 用统一配置源和统一配置对象约束行为，而不是强行统一注入技术
- [去掉脚本后本地启动路径增多，可能出现某些 IDE 场景未加载环境] → 在 README 中明确支持的运行方式，并在缺 key 时继续提供可诊断降级
- [Dart 配置模型重构可能影响现有测试] → 保持 `AMapConfig` 对外语义稳定，只改变其取值来源和构造方式
- [客户端继续持有 Web Service key 仍存在泄露风险] → 在规格中把服务端代理列为后续迁移方向，并避免把“后端下发 key”误记为安全方案

## Migration Plan

1. 新增统一的本地环境读取与构建注入路径，保证 Android 与 iOS 都可以在不依赖专用脚本的情况下拿到 key
2. 调整 `AMapConfig` 与相关服务，使 Dart 层从统一注入结果读取配置
3. 保留现有降级提示、fallback 与验证步骤，更新 README 的运行说明
4. 删除或降级旧启动脚本的主路径地位，避免文档继续将其作为推荐入口
5. 通过 analyze / test / 平台构建验证新的配置链路，必要时保留兼容回退一段时间

回滚策略：
- 若新配置链路在某个平台不可用，可临时恢复原脚本或生成式 xcconfig 作为兼容回退，但 README 需明确其为过渡方案

## Open Questions

- iOS 最终采用在 Xcode 构建阶段直接读取环境，还是保留一个静态本地 xcconfig 模板并由开发者自行填写，需在实现前根据工程可维护性定稿
- 后续服务端代理会由现有后端承担，还是需要单独的轻量转发层，本次只记录方向，不在本变更内定案
