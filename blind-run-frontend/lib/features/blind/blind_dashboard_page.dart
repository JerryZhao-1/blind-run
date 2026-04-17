import 'package:aidrun_demo/app/providers.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(blindAccessibilityServiceProvider)
          .announcePage('盲人主页。向下找到发起预约按钮开始新的陪跑预约，或查看当前行程。');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final activeRun = state.runs
        .where((run) => run.blindRunnerId == controller.currentUser?.id)
        .where(
          (run) => [
            RunStatus.pending,
            RunStatus.accepted,
            RunStatus.arrived,
            RunStatus.running,
          ].contains(run.status),
        )
        .firstOrNull;

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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              BlindAccessibleButton(
                onPressed: () {
                  controller.logout();
                  context.go('/');
                },
                enabled: true,
                label: '切换角色',
                hint: '退出盲人模式并返回角色选择',
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
                    '切换角色',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
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
                : '当前有进行中的行程，状态为${activeRun.status.blindLabel}，地点${activeRun.location}，时间${activeRun.timeLabel}。',
            child: SectionCard(
              color: AppTheme.zinc,
              child: Text(
                activeRun == null
                    ? '当前没有进行中的行程。\n请使用下方主按钮发起新的陪跑预约。'
                    : '当前行程：${activeRun.status.blindLabel}\n${activeRun.location} · ${activeRun.timeLabel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          activeRun != null
              ? LargeActionButton(
                  onPressed: () => context.go('/blind/run/${activeRun.id}'),
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.black,
                  icon: const Icon(Icons.directions_run, size: 120),
                  title: '查看行程',
                  subtitle: activeRun.status.blindLabel,
                  semanticsLabel: '查看当前行程，当前状态${activeRun.status.blindLabel}',
                  semanticsHint: '打开当前行程详情，并继续完成下一步',
                )
              : LargeActionButton(
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
