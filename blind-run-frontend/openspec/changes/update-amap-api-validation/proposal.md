# Change: update-amap-api-validation

## Why
高德地图接入已经落地，但验收中发现 Android 原生层读取 key 的方式与 README 中推荐的 `flutter run --dart-define=...` 不一致，可能导致 Dart 层认为已配置、高德原生 SDK 实际拿不到 key。还需要把当前已经验证过的高德调用情况沉淀成可复现的使用与排查说明。

## What Changes
- 审计高德 Web Service、地图 SDK、定位 SDK 的调用链，并记录当前可验证结果
- 修复 Android 原生 key 注入，使其优先读取 Flutter 传入的 `--dart-define`，环境变量保留为兼容回退
- 保持地图缺 key 降级、地点搜索无 key 降级等现有行为不变
- 更新 README，给出可验证的运行方式、校验命令和已知限制

## Impact
- Affected specs: `map-experience`
- Affected code: `android/app/build.gradle.kts`, `README.md`, `test/widget_test.dart`
