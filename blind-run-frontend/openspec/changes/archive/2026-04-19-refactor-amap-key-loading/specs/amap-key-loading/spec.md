## ADDED Requirements

### Requirement: AMap Development Configuration Uses Local Environment Files
The system SHALL treat the supported local environment files as the single development-time source for AMap keys and SHALL NOT require a dedicated helper script to make those keys available.

#### Scenario: Supported local env file provides AMap keys for development
- **WHEN** a developer defines `AMAP_ANDROID_KEY`, `AMAP_IOS_KEY`, or `AMAP_WEB_KEY` in a supported local environment file
- **THEN** the app's supported build and run flows can consume those values without requiring `./scripts/flutter_run_with_amap.sh`

### Requirement: Flutter and Native Layers Receive Consistent AMap Keys
The system SHALL inject AMap keys so that Dart code and native platform code resolve from the same effective configuration for a given build.

#### Scenario: Android receives the same effective key in Dart and native layers
- **WHEN** an Android build is produced with a configured `AMAP_ANDROID_KEY`
- **THEN** the Dart configuration model resolves that key for runtime checks
- **AND** the Android native layer exposes the same effective key to `BuildConfig` and the merged manifest entry `com.amap.api.v2.apikey`

#### Scenario: iOS receives the same effective key in Dart and native layers
- **WHEN** an iOS build is produced with a configured `AMAP_IOS_KEY`
- **THEN** the Dart configuration model resolves that key for runtime checks
- **AND** the iOS app bundle exposes the same effective key through `Info.plist` so native AMap initialization can use it

### Requirement: AMap Configuration Distinguishes Native SDK and Web Service Keys
The system SHALL model native SDK keys and Web Service keys as separate configuration concerns while exposing them through one unified application configuration surface.

#### Scenario: Native map key is missing but Web Service key exists
- **WHEN** the runtime configuration contains `AMAP_WEB_KEY` but omits the platform's native SDK key
- **THEN** native map features remain disabled
- **AND** Web Service-backed search features can still evaluate their own key availability independently

#### Scenario: Web Service key is missing but native SDK key exists
- **WHEN** the runtime configuration contains the platform's native SDK key but omits `AMAP_WEB_KEY`
- **THEN** native map features remain eligible to initialize
- **AND** place-search features can independently fall back without treating the native key as a substitute
