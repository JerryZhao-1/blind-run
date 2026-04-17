import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/app/state/app_state_controller.dart';
import 'package:aidrun_demo/core/models/reward_item.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/amap_map_view.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VolunteerDashboardPage extends ConsumerStatefulWidget {
  const VolunteerDashboardPage({super.key});

  @override
  ConsumerState<VolunteerDashboardPage> createState() =>
      _VolunteerDashboardPageState();
}

class _VolunteerDashboardPageState extends ConsumerState<VolunteerDashboardPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final pendingRuns =
        state.runs.where((run) => run.status == RunStatus.pending).toList();
    final activeRun = state.runs
        .where((run) => run.volunteer?.id == controller.currentUser?.id)
        .where(
          (run) => [
            RunStatus.accepted,
            RunStatus.arrived,
            RunStatus.running,
          ].contains(run.status),
        )
        .firstOrNull;
    final volunteerHistoryRuns = state.runs
        .where((run) => run.volunteer?.id == controller.currentUser?.id)
        .where(
          (run) => [RunStatus.completed, RunStatus.cancelled].contains(run.status),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final pages = [
      _VolunteerMapTab(
        config: ref.watch(aMapConfigProvider),
        controller: controller,
        pendingRuns: pendingRuns,
        activeRun: activeRun,
      ),
      _VolunteerHistoryTab(history: volunteerHistoryRuns),
      _VolunteerStoreTab(rewards: state.rewards),
      _VolunteerProfileTab(controller: controller),
    ];

    return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        indicatorColor: Colors.black,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) => setState(() => _tabIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: '地图'),
          NavigationDestination(icon: Icon(Icons.history), label: '历史'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: '商城'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}

class _VolunteerMapTab extends StatelessWidget {
  const _VolunteerMapTab({
    required this.config,
    required this.controller,
    required this.pendingRuns,
    required this.activeRun,
  });

  final AMapConfig config;
  final AppStateController controller;
  final List<Run> pendingRuns;
  final Run? activeRun;

  @override
  Widget build(BuildContext context) {
    final currentActiveRun = activeRun;
    final points = pendingRuns
        .where((run) => run.latitude != null && run.longitude != null)
        .map((run) => AMapMarkerViewData(
              id: run.id,
              latitude: run.latitude!,
              longitude: run.longitude!,
              title: run.location,
              snippet: run.address.isEmpty ? run.timeLabel : run.address,
            ))
        .toList();

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 180),
            child: AMapMapView(
              config: config,
              centerLatitude: 39.9042,
              centerLongitude: 116.4074,
              zoom: 11,
              showMyLocation: true,
              markers: points,
              fallbackMessage: '高德地图未配置完成，当前显示附近需求列表，地图区域已降级。',
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: const [
                Icon(Icons.circle, color: AppTheme.emerald, size: 12),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '在线 - 正在寻找附近需求',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.menu),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.56,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        '附近需求 (${pendingRuns.length})',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      if (currentActiveRun != null)
                        GestureDetector(
                          onTap: () =>
                              context.go('/volunteer/run/${currentActiveRun.id}'),
                          child: SectionCard(
                            color: Colors.black,
                            child: const Row(
                              children: [
                                Icon(Icons.navigation, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '当前行程进行中',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (currentActiveRun != null) const SizedBox(height: 12),
                      for (final run in pendingRuns) ...[
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.softGray,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(Icons.place),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          run.location,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          run.timeLabel,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (run.notes.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.softGray,
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Text('备注: ${run.notes}'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: currentActiveRun != null
                                      ? null
                                      : () {
                                          controller.acceptRun(run.id);
                                          context.go('/volunteer/run/${run.id}');
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.black12,
                                    disabledForegroundColor: Colors.black38,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(
                                    currentActiveRun != null ? '请先完成当前行程' : '立即接单',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VolunteerHistoryTab extends StatelessWidget {
  const _VolunteerHistoryTab({required this.history});

  final List<Run> history;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '历史行程',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('暂无历史行程'),
              ),
            ),
          for (final run in history) ...[
            SectionCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          run.location,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${run.timeLabel} · ${run.status.volunteerLabel}'),
                      ],
                    ),
                  ),
                  Text(
                    run.status == RunStatus.completed ? '+50 积分' : '已取消',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _VolunteerStoreTab extends StatelessWidget {
  const _VolunteerStoreTab({required this.rewards});

  final List<RewardItem> rewards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('积分商城'),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: const SectionCard(
                color: Color(0xFF1D1D1F),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前可用积分', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 12),
                    Text(
                      '1,250 分',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.6,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = rewards[index];
                  return SectionCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppNetworkImage(
                          imageUrl: item.imageUrl,
                          height: 96,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.points} 积分',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(36),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('兑换'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                childCount: rewards.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerProfileTab extends StatelessWidget {
  const _VolunteerProfileTab({required this.controller});

  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 32),
          SectionCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.softGray,
                  child: Text(
                    user?.displayName.characters.first ?? '志',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? '志愿者',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  '4.98 分 · 128 次评价',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric(label: '完成行程', value: '42'),
                    _Metric(label: '陪伴公里', value: '186'),
                    _Metric(label: '获得积分', value: '1.2k'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings),
                  title: const Text('设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppTheme.red),
                  title: const Text(
                    '退出登录 / 切换角色',
                    style: TextStyle(color: AppTheme.red),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    controller.logout();
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
