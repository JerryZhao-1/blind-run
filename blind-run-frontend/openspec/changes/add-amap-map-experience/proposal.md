# Change: add-amap-map-experience

## Why
当前项目的地图展示仍基于 `flutter_map + OSM`，盲人端预约流程也没有真实地点搜索和结构化选点能力。为了贴近中文场景下的地图体验，需要接入高德地图能力，统一双端地图展示与地点选择流程。

## What Changes
- 新增高德地图基础能力层，封装地图展示、定位与地点搜索接入
- 志愿者端将地图展示从 `flutter_map` 切换为高德地图
- 盲人端新增“语音/文字搜索地点 -> 候选列表选择 -> 返回预约”的地点选择流程
- `RunRequestInput` 与 `RunRepository.createBlindRun` 改为使用结构化地点与真实坐标
- 平台侧补齐高德 `key`、定位权限、隐私合规初始化与缺失配置时的降级提示

## Impact
- Affected specs: `map-experience`
- Affected code: `lib/features/blind`, `lib/features/volunteer`, `lib/core/models`, `lib/core/services`, `lib/app/providers.dart`, `android/app`, `ios/Runner`, `pubspec.yaml`, `README.md`
