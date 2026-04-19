import 'dart:async';

import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/blind_profile.dart';
import 'package:aidrun_demo/core/models/current_user.dart';
import 'package:aidrun_demo/core/models/emergency_contact.dart';
import 'package:aidrun_demo/core/models/order_review.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
import 'package:aidrun_demo/core/models/app_settings.dart';
import 'package:aidrun_demo/core/repositories/auth_repository.dart';
import 'package:aidrun_demo/core/repositories/auth_session_store.dart';
import 'package:aidrun_demo/core/repositories/blind_profile_repository.dart';
import 'package:aidrun_demo/core/repositories/emergency_contact_repository.dart';
import 'package:aidrun_demo/core/repositories/order_repository.dart';
import 'package:aidrun_demo/core/repositories/settings_repository.dart';
import 'package:aidrun_demo/core/repositories/volunteer_profile_repository.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/core/services/place_search_service.dart';
import 'package:aidrun_demo/core/services/speech_recognition_service.dart';
import 'package:aidrun_demo/core/services/speech_service.dart';

class FakeAuthSessionStore implements AuthSessionStore {
  FakeAuthSessionStore([this.session]);

  AuthSession? session;

  @override
  void clearSession() {
    session = null;
  }

  @override
  AuthSession? readSession() => session;

  @override
  void saveSession(AuthSession session) {
    this.session = session;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({required this.currentUser, AuthSession? verifySession})
    : verifySession =
          verifySession ??
          AuthSession(
            token: 'token',
            userId: currentUser.userId,
            role: currentUser.role,
          );

  CurrentUser currentUser;
  AuthSession verifySession;
  int sendCodeCalls = 0;

  @override
  Future<CurrentUser> getCurrentUser() async => currentUser;

  @override
  Future<void> sendCode(String phone) async {
    sendCodeCalls += 1;
  }

  @override
  Future<UserRole> setRole(UserRole role) async {
    currentUser = CurrentUser(
      userId: currentUser.userId,
      phoneMasked: currentUser.phoneMasked,
      role: role,
      createdAt: currentUser.createdAt,
    );
    verifySession = verifySession.copyWith(role: role);
    return role;
  }

  @override
  Future<AuthSession> verifyCode(String phone, String code) async =>
      verifySession;
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this._settings = const AppSettings()]);

  AppSettings _settings;

  @override
  AppSettings load() => _settings;

  @override
  void save(AppSettings settings) {
    _settings = settings;
  }
}

class FakeBlindProfileRepository implements BlindProfileRepository {
  FakeBlindProfileRepository([this.profile = const BlindProfile(name: '李明')]);

  BlindProfile profile;

  @override
  Future<BlindProfile> getProfile() async => profile;

  @override
  Future<BlindProfile> updateProfile(BlindProfile profile) async {
    this.profile = profile;
    return profile;
  }
}

class FakeEmergencyContactRepository implements EmergencyContactRepository {
  FakeEmergencyContactRepository([List<EmergencyContact>? contacts])
    : contacts = contacts ?? <EmergencyContact>[];

  final List<EmergencyContact> contacts;

  @override
  Future<EmergencyContact> createContact(
    int userId, {
    required String name,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    final contact = EmergencyContact(
      id: contacts.length + 1,
      name: name,
      phone: phone,
      relationship: relationship,
      isPrimary: isPrimary,
    );
    contacts.add(contact);
    return contact;
  }

  @override
  Future<void> deleteContact(int userId, int contactId) async {
    contacts.removeWhere((item) => item.id == contactId);
  }

  @override
  Future<List<EmergencyContact>> listContacts(int userId) async =>
      List<EmergencyContact>.from(contacts);

  @override
  Future<void> setPrimary(int userId, int contactId) async {
    for (var index = 0; index < contacts.length; index += 1) {
      final item = contacts[index];
      contacts[index] = item.copyWith(isPrimary: item.id == contactId);
    }
  }

  @override
  Future<EmergencyContact> updateContact(
    int userId,
    int contactId, {
    required String name,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    final index = contacts.indexWhere((item) => item.id == contactId);
    final updated = EmergencyContact(
      id: contactId,
      name: name,
      phone: phone,
      relationship: relationship,
      isPrimary: isPrimary,
    );
    contacts[index] = updated;
    return updated;
  }
}

class FakeVolunteerProfileRepository implements VolunteerProfileRepository {
  FakeVolunteerProfileRepository({
    this.profile = const VolunteerProfile(
      id: 'volunteer-1',
      name: '爱心志愿者',
      verificationStatus: 'APPROVED',
      availableTimeSlots: [],
    ),
    this.locationError,
    List<Exception?>? locationErrors,
  }) : locationErrors = locationErrors ?? const [];

  VolunteerProfile profile;
  final Exception? locationError;
  final List<Exception?> locationErrors;
  final List<LocationUpdateCall> locationCalls = <LocationUpdateCall>[];
  int _locationAttempts = 0;

  @override
  Future<VolunteerProfile> getProfile() async => profile;

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required bool isOnline,
  }) async {
    final attemptError = _locationAttempts < locationErrors.length
        ? locationErrors[_locationAttempts]
        : locationError;
    _locationAttempts += 1;
    if (attemptError != null) {
      throw attemptError;
    }
    locationCalls.add(
      LocationUpdateCall(
        latitude: latitude,
        longitude: longitude,
        isOnline: isOnline,
      ),
    );
  }

  @override
  Future<VolunteerProfile> updateProfile(VolunteerProfile profile) async {
    this.profile = profile;
    return profile;
  }
}

class LocationUpdateCall {
  const LocationUpdateCall({
    required this.latitude,
    required this.longitude,
    required this.isOnline,
  });

  final double latitude;
  final double longitude;
  final bool isOnline;
}

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({
    List<Run>? blindRuns,
    List<Run>? availableRuns,
    List<Run>? volunteerRuns,
    this.acceptError,
    this.getOrderError,
    this.acceptedVolunteerStatus = RunStatus.inProgress,
    this.stripVolunteerContextOnOwnedReads = false,
  }) : blindRuns = blindRuns ?? <Run>[],
       availableRuns = availableRuns ?? <Run>[],
       volunteerRuns = volunteerRuns ?? <Run>[];

  final List<Run> blindRuns;
  final List<Run> availableRuns;
  final List<Run> volunteerRuns;
  final Exception? acceptError;
  final Exception? getOrderError;
  final RunStatus acceptedVolunteerStatus;
  final bool stripVolunteerContextOnOwnedReads;
  final Map<String, OrderReview> reviews = <String, OrderReview>{};
  int createOrderCalls = 0;
  int listMyOrdersCalls = 0;

  @override
  Future<void> acceptOrder(String orderId) async {
    if (acceptError != null) {
      throw acceptError!;
    }
    _replaceStatus(availableRuns, orderId, RunStatus.inProgress);
    final run = availableRuns.firstWhere((item) => item.id == orderId);
    volunteerRuns.add(
      _stripVolunteerContext(run).copyWith(
        status: acceptedVolunteerStatus,
        volunteerOwnershipConfirmed: true,
      ),
    );
    availableRuns.removeWhere((item) => item.id == orderId);
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    _replaceStatus(blindRuns, orderId, RunStatus.cancelled);
    _replaceStatus(volunteerRuns, orderId, RunStatus.cancelled);
  }

  @override
  Future<Run> createOrder(CreateOrderPayload payload) async {
    createOrderCalls += 1;
    final run = Run(
      id: '${blindRuns.length + 1}',
      blindRunnerId: 'blind-1',
      location: payload.startAddress,
      timeLabel: payload.timeLabel,
      address: payload.startAddress,
      status: RunStatus.pendingMatch,
      createdAt: payload.plannedStartTime,
      updatedAt: payload.plannedStartTime,
      latitude: payload.startLatitude,
      longitude: payload.startLongitude,
      plannedStart: payload.plannedStartTime,
      plannedEnd: payload.plannedEndTime,
    );
    blindRuns.insert(0, run);
    return run;
  }

  @override
  Future<void> createReview(
    String orderId,
    int rating, {
    String comment = '',
  }) async {
    reviews[orderId] = OrderReview(
      orderId: int.parse(orderId),
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> finishOrder(String orderId) async {
    _replaceStatus(volunteerRuns, orderId, RunStatus.completed);
  }

  @override
  Future<Run> getOrder(String orderId) async {
    if (getOrderError != null) {
      throw getOrderError!;
    }
    return [
      ...blindRuns,
      ...availableRuns,
      ...volunteerRuns,
    ].firstWhere((item) => item.id == orderId);
  }

  @override
  Future<OrderReview?> getReview(String orderId) async => reviews[orderId];

  @override
  Future<List<Run>> listAvailableOrders() async =>
      List<Run>.from(availableRuns);

  @override
  Future<List<Run>> listMyOrders(UserRole role) async {
    listMyOrdersCalls += 1;
    if (role == UserRole.blind) {
      return List<Run>.from(blindRuns);
    }
    return List<Run>.from(volunteerRuns);
  }

  @override
  Future<void> markArrived(String orderId) async {
    _replaceStatus(volunteerRuns, orderId, RunStatus.driverArrived);
  }

  @override
  Future<void> markEnRoute(String orderId) async {
    _replaceStatus(volunteerRuns, orderId, RunStatus.driverEnRoute);
  }

  void _replaceStatus(List<Run> source, String orderId, RunStatus status) {
    final index = source.indexWhere((item) => item.id == orderId);
    if (index == -1) {
      return;
    }
    source[index] = source[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  Run _stripVolunteerContext(Run run) {
    if (!stripVolunteerContextOnOwnedReads) {
      return run;
    }
    return Run(
      id: run.id,
      blindRunnerId: run.blindRunnerId,
      location: run.location,
      timeLabel: run.timeLabel,
      status: run.status,
      createdAt: run.createdAt,
      updatedAt: run.updatedAt,
      notes: run.notes,
      address: run.address,
      volunteer: run.volunteer,
      blindRating: run.blindRating,
      distanceKm: run.distanceKm,
      durationMinutes: run.durationMinutes,
      plannedStart: run.plannedStart,
      plannedEnd: run.plannedEnd,
      volunteerPhone: run.volunteerPhone,
    );
  }
}

class FakeLocationService implements AppLocationService {
  const FakeLocationService({
    this.location = const DeviceLocation(
      latitude: 39.9042,
      longitude: 116.4074,
    ),
    this.failureReason,
  });

  final DeviceLocation? location;
  final DeviceLocationFailureReason? failureReason;

  @override
  Future<DeviceLocationLookup> locate() async => DeviceLocationLookup(
    location: location,
    failureReason: failureReason,
  );

  @override
  Future<DeviceLocation?> locateOnce() async => location;
}

class SequencedFakeLocationService implements AppLocationService {
  SequencedFakeLocationService(this.lookups);

  final List<FutureOr<DeviceLocationLookup>> lookups;
  int locateCalls = 0;

  @override
  Future<DeviceLocationLookup> locate() async {
    final index = locateCalls < lookups.length
        ? locateCalls
        : lookups.length - 1;
    locateCalls += 1;
    return lookups[index];
  }

  @override
  Future<DeviceLocation?> locateOnce() async {
    return (await locate()).location;
  }
}

class FakeSpeechService implements SpeechService {
  final List<String> messages = <String>[];

  @override
  Future<void> speak(String text) async {
    messages.add(text);
  }

  @override
  Future<void> stop() async {}
}

class FakeSpeechRecognitionService implements SpeechRecognitionService {
  FakeSpeechRecognitionService({required this.result});

  final VoiceCaptureResult result;

  @override
  Future<VoiceCaptureResult> listenForTranscript({
    Duration listenFor = const Duration(seconds: 6),
    Duration pauseFor = const Duration(seconds: 2),
    void Function(VoiceCaptureState state)? onStateChanged,
  }) async {
    onStateChanged?.call(result.state);
    return result;
  }

  @override
  Future<RunRequestInput> listenForRunRequest() async {
    return RunRequestInput(
      place: const PlaceSuggestion(
        name: '朝阳公园',
        address: '北京市朝阳区朝阳公园南路1号',
        latitude: 39.9435,
        longitude: 116.4830,
      ),
      timeLabel: parseTimeLabel(result.transcript),
      transcript: result.transcript,
      usedFallback: false,
    );
  }

  @override
  String parseTimeLabel(String transcript) {
    if (transcript.contains('半小时')) {
      return '30分钟后';
    }
    return transcript.trim().isEmpty ? '现在出发' : transcript;
  }
}

class FakePlaceSearchService implements PlaceSearchService {
  const FakePlaceSearchService();

  @override
  Future<List<PlaceSuggestion>> search(
    String keyword, {
    DeviceLocation? near,
  }) async {
    return const [
      PlaceSuggestion(
        name: '朝阳公园',
        address: '北京市朝阳区朝阳公园南路1号',
        latitude: 39.9435,
        longitude: 116.4830,
      ),
    ];
  }
}

Run buildRun({
  required String id,
  required String location,
  required RunStatus status,
  String address = '',
  String timeLabel = '今天 19:00-20:00',
  double? latitude = 39.9042,
  double? longitude = 116.4074,
  String? blindUserPhone,
  String? volunteerPhone,
  bool volunteerOwnershipConfirmed = false,
}) {
  return Run(
    id: id,
    blindRunnerId: 'blind-1',
    location: location,
    timeLabel: timeLabel,
    address: address,
    status: status,
    createdAt: DateTime(2026, 4, 19, 19),
    updatedAt: DateTime(2026, 4, 19, 19),
    latitude: latitude,
    longitude: longitude,
    plannedStart: DateTime(2026, 4, 19, 19),
    plannedEnd: DateTime(2026, 4, 19, 20),
    blindUserPhone: blindUserPhone,
    volunteerPhone: volunteerPhone,
    volunteerOwnershipConfirmed: volunteerOwnershipConfirmed,
  );
}
