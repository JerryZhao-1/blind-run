import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/api_failure.dart';
import 'package:aidrun_demo/core/models/app_settings.dart';
import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/blind_profile.dart';
import 'package:aidrun_demo/core/models/current_user.dart';
import 'package:aidrun_demo/core/models/emergency_contact.dart';
import 'package:aidrun_demo/core/models/order_review.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
import 'package:aidrun_demo/core/repositories/auth_repository.dart';
import 'package:aidrun_demo/core/repositories/auth_session_store.dart';
import 'package:aidrun_demo/core/repositories/blind_profile_repository.dart';
import 'package:aidrun_demo/core/repositories/emergency_contact_repository.dart';
import 'package:aidrun_demo/core/repositories/order_repository.dart';
import 'package:aidrun_demo/core/repositories/settings_repository.dart';
import 'package:aidrun_demo/core/repositories/volunteer_profile_repository.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/core/services/place_search_service.dart';
import 'package:aidrun_demo/demo/demo_showcase_seed.dart';
import 'package:aidrun_demo/demo/demo_scenario_store.dart';

List buildDemoShowcaseOverrides() {
  return [
    demoShowcaseModeProvider.overrideWithValue(true),
    authSessionStoreProvider.overrideWith(
      (ref) => DemoAuthSessionStore(ref.watch(demoScenarioStoreProvider)),
    ),
    settingsRepositoryProvider.overrideWith(
      (ref) => DemoSettingsRepository(ref.watch(demoScenarioStoreProvider)),
    ),
    authRepositoryProvider.overrideWith(
      (ref) => DemoAuthRepository(ref.watch(demoScenarioStoreProvider)),
    ),
    orderRepositoryProvider.overrideWith(
      (ref) => DemoOrderRepository(ref.watch(demoScenarioStoreProvider)),
    ),
    blindProfileRepositoryProvider.overrideWith(
      (ref) => DemoBlindProfileRepository(ref.watch(demoScenarioStoreProvider)),
    ),
    volunteerProfileRepositoryProvider.overrideWith(
      (ref) =>
          DemoVolunteerProfileRepository(ref.watch(demoScenarioStoreProvider)),
    ),
    emergencyContactRepositoryProvider.overrideWith(
      (ref) =>
          DemoEmergencyContactRepository(ref.watch(demoScenarioStoreProvider)),
    ),
    placeSearchServiceProvider.overrideWith(
      (ref) => DemoPlaceSearchService(ref.watch(demoScenarioStoreProvider)),
    ),
    appLocationServiceProvider.overrideWith(
      (ref) => DemoLocationService(ref.watch(demoScenarioStoreProvider)),
    ),
  ];
}

class DemoAuthSessionStore implements AuthSessionStore {
  DemoAuthSessionStore(this.store);

  final DemoScenarioStore store;

  @override
  void clearSession() {
    store.session = null;
  }

  @override
  AuthSession? readSession() => store.session;

  @override
  void saveSession(AuthSession session) {
    store.session = session;
  }
}

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this.store);

  final DemoScenarioStore store;

  @override
  Future<CurrentUser> getCurrentUser() async {
    final currentUser = store.currentUser;
    if (currentUser == null) {
      throw const ApiFailure(message: '请先选择展示场景');
    }
    return currentUser;
  }

  @override
  Future<void> sendCode(String phone) async {}

  @override
  Future<UserRole> setRole(UserRole role) async {
    final existingUser = store.currentUser;
    if (existingUser == null) {
      store.currentUser = CurrentUser(
        userId: 9000,
        phoneMasked: '演示账号',
        role: role,
      );
      store.session = AuthSession(
        token: 'demo-session',
        userId: 9000,
        role: role,
      );
      return role;
    }
    store.currentUser = CurrentUser(
      userId: existingUser.userId,
      phoneMasked: existingUser.phoneMasked,
      role: role,
      createdAt: existingUser.createdAt,
    );
    store.session = (store.session ??
            AuthSession(
              token: 'demo-session',
              userId: existingUser.userId,
              role: role,
            ))
        .copyWith(role: role);
    return role;
  }

  @override
  Future<AuthSession> verifyCode(String phone, String code) async {
    final session = store.session;
    if (session == null) {
      throw const ApiFailure(message: '展示场景尚未初始化');
    }
    return session;
  }
}

class DemoSettingsRepository implements SettingsRepository {
  DemoSettingsRepository(this.store);

  final DemoScenarioStore store;

  @override
  AppSettings load() => store.settings;

  @override
  void save(AppSettings settings) {
    store.settings = settings;
  }
}

class DemoBlindProfileRepository implements BlindProfileRepository {
  DemoBlindProfileRepository(this.store);

  final DemoScenarioStore store;

  @override
  Future<BlindProfile> getProfile() async {
    return store.blindProfile ?? const BlindProfile();
  }

  @override
  Future<BlindProfile> updateProfile(BlindProfile profile) async {
    store.blindProfile = profile;
    return profile;
  }
}

class DemoEmergencyContactRepository implements EmergencyContactRepository {
  DemoEmergencyContactRepository(this.store);

  final DemoScenarioStore store;

  @override
  Future<EmergencyContact> createContact(
    int userId, {
    required String name,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    final contact = EmergencyContact(
      id: store.emergencyContacts.length + 1,
      name: name,
      phone: phone,
      relationship: relationship,
      isPrimary: isPrimary,
    );
    store.emergencyContacts.add(contact);
    return contact;
  }

  @override
  Future<void> deleteContact(int userId, int contactId) async {
    store.emergencyContacts.removeWhere((contact) => contact.id == contactId);
  }

  @override
  Future<List<EmergencyContact>> listContacts(int userId) async {
    return List<EmergencyContact>.from(store.emergencyContacts);
  }

  @override
  Future<void> setPrimary(int userId, int contactId) async {
    for (var index = 0; index < store.emergencyContacts.length; index += 1) {
      final item = store.emergencyContacts[index];
      store.emergencyContacts[index] = item.copyWith(
        isPrimary: item.id == contactId,
      );
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
    final index = store.emergencyContacts.indexWhere(
      (item) => item.id == contactId,
    );
    final updated = EmergencyContact(
      id: contactId,
      name: name,
      phone: phone,
      relationship: relationship,
      isPrimary: isPrimary,
    );
    if (index >= 0) {
      store.emergencyContacts[index] = updated;
    }
    return updated;
  }
}

class DemoVolunteerProfileRepository implements VolunteerProfileRepository {
  DemoVolunteerProfileRepository(this.store);

  final DemoScenarioStore store;

  @override
  Future<VolunteerProfile> getProfile() async {
    return store.volunteerProfile ??
        const VolunteerProfile(
          id: 'demo-volunteer',
          name: '演示志愿者',
          verificationStatus: 'APPROVED',
          availableTimeSlots: [],
        );
  }

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required bool isOnline,
  }) async {
    store.volunteerLocation = DeviceLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<VolunteerProfile> updateProfile(VolunteerProfile profile) async {
    store.volunteerProfile = profile;
    return profile;
  }
}

class DemoOrderRepository implements OrderRepository {
  DemoOrderRepository(this.store);

  final DemoScenarioStore store;

  @override
  Future<void> acceptOrder(String orderId) async {
    final index = store.availableRuns.indexWhere((item) => item.id == orderId);
    if (index == -1) {
      throw const ApiFailure(message: '演示订单不存在');
    }
    final run = store.availableRuns.removeAt(index);
    store.volunteerRuns.insert(
      0,
      run.copyWith(
        status: RunStatus.inProgress,
        updatedAt: DateTime.now(),
        volunteerOwnershipConfirmed: true,
      ),
    );
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    _replaceStatus(store.blindRuns, orderId, RunStatus.cancelled);
    _replaceStatus(store.volunteerRuns, orderId, RunStatus.cancelled);
  }

  @override
  Future<Run> createOrder(CreateOrderPayload payload) async {
    final run = Run(
      id: '${store.blindRuns.length + 100}',
      blindRunnerId: 'blind-${store.currentUser?.userId ?? 0}',
      location: payload.startAddress,
      timeLabel: payload.timeLabel,
      status: RunStatus.pendingMatch,
      createdAt: payload.plannedStartTime,
      updatedAt: payload.plannedStartTime,
      address: payload.startAddress,
      latitude: payload.startLatitude,
      longitude: payload.startLongitude,
      plannedStart: payload.plannedStartTime,
      plannedEnd: payload.plannedEndTime,
      notes: payload.notes,
    );
    store.blindRuns.insert(0, run);
    return run;
  }

  @override
  Future<void> createReview(
    String orderId,
    int rating, {
    String comment = '',
  }) async {
    store.reviews[orderId] = OrderReview(
      orderId: int.tryParse(orderId) ?? 0,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> finishOrder(String orderId) async {
    final now = DateTime.now();
    void completeRun(List<Run> source) {
      final index = source.indexWhere((item) => item.id == orderId);
      if (index == -1) {
        return;
      }
      source[index] = source[index].copyWith(
        status: RunStatus.completed,
        updatedAt: now,
        distanceKm: source[index].distanceKm ?? 5.2,
        durationMinutes: source[index].durationMinutes ?? 62,
      );
    }

    completeRun(store.volunteerRuns);
    completeRun(store.blindRuns);
  }

  @override
  Future<Run> getOrder(String orderId) async {
    final run = store.findRun(orderId);
    if (run == null) {
      throw const ApiFailure(message: '未找到演示订单');
    }
    return run;
  }

  @override
  Future<OrderReview?> getReview(String orderId) async => store.reviews[orderId];

  @override
  Future<List<Run>> listAvailableOrders() async {
    if (!store.settings.volunteerAvailable) {
      return const [];
    }
    return List<Run>.from(store.availableRuns);
  }

  @override
  Future<List<Run>> listMyOrders(UserRole role) async {
    if (role == UserRole.blind) {
      return List<Run>.from(store.blindRuns);
    }
    return List<Run>.from(store.volunteerRuns);
  }

  @override
  Future<void> markArrived(String orderId) async {
    _replaceStatus(store.volunteerRuns, orderId, RunStatus.driverArrived);
  }

  @override
  Future<void> markEnRoute(String orderId) async {
    _replaceStatus(store.volunteerRuns, orderId, RunStatus.driverEnRoute);
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
}

class DemoLocationService implements AppLocationService {
  DemoLocationService(this.store);

  final DemoScenarioStore store;

  @override
  Future<DeviceLocationLookup> locate() async {
    if (!store.hasActiveScenario) {
      return const DeviceLocationLookup(
        failureReason: DeviceLocationFailureReason.unavailable,
        errorCode: 'demo_scenario_missing',
      );
    }
    return DeviceLocationLookup(location: store.volunteerLocation);
  }

  @override
  Future<DeviceLocation?> locateOnce() async => (await locate()).location;
}

class DemoPlaceSearchService implements PlaceSearchService {
  DemoPlaceSearchService(this.store);

  final DemoScenarioStore store;

  @override
  Future<List<PlaceSuggestion>> search(
    String keyword, {
    DeviceLocation? near,
  }) async {
    return filterDemoShowcasePlaces(
      keyword,
      near: near ?? store.volunteerLocation,
    );
  }
}
