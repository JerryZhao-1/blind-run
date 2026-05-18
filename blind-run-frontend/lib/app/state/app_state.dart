import 'package:aidrun_demo/core/models/auth_flow_state.dart';
import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/blind_profile.dart';
import 'package:aidrun_demo/core/models/current_user.dart';
import 'package:aidrun_demo/core/models/emergency_contact.dart';
import 'package:aidrun_demo/core/models/realtime_dispatch_connection_status.dart';
import 'package:aidrun_demo/core/models/reward_item.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/models/volunteer_intake_readiness.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
import 'package:aidrun_demo/core/models/app_settings.dart';

class AppState {
  const AppState({
    required this.bootstrapping,
    required this.authFlowState,
    required this.settings,
    required this.rewards,
    required this.blindRuns,
    required this.volunteerAvailableRuns,
    required this.volunteerMyRuns,
    required this.volunteerIntakeReadiness,
    required this.realtimeDispatchConnectionStatus,
    this.session,
    this.currentUser,
    this.role,
    this.blindProfile,
    this.volunteerProfile,
    this.emergencyContacts = const [],
    this.pendingLoginPhone = '',
    this.isBusy = false,
    this.errorMessage,
  });

  factory AppState.initial({
    required AppSettings settings,
    required List<RewardItem> rewards,
  }) {
    return AppState(
      bootstrapping: true,
      authFlowState: AuthFlowState.idle,
      settings: settings,
      rewards: rewards,
      blindRuns: const [],
      volunteerAvailableRuns: const [],
      volunteerMyRuns: const [],
      volunteerIntakeReadiness: VolunteerIntakeReadiness.offline,
      realtimeDispatchConnectionStatus:
          RealtimeDispatchConnectionStatus.disconnected,
    );
  }

  final bool bootstrapping;
  final AuthFlowState authFlowState;
  final AuthSession? session;
  final CurrentUser? currentUser;
  final UserRole? role;
  final AppSettings settings;
  final List<RewardItem> rewards;
  final List<Run> blindRuns;
  final List<Run> volunteerAvailableRuns;
  final List<Run> volunteerMyRuns;
  final VolunteerIntakeReadiness volunteerIntakeReadiness;
  final RealtimeDispatchConnectionStatus realtimeDispatchConnectionStatus;
  final BlindProfile? blindProfile;
  final VolunteerProfile? volunteerProfile;
  final List<EmergencyContact> emergencyContacts;
  final String pendingLoginPhone;
  final bool isBusy;
  final String? errorMessage;

  bool get isAuthenticated => session != null && currentUser != null;

  AppState copyWith({
    bool? bootstrapping,
    AuthFlowState? authFlowState,
    AuthSession? session,
    bool clearSession = false,
    CurrentUser? currentUser,
    bool clearCurrentUser = false,
    UserRole? role,
    bool clearRole = false,
    AppSettings? settings,
    List<RewardItem>? rewards,
    List<Run>? blindRuns,
    List<Run>? volunteerAvailableRuns,
    List<Run>? volunteerMyRuns,
    VolunteerIntakeReadiness? volunteerIntakeReadiness,
    RealtimeDispatchConnectionStatus? realtimeDispatchConnectionStatus,
    BlindProfile? blindProfile,
    bool clearBlindProfile = false,
    VolunteerProfile? volunteerProfile,
    bool clearVolunteerProfile = false,
    List<EmergencyContact>? emergencyContacts,
    String? pendingLoginPhone,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppState(
      bootstrapping: bootstrapping ?? this.bootstrapping,
      authFlowState: authFlowState ?? this.authFlowState,
      session: clearSession ? null : (session ?? this.session),
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      role: clearRole ? null : (role ?? this.role),
      settings: settings ?? this.settings,
      rewards: rewards ?? this.rewards,
      blindRuns: blindRuns ?? this.blindRuns,
      volunteerAvailableRuns:
          volunteerAvailableRuns ?? this.volunteerAvailableRuns,
      volunteerMyRuns: volunteerMyRuns ?? this.volunteerMyRuns,
      volunteerIntakeReadiness:
          volunteerIntakeReadiness ?? this.volunteerIntakeReadiness,
      realtimeDispatchConnectionStatus:
          realtimeDispatchConnectionStatus ??
          this.realtimeDispatchConnectionStatus,
      blindProfile: clearBlindProfile
          ? null
          : (blindProfile ?? this.blindProfile),
      volunteerProfile: clearVolunteerProfile
          ? null
          : (volunteerProfile ?? this.volunteerProfile),
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      pendingLoginPhone: pendingLoginPhone ?? this.pendingLoginPhone,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
