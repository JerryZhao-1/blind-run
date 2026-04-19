## Context

The volunteer dashboard now uses app-level AMap location to establish intake readiness and reports that coordinate to `/api/volunteer/location`. That coordinate is visible in diagnostic output and can differ from the map camera, because the map wrapper still initializes at a fixed Beijing coordinate and the AMap map plugin does not recenter when `initialCameraPosition` changes after creation.

The native map plugin also deliberately does not use automatic tracking as the source of camera movement. On iOS the plugin sets `userTrackingMode` to `None`; on Android it uses a no-center follow mode. Therefore `showMyLocation: true` is insufficient for centering the volunteer map.

## Goals / Non-Goals

**Goals:**
- Center the volunteer dashboard map on the same app-level location used for intake readiness after the first successful fix.
- Provide a manual "return to my location" control using the latest known app-level location.
- Avoid moving the camera repeatedly during heartbeat updates.
- Keep the map usable if the native blue-dot layer fails independently of app-level location.

**Non-Goals:**
- Changing backend matching, order feeds, or `/api/volunteer/location`.
- Replacing AMap Flutter plugins.
- Making all map screens follow current location.
- Forcing continuous map tracking while the volunteer pans or inspects nearby orders.

## Decisions

### Decision: Use app-level volunteer location as the map source of truth

The volunteer dashboard should reuse the latest `DeviceLocation` returned by the readiness/heartbeat location service, because that is the location already proven to drive backend intake readiness.

**Alternatives considered:**
- Use the map plugin's `onLocationChanged` blue-dot callback. Rejected because it is a separate native location path and has already produced misleading failures independent of app-level intake readiness.
- Rely on `showMyLocation`. Rejected because the current plugin intentionally does not center the camera.

### Decision: Add imperative camera movement to the shared map wrapper

The shared `AMapMapView` wrapper should expose a minimal way to receive `onMapCreated` or a target coordinate that triggers `AMapController.moveCamera(CameraUpdate.newLatLngZoom(...))`. The volunteer dashboard should use this to move the camera when the first app-level location becomes available.

**Alternatives considered:**
- Only update `centerLatitude` and `centerLongitude`. Rejected because `initialCameraPosition` is only applied when the native map is created.
- Modify the native plugin to enable tracking mode. Rejected because tracking semantics differ by platform and would make every `showMyLocation` map follow unexpectedly.

### Decision: Auto-center once, then let users control the map

The dashboard should automatically recenter on the first successful app-level location for the current page lifetime. Later heartbeats should update the stored latest location and marker, but should not move the camera unless the volunteer taps the return-to-location control.

**Alternatives considered:**
- Recenter on every heartbeat. Rejected because it fights user panning and can make nearby-order inspection frustrating.
- Never recenter automatically. Rejected because the current user report shows explanatory copy alone is not enough.

## Risks / Trade-offs

- [Map controller timing] -> Store pending target location and move once the native map controller is available.
- [User location marker duplicates native blue dot] -> Use a clear app-level "当前位置" marker and keep it consistent with backend readiness location.
- [Heartbeat updates can arrive while the user is browsing] -> Update marker/debug data but do not move camera unless explicitly requested.
- [Platform camera behavior varies] -> Use existing `CameraUpdate.newLatLngZoom` through the plugin's public controller API instead of native-only code.

## Migration Plan

1. Extend the shared Flutter map wrapper with a safe camera-move hook or target-location input.
2. Store the latest app-level volunteer location in the dashboard state when readiness location succeeds.
3. Auto-center once after the first successful location and add/update a current-location marker.
4. Add a visible "回到当前位置" control that moves to the latest app-level location on demand.
5. Validate on iOS with the current live AMap location logs and keep backend behavior unchanged.

Rollback can remove the camera movement and current-location marker while leaving readiness state and backend reporting intact.

## Open Questions

None.
