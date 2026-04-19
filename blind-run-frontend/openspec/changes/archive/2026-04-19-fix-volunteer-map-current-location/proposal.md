## Why

The volunteer dashboard can now become intake-ready with a real device location, but the map still opens on the fixed Beijing viewport and does not move to the volunteer's current location. This creates a new mismatch: the status says the volunteer is online, while the map visually suggests the app is still somewhere else.

## What Changes

- Recenter the volunteer dashboard map after the first successful app-level location fix used for intake readiness.
- Add an explicit way to return the map camera to the latest known volunteer location after the user pans away.
- Represent the latest app-level volunteer location on the map so the volunteer can see the same location used for backend intake readiness.
- Avoid repeatedly moving the camera on every heartbeat, so background location updates do not fight user map gestures.
- Preserve existing backend endpoints, order matching, and location-report payloads.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `map-experience`: Volunteer-facing maps must be able to center on the app-confirmed current location rather than only showing a fixed initial viewport.

## Impact

- Affects the shared Flutter `AMapMapView` wrapper, the volunteer dashboard map tab, and widget tests around volunteer map/readiness behavior.
- May require using `AMapController.moveCamera(CameraUpdate.newLatLngZoom(...))` because `initialCameraPosition` only applies when the native map is created.
- Does not change backend APIs, authentication, order feeds, or AMap key configuration.
