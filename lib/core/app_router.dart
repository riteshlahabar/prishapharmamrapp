import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/attendance/ui/home_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/messages/ui/inbox_screen.dart';
import '../features/persons/ui/client_form_screen.dart';
import '../features/persons/ui/my_clients_screen.dart';
import '../features/profile/ui/profile_screen.dart';
import '../features/shell/ui/app_shell.dart';
import '../features/visits/ui/visit_form_screen.dart';
import '../features/visits/ui/visits_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Routes, with one redirect: no token means login, a token means anywhere
/// but login. There is no splash route — `main()` holds the first frame
/// back so the native launch window covers startup, and by the time
/// anything paints this redirect has already settled on the right screen.
///
/// The redirect reads synchronous providers rather than hitting disk, so it
/// cannot flicker. The token is loaded once in `main()` before `runApp`.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    // Re-runs the redirect whenever sign-in state changes, so signing out
    // from the profile tab moves the whole app to login by itself.
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final signedIn = ref.read(isSignedInProvider);
      final atLogin = state.matchedLocation == '/login';

      if (!signedIn) return atLogin ? null : '/login';
      if (atLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      // One branch per tab, each keeping its own history.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/visits',
                builder: (context, state) => const VisitsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clients',
                builder: (context, state) => const MyClientsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Outside the shell: full-screen forms over the tabs.
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/visits/new',
        builder: (context, state) => const VisitFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/clients/new',
        builder: (context, state) => const ClientFormScreen(),
      ),
    ],
  );
});

/// Bridges Riverpod to GoRouter's `refreshListenable`: the redirect has to
/// re-runs when sign-in state changes, so signing out moves the whole app.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(isSignedInProvider, (_, _) => notifyListeners());
  }
}
