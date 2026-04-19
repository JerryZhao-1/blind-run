## 1. Map Camera Support

- [x] 1.1 Extend the shared `AMapMapView` wrapper so callers can move the native camera to an app-provided coordinate after the map controller is available.
- [x] 1.2 Ensure camera movement uses `AMapController.moveCamera(CameraUpdate.newLatLngZoom(...))` rather than relying on `initialCameraPosition` rebuilds.

## 2. Volunteer Dashboard Location Display

- [x] 2.1 Store the latest successful app-level volunteer location in the dashboard state when readiness location succeeds.
- [x] 2.2 Add a "当前位置" app-level map marker based on the latest volunteer location.
- [x] 2.3 Auto-center the volunteer map once after the first successful location for the current dashboard page lifetime.
- [x] 2.4 Add a visible "回到当前位置" control that recenters the map to the latest known volunteer location on demand.

## 3. Heartbeat And Validation

- [x] 3.1 Keep later heartbeat location updates from automatically moving the camera after the initial auto-center.
- [x] 3.2 Add widget tests or focused unit coverage for first-location centering intent, current-location marker presence, and heartbeat non-recentering behavior where Flutter test boundaries allow it.
- [x] 3.3 Manually verify on iOS that the volunteer dashboard moves from the default Beijing view to the real app-level current location after successful readiness.
