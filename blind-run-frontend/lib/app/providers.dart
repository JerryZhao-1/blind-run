import 'package:aidrun_demo/app/state/app_state.dart';
import 'package:aidrun_demo/app/state/app_state_controller.dart';
import 'package:aidrun_demo/core/network/api_client.dart';
import 'package:aidrun_demo/core/repositories/auth_repository.dart';
import 'package:aidrun_demo/core/repositories/auth_session_store.dart';
import 'package:aidrun_demo/core/repositories/blind_profile_repository.dart';
import 'package:aidrun_demo/core/repositories/emergency_contact_repository.dart';
import 'package:aidrun_demo/core/repositories/order_repository.dart';
import 'package:aidrun_demo/core/repositories/settings_repository.dart';
import 'package:aidrun_demo/core/repositories/volunteer_profile_repository.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/core/services/blind_accessibility_service.dart';
import 'package:aidrun_demo/core/services/order_time_resolver.dart';
import 'package:aidrun_demo/core/services/place_search_service.dart';
import 'package:aidrun_demo/core/services/speech_recognition_service.dart';
import 'package:aidrun_demo/core/services/speech_service.dart';
import 'package:aidrun_demo/demo/demo_mode.dart';
import 'package:aidrun_demo/demo/demo_scenario_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences override missing'),
);

final authSessionStoreProvider = Provider<AuthSessionStore>(
  (ref) => SharedPrefsAuthSessionStore(ref.watch(sharedPreferencesProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SharedPrefsSettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiBaseUrlProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://47.114.113.171',
  );
});

final demoShowcaseModeProvider = Provider<bool>((ref) => kDemoShowcaseMode);

final demoShowcaseScenarioProvider = Provider<DemoShowcaseScenario>((ref) {
  final normalized = kDemoShowcaseScenarioKey.trim().toLowerCase();
  return switch (normalized) {
    'blind' => DemoShowcaseScenario.blindJourney,
    _ => DemoShowcaseScenario.volunteerJourney,
  };
});

final demoVideoCaptureSceneProvider = Provider<DemoVideoCaptureScene?>((ref) {
  return DemoVideoCaptureSceneX.fromConfigKey(kDemoVideoCaptureSceneKey);
});

final demoStartupRouteProvider = Provider<String>((ref) {
  final captureScene = ref.watch(demoVideoCaptureSceneProvider);
  if (captureScene != null) {
    return captureScene.targetRoute;
  }
  return ref.watch(demoShowcaseScenarioProvider).targetRoute;
});

final demoScenarioStoreProvider = Provider<DemoScenarioStore>(
  (ref) => DemoScenarioStore(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    httpClient: ref.watch(httpClientProvider),
    sessionStore: ref.watch(authSessionStoreProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(ref.watch(apiClientProvider)),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => HttpOrderRepository(ref.watch(apiClientProvider)),
);

final blindProfileRepositoryProvider = Provider<BlindProfileRepository>(
  (ref) => HttpBlindProfileRepository(ref.watch(apiClientProvider)),
);

final volunteerProfileRepositoryProvider = Provider<VolunteerProfileRepository>(
  (ref) => HttpVolunteerProfileRepository(ref.watch(apiClientProvider)),
);

final emergencyContactRepositoryProvider = Provider<EmergencyContactRepository>(
  (ref) => HttpEmergencyContactRepository(ref.watch(apiClientProvider)),
);

final aMapConfigProvider = Provider<AMapConfig>(
  (ref) => AMapConfig.fromEnvironment(),
);

final appLocationServiceProvider = Provider<AppLocationService>(
  (ref) => AMapLocationService(ref.watch(aMapConfigProvider)),
);

final placeSearchServiceProvider = Provider<PlaceSearchService>(
  (ref) => AMapPlaceSearchService(ref.watch(aMapConfigProvider)),
);

final speechServiceProvider = Provider<SpeechService>(
  (ref) => DeviceSpeechService(),
);

final blindAccessibilityServiceProvider = Provider<BlindAccessibilityService>(
  (ref) =>
      CoordinatedBlindAccessibilityService(ref.watch(speechServiceProvider)),
);

final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>(
  (ref) => DeviceSpeechRecognitionService(),
);

final orderTimeResolverProvider = Provider<OrderTimeResolver>(
  (ref) => const OrderTimeResolver(),
);

final appStateControllerProvider =
    NotifierProvider<AppStateController, AppState>(AppStateController.new);

final goRouterRefreshProvider = Provider<RouterRefreshListenable>((ref) {
  return RouterRefreshListenable(ref);
});

class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(this.ref) {
    ref.listen(appStateControllerProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref ref;
}
