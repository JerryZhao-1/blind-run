import 'package:aidrun_demo/app/state/app_state.dart';
import 'package:aidrun_demo/app/state/app_state_controller.dart';
import 'package:aidrun_demo/core/repositories/role_session_store.dart';
import 'package:aidrun_demo/core/repositories/run_repository.dart';
import 'package:aidrun_demo/core/repositories/settings_repository.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/core/services/blind_accessibility_service.dart';
import 'package:aidrun_demo/core/services/place_search_service.dart';
import 'package:aidrun_demo/core/services/speech_recognition_service.dart';
import 'package:aidrun_demo/core/services/speech_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences override missing'),
);

final roleSessionStoreProvider = Provider<RoleSessionStore>(
  (ref) => SharedPrefsRoleSessionStore(ref.watch(sharedPreferencesProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SharedPrefsSettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final runRepositoryProvider = Provider<RunRepository>(
  (ref) => LocalRunRepository(),
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
