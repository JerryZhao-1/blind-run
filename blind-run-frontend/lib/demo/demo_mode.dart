const bool kDemoShowcaseMode = bool.fromEnvironment(
  'DEMO_SHOWCASE_MODE',
  defaultValue: false,
);

const String kDemoShowcaseScenarioKey = String.fromEnvironment(
  'DEMO_SHOWCASE_SCENARIO',
  defaultValue: 'volunteer',
);

const String kDemoVideoCaptureSceneKey = String.fromEnvironment(
  'DEMO_VIDEO_CAPTURE_SCENE',
  defaultValue: '',
);
