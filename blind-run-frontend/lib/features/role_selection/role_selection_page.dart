import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  bool _isRouting = false;

  Future<void> _selectRole(UserRole role) async {
    setState(() => _isRouting = true);
    ref.read(appStateControllerProvider.notifier).selectRole(role);
    final speech = ref.read(speechServiceProvider);
    await speech.speak('已切换到${role.label}模式');
    if (!mounted) {
      return;
    }
    context.go(role == UserRole.blind ? '/blind' : '/volunteer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    '欢迎使用\nAidRun 助盲跑',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  LargeActionButton(
                    onPressed: () => _selectRole(UserRole.blind),
                    enabled: !_isRouting,
                    backgroundColor: AppTheme.yellow,
                    foregroundColor: Colors.black,
                    icon: const Icon(Icons.visibility, size: 76),
                    title: '我是盲人跑者',
                    subtitle: '需要陪跑协助',
                  ),
                  const SizedBox(height: 20),
                  LargeActionButton(
                    onPressed: () => _selectRole(UserRole.volunteer),
                    enabled: !_isRouting,
                    backgroundColor: AppTheme.zinc,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.volunteer_activism, size: 76),
                    title: '我是志愿者',
                    subtitle: '提供陪跑服务',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
