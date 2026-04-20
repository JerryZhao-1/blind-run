# AidRun Demo Video Playbook

This playbook produces one side-by-side review video from separately recorded blind-side and volunteer-side clips. The output is editorially aligned, not live-synchronized.

## Output

- Final shareable export: `~/Desktop/aidrun-demo-review.mp4`
- Local raw clips: `.demo-video/raw/`
- Local intermediate exports or retries: `.demo-video/render/`

`.demo-video/` is intentionally gitignored.

## Capture Scenes

All capture scenes use:

- `--dart-define-from-file=.env`
- `--dart-define=DEMO_SHOWCASE_MODE=true`
- `--dart-define=DEMO_VIDEO_CAPTURE_SCENE=<scene>`

Recommended iOS workflow on this branch:

1. Run `flutter build ios --debug --config-only ...` with the target scene define.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Select the target device.
4. Press Run in Xcode.
5. Record the clip with the native macOS recording workflow you trust for that device.

## Required Clips

### 1. `blind-request.mov`

- Scene: `blind-request`
- Start screen: blind request flow
- Operator actions:
  1. Open place search
  2. Search `海湾一号` or `小径湾`
  3. Select `华润小径湾海湾一号`
  4. Keep the default time or pick one preset
  5. Submit the request
  6. Stop after the app returns to the blind home page and shows the current-order affordance

### 2. `volunteer-nearby.mov`

- Scene: `volunteer-nearby`
- Start screen: volunteer nearby-demand dashboard
- Operator actions:
  1. Let the nearby demand card sit on screen briefly
  2. Tap `立即接单`
  3. Wait for the active-order screen to appear
  4. Tap `我已出发`
  5. Stop after the state advances to the next action

### 3. `blind-active.mov`

- Scene: `blind-active`
- Start screen: blind current-order detail
- Operator actions:
  1. Let the current status and volunteer contact stay visible
  2. Do not cancel or rate
  3. Stop after a short hold

### 4. `volunteer-enroute.mov`

- Scene: `volunteer-enroute`
- Start screen: volunteer active-order page
- Operator actions:
  1. Let the map and order card stay visible
  2. Do not advance to arrival in this clip
  3. Stop after a short hold

### 5. `blind-review.mov`

- Scene: `blind-review`
- Start screen: blind rating page
- Operator actions:
  1. Keep the review choices visible
  2. Optionally tap `非常满意` near the end if you want the clip to land on completion
  3. Stop before leaving the rating context unless you deliberately want the post-rating transition

### 6. `volunteer-complete.mov`

- Scene: `volunteer-complete`
- Start screen: volunteer settlement page
- Operator actions:
  1. Keep mileage, duration, and points visible
  2. Do not tap `返回大厅`
  3. Stop after a short hold

## Story Pairing

The default composition manifest pairs the clips in this order:

1. `blind-request.mov` + `volunteer-nearby.mov`
2. `blind-active.mov` + `volunteer-enroute.mov`
3. `blind-review.mov` + `volunteer-complete.mov`

## Naming Rules

- Save raw files exactly with the names above.
- Put every source clip under `.demo-video/raw/`.
- Keep replacements on the same file name so the composition step does not need to change.

## Composition

The repository-owned compositor reads `tools/demo_video/review_manifest.json`.

Use the browser compositor flow that has been verified against the current clip set:

```bash
python3 tools/demo_video/demo_video_server.py 4174
open -a Safari "http://127.0.0.1:4174/tools/demo_video/review_compositor.html?clips=/.demo-video/raw/"
```

Then click `预览并导出` and copy the newest downloaded `aidrun-demo-review*.mp4` to `~/Desktop/aidrun-demo-review.mp4`.

The composition layout is a 1920x1080 landscape video with:

- left pane: `盲人端`
- right pane: `志愿者端`
- dark matte background outside the app panes

The current manifest trims each pair to the shorter clip duration so the split screen never drifts into an empty pane.

For the current macOS mirroring setup, `review_manifest.json` also includes a calibrated `sourceCrop` rectangle for display-level recordings from `screencapture -v -D2 ...`. Keep the iPhone Mirroring window in the same position and size while recording the full clip set.
