## Context
项目是 Flutter 双端演示应用，当前志愿者端地图直接使用 OSM 切片，盲人端预约只支持语音解析出模拟地点和时间。接入高德后，需要同时解决三件事：地图底图替换、盲人端地点候选搜索、平台端 key 与隐私合规。

## Goals
- 让志愿者端在 Android/iOS 上显示高德地图与待接单位置
- 让盲人端先完成地点选择，再发起预约
- 在缺少高德 key、权限不足、测试环境中提供可诊断的降级展示

## Non-Goals
- 不实现路线规划、导航播报、实时轨迹跟随
- 不引入后端代理层
- 不做复杂 POI 分类筛选或地图拖点交互

## Decisions
### 1. 地图与搜索能力分离
- 地图展示使用 `amap_flutter_map`
- 一次定位使用 `amap_flutter_location`
- 地点候选搜索优先走高德 Web Service 输入提示接口
- 当缺失 Web Service key 或调用失败时，回退到本地演示地点列表过滤，保证流程可用

### 2. 统一配置入口
- 使用 `String.fromEnvironment` 读取 `AMAP_ANDROID_KEY`、`AMAP_IOS_KEY`、`AMAP_WEB_KEY`
- 页面代码只依赖统一的 AMap 配置对象，不直接读取环境变量
- 地图组件在 key 不完整或测试环境下不实例化原生地图，而是显示占位卡片与说明

### 3. 盲人端流程
- `/blind/request` 负责承载预约表单与确认
- 新增 `/blind/request/place` 作为地点搜索页
- 地点页通过语音或文本发起搜索，返回结构化地点对象
- 预约页只处理地点回填、时间输入和提交

### 4. 数据模型
- 新增结构化地点值对象，包含名称、地址、纬度、经度
- `RunRequestInput` 使用结构化地点对象
- `Run` 保留 `location` 文本用于现有展示，但其来源改为地点对象名称，并新增可选 `address`
- 仓储创建行程时写入真实经纬度，停止生成随机坐标

## Risks
- 高德 key 或隐私初始化不正确会导致地图白屏
- Widget test 环境不支持原生地图 PlatformView
- 地点搜索接口缺 key 时流程会受阻

## Mitigations
- 将 map 渲染包在统一 wrapper 中，测试与缺 key 时走占位 UI
- 搜索接口内建本地 fallback 列表
- README 明确 dart-define 与平台配置要求
