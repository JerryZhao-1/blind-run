## Why

当前 AMap key 的本地开发体验依赖 `./scripts/flutter_run_with_amap.sh`，iOS 还需要通过脚本生成 `Amap.local.xcconfig`，导致配置入口分散、启动方式不一致，也让 Dart 层与原生层对 key 来源的约束越来越难维护。与此同时，`AMAP_WEB_KEY` 仍由客户端直接使用，虽然短期可接受，但需要在变更设计中明确未来迁移到后端代理的安全方向。

## What Changes

- 重构 AMap key 加载方式，统一以未跟踪的本地环境文件作为开发期单一配置源，移除对专用启动脚本的依赖
- 调整 Flutter、Android、iOS 三层配置链路，使 Dart 层和原生层都能从同一套构建时配置中获取 AMap key
- 更新 AMap 配置模型，区分原生 SDK key 与 Web Service key 的职责和未来演进方向
- 保持现有地图缺 key 降级、地点搜索 fallback、README 校验指引等行为可用
- 在文档与设计中明确：Web Service key 的长期目标是迁移到后端代理，而不是继续由客户端直接持有

## Capabilities

### New Capabilities
- `amap-key-loading`: 统一描述 AMap key 在 Flutter、Android、iOS 之间的加载、注入、回退与开发配置约束
- `map-experience`: 规范化当前地图与地点搜索相关的 AMap 运行时配置要求，并纳入新的 key 加载约束与长期安全方向

### Modified Capabilities
<!-- none -->

## Impact

- Affected code: `lib/core/services/amap_config.dart`, `android/app/build.gradle.kts`, `ios/Flutter/*.xcconfig`, `ios/Runner/Info.plist`, `README.md`, `scripts/flutter_run_with_amap.sh`
- Affected systems: Flutter runtime config, Android Gradle build, iOS Xcode build settings, AMap Web Service integration
- Dependencies: local `.env` files, Flutter build configuration, AMap Android/iOS SDK key injection, AMap Web Service key usage
