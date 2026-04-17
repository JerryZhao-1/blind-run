import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/run_rating.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/blind_page_scaffold.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BlindActiveRunPage extends ConsumerStatefulWidget {
  const BlindActiveRunPage({super.key, required this.runId});

  final String runId;

  @override
  ConsumerState<BlindActiveRunPage> createState() => _BlindActiveRunPageState();
}

class _BlindActiveRunPageState extends ConsumerState<BlindActiveRunPage> {
  RunStatus? _lastAnnouncedStatus;
  bool _ratedAnnouncementSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final run = ref
          .read(appStateControllerProvider)
          .runs
          .where((item) => item.id == widget.runId)
          .firstOrNull;
      if (run == null) {
        return;
      }
      _lastAnnouncedStatus = run.status;
      ref
          .read(blindAccessibilityServiceProvider)
          .announcePage(_statusAnnouncement(run.status));
    });
  }

  String _statusAnnouncement(RunStatus status) {
    return switch (status) {
      RunStatus.pending => '当前状态：正在匹配志愿者，请原地等待。',
      RunStatus.accepted => '当前状态：志愿者已接单，正在赶来。',
      RunStatus.arrived => '当前状态：志愿者已到达，请准备汇合。',
      RunStatus.running => '当前状态：已经开始跑步。',
      RunStatus.completed => '当前状态：行程已结束，请评价本次志愿服务。',
      RunStatus.cancelled => '当前状态：本次行程已取消。',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final run = state.runs.where((item) => item.id == widget.runId).firstOrNull;
    if (run == null) {
      return const Scaffold(body: Center(child: Text('未找到行程')));
    }

    if (_lastAnnouncedStatus != run.status) {
      _lastAnnouncedStatus = run.status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(blindAccessibilityServiceProvider)
            .announceStatusChange(_statusAnnouncement(run.status));
      });
    }

    if (run.status == RunStatus.completed &&
        run.blindRating == null &&
        !_ratedAnnouncementSent) {
      _ratedAnnouncementSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(blindAccessibilityServiceProvider)
            .announceStatusChange('行程已结束，请从好评、一般或差评中选择一个评价。');
      });
    }

    if (run.status != RunStatus.completed || run.blindRating != null) {
      _ratedAnnouncementSent = false;
    }

    if (run.status == RunStatus.completed && run.blindRating == null) {
      return BlindPageScaffold(
        aiButtonKey: const Key('blind-ai-assistant-button'),
        header: Semantics(
          header: true,
          child: const Text(
            '行程已结束',
            style: TextStyle(
              color: AppTheme.yellow,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: ListView(
          children: [
            Semantics(
              container: true,
              label: '请评价本次志愿服务。选择好评、一般或差评。',
              child: const Text(
                '请评价本次志愿服务',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 32),
            for (final rating in RunRating.values) ...[
              BlindAccessibleButton(
                onPressed: () {
                  controller.rateRun(widget.runId, rating);
                  context.go('/blind');
                },
                enabled: true,
                label: '评价${rating.label}',
                hint: '提交${rating.label}并返回盲人主页',
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: switch (rating) {
                        RunRating.good => AppTheme.emerald,
                        RunRating.average => AppTheme.yellow,
                        RunRating.bad => AppTheme.red,
                      },
                      foregroundColor: rating == RunRating.bad
                          ? Colors.white
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 28),
                    ),
                    child: Text(
                      rating.label,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      );
    }

    return BlindPageScaffold(
      aiButtonKey: const Key('blind-ai-assistant-button'),
      body: ListView(
        children: [
          Semantics(
            container: true,
            label:
                '当前行程状态${run.status.blindLabel}。${switch (run.status) {
                  RunStatus.pending => '请在原地等待。',
                  RunStatus.accepted => '志愿者正在赶来。',
                  RunStatus.arrived => '请与志愿者汇合。',
                  RunStatus.running => '享受跑步的乐趣吧。',
                  RunStatus.completed => '感谢您的使用。',
                  RunStatus.cancelled => '本次行程已取消。',
                }}',
            child: SectionCard(
              color: AppTheme.zinc,
              child: Column(
                children: [
                  Text(
                    run.status.blindLabel,
                    style: const TextStyle(
                      color: AppTheme.yellow,
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    switch (run.status) {
                      RunStatus.pending => '请在原地等待',
                      RunStatus.accepted => '志愿者正在赶来',
                      RunStatus.arrived => '请与志愿者汇合',
                      RunStatus.running => '享受跑步的乐趣吧',
                      RunStatus.completed => '感谢您的使用',
                      RunStatus.cancelled => '本次行程已取消',
                    },
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (run.volunteer != null &&
              [
                RunStatus.accepted,
                RunStatus.arrived,
                RunStatus.running,
              ].contains(run.status))
            Semantics(
              container: true,
              label:
                  '志愿者信息，姓名${run.volunteer!.name}，评分${run.volunteer!.rating.toStringAsFixed(1)}。',
              child: SectionCard(
                color: AppTheme.zinc,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white10,
                      child: Text(
                        run.volunteer!.name.characters.first,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            run.volunteer!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '评分 ${run.volunteer!.rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: AppTheme.yellow,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (run.volunteer != null &&
              [
                RunStatus.accepted,
                RunStatus.arrived,
                RunStatus.running,
              ].contains(run.status))
            const SizedBox(height: 16),
          Semantics(
            container: true,
            label:
                '行程信息，地点${run.location}，时间${run.timeLabel}${run.notes.isNotEmpty ? '，备注${run.notes}' : ''}。',
            child: SectionCard(
              color: AppTheme.zinc,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(icon: Icons.place, text: run.location),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.schedule, text: run.timeLabel),
                  if (run.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.notes, text: run.notes),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (run.status == RunStatus.pending)
            _SemanticButton(
              label: '测试，模拟志愿者接单',
              hint: '将当前状态切换为志愿者已接单',
              onPressed: () {
                controller.acceptRun(run.id);
              },
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 22),
                ),
                child: const Text(
                  '[测试] 模拟志愿者接单',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          if (run.status == RunStatus.accepted) ...[
            _SemanticButton(
              label: '联系志愿者',
              hint: '当前为演示按钮，不会拨号',
              onPressed: () {},
              child: FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 22),
                ),
                icon: const Icon(Icons.phone),
                label: const Text(
                  '联系志愿者',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SemanticButton(
              label: '测试，模拟志愿者到达',
              hint: '将当前状态切换为志愿者已到达',
              onPressed: () =>
                  controller.updateRunStatus(run.id, RunStatus.arrived),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text(
                  '[测试] 模拟志愿者到达',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (run.status == RunStatus.arrived)
            _SemanticButton(
              label: '测试，模拟开始跑步',
              hint: '将当前状态切换为开始跑步',
              onPressed: () =>
                  controller.updateRunStatus(run.id, RunStatus.running),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text(
                  '[测试] 模拟开始跑步',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          if (run.status == RunStatus.running)
            _SemanticButton(
              label: '测试，模拟结束行程',
              hint: '将当前状态切换为行程完成，并进入评价',
              onPressed: () =>
                  controller.updateRunStatus(run.id, RunStatus.completed),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text(
                  '[测试] 模拟结束行程',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          if ([RunStatus.pending, RunStatus.accepted].contains(run.status)) ...[
            const SizedBox(height: 12),
            _SemanticButton(
              label: '取消行程',
              hint: '取消当前陪跑请求并返回盲人主页',
              onPressed: () {
                controller.cancelRun(run.id);
                context.go('/blind');
              },
              child: FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 22),
                ),
                icon: const Icon(Icons.cancel),
                label: const Text(
                  '取消行程',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SemanticButton extends StatelessWidget {
  const _SemanticButton({
    required this.label,
    required this.hint,
    this.onPressed,
    required this.child,
  });

  final String label;
  final String hint;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlindAccessibleButton(
      onPressed: onPressed,
      enabled: onPressed != null,
      label: label,
      hint: hint,
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.yellow),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
