## Context
The existing prototype is a browser-only React app using local role persistence, Firestore-backed run state, browser speech synthesis/recognition, and React Leaflet. The target is a mobile-first Flutter app for Android and iOS with no backend dependency.

## Goals
- Deliver a single Flutter codebase that reproduces the current end-user flows.
- Keep dual-role interaction state synchronized inside one local app session.
- Use device-native speech capabilities when available, with deterministic fallback paths.
- Preserve a clear accessibility-oriented blind-side UI and a richer volunteer-side UI.

## Non-Goals
- No backend or cloud synchronization.
- No production-grade authentication.
- No admin tooling or real payment/reward redemption.

## Decisions
### State management
Use `flutter_riverpod` for app state, repositories, and service injection. The app has multiple cross-screen concerns and deterministic mock flows; Riverpod keeps those dependencies explicit without introducing widget tree coupling.

### Routing
Use `go_router` with redirect guards driven by the persisted session role. This preserves the current route structure while fitting Flutter navigation.

### Data model and storage
Replace Firestore documents with in-memory repository state backed by lightweight persistence for session and settings. Run data is initialized from local mock seeds and updated through repository methods.

### Device capabilities
- Use `flutter_tts` for speech output.
- Use `speech_to_text` for speech recognition.
- Wrap both behind interfaces so the app can fall back cleanly when permissions, device support, or simulators fail.
- Use `flutter_map` with OpenStreetMap tiles for map rendering and provide a non-blocking placeholder if tiles cannot load.

## Risks
- Speech recognition behaves differently across iOS, Android, simulator, and permission states.
- `flutter_map` depends on network tiles; tile failure must not block the volunteer flow.
- Replacing Firestore listeners with local state requires careful modeling so blind and volunteer flows stay coherent.

## Validation
- Widget tests for route/session behavior and main flow entrypoints.
- Repository tests for run lifecycle transitions.
- Static validation via `flutter analyze`.
