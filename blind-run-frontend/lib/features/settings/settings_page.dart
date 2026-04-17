import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    _contactController = TextEditingController(
      text: ref.read(appStateControllerProvider).settings.emergencyContact,
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.watch(appStateControllerProvider.notifier);
    final role = state.role;

    if (role == UserRole.volunteer) {
      return Scaffold(
        backgroundColor: AppTheme.softGray,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text(
            '设置',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              child: Column(
                children: const [
                  _SettingLine(
                    icon: Icons.person_outline,
                    title: '个人资料',
                  ),
                  Divider(),
                  _SettingLine(
                    icon: Icons.shield_outlined,
                    title: '账号安全',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: state.settings.volunteerAvailable,
                    onChanged: controller.updateVolunteerAvailability,
                    title: const Text('接收新订单推送'),
                    secondary: const Icon(Icons.notifications_active_outlined),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Text(
                    '关闭后，您将不会收到新的附近盲人跑步预约推送，但已接订单不受影响。',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                children: const [
                  _SettingLine(icon: Icons.help_outline, title: '帮助中心'),
                  Divider(),
                  _SettingLine(icon: Icons.tune, title: '通用设置'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                ref.read(speechServiceProvider).speak('设置已保存');
                context.pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存设置'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                controller.logout();
                context.go('/');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.red,
                side: const BorderSide(color: Colors.black12),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('退出登录 / 切换角色'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: AppTheme.yellow,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          '设置',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            color: AppTheme.zinc,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '紧急联系人电话',
                  style: TextStyle(
                    color: AppTheme.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: '请输入手机号',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '在紧急情况下，我们将通过短信通知该联系人。',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              controller.updateEmergencyContact(_contactController.text.trim());
              ref.read(speechServiceProvider).speak('设置已保存');
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text(
              '保存设置',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              controller.logout();
              context.go('/');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              '切换角色',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingLine extends StatelessWidget {
  const _SettingLine({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
