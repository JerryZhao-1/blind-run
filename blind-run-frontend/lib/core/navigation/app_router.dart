import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/features/blind/blind_active_run_page.dart';
import 'package:aidrun_demo/features/blind/blind_dashboard_page.dart';
import 'package:aidrun_demo/features/blind/place_search_page.dart';
import 'package:aidrun_demo/features/blind/request_run_page.dart';
import 'package:aidrun_demo/features/role_selection/role_selection_page.dart';
import 'package:aidrun_demo/features/settings/settings_page.dart';
import 'package:aidrun_demo/features/volunteer/volunteer_active_run_page.dart';
import 'package:aidrun_demo/features/volunteer/volunteer_dashboard_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(goRouterRefreshProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final role = ref.read(appStateControllerProvider).role;
      final location = state.fullPath ?? state.uri.toString();
      final isBlindRoute = location.startsWith('/blind');
      final isVolunteerRoute = location.startsWith('/volunteer');
      final isSettingsRoute = location == '/settings';

      if (location == '/') {
        if (role == UserRole.blind) {
          return '/blind';
        }
        if (role == UserRole.volunteer) {
          return '/volunteer';
        }
        return null;
      }

      if (role == null) {
        return '/';
      }

      if (isBlindRoute && role != UserRole.blind) {
        return '/volunteer';
      }

      if (isVolunteerRoute && role != UserRole.volunteer) {
        return '/blind';
      }

      if (isSettingsRoute) {
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/blind',
        builder: (context, state) => const BlindDashboardPage(),
      ),
      GoRoute(
        path: '/blind/request',
        builder: (context, state) => const RequestRunPage(),
      ),
      GoRoute(
        path: '/blind/request/place',
        builder: (context, state) => const BlindPlaceSearchPage(),
      ),
      GoRoute(
        path: '/blind/run/:id',
        builder: (context, state) => BlindActiveRunPage(
          runId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/volunteer',
        builder: (context, state) => const VolunteerDashboardPage(),
      ),
      GoRoute(
        path: '/volunteer/run/:id',
        builder: (context, state) => VolunteerActiveRunPage(
          runId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
