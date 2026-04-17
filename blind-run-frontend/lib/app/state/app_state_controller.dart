import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/app/state/app_state.dart';
import 'package:aidrun_demo/core/models/app_settings.dart';
import 'package:aidrun_demo/core/models/app_user.dart';
import 'package:aidrun_demo/core/models/reward_item.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_rating.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStateController extends Notifier<AppState> {
  static const blindUser = AppUser(
    id: 'demo-blind-id',
    displayName: '盲人跑者',
    role: UserRole.blind,
  );

  static const volunteerUser = AppUser(
    id: 'demo-volunteer-id',
    displayName: '爱心志愿者',
    role: UserRole.volunteer,
  );

  static const volunteerProfile = VolunteerProfile(
    id: 'demo-volunteer-id',
    name: '爱心志愿者',
    rating: 4.98,
    phone: '13800138000',
    avatarSeed: 'volunteer-main',
  );

  @override
  AppState build() {
    final roleStore = ref.watch(roleSessionStoreProvider);
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    final runRepository = ref.watch(runRepositoryProvider);

    return AppState(
      role: roleStore.readRole(),
      settings: settingsRepository.load(),
      runs: runRepository.loadRuns(),
      rewards: const [
        RewardItem(
          id: 'reward-1',
          name: '运动水壶',
          points: 500,
          imageUrl: 'https://picsum.photos/seed/bottle/400/300',
        ),
        RewardItem(
          id: 'reward-2',
          name: '速干排汗T恤',
          points: 1200,
          imageUrl: 'https://picsum.photos/seed/shirt/400/300',
        ),
        RewardItem(
          id: 'reward-3',
          name: '专业跑步袜',
          points: 300,
          imageUrl: 'https://picsum.photos/seed/socks/400/300',
        ),
        RewardItem(
          id: 'reward-4',
          name: '运动腰包',
          points: 800,
          imageUrl: 'https://picsum.photos/seed/bag/400/300',
        ),
      ],
    );
  }

  AppUser? get currentUser => switch (state.role) {
        UserRole.blind => blindUser,
        UserRole.volunteer => volunteerUser,
        null => null,
      };

  List<Run> get pendingRuns =>
      state.runs.where((run) => run.status == RunStatus.pending).toList();

  Run? get blindActiveRun {
    return state.runs
        .where((run) => run.blindRunnerId == blindUser.id)
        .where(
          (run) => [
            RunStatus.pending,
            RunStatus.accepted,
            RunStatus.arrived,
            RunStatus.running,
          ].contains(run.status),
        )
        .firstOrNull;
  }

  Run? get volunteerActiveRun {
    return state.runs
        .where((run) => run.volunteer?.id == volunteerUser.id)
        .where(
          (run) => [
            RunStatus.accepted,
            RunStatus.arrived,
            RunStatus.running,
          ].contains(run.status),
        )
        .firstOrNull;
  }

  List<Run> get volunteerHistoryRuns {
    final items = state.runs
        .where((run) => run.volunteer?.id == volunteerUser.id)
        .where(
          (run) => [RunStatus.completed, RunStatus.cancelled].contains(run.status),
        )
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Run? runById(String id) {
    return state.runs.where((run) => run.id == id).firstOrNull;
  }

  void selectRole(UserRole role) {
    ref.read(roleSessionStoreProvider).saveRole(role);
    state = state.copyWith(role: role);
  }

  void logout() {
    ref.read(roleSessionStoreProvider).clearRole();
    state = state.copyWith(clearRole: true);
  }

  void saveSettings(AppSettings settings) {
    ref.read(settingsRepositoryProvider).save(settings);
    state = state.copyWith(settings: settings);
  }

  void updateEmergencyContact(String contact) {
    saveSettings(state.settings.copyWith(emergencyContact: contact));
  }

  void updateNotifications(bool enabled) {
    saveSettings(state.settings.copyWith(notificationsEnabled: enabled));
  }

  void updateVolunteerAvailability(bool available) {
    saveSettings(state.settings.copyWith(volunteerAvailable: available));
  }

  Run createBlindRun(RunRequestInput input) {
    final runs = ref.read(runRepositoryProvider).createBlindRun(
          blindRunnerId: blindUser.id,
          location: input.place.name,
          address: input.place.address,
          latitude: input.place.latitude,
          longitude: input.place.longitude,
          timeLabel: input.timeLabel,
          notes: input.notes,
        );
    state = state.copyWith(runs: runs);
    return runs.first;
  }

  void acceptRun(String runId) {
    final runs = ref.read(runRepositoryProvider).acceptRun(
          runId: runId,
          volunteer: volunteerProfile,
        );
    state = state.copyWith(runs: runs);
  }

  void updateRunStatus(String runId, RunStatus status) {
    final runs = ref.read(runRepositoryProvider).updateRunStatus(
          runId: runId,
          status: status,
        );
    state = state.copyWith(runs: runs);
  }

  void cancelRun(String runId) {
    final runs = ref.read(runRepositoryProvider).cancelRun(runId);
    state = state.copyWith(runs: runs);
  }

  void rateRun(String runId, RunRating rating) {
    final runs = ref.read(runRepositoryProvider).rateRun(
          runId: runId,
          rating: rating,
        );
    state = state.copyWith(runs: runs);
  }
}
