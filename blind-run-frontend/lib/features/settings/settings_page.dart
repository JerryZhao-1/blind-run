import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/blind_profile.dart';
import 'package:aidrun_demo/core/models/emergency_contact.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
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
  late final TextEditingController _blindNameController;
  late final TextEditingController _paceController;
  late final TextEditingController _needsController;
  late final TextEditingController _volunteerNameController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(appStateControllerProvider);
    _blindNameController =
        TextEditingController(text: state.blindProfile?.name ?? '');
    _paceController =
        TextEditingController(text: state.blindProfile?.runningPace ?? '');
    _needsController =
        TextEditingController(text: state.blindProfile?.specialNeeds ?? '');
    _volunteerNameController =
        TextEditingController(text: state.volunteerProfile?.name ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(appStateControllerProvider.notifier);
      if (ref.read(appStateControllerProvider).role == UserRole.blind) {
        controller.loadBlindProfileData();
      } else {
        controller.loadVolunteerProfile();
      }
    });
  }

  @override
  void dispose() {
    _blindNameController.dispose();
    _paceController.dispose();
    _needsController.dispose();
    _volunteerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.watch(appStateControllerProvider.notifier);
    final role = state.role;

    if (role == UserRole.volunteer) {
      final profile = state.volunteerProfile;
      if (_volunteerNameController.text.isEmpty && profile != null) {
        _volunteerNameController.text = profile.name;
      }
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '志愿者资料',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _volunteerNameController,
                    decoration: const InputDecoration(labelText: '姓名'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '认证状态：${profile?.verificationStatus.isNotEmpty == true ? profile!.verificationStatus : '未认证'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
            FilledButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final current = state.volunteerProfile ??
                    const VolunteerProfile(
                      id: '',
                      name: '',
                      verificationStatus: '',
                      availableTimeSlots: [],
                    );
                await controller.saveVolunteerProfile(
                  current.copyWith(name: _volunteerNameController.text.trim()),
                );
                if (!context.mounted) {
                  return;
                }
                ref.read(speechServiceProvider).speak('设置已保存');
                navigator.pop();
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
                context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.red,
                side: const BorderSide(color: Colors.black12),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('退出登录'),
            ),
          ],
        ),
      );
    }

    final blindProfile = state.blindProfile;
    if (blindProfile != null && _blindNameController.text.isEmpty) {
      _blindNameController.text = blindProfile.name;
      _paceController.text = blindProfile.runningPace;
      _needsController.text = blindProfile.specialNeeds;
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
                  '盲人资料',
                  style: TextStyle(
                    color: AppTheme.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _darkField(_blindNameController, '姓名'),
                const SizedBox(height: 12),
                _darkField(_paceController, '跑步配速'),
                const SizedBox(height: 12),
                _darkField(_needsController, '特殊需求', maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            color: AppTheme.zinc,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '紧急联系人',
                  style: TextStyle(
                    color: AppTheme.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.emergencyContacts.isEmpty)
                  const Text(
                    '当前没有紧急联系人。创建订单前至少需要 1 个紧急联系人。',
                    style: TextStyle(color: Colors.white70),
                  ),
                for (final contact in state.emergencyContacts) ...[
                  _BlindContactTile(
                    contact: contact,
                    onEdit: () => _showContactDialog(existing: contact),
                    onDelete: () =>
                        ref.read(appStateControllerProvider.notifier).deleteEmergencyContact(contact.id),
                    onSetPrimary: contact.isPrimary
                        ? null
                        : () => ref
                            .read(appStateControllerProvider.notifier)
                            .setPrimaryEmergencyContact(contact.id),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showContactDialog(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('新增联系人'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await controller.saveBlindProfile(
                BlindProfile(
                  name: _blindNameController.text.trim(),
                  runningPace: _paceController.text.trim(),
                  specialNeeds: _needsController.text.trim(),
                ),
              );
              if (!navigator.mounted) {
                return;
              }
              ref.read(speechServiceProvider).speak('设置已保存');
              navigator.pop();
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
              context.go('/login');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              '退出登录',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppTheme.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _darkField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 20),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _showContactDialog({EmergencyContact? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final relationshipController =
        TextEditingController(text: existing?.relationship ?? '');
    var isPrimary = existing?.isPrimary ?? false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(existing == null ? '新增联系人' : '编辑联系人'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '姓名'),
                    ),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: '手机号'),
                    ),
                    TextField(
                      controller: relationshipController,
                      decoration: const InputDecoration(labelText: '关系'),
                    ),
                    CheckboxListTile(
                      value: isPrimary,
                      onChanged: (value) =>
                          setModalState(() => isPrimary = value ?? false),
                      title: const Text('设为主要联系人'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    if (existing == null) {
                      await ref.read(appStateControllerProvider.notifier).addEmergencyContact(
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            relationship: relationshipController.text.trim(),
                            isPrimary: isPrimary,
                          );
                    } else {
                      await ref
                          .read(appStateControllerProvider.notifier)
                          .updateEmergencyContact(
                            contactId: existing.id,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            relationship: relationshipController.text.trim(),
                            isPrimary: isPrimary,
                          );
                    }
                    if (navigator.mounted) {
                      navigator.pop();
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    relationshipController.dispose();
  }
}

class _BlindContactTile extends StatelessWidget {
  const _BlindContactTile({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    this.onSetPrimary,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${contact.name}${contact.isPrimary ? ' · 主要联系人' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                color: Colors.white,
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                onPressed: onDelete,
                color: Colors.white,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Text(
            '${contact.phone} · ${contact.relationship}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (onSetPrimary != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onSetPrimary,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
              child: const Text('设为主要联系人'),
            ),
          ],
        ],
      ),
    );
  }
}
