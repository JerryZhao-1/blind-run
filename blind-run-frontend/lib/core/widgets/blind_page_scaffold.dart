import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlindPageScaffold extends ConsumerWidget {
  const BlindPageScaffold({
    super.key,
    required this.body,
    this.header,
    this.aiButtonKey,
    this.onAiAssistant,
  });

  final Widget body;
  final Widget? header;
  final Key? aiButtonKey;
  final VoidCallback? onAiAssistant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> handleAiAssistant() async {
      onAiAssistant?.call();
      await ref
          .read(blindAccessibilityServiceProvider)
          .announceAiAssistantPlaceholder();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[header!, const SizedBox(height: 16)],
              Expanded(child: body),
              const SizedBox(height: 16),
              BlindAccessibleButton(
                key: aiButtonKey,
                onPressed: handleAiAssistant,
                enabled: true,
                label: 'AI语音助手',
                hint: '当前未开放，点击后会提示稍后使用',
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.zinc,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.record_voice_over),
                    label: const Text(
                      'AI语音助手',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
