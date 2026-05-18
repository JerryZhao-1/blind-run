import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/blind_page_scaffold.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BlindDashboardPage extends ConsumerStatefulWidget {
  const BlindDashboardPage({super.key});

  @override
  ConsumerState<BlindDashboardPage> createState() => _BlindDashboardPageState();
}

class _BlindDashboardPageState extends ConsumerState<BlindDashboardPage> {
  String? _lastAnnouncedSummary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appStateControllerProvider.notifier).refreshBlindRuns();
      if (!mounted) {
        return;
      }
      final activeRun = ref
          .read(appStateControllerProvider.notifier)
          .blindActiveRun;
      _lastAnnouncedSummary = _announcementForActiveRun(activeRun);
      ref
          .read(blindAccessibilityServiceProvider)
          .announcePage(_lastAnnouncedSummary!);
    });
  }

  String _announcementForActiveRun(Run? activeRun) {
    if (activeRun == null) {
      return '盲人主页。当前没有进行中的行程。向下找到发起预约按钮开始新的陪跑预约。';
    }
    return '盲人主页。当前订单状态${activeRun.status.blindLabel}，地点${activeRun.location}，时间${activeRun.timeLabel}。向下找到查看当前订单按钮打开详情。';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final activeRun = controller.blindActiveRun;
    final currentAnnouncement = _announcementForActiveRun(activeRun);

    if (_lastAnnouncedSummary != null &&
        _lastAnnouncedSummary != currentAnnouncement) {
      _lastAnnouncedSummary = currentAnnouncement;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(blindAccessibilityServiceProvider)
            .announceStatusChange(currentAnnouncement);
      });
    }

    return BlindPageScaffold(
      aiButtonKey: const Key('blind-ai-assistant-button'),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              '盲人主流程',
              style: TextStyle(
                color: AppTheme.yellow,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              BlindAccessibleButton(
                onPressed: () => context.push('/settings'),
                enabled: true,
                label: '设置',
                hint: '打开设置页面',
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.zinc,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.settings),
                  label: const Text(
                    '设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              BlindAccessibleButton(
                onPressed: () async {
                  await controller.logout();
                  if (!context.mounted) {
                    return;
                  }
                  context.go('/login');
                },
                enabled: true,
                label: '退出登录',
                hint: '退出当前账号并返回登录页',
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.zinc,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    '退出登录',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          Semantics(
            container: true,
            label: activeRun == null
                ? '当前没有进行中的行程，你可以立即发起新的陪跑预约。'
                : '当前有进行中的行程，状态为${activeRun.status.blindLabel}，地点${activeRun.location}，时间${activeRun.timeLabel}。你可以打开当前订单详情。',
            child: SectionCard(
              color: AppTheme.zinc,
              child: activeRun == null
                  ? const Text(
                      '当前没有进行中的行程。\n请使用下方主按钮发起新的陪跑预约。',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前订单：${activeRun.status.blindLabel}',
                          style: const TextStyle(
                            color: AppTheme.yellow,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activeRun.location,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeRun.timeLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (activeRun != null) ...[
            const SizedBox(height: 16),
            Semantics(
              container: true,
              label:
                  '当前订单摘要，状态${activeRun.status.blindLabel}，地点${activeRun.location}，时间${activeRun.timeLabel}。',
              child: SectionCard(
                color: Colors.white10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.yellow,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '返回主页后，你可以在这里快速确认订单状态；需要更详细的信息时，再进入当前订单详情。',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          activeRun != null
              ? LargeActionButton(
                  key: const Key('blind-dashboard-active-order-button'),
                  onPressed: () => context.go('/blind/run/${activeRun.id}'),
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.black,
                  icon: const Icon(Icons.directions_run, size: 120),
                  title: '查看当前订单',
                  subtitle:
                      '${activeRun.status.blindLabel} · ${activeRun.timeLabel}',
                  semanticsLabel:
                      '查看当前订单，当前状态${activeRun.status.blindLabel}，地点${activeRun.location}',
                  semanticsHint: '打开当前行程详情，并继续完成下一步',
                )
              : LargeActionButton(
                  key: const Key('blind-dashboard-create-order-button'),
                  onPressed: () => context.go('/blind/request'),
                  backgroundColor: AppTheme.yellow,
                  foregroundColor: Colors.black,
                  icon: const Icon(Icons.navigation, size: 120),
                  title: '发起预约',
                  subtitle: '进入地点和时间填写流程',
                  semanticsLabel: '发起陪跑预约',
                  semanticsHint: '打开预约页面，先选择地点，再设置出发时间',
                ),
        ],
      ),
    );
  }
}
