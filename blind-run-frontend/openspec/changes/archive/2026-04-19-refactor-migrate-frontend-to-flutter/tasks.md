## 1. Specification
- [x] 1.1 Add migration proposal, design, tasks, and spec delta for the Flutter rewrite
- [x] 1.2 Validate the OpenSpec change with strict mode

## 2. Flutter project bootstrap
- [x] 2.1 Generate a Flutter app in the repository root with Android and iOS targets
- [x] 2.2 Add required Flutter dependencies for routing, state, maps, speech, and local persistence
- [x] 2.3 Replace the current web-first entrypoint with the Flutter runtime

## 3. App architecture
- [x] 3.1 Add app models, repositories, providers, and service abstractions
- [x] 3.2 Implement local mock state flow for session, runs, settings, and rewards
- [x] 3.3 Add route guards and shared theme tokens

## 4. Product flows
- [x] 4.1 Implement role selection and session restore
- [x] 4.2 Implement blind dashboard, request flow, active run flow, and rating flow
- [x] 4.3 Implement volunteer dashboard tabs, accept flow, active run flow, and summary flow
- [x] 4.4 Implement role-aware settings pages

## 5. Device integrations and validation
- [x] 5.1 Add TTS and speech recognition with fallback behavior
- [x] 5.2 Add map rendering with graceful degradation
- [x] 5.3 Run `flutter analyze` and `flutter test`
