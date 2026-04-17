import 'package:aidrun_demo/core/models/app_settings.dart';
import 'package:aidrun_demo/core/models/reward_item.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/user_role.dart';

class AppState {
  const AppState({
    required this.role,
    required this.settings,
    required this.runs,
    required this.rewards,
  });

  final UserRole? role;
  final AppSettings settings;
  final List<Run> runs;
  final List<RewardItem> rewards;

  AppState copyWith({
    UserRole? role,
    bool clearRole = false,
    AppSettings? settings,
    List<Run>? runs,
    List<RewardItem>? rewards,
  }) {
    return AppState(
      role: clearRole ? null : (role ?? this.role),
      settings: settings ?? this.settings,
      runs: runs ?? this.runs,
      rewards: rewards ?? this.rewards,
    );
  }
}
