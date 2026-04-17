## 1. OpenSpec
- [x] 1.1 新增 `update-amap-api-validation` proposal、tasks 与 spec delta

## 2. Validation Audit
- [x] 2.1 核对高德 Web Service、地图 SDK、定位 SDK 的调用入口与配置来源
- [x] 2.2 记录当前已验证结论与已知限制，作为文档与验收基线

## 3. Android Key Injection Fix
- [x] 3.1 调整 Android 原生 key 解析逻辑，优先读取 Flutter `dart-defines`
- [x] 3.2 保留 `AMAP_ANDROID_KEY` 环境变量作为兼容回退

## 4. Documentation and Coverage
- [x] 4.1 更新 README 中的高德运行方式、排查步骤与 iOS 真机验收说明
- [x] 4.2 补充地图降级测试，覆盖无 key 时不创建原生地图的占位行为

## 5. Validation
- [x] 5.1 通过 `flutter analyze`
- [x] 5.2 通过 `flutter test`
- [x] 5.3 验证高德 `inputtips` 返回 `status=1`
- [x] 5.4 验证 Android Debug 构建仅使用 `--dart-define=AMAP_ANDROID_KEY=...` 时，原生产物内 key 注入正确
- [x] 5.5 验证 iOS simulator 构建可通过，并记录 Apple Silicon 模拟器限制
