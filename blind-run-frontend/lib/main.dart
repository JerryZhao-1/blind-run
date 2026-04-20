import 'package:aidrun_demo/app/aidrun_app.dart';
import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/demo/demo_mode.dart';
import 'package:aidrun_demo/demo/demo_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final aMapConfig = await AMapConfig.load();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        aMapConfigProvider.overrideWithValue(aMapConfig),
        if (kDemoShowcaseMode) ...buildDemoShowcaseOverrides(),
      ],
      child: const AidRunApp(),
    ),
  );
}
