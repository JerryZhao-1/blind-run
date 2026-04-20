import 'dart:async';

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
  Timer? _pollingTimer;
  RunStatus? _lastAnnouncedStatus;
  bool _ratedAnnouncementSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refresh();
      final run = ref
          .read(appStateControllerProvider.notifier)
          .runById(widget.runId);
      if (run == null) {
        return;
      }
      _lastAnnouncedStatus = run.status;
      ref
          .read(blindAccessibilityServiceProvider)
          .announcePage(_statusAnnouncement(run.status));
    });
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref
        .read(appStateControllerProvider.notifier)
        .refreshOrder(widget.runId);
    await ref
        .read(appStateControllerProvider.notifier)
        .refreshReview(widget.runId);
  }

  String _statusAnnouncement(RunStatus status) {
    return switch (status) {
      RunStatus.pendingMatch => '当前状态：正在匹配志愿者，请原地等待。',
      RunStatus.pendingAccept => '当前状态：已有志愿者收到邀请，正在等待确认。',
      RunStatus.inProgress => '当前状态：志愿者已接单。',
      RunStatus.driverEnRoute => '当前状态：志愿者正在赶来。',
      RunStatus.driverArrived => '当前状态：志愿者已到达，请准备汇合。',
      RunStatus.completed => '当前状态：行程已结束，请评价本次志愿服务。',
      RunStatus.cancelled => '当前状态：本次行程已取消。',
      RunStatus.rematching => '当前状态：系统正在重新匹配志愿者。',
      RunStatus.noVolunteer => '当前状态：暂无志愿者响应，你可以稍后再试或取消行程。',
    };
  }

  String _statusSupportText(RunStatus status) {
    return switch (status) {
      RunStatus.pendingMatch => '请在原地等待',
      RunStatus.pendingAccept => '正在等待志愿者确认',
      RunStatus.inProgress => '志愿者已接单，请保持沟通',
      RunStatus.driverEnRoute => '志愿者正在赶来',
      RunStatus.driverArrived => '请与志愿者汇合',
      RunStatus.completed => '感谢您的使用',
      RunStatus.cancelled => '本次行程已取消',
      RunStatus.rematching => '系统正在重新匹配',
      RunStatus.noVolunteer => '当前暂无志愿者可接单',
    };
  }

  bool _canCancel(RunStatus status) {
    return {
      RunStatus.pendingMatch,
      RunStatus.pendingAccept,
      RunStatus.rematching,
      RunStatus.noVolunteer,
    }.contains(status);
  }

  Widget _buildHeader(String title) {
    return Row(
      children: [
        BlindAccessibleButton(
          key: const Key('blind-active-run-home-button'),
          onPressed: () => context.go('/blind'),
          enabled: true,
          label: '返回盲人主页',
          hint: '返回主页并查看当前订单状态摘要',
          child: FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.zinc,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text(
              '返回主页',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.yellow,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final demoMode = ref.watch(demoShowcaseModeProvider);
    final run = controller.runById(widget.runId);
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
        header: _buildHeader('行程已结束'),
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
                onPressed: () async {
                  await controller.rateRun(widget.runId, rating);
                  if (!context.mounted) {
                    return;
                  }
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

    final hasVolunteerPhone = (run.volunteerPhone ?? run.volunteer?.phone ?? '')
        .trim()
        .isNotEmpty;
    final volunteerDisplayPhone =
        run.volunteerPhone ?? run.volunteer?.phone ?? '暂未分配';

    return BlindPageScaffold(
      aiButtonKey: const Key('blind-ai-assistant-button'),
      header: _buildHeader('当前订单'),
      body: ListView(
        children: [
          Semantics(
            container: true,
            label:
                '当前行程状态${run.status.blindLabel}。${_statusSupportText(run.status)}。',
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
                    _statusSupportText(run.status),
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
          if (hasVolunteerPhone)
            Semantics(
              container: true,
              label: '志愿者联系方式，手机号$volunteerDisplayPhone。',
              child: SectionCard(
                color: AppTheme.zinc,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '志愿者联系方式',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            volunteerDisplayPhone,
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
          if (hasVolunteerPhone) const SizedBox(height: 16),
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
          if (_canCancel(run.status)) ...[
            const SizedBox(height: 16),
            _SemanticButton(
              label: '取消行程',
              hint: '取消当前陪跑请求并返回盲人主页',
              onPressed: () async {
                await controller.cancelRun(run.id);
                if (!context.mounted) {
                  return;
                }
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
          if (demoMode && run.status == RunStatus.driverArrived) ...[
            const SizedBox(height: 16),
            _SemanticButton(
              label: '结束行程',
              hint: '结束当前演示行程并进入评价页面',
              onPressed: () async {
                await controller.finishRun(run.id);
              },
              child: FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 22),
                ),
                icon: const Icon(Icons.flag),
                label: const Text(
                  '结束行程',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppTheme.red),
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
