import 'package:aidrun_demo/core/models/app_settings.dart';
import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/blind_profile.dart';
import 'package:aidrun_demo/core/models/current_user.dart';
import 'package:aidrun_demo/core/models/emergency_contact.dart';
import 'package:aidrun_demo/core/models/order_review.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/demo/demo_showcase_seed.dart';

enum DemoShowcaseScenario {
  volunteerJourney,
  blindJourney,
}

extension DemoShowcaseScenarioX on DemoShowcaseScenario {
  String get title => switch (this) {
        DemoShowcaseScenario.volunteerJourney => '志愿者展示',
        DemoShowcaseScenario.blindJourney => '盲人展示',
      };

  String get subtitle => switch (this) {
        DemoShowcaseScenario.volunteerJourney => '从附近需求开始，演示接单、出发、到达、完成和历史记录',
        DemoShowcaseScenario.blindJourney => '从预约开始，演示下单、当前订单、设置和评价流程',
      };

  UserRole get role => switch (this) {
        DemoShowcaseScenario.volunteerJourney => UserRole.volunteer,
        DemoShowcaseScenario.blindJourney => UserRole.blind,
      };

  String get targetRoute => switch (this) {
        DemoShowcaseScenario.volunteerJourney => '/volunteer',
        DemoShowcaseScenario.blindJourney => '/blind',
      };
}

enum DemoVideoCaptureScene {
  blindRequest,
  blindActive,
  blindArrived,
  blindReview,
  volunteerNearby,
  volunteerEnRoute,
  volunteerComplete,
}

extension DemoVideoCaptureSceneX on DemoVideoCaptureScene {
  static DemoVideoCaptureScene? fromConfigKey(String rawValue) {
    return switch (rawValue.trim().toLowerCase()) {
      'blind-request' => DemoVideoCaptureScene.blindRequest,
      'blind-active' => DemoVideoCaptureScene.blindActive,
      'blind-arrived' => DemoVideoCaptureScene.blindArrived,
      'blind-review' => DemoVideoCaptureScene.blindReview,
      'volunteer-nearby' => DemoVideoCaptureScene.volunteerNearby,
      'volunteer-enroute' => DemoVideoCaptureScene.volunteerEnRoute,
      'volunteer-complete' => DemoVideoCaptureScene.volunteerComplete,
      _ => null,
    };
  }

  DemoShowcaseScenario get scenario => switch (this) {
        DemoVideoCaptureScene.blindRequest ||
        DemoVideoCaptureScene.blindActive ||
        DemoVideoCaptureScene.blindArrived ||
        DemoVideoCaptureScene.blindReview => DemoShowcaseScenario.blindJourney,
        DemoVideoCaptureScene.volunteerNearby ||
        DemoVideoCaptureScene.volunteerEnRoute ||
        DemoVideoCaptureScene.volunteerComplete =>
          DemoShowcaseScenario.volunteerJourney,
      };

  String get targetRoute => switch (this) {
        DemoVideoCaptureScene.blindRequest => '/blind/request',
        DemoVideoCaptureScene.blindActive => '/blind/run/$kDemoStoryOrderId',
        DemoVideoCaptureScene.blindArrived => '/blind/run/$kDemoStoryOrderId',
        DemoVideoCaptureScene.blindReview => '/blind/run/$kDemoStoryOrderId',
        DemoVideoCaptureScene.volunteerNearby => '/volunteer',
        DemoVideoCaptureScene.volunteerEnRoute =>
          '/volunteer/run/$kDemoStoryOrderId',
        DemoVideoCaptureScene.volunteerComplete =>
          '/volunteer/run/$kDemoStoryOrderId',
      };

  String get configKey => switch (this) {
        DemoVideoCaptureScene.blindRequest => 'blind-request',
        DemoVideoCaptureScene.blindActive => 'blind-active',
        DemoVideoCaptureScene.blindArrived => 'blind-arrived',
        DemoVideoCaptureScene.blindReview => 'blind-review',
        DemoVideoCaptureScene.volunteerNearby => 'volunteer-nearby',
        DemoVideoCaptureScene.volunteerEnRoute => 'volunteer-enroute',
        DemoVideoCaptureScene.volunteerComplete => 'volunteer-complete',
      };
}

class DemoScenarioStore {
  DemoScenarioStore() {
    clear();
  }

  DemoShowcaseScenario? activeScenario;
  DemoVideoCaptureScene? activeCaptureScene;
  AuthSession? session;
  CurrentUser? currentUser;
  BlindProfile? blindProfile;
  VolunteerProfile? volunteerProfile;
  AppSettings settings = const AppSettings(
    notificationsEnabled: true,
    volunteerAvailable: false,
  );
  DeviceLocation volunteerLocation = kDemoShowcaseLocation;
  final List<EmergencyContact> emergencyContacts = <EmergencyContact>[];
  final List<Run> blindRuns = <Run>[];
  final List<Run> availableRuns = <Run>[];
  final List<Run> volunteerRuns = <Run>[];
  final Map<String, OrderReview> reviews = <String, OrderReview>{};

  bool get hasActiveScenario => activeScenario != null;

  void activate(DemoShowcaseScenario scenario) {
    clear();
    activeScenario = scenario;
    switch (scenario) {
      case DemoShowcaseScenario.volunteerJourney:
        _seedVolunteerJourney();
      case DemoShowcaseScenario.blindJourney:
        _seedBlindJourney();
    }
  }

  void activateCaptureScene(DemoVideoCaptureScene scene) {
    clear();
    activeScenario = scene.scenario;
    activeCaptureScene = scene;
    switch (scene) {
      case DemoVideoCaptureScene.blindRequest:
        _seedBlindRequestCapture();
      case DemoVideoCaptureScene.blindActive:
        _seedBlindActiveCapture();
      case DemoVideoCaptureScene.blindArrived:
        _seedBlindArrivedCapture();
      case DemoVideoCaptureScene.blindReview:
        _seedBlindReviewCapture();
      case DemoVideoCaptureScene.volunteerNearby:
        _seedVolunteerNearbyCapture();
      case DemoVideoCaptureScene.volunteerEnRoute:
        _seedVolunteerEnRouteCapture();
      case DemoVideoCaptureScene.volunteerComplete:
        _seedVolunteerCompleteCapture();
    }
  }

  void clear() {
    activeScenario = null;
    activeCaptureScene = null;
    session = null;
    currentUser = null;
    blindProfile = null;
    volunteerProfile = null;
    settings = const AppSettings(
      notificationsEnabled: true,
      volunteerAvailable: false,
    );
    volunteerLocation = kDemoShowcaseLocation;
    emergencyContacts.clear();
    blindRuns.clear();
    availableRuns.clear();
    volunteerRuns.clear();
    reviews.clear();
  }

  Run? findRun(String orderId) {
    for (final run in [...blindRuns, ...availableRuns, ...volunteerRuns]) {
      if (run.id == orderId) {
        return run;
      }
    }
    return null;
  }

  void _seedVolunteerJourney() {
    final now = DateTime.now();
    final plannedStart = now.add(const Duration(minutes: 20));
    final plannedEnd = plannedStart.add(const Duration(hours: 1));
    _seedVolunteerBase();
    availableRuns.add(
      _buildRun(
        id: '801',
        location: kDemoVolunteerPickupPlace.name,
        address: kDemoVolunteerPickupPlace.address,
        status: RunStatus.pendingAccept,
        latitude: kDemoVolunteerPickupPlace.latitude,
        longitude: kDemoVolunteerPickupPlace.longitude,
        plannedStart: plannedStart,
        plannedEnd: plannedEnd,
        blindUserPhone: '130****9977',
      ),
    );
    volunteerRuns.add(
      _buildRun(
        id: '610',
        location: '奥林匹克森林公园南园',
        address: '北京市朝阳区科荟路33号',
        status: RunStatus.completed,
        latitude: 40.0150,
        longitude: 116.3900,
        plannedStart: now.subtract(const Duration(days: 2, hours: 1)),
        plannedEnd: now.subtract(const Duration(days: 2)),
        distanceKm: 5.6,
        durationMinutes: 58,
        volunteerOwnershipConfirmed: true,
      ),
    );
  }

  void _seedBlindJourney() {
    _seedBlindBase();
  }

  void _seedVolunteerBase() {
    session = const AuthSession(
      token: 'demo-volunteer-token',
      userId: 2001,
      role: UserRole.volunteer,
    );
    currentUser = const CurrentUser(
      userId: 2001,
      phoneMasked: kDemoStoryVolunteerPhoneMasked,
      role: UserRole.volunteer,
    );
    volunteerProfile = const VolunteerProfile(
      id: 'demo-volunteer',
      name: kDemoStoryVolunteerName,
      verificationStatus: 'APPROVED',
      availableTimeSlots: [],
      phone: kDemoStoryVolunteerPhoneMasked,
      avatarSeed: 'demo-volunteer',
    );
    settings = const AppSettings(
      notificationsEnabled: true,
      volunteerAvailable: true,
    );
    volunteerLocation = kDemoShowcaseLocation;
  }

  void _seedBlindBase() {
    volunteerLocation = kDemoShowcaseLocation;
    session = const AuthSession(
      token: 'demo-blind-token',
      userId: 1001,
      role: UserRole.blind,
    );
    currentUser = const CurrentUser(
      userId: 1001,
      phoneMasked: kDemoStoryBlindPhoneMasked,
      role: UserRole.blind,
    );
    blindProfile = const BlindProfile(
      name: kDemoStoryBlindName,
      runningPace: '6:30/km',
      specialNeeds: '转弯和路沿请提前语音提醒',
    );
    emergencyContacts.addAll(const [
      EmergencyContact(
        id: 1,
        name: '张兰',
        phone: '139****9000',
        relationship: '家人',
        isPrimary: true,
      ),
      EmergencyContact(
        id: 2,
        name: '王磊',
        phone: '137****7000',
        relationship: '朋友',
        isPrimary: false,
      ),
    ]);
  }

  void _seedBlindRequestCapture() {
    _seedBlindBase();
  }

  void _seedBlindActiveCapture() {
    _seedBlindBase();
    blindRuns.add(
      _buildStoryRun(
        status: RunStatus.driverEnRoute,
        volunteerPhone: kDemoStoryVolunteerPhoneMasked,
      ),
    );
  }

  void _seedBlindArrivedCapture() {
    _seedBlindBase();
    blindRuns.add(
      _buildStoryRun(
        status: RunStatus.driverArrived,
        volunteerPhone: kDemoStoryVolunteerPhoneMasked,
      ),
    );
  }

  void _seedBlindReviewCapture() {
    _seedBlindBase();
    blindRuns.add(
      _buildStoryRun(
        status: RunStatus.completed,
        volunteerPhone: kDemoStoryVolunteerPhoneMasked,
        distanceKm: kDemoStoryDistanceKm,
        durationMinutes: kDemoStoryDurationMinutes,
      ),
    );
  }

  void _seedVolunteerNearbyCapture() {
    _seedVolunteerBase();
    availableRuns.add(
      _buildStoryRun(
        status: RunStatus.pendingAccept,
        blindUserPhone: kDemoStoryBlindPhoneMasked,
      ),
    );
  }

  void _seedVolunteerEnRouteCapture() {
    _seedVolunteerBase();
    volunteerRuns.add(
      _buildStoryRun(
        status: RunStatus.driverEnRoute,
        blindUserPhone: kDemoStoryBlindPhoneMasked,
        volunteerOwnershipConfirmed: true,
      ),
    );
  }

  void _seedVolunteerCompleteCapture() {
    _seedVolunteerBase();
    volunteerRuns.add(
      _buildStoryRun(
        status: RunStatus.completed,
        blindUserPhone: kDemoStoryBlindPhoneMasked,
        distanceKm: kDemoStoryDistanceKm,
        durationMinutes: kDemoStoryDurationMinutes,
        volunteerOwnershipConfirmed: true,
      ),
    );
  }

  Run _buildStoryRun({
    required RunStatus status,
    String? volunteerPhone,
    String? blindUserPhone,
    double? distanceKm,
    int? durationMinutes,
    bool volunteerOwnershipConfirmed = false,
  }) {
    final now = DateTime.now();
    final plannedStart = now.add(const Duration(minutes: 8));
    final plannedEnd = plannedStart.add(const Duration(hours: 1));
    return _buildRun(
      id: kDemoStoryOrderId,
      location: kDemoStoryPrimaryPlace.name,
      address: kDemoStoryPrimaryPlace.address,
      status: status,
      latitude: kDemoStoryPrimaryPlace.latitude,
      longitude: kDemoStoryPrimaryPlace.longitude,
      plannedStart: plannedStart,
      plannedEnd: plannedEnd,
      notes: kDemoStoryMeetingNotes,
      volunteerPhone: volunteerPhone,
      blindUserPhone: blindUserPhone,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      volunteerOwnershipConfirmed: volunteerOwnershipConfirmed,
    );
  }

  Run _buildRun({
    required String id,
    required String location,
    required String address,
    required RunStatus status,
    required DateTime plannedStart,
    required DateTime plannedEnd,
    String notes = '',
    double? latitude,
    double? longitude,
    double? distanceKm,
    int? durationMinutes,
    String? volunteerPhone,
    String? blindUserPhone,
    bool volunteerOwnershipConfirmed = false,
  }) {
    return Run(
      id: id,
      blindRunnerId: 'blind-${currentUser?.userId ?? 0}',
      location: location,
      timeLabel: Run.formatTimeLabel(plannedStart, plannedEnd),
      notes: notes,
      status: status,
      createdAt: plannedStart.subtract(const Duration(minutes: 10)),
      updatedAt: plannedStart.subtract(const Duration(minutes: 5)),
      address: address,
      latitude: latitude,
      longitude: longitude,
      plannedStart: plannedStart,
      plannedEnd: plannedEnd,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      volunteerPhone: volunteerPhone,
      blindUserPhone: blindUserPhone,
      volunteerOwnershipConfirmed: volunteerOwnershipConfirmed,
    );
  }
}
