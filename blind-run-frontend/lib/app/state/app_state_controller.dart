import 'dart:async';

import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/app/state/app_state.dart';
import 'package:aidrun_demo/core/models/api_failure.dart';
import 'package:aidrun_demo/core/models/app_settings.dart';
import 'package:aidrun_demo/core/models/auth_flow_state.dart';
import 'package:aidrun_demo/core/models/blind_profile.dart';
import 'package:aidrun_demo/core/models/current_user.dart';
import 'package:aidrun_demo/core/models/dispatch_opportunity.dart';
import 'package:aidrun_demo/core/models/realtime_dispatch_connection_status.dart';
import 'package:aidrun_demo/core/models/reward_item.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_rating.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/models/volunteer_accept_run_result.dart';
import 'package:aidrun_demo/core/models/volunteer_intake_readiness.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
import 'package:aidrun_demo/core/repositories/order_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStateController extends Notifier<AppState> {
  bool _bootstrapScheduled = false;
  StreamSubscription<dynamic>? _dispatchSubscription;
  static final _loginPhonePattern = RegExp(r'^1[3-9]\d{9}$');

  static const _rewards = [
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
  ];

  @override
  AppState build() {
    final settings = ref.watch(settingsRepositoryProvider).load();
    final initialState = AppState.initial(
      settings: settings,
      rewards: _rewards,
    );
    if (!_bootstrapScheduled) {
      _bootstrapScheduled = true;
      Future.microtask(_bootstrap);
    }
    return initialState;
  }

  AppSettings get settings => state.settings;
  CurrentUser? get currentUser => state.currentUser;
  VolunteerIntakeReadiness get volunteerIntakeReadiness =>
      state.volunteerIntakeReadiness;

  List<Run> get pendingRuns => state.volunteerAvailableRuns;

  Run? get blindActiveRun => state.blindRuns
      .where((run) => run.status.isBlindActive)
      .sortedByUpdated()
      .firstOrNull;

  Run? get volunteerActiveRun => state.volunteerMyRuns
      .where((run) => run.status.isVolunteerActive)
      .sortedByUpdated()
      .firstOrNull;

  Run? volunteerOwnedRunById(String id) =>
      state.volunteerMyRuns.where((run) => run.id == id).firstOrNull;

  List<Run> get volunteerHistoryRuns => state.volunteerMyRuns
      .where((run) => run.status.isTerminal)
      .sortedByUpdated();

  Run? runById(String id) {
    for (final run in [
      ...state.blindRuns,
      ...state.volunteerMyRuns,
      ...state.volunteerAvailableRuns,
    ]) {
      if (run.id == id) {
        return run;
      }
    }
    return null;
  }

  Future<void> sendCode(String phone) async {
    final normalizedPhone = phone.trim();
    final validationMessage = _validateLoginPhone(normalizedPhone);
    if (validationMessage != null) {
      state = state.copyWith(
        authFlowState: AuthFlowState.idle,
        pendingLoginPhone: normalizedPhone,
        errorMessage: validationMessage,
      );
      throw ApiFailure(message: validationMessage);
    }
    state = state.copyWith(
      authFlowState: AuthFlowState.sendingCode,
      pendingLoginPhone: normalizedPhone,
      clearError: true,
    );
    try {
      await ref.read(authRepositoryProvider).sendCode(normalizedPhone);
      state = state.copyWith(authFlowState: AuthFlowState.idle);
    } catch (error) {
      state = state.copyWith(
        authFlowState: AuthFlowState.idle,
        errorMessage: _messageForError(error),
      );
      rethrow;
    }
  }

  Future<void> verifyCode(String phone, String code) async {
    final normalizedPhone = phone.trim();
    final validationMessage = _validateLoginPhone(normalizedPhone);
    if (validationMessage != null) {
      state = state.copyWith(
        authFlowState: AuthFlowState.idle,
        pendingLoginPhone: normalizedPhone,
        errorMessage: validationMessage,
      );
      throw ApiFailure(message: validationMessage);
    }
    state = state.copyWith(
      authFlowState: AuthFlowState.verifyingCode,
      pendingLoginPhone: normalizedPhone,
      clearError: true,
    );
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .verifyCode(normalizedPhone, code.trim());
      ref.read(authSessionStoreProvider).saveSession(session);
      final currentUser = await ref
          .read(authRepositoryProvider)
          .getCurrentUser();
      state = state.copyWith(
        authFlowState: AuthFlowState.idle,
        session: session,
        currentUser: currentUser,
        role: currentUser.role,
        bootstrapping: false,
      );
      await _refreshPostAuth();
    } catch (error) {
      state = state.copyWith(
        authFlowState: AuthFlowState.idle,
        errorMessage: _messageForError(error),
      );
      rethrow;
    }
  }

  Future<void> submitRole(UserRole role) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final previousSession = state.session;
      final roleResult = await ref.read(authRepositoryProvider).setRole(role);
      final renewedSession = previousSession?.copyWith(
        token: roleResult.token ?? previousSession.token,
        userId: roleResult.userId ?? previousSession.userId,
        role: roleResult.role,
      );
      if (renewedSession != null) {
        ref.read(authSessionStoreProvider).saveSession(renewedSession);
        state = state.copyWith(
          session: renewedSession,
          role: renewedSession.role,
        );
      }
      final currentUser = await ref
          .read(authRepositoryProvider)
          .getCurrentUser();
      final confirmedSession = renewedSession?.copyWith(role: currentUser.role);
      if (confirmedSession != null) {
        ref.read(authSessionStoreProvider).saveSession(confirmedSession);
      }
      state = state.copyWith(
        isBusy: false,
        role: currentUser.role,
        currentUser: currentUser,
        session: confirmedSession,
      );
      await _refreshPostAuth();
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _messageForError(error),
      );
      rethrow;
    }
  }

  Future<void> refreshBlindRuns() async {
    final role = state.role;
    if (role != UserRole.blind) {
      return;
    }
    final runs = await _guardUnauthorized(
      () => ref.read(orderRepositoryProvider).listMyOrders(UserRole.blind),
    );
    if (runs == null) {
      return;
    }
    state = state.copyWith(blindRuns: runs, clearError: true);
  }

  Future<bool> refreshVolunteerDashboard() async {
    if (state.role != UserRole.volunteer) {
      return false;
    }
    final results = await Future.wait([
      _guardUnauthorized(
        () => ref.read(orderRepositoryProvider).listAvailableOrders(),
      ),
      _guardUnauthorized(
        () =>
            ref.read(orderRepositoryProvider).listMyOrders(UserRole.volunteer),
      ),
    ]);
    final availableRuns = results[0];
    final myRuns = results[1];
    if (availableRuns == null || myRuns == null) {
      if (state.settings.volunteerAvailable &&
          state.volunteerIntakeReadiness ==
              VolunteerIntakeReadiness.onlineReady) {
        state = state.copyWith(
          volunteerIntakeReadiness: VolunteerIntakeReadiness.reportFailed,
        );
      }
      return false;
    }
    final previousRuns = {
      for (final run in [
        ...state.volunteerAvailableRuns,
        ...state.volunteerMyRuns,
      ])
        run.id: run,
    };
    final availableById = {for (final run in availableRuns) run.id: run};
    final hydratedMyRuns = myRuns
        .map(
          (run) => _mergeRunContinuity(
            run.copyWith(volunteerOwnershipConfirmed: true),
            availableById[run.id] ?? previousRuns[run.id],
          ),
        )
        .toList(growable: false);
    final ownedIds = hydratedMyRuns.map((run) => run.id).toSet();
    final hydratedAvailableRunsFromPolling = availableRuns
        .where((run) => !ownedIds.contains(run.id))
        .map((run) => _mergeRunContinuity(run, previousRuns[run.id]))
        .toList(growable: false);
    final pollingIds = hydratedAvailableRunsFromPolling
        .map((run) => run.id)
        .toSet();
    final activeRealtimeRuns = state.volunteerAvailableRuns
        .where(
          (run) =>
              run.isRealtimeDispatch &&
              !ownedIds.contains(run.id) &&
              !pollingIds.contains(run.id),
        )
        .toList(growable: false);
    state = state.copyWith(
      volunteerAvailableRuns: [
        ...activeRealtimeRuns,
        ...hydratedAvailableRunsFromPolling,
      ],
      volunteerMyRuns: hydratedMyRuns,
      clearError: true,
    );
    return true;
  }

  Future<Run?> refreshOrder(String runId) async {
    final previous = runById(runId);
    final run = await _guardUnauthorized(
      () => ref.read(orderRepositoryProvider).getOrder(runId),
    );
    if (run == null) {
      return null;
    }
    final normalized = _mergeRunContinuity(
      state.role == UserRole.volunteer
          ? run.copyWith(volunteerOwnershipConfirmed: true)
          : run,
      previous,
    );
    _mergeRun(normalized);
    return normalized;
  }

  Future<Run> createBlindRun(RunRequestInput input) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      throw const ApiFailure(message: '请先登录');
    }
    await loadBlindProfileData();
    if (state.emergencyContacts.isEmpty) {
      throw const ApiFailure(message: '请先添加至少一个紧急联系人');
    }
    final resolved = ref
        .read(orderTimeResolverProvider)
        .resolve(input.timeLabel);
    final run = await _guardUnauthorized(
      () => ref
          .read(orderRepositoryProvider)
          .createOrder(
            CreateOrderPayload(
              startLatitude: input.place.latitude,
              startLongitude: input.place.longitude,
              startAddress: input.place.address,
              plannedStartTime: resolved.plannedStart,
              plannedEndTime: resolved.plannedEnd,
              timeLabel: resolved.displayLabel,
              notes: input.notes,
            ),
          ),
    );
    if (run == null) {
      throw const ApiFailure(message: '创建订单失败');
    }
    final hydratedRun = await refreshOrder(run.id) ?? run;
    await refreshBlindRuns();
    return hydratedRun;
  }

  Future<void> cancelRun(String runId) async {
    await _guardUnauthorized(
      () => ref.read(orderRepositoryProvider).cancelOrder(runId),
    );
    await _refreshOrdersForCurrentRole();
    await refreshOrder(runId);
  }

  Future<void> rateRun(String runId, RunRating rating) async {
    await _guardUnauthorized(
      () => ref
          .read(orderRepositoryProvider)
          .createReview(runId, rating.backendRating),
    );
    final run = runById(runId);
    if (run != null) {
      _mergeRun(run.copyWith(blindRating: rating));
    }
  }

  Future<VolunteerAcceptRunResult> acceptRun(String runId) async {
    state = state.copyWith(clearError: true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .respondToOrder(runId, OrderResponseAction.accept);
    } catch (error) {
      return _handleAcceptRunError(error);
    }
    final refreshed = await refreshVolunteerDashboard();
    final confirmedFromOwnedRuns = volunteerOwnedRunById(runId);
    if (refreshed && confirmedFromOwnedRuns != null) {
      final hydrated = await refreshOrder(runId);
      return VolunteerAcceptRunResult.confirmed(
        volunteerOwnedRunById(runId) ?? hydrated ?? confirmedFromOwnedRuns,
      );
    }

    final hydrated = await refreshOrder(runId);
    if (hydrated != null) {
      return VolunteerAcceptRunResult.confirmed(
        volunteerOwnedRunById(runId) ?? hydrated,
      );
    }

    final message = state.errorMessage ?? '接单状态暂未确认，请稍后重试。';
    state = state.copyWith(errorMessage: message);
    return VolunteerAcceptRunResult.failed(message);
  }

  Future<void> declineRun(String runId) async {
    state = state.copyWith(clearError: true);
    final declined = await _guardUnauthorized(() async {
      await ref
          .read(orderRepositoryProvider)
          .respondToOrder(runId, OrderResponseAction.decline);
      return true;
    });
    if (declined == null) {
      return;
    }
    state = state.copyWith(
      volunteerAvailableRuns: state.volunteerAvailableRuns
          .where((run) => run.id != runId)
          .toList(growable: false),
      clearError: true,
    );
  }

  Future<void> markEnRoute(String runId) async {
    await _guardUnauthorized(
      () => ref.read(orderRepositoryProvider).markEnRoute(runId),
    );
    await refreshVolunteerDashboard();
    await refreshOrder(runId);
  }

  Future<void> markArrived(String runId) async {
    await _guardUnauthorized(
      () => ref.read(orderRepositoryProvider).markArrived(runId),
    );
    await refreshVolunteerDashboard();
    await refreshOrder(runId);
  }

  Future<void> finishRun(String runId) async {
    await _guardUnauthorized(
      () => ref.read(orderRepositoryProvider).finishOrder(runId),
    );
    await refreshVolunteerDashboard();
    await refreshOrder(runId);
  }

  Future<void> loadBlindProfileData() async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      return;
    }
    final profile = await _guardUnauthorized(
      () => ref.read(blindProfileRepositoryProvider).getProfile(),
    );
    final contacts = await _guardUnauthorized(
      () => ref
          .read(emergencyContactRepositoryProvider)
          .listContacts(currentUser.userId),
    );
    if (profile == null || contacts == null) {
      return;
    }
    state = state.copyWith(
      blindProfile: profile,
      emergencyContacts: contacts,
      clearError: true,
    );
  }

  Future<void> saveBlindProfile(BlindProfile profile) async {
    final updated = await _guardUnauthorized(
      () => ref.read(blindProfileRepositoryProvider).updateProfile(profile),
    );
    if (updated == null) {
      return;
    }
    state = state.copyWith(blindProfile: updated, clearError: true);
  }

  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      return;
    }
    await _guardUnauthorized(
      () => ref
          .read(emergencyContactRepositoryProvider)
          .createContact(
            currentUser.userId,
            name: name,
            phone: phone,
            relationship: relationship,
            isPrimary: isPrimary,
          ),
    );
    await loadBlindProfileData();
  }

  Future<void> updateEmergencyContact({
    required int contactId,
    required String name,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      return;
    }
    await _guardUnauthorized(
      () => ref
          .read(emergencyContactRepositoryProvider)
          .updateContact(
            currentUser.userId,
            contactId,
            name: name,
            phone: phone,
            relationship: relationship,
            isPrimary: isPrimary,
          ),
    );
    await loadBlindProfileData();
  }

  Future<void> deleteEmergencyContact(int contactId) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      return;
    }
    await _guardUnauthorized(
      () => ref
          .read(emergencyContactRepositoryProvider)
          .deleteContact(currentUser.userId, contactId),
    );
    await loadBlindProfileData();
  }

  Future<void> setPrimaryEmergencyContact(int contactId) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      return;
    }
    await _guardUnauthorized(
      () => ref
          .read(emergencyContactRepositoryProvider)
          .setPrimary(currentUser.userId, contactId),
    );
    await loadBlindProfileData();
  }

  Future<void> loadVolunteerProfile() async {
    final profile = await _guardUnauthorized(
      () => ref.read(volunteerProfileRepositoryProvider).getProfile(),
    );
    if (profile == null) {
      return;
    }
    state = state.copyWith(volunteerProfile: profile, clearError: true);
  }

  Future<void> saveVolunteerProfile(VolunteerProfile profile) async {
    final updated = await _guardUnauthorized(
      () => ref.read(volunteerProfileRepositoryProvider).updateProfile(profile),
    );
    if (updated == null) {
      return;
    }
    state = state.copyWith(volunteerProfile: updated, clearError: true);
  }

  void updateNotifications(bool enabled) {
    _saveSettings(state.settings.copyWith(notificationsEnabled: enabled));
  }

  void updateVolunteerAvailability(bool available) {
    _saveSettings(state.settings.copyWith(volunteerAvailable: available));
    state = state.copyWith(
      volunteerIntakeReadiness: available
          ? VolunteerIntakeReadiness.connecting
          : VolunteerIntakeReadiness.offline,
      realtimeDispatchConnectionStatus: available
          ? RealtimeDispatchConnectionStatus.connecting
          : RealtimeDispatchConnectionStatus.disconnected,
      clearError: available,
    );
    if (!available) {
      unawaited(stopRealtimeDispatch());
    }
  }

  void setVolunteerIntakeReadiness(
    VolunteerIntakeReadiness readiness, {
    bool clearError = false,
    String? errorMessage,
  }) {
    state = state.copyWith(
      volunteerIntakeReadiness: readiness,
      clearError: clearError,
      errorMessage: errorMessage,
    );
  }

  Future<bool> reportVolunteerLocation({
    required double latitude,
    required double longitude,
    required bool isOnline,
  }) async {
    final result = await _guardUnauthorized(() async {
      await ref
          .read(volunteerProfileRepositoryProvider)
          .updateLocation(
            latitude: latitude,
            longitude: longitude,
            isOnline: isOnline,
          );
      return true;
    });
    if (result != null) {
      ref
          .read(realtimeDispatchServiceProvider)
          .sendLocationUpdate(
            latitude: latitude,
            longitude: longitude,
            isOnline: isOnline,
          );
    }
    return result != null;
  }

  Future<void> startRealtimeDispatch() async {
    final session = state.session;
    final role = state.role;
    if (session == null || role == null || role == UserRole.unset) {
      return;
    }
    _dispatchSubscription ??= ref
        .read(realtimeDispatchServiceProvider)
        .events
        .listen(_handleRealtimeDispatchEvent);
    await ref
        .read(realtimeDispatchServiceProvider)
        .connect(role: role, token: session.token);
  }

  Future<void> stopRealtimeDispatch() async {
    await ref.read(realtimeDispatchServiceProvider).stop();
  }

  Future<void> refreshReview(String runId) async {
    final review = await _guardUnauthorized(
      () => ref.read(orderRepositoryProvider).getReview(runId),
    );
    if (review == null) {
      return;
    }
    final run = runById(runId);
    if (run == null) {
      return;
    }
    final rating = RunRatingX.fromBackendRating(review.rating);
    if (rating == null) {
      return;
    }
    _mergeRun(run.copyWith(blindRating: rating));
  }

  Future<void> logout({bool notifyBackend = true}) async {
    if (notifyBackend && state.session != null) {
      try {
        await ref.read(authRepositoryProvider).logout();
      } catch (_) {
        // Local logout must remain deterministic even when the backend rejects
        // an already-expired token or the network is unavailable.
      }
    }
    _clearLocalSession();
  }

  void _clearLocalSession() {
    unawaited(_dispatchSubscription?.cancel());
    _dispatchSubscription = null;
    unawaited(stopRealtimeDispatch());
    ref.read(authSessionStoreProvider).clearSession();
    final settings = ref.read(settingsRepositoryProvider).load();
    state = AppState.initial(
      settings: settings,
      rewards: _rewards,
    ).copyWith(bootstrapping: false, clearError: true);
  }

  Future<void> _bootstrap() async {
    final session = ref.read(authSessionStoreProvider).readSession();
    if (session == null) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(bootstrapping: false, clearError: true);
      return;
    }
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      session: session,
      role: session.role,
      clearError: true,
    );
    try {
      final currentUser = await ref
          .read(authRepositoryProvider)
          .getCurrentUser();
      if (!ref.mounted) {
        return;
      }
      final resolvedSession = session.copyWith(role: currentUser.role);
      ref.read(authSessionStoreProvider).saveSession(resolvedSession);
      state = state.copyWith(
        session: resolvedSession,
        currentUser: currentUser,
        role: currentUser.role,
        bootstrapping: false,
        volunteerIntakeReadiness:
            resolvedSession.role == UserRole.volunteer &&
                state.settings.volunteerAvailable
            ? VolunteerIntakeReadiness.connecting
            : VolunteerIntakeReadiness.offline,
      );
      await _refreshPostAuth();
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      if (error is ApiFailure && error.isUnauthorized) {
        _clearLocalSession();
      } else {
        state = state.copyWith(
          bootstrapping: false,
          errorMessage: _messageForError(error),
        );
      }
    }
  }

  Future<void> _refreshPostAuth() async {
    switch (state.role) {
      case UserRole.blind:
        await Future.wait([refreshBlindRuns(), loadBlindProfileData()]);
        break;
      case UserRole.volunteer:
        await Future.wait([
          refreshVolunteerDashboard(),
          loadVolunteerProfile(),
        ]);
        break;
      case UserRole.unset:
      case null:
        break;
    }
  }

  Future<void> _refreshOrdersForCurrentRole() async {
    switch (state.role) {
      case UserRole.blind:
        await refreshBlindRuns();
        break;
      case UserRole.volunteer:
        await refreshVolunteerDashboard();
        break;
      case UserRole.unset:
      case null:
        break;
    }
  }

  void _mergeRun(Run run) {
    List<Run> merge(List<Run> source, {required bool addIfMissing}) {
      final existingIndex = source.indexWhere((item) => item.id == run.id);
      if (existingIndex == -1) {
        if (!addIfMissing) {
          return source;
        }
        return [...source, run];
      }
      final updated = [...source];
      updated[existingIndex] = _mergeRunContinuity(run, updated[existingIndex]);
      return updated;
    }

    final shouldStoreInBlind =
        state.role == UserRole.blind ||
        state.blindRuns.any((item) => item.id == run.id);
    final shouldStoreInVolunteerMy =
        run.volunteerOwnershipConfirmed ||
        state.volunteerMyRuns.any((item) => item.id == run.id);
    final shouldStoreInVolunteerAvailable =
        !run.volunteerOwnershipConfirmed &&
        state.volunteerAvailableRuns.any((item) => item.id == run.id);

    state = state.copyWith(
      blindRuns: merge(state.blindRuns, addIfMissing: shouldStoreInBlind),
      volunteerMyRuns: merge(
        state.volunteerMyRuns,
        addIfMissing: shouldStoreInVolunteerMy,
      ),
      volunteerAvailableRuns: run.volunteerOwnershipConfirmed
          ? state.volunteerAvailableRuns
                .where((item) => item.id != run.id)
                .toList(growable: false)
          : merge(
              state.volunteerAvailableRuns,
              addIfMissing: shouldStoreInVolunteerAvailable,
            ),
    );
  }

  void _handleRealtimeDispatchEvent(dynamic event) {
    if (!ref.mounted || event == null) {
      return;
    }
    final status = event.status;
    if (status is RealtimeDispatchConnectionStatus) {
      state = state.copyWith(realtimeDispatchConnectionStatus: status);
      return;
    }
    final opportunity = event.opportunity;
    if (opportunity is DispatchOpportunity &&
        state.role == UserRole.volunteer) {
      _mergeRealtimeDispatchRun(opportunity.toRun());
    }
  }

  void _mergeRealtimeDispatchRun(Run run) {
    final withoutDuplicate = state.volunteerAvailableRuns
        .where((item) => item.id != run.id)
        .toList(growable: false);
    state = state.copyWith(
      volunteerAvailableRuns: [run, ...withoutDuplicate],
      clearError: true,
    );
  }

  Run _mergeRunContinuity(Run run, Run? fallback) {
    if (fallback == null) {
      return run;
    }
    return run.mergedWith(fallback);
  }

  void _saveSettings(AppSettings settings) {
    ref.read(settingsRepositoryProvider).save(settings);
    state = state.copyWith(settings: settings);
  }

  Future<T?> _guardUnauthorized<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      if (!ref.mounted) {
        return null;
      }
      if (error is ApiFailure && error.isUnauthorized) {
        _clearLocalSession();
      } else {
        state = state.copyWith(errorMessage: _messageForError(error));
      }
      return null;
    }
  }

  VolunteerAcceptRunResult _handleAcceptRunError(Object error) {
    if (!ref.mounted) {
      return const VolunteerAcceptRunResult.failed('接单失败，请稍后重试。');
    }
    if (error is ApiFailure && error.isUnauthorized) {
      _clearLocalSession();
    } else {
      state = state.copyWith(errorMessage: _messageForError(error));
    }
    return VolunteerAcceptRunResult.failed(_messageForError(error));
  }

  String? _validateLoginPhone(String phone) {
    if (_loginPhonePattern.hasMatch(phone)) {
      return null;
    }
    return '请输入 11 位中国大陆手机号，例如 13800138000';
  }

  String _messageForError(Object error) {
    if (error is ApiFailure) {
      return error.message;
    }
    return '操作失败，请稍后重试';
  }
}

extension on Iterable<Run> {
  List<Run> sortedByUpdated() {
    final items = toList(growable: false);
    final mutable = [...items];
    mutable.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return mutable;
  }
}
