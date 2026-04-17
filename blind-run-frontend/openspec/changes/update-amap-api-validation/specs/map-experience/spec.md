## ADDED Requirements
### Requirement: Android Native AMap Key Matches Flutter Runtime Configuration
The system SHALL inject the Android native AMap key from the same Flutter runtime configuration used by Dart code, with the process environment retained as a compatibility fallback.

#### Scenario: Flutter run injects native Android key
- **WHEN** the app is built or run with `--dart-define=AMAP_ANDROID_KEY=TEST123`
- **THEN** the generated Android `BuildConfig` exposes `AMAP_ANDROID_KEY=TEST123`
- **AND** the merged Android manifest writes `com.amap.api.v2.apikey` as `TEST123`

#### Scenario: Environment variable remains supported as fallback
- **WHEN** no Flutter `AMAP_ANDROID_KEY` define is provided
- **AND** the process environment contains `AMAP_ANDROID_KEY`
- **THEN** the Android native map and location SDKs receive that environment value

### Requirement: Verified AMap Usage Guide Is Available
The system SHALL document a verified usage path and troubleshooting guide for AMap integrations.

#### Scenario: README explains supported launch flows
- **WHEN** a developer follows the project README
- **THEN** they can either launch with direct `flutter run --dart-define=...` arguments
- **AND** use `.env.amap.local` together with `./scripts/flutter_run_with_amap.sh`

#### Scenario: README explains validation and simulator limits
- **WHEN** a developer diagnoses AMap integration failures
- **THEN** the README provides a Web Service validation step and Android native key verification step
- **AND** it states that iOS map rendering must be finally validated on a real device because Apple Silicon simulators have an upstream AMap SDK architecture limitation
