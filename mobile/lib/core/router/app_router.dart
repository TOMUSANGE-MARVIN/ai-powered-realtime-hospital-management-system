import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/book_appointment_screen.dart';
import '../../features/appointments/presentation/my_appointments_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/doctors/presentation/doctor_detail_screen.dart';
import '../../features/doctors/presentation/doctors_list_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/profile_screen.dart';

/// Bridges Riverpod's [authControllerProvider] to go_router's
/// [Listenable]-based `refreshListenable`, so navigation reacts immediately
/// to sign in / sign out without polling.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      const publicRoutes = {'/login', '/register'};

      if (authState.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final isLoggedIn = authState.value != null;
      if (!isLoggedIn) {
        return publicRoutes.contains(location) ? null : '/login';
      }

      if (location == '/splash' || publicRoutes.contains(location)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/doctors/:id',
        builder: (context, state) => DoctorDetailScreen(doctorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:doctorId',
        builder: (context, state) => BookAppointmentScreen(
          doctorId: state.pathParameters['doctorId']!,
          doctorName: state.extra as String?,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (context, state) => const DoctorsListScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/appointments',
                builder: (context, state) => const MyAppointmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/home/profile', builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});
