# AidRun 助盲跑 Flutter App

本仓库为 Flutter 双端项目，当前主工程用于构建 Android 与 iOS 前端展示版。

## 技术栈

- Flutter
- Riverpod
- go_router
- amap_flutter_map / amap_flutter_location
- flutter_tts
- speech_to_text
- shared_preferences

## 运行方式

1. 安装 Flutter 依赖
   `flutter pub get`
2. 复制 `.env.example` 为本地 `.env`，填入 Firebase / Gemini / AMap key
3. 推荐使用本地环境文件直接启动
   `flutter run --dart-define-from-file=.env`
4. 也可以显式传入 `dart-define`
   `flutter run --dart-define=AMAP_ANDROID_KEY=你的AndroidKey --dart-define=AMAP_IOS_KEY=你的iOSKey --dart-define=AMAP_WEB_KEY=你的WebServiceKey`
5. 兼容入口：已配置本地 `.env` 后可直接运行
   `./scripts/flutter_run_with_amap.sh`

## 高德地图配置

- Android 原生地图/定位 SDK 与 Dart 层优先读取 Flutter `dart-defines` 注入的 `AMAP_ANDROID_KEY`；若未提供，Android 构建仍兼容回退到进程环境变量
- iOS 地图与定位 SDK 与 Dart 层通过同一份 Flutter `DART_DEFINES` 获取 `AMAP_IOS_KEY`，不再依赖生成式 `Amap.local.xcconfig`
- 地点搜索 Web Service key 通过同一份运行时配置中的 `AMAP_WEB_KEY` 注入
- 迁移参考用的 React `src/` 代码通过 `.env` 中的 `VITE_FIREBASE_*` 变量读取 Firebase 配置
- `GEMINI_API_KEY` 通过 Vite 环境变量注入构建时常量，不再写入仓库文件
- `./scripts/flutter_run_with_amap.sh` 仅作为兼容包装，内部会转为 `flutter run --dart-define-from-file=<env-file>`
- 未配置 key 时：
  - 志愿者端地图会显示占位提示，不会白屏
  - 盲人端地点搜索会回退到本地演示地点列表
- 高德 SDK 使用前需要满足隐私合规要求，当前工程已在地图 wrapper 和定位服务中按“已展示、已包含、已同意”进行初始化，正式接入时应替换为真实隐私授权流程
- 当前客户端仍直接持有 `AMAP_WEB_KEY` 调用高德 Web Service，这只是过渡方案；长期方向应迁移到服务端代理，而不是由服务端下发 key 给客户端

## 高德接入校验

- Web Service key 校验
  `curl -s "https://restapi.amap.com/v3/assistant/inputtips?key=$AMAP_WEB_KEY&keywords=天坛&datatype=poi&city=北京&citylimit=false"`
  返回结果应包含 `"status":"1"` 和非空 `tips`
- 推荐的本地启动/构建方式
  `flutter run --dart-define-from-file=.env`
- Android 原生 key 注入校验
  `flutter build apk --debug --dart-define=AMAP_ANDROID_KEY=TEST123 --dart-define=AMAP_IOS_KEY=DUMMY --dart-define=AMAP_WEB_KEY=DUMMY`
  随后检查 `build/app/generated/source/buildConfig/debug/com/aidrun/aidrun_demo/BuildConfig.java` 与 `build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml`，两处都应包含 `TEST123`
- iOS 构建校验
  `flutter build ios --simulator --debug --no-codesign --dart-define=AMAP_ANDROID_KEY=DUMMY --dart-define=AMAP_IOS_KEY=DUMMY --dart-define=AMAP_WEB_KEY=DUMMY`
  当前 Apple Silicon 上的 iOS 26+ simulator 会提示 `AMapFoundation` 缺少 `arm64` 支持，构建可继续，但地图渲染与定位验收必须以真机为准

## 常见排查

- 地图区域只显示占位提示：
  - 检查是否通过 `--dart-define-from-file` 或显式 `--dart-define` 传入 `AMAP_ANDROID_KEY` / `AMAP_IOS_KEY`
  - Android 若使用 `flutter run --dart-define=...`，可按上面的 BuildConfig/manifest 步骤确认原生层也已拿到 key
- 地点搜索只返回演示数据：
  - 检查 `AMAP_WEB_KEY` 是否配置
  - 先执行上面的 `inputtips` 请求，确认高德 Web Service key 返回 `"status":"1"`

## 生产后端基线对接

- 当前 Flutter 客户端默认通过 `--dart-define=API_BASE_URL=...` 读取后端地址；未显式传入时默认使用 `http://47.114.113.171`
- 当前实现以线上 Swagger 和运行时行为为准，不再假设本地 `blind-run-backend` 仓库完全等同于生产接口
- 已接通的基础链路：
  - 短信登录、JWT 会话恢复、`/api/auth/me` 校验、角色绑定
  - 盲人端资料、紧急联系人、下单、活跃订单轮询、取消、评价
  - 志愿者端资料、可接单列表、我的订单、接单、出发、到达、完成、位置心跳
- 当前明确排除的链路：
  - WebSocket 实时推送
  - 管理后台 / 客服后台 / 培训 / 紧急事件 / 通话 / 志愿者认证上传
  - 商城奖励后端化
- 当前实现需要容忍的运行时漂移：
  - 线上返回的错误体可能是 `{message}`、`{error}` 或空响应，客户端统一按 `ApiFailure` 归一化
  - 线上存在多类 JWT；普通用户端仅依赖 `/api/auth/*` 和用户侧接口，不假设客服 token 可互通
  - 部分生产字段与旧文档不一致，例如盲人资料中的紧急联系人字段已迁移为独立资源，客户端以独立紧急联系人接口为准

## 校验命令

- 静态检查
  `flutter analyze`
- 测试
  `flutter test`
- Android Debug 构建
  `flutter build apk --debug`
- iOS Simulator Debug 构建
  `flutter build ios --simulator --debug --no-codesign`

## 说明

- `lib/` 为当前 Flutter 主代码。
- `android/` 与 `ios/` 为原生工程壳。
- 原 `src/` React 代码保留为迁移参考，不再作为主运行时入口。
- 本地敏感配置统一放在未跟踪的 `.env` / `.env.local` / `.env.amap.local` 中。
