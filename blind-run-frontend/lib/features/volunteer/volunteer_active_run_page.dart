import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/amap_map_view.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VolunteerActiveRunPage extends ConsumerWidget {
  const VolunteerActiveRunPage({
    super.key,
    required this.runId,
  });

  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final config = ref.watch(aMapConfigProvider);
    final run = state.runs.where((item) => item.id == runId).firstOrNull;
    if (run == null) {
      return const Scaffold(
        body: Center(child: Text('未找到行程')),
      );
    }

    if (run.status == RunStatus.completed) {
      return Scaffold(
        backgroundColor: AppTheme.softGray,
        body: Stack(
          children: [
            Positioned.fill(
              child: AMapMapView(
                config: config,
                centerLatitude: run.latitude ?? 39.9062,
                centerLongitude: run.longitude ?? 116.4074,
                zoom: 15,
                markers: [
                  if (run.latitude != null && run.longitude != null)
                    AMapMarkerViewData(
                      id: run.id,
                      latitude: run.latitude!,
                      longitude: run.longitude!,
                      title: run.location,
                      snippet: run.address,
                    ),
                ],
                fallbackMessage: '高德地图未配置完成，结算页地图已降级为占位状态。',
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '行程结算',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text('感谢您的爱心陪伴'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SectionCard(
                            color: AppTheme.softGray,
                            child: Column(
                              children: [
                                const Text('里程'),
                                const SizedBox(height: 8),
                                Text(
                                  '${run.distanceKm?.toStringAsFixed(1) ?? '3.2'} km',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SectionCard(
                            color: AppTheme.softGray,
                            child: Column(
                              children: [
                                const Text('时长'),
                                const SizedBox(height: 8),
                                Text(
                                  '${run.durationMinutes ?? 34} min',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: SectionCard(
                            color: Color(0xFFD1FAE5),
                            child: Column(
                              children: [
                                Text('获得积分'),
                                SizedBox(height: 8),
                                Text(
                                  '+50',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.emerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.go('/volunteer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('返回大厅'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      body: Stack(
        children: [
          Positioned.fill(
            child: AMapMapView(
              config: config,
              centerLatitude: run.latitude ?? 39.9042,
              centerLongitude: run.longitude ?? 116.4074,
              zoom: 13,
              markers: [
                if (run.latitude != null && run.longitude != null)
                  AMapMarkerViewData(
                    id: run.id,
                    latitude: run.latitude!,
                    longitude: run.longitude!,
                    title: run.location,
                    snippet: run.address.isEmpty ? run.timeLabel : run.address,
                  ),
              ],
              fallbackMessage: '高德地图未配置完成，行程地图已降级为占位状态。',
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: FilledButton(
              onPressed: () => context.go('/volunteer'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.arrow_back),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    run.status.volunteerLabel,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    switch (run.status) {
                      RunStatus.accepted => '请尽快前往指定地点',
                      RunStatus.arrived => '您已到达，请与跑者汇合',
                      RunStatus.running => '保持配速，注意安全',
                      RunStatus.pending => '准备接单',
                      RunStatus.completed => '感谢您的志愿服务',
                      RunStatus.cancelled => '行程已取消',
                    },
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    color: AppTheme.softGray,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '盲人跑者',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.message)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.phone)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${run.location}\n${run.timeLabel}${run.notes.isEmpty ? '' : '\n备注: ${run.notes}'}',
                                style: const TextStyle(height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (run.status == RunStatus.accepted) {
                          controller.updateRunStatus(run.id, RunStatus.arrived);
                        } else if (run.status == RunStatus.arrived) {
                          controller.updateRunStatus(run.id, RunStatus.running);
                        } else if (run.status == RunStatus.running) {
                          controller.updateRunStatus(run.id, RunStatus.completed);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: run.status == RunStatus.running
                            ? AppTheme.red
                            : Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: Icon(
                        switch (run.status) {
                          RunStatus.accepted => Icons.navigation,
                          RunStatus.arrived => Icons.play_arrow,
                          RunStatus.running => Icons.flag,
                          _ => Icons.check,
                        },
                      ),
                      label: Text(
                        switch (run.status) {
                          RunStatus.accepted => '我已到达集合点',
                          RunStatus.arrived => '开始跑步',
                          RunStatus.running => '结束行程',
                          _ => '返回',
                        },
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
