## 1. Configuration Foundation

- [x] 1.1 Audit the current AMap key loading path across Dart, Android Gradle, iOS build settings, and helper scripts, and remove script-only assumptions from the implementation plan
- [x] 1.2 Introduce a unified development-time configuration source for `AMAP_ANDROID_KEY`, `AMAP_IOS_KEY`, and `AMAP_WEB_KEY` that does not require `./scripts/flutter_run_with_amap.sh`
- [x] 1.3 Refactor `AMapConfig` and related consumers so Dart runtime checks resolve from the unified injected configuration instead of `String.fromEnvironment` alone

## 2. Platform Injection

- [x] 2.1 Update Android key injection so the native AMap SDK and Dart layer resolve the same effective `AMAP_ANDROID_KEY` from the unified configuration source
- [x] 2.2 Update iOS key injection so `Info.plist` and native AMap initialization resolve `AMAP_IOS_KEY` without relying on generated local xcconfig output from the helper script
- [x] 2.3 Preserve separate handling for native SDK keys and `AMAP_WEB_KEY` so map initialization and Web Service search can fail independently

## 3. Map Experience and Documentation

- [x] 3.1 Keep existing map fallback and place-search fallback behavior intact after the key-loading refactor
- [x] 3.2 Update README to document the primary non-script launch/build flow, any compatibility path that remains, and the current validation steps
- [x] 3.3 Add or revise documentation to state that client-side `AMAP_WEB_KEY` usage is transitional and that server-side proxying is the long-term security direction

## 4. Verification

- [x] 4.1 Add or update tests covering unified AMap configuration behavior and missing-key fallback paths
- [x] 4.2 Verify supported builds resolve consistent Android and iOS native key injection from the new configuration path
- [x] 4.3 Run `openspec validate refactor-amap-key-loading --strict --no-interactive`, `flutter analyze`, and relevant tests before marking the change complete
