## 1. Demo Bootstrap

- [x] 1.1 Add an explicit demo-showcase startup switch and root provider override wiring for demo dependencies.
- [x] 1.2 Add a lightweight showcase launcher/bootstrap path that seeds prepared session, current-user, and role state without live SMS login.

## 2. Demo Data Sources

- [x] 2.1 Create app-owned demo repositories and services under `lib/demo/` using a shared in-memory showcase scenario store.
- [x] 2.2 Add deterministic demo map/location configuration so showcase runs avoid live AMap and live device-location dependencies.

## 3. Showcase Flows

- [x] 3.1 Wire volunteer showcase scenarios through nearby-order, accept, active-order, progress, and history flows using the shared demo state.
- [x] 3.2 Wire blind showcase scenarios through home, request, active-order, cancel/review, and settings/profile flows using the shared demo state.

## 4. Demo Validation

- [x] 4.1 Add clear launch guidance and visible demo-mode cues so presenters can reliably enter the showcase flow.
- [x] 4.2 Verify the end-to-end presentation script for both volunteer and blind showcase scenarios on the target demo environment.

## 5. Presentation Realism Refresh

- [x] 5.1 Replace fallback map presentation with real AMap rendering backed by curated fixed volunteer/blind points and deterministic seeded location input.
- [x] 5.2 Change presentation startup so volunteer/blind scenario selection happens through non-visible startup configuration instead of an in-app showcase launcher.
- [x] 5.3 Remove visible demo-only UI cues so the presentation branch looks the same as the real product during recordings and live demos.
- [x] 5.4 Diagnose and fix the volunteer nearby-demand menu artifact that currently appears as a tiny black mark.
- [x] 5.5 Re-run the presentation script on the target demo device/network and confirm the volunteer and blind flows still work with real AMap visuals enabled.
