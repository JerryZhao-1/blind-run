import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _phoneController;
  late final TextEditingController _codeController;
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    final pendingPhone = ref.read(appStateControllerProvider).pendingLoginPhone;
    _phoneController = TextEditingController(text: pendingPhone);
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    try {
      await ref
          .read(appStateControllerProvider.notifier)
          .sendCode(_phoneController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码已发送')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(appStateControllerProvider).errorMessage ?? '发送验证码失败',
          ),
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    try {
      await ref.read(appStateControllerProvider.notifier).verifyCode(
            _phoneController.text.trim(),
            _codeController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      final role = ref.read(appStateControllerProvider).role;
      final target = switch (role) {
        UserRole.blind => '/blind',
        UserRole.volunteer => '/volunteer',
        UserRole.unset || null => '/role-selection',
      };
      context.go(target);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(appStateControllerProvider).errorMessage ?? '登录失败',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final isSending = state.authFlowState.name == 'sendingCode';
    final isVerifying = state.authFlowState.name == 'verifyingCode';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AidRun 助盲跑',
                    style: TextStyle(
                      color: AppTheme.yellow,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '使用短信验证码登录，进入真实的盲人/志愿者服务流程。',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('手机号'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSending ? null : _sendCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(isSending ? '发送中...' : '发送验证码'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('验证码'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: !_codeSent || isVerifying ? null : _verifyCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(isVerifying ? '登录中...' : '登录'),
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppTheme.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }
}
