import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/book_appointment_screen.dart';
import '../../features/appointments/presentation/my_appointments_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/auth/state/onboarding_controller.dart';
import '../../features/calls/presentation/calls_screen.dart';
import '../../features/chat/data/chat_args.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/new_chat_screen.dart';
import '../../features/doctor/presentation/doctor_appointments_screen.dart';
import '../../features/doctor/presentation/doctor_dashboard_screen.dart';
import '../../features/doctor/presentation/doctor_earnings_screen.dart';
import '../../features/doctor/presentation/doctor_home_shell.dart';
import '../../features/doctor/presentation/doctor_reviews_screen.dart';
import '../../features/doctor/presentation/new_prescription_screen.dart';
import '../../features/doctors/presentation/ai_symptom_search_screen.dart';
import '../../features/doctors/presentation/all_categories_screen.dart';
import '../../features/doctors/presentation/doctor_detail_screen.dart';
import '../../features/doctors/presentation/doctors_list_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/patient_home_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';

/// Bridges Riverpod's [authControllerProvider] to go_router's
/// [Listenable]-based `refreshListenable`, so navigation reacts immediately
/// to sign in / sign out without polling.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(onboardingControllerProvider, (_, _) => notifyListeners());
  }
}

/// Lets code outside any specific screen's `BuildContext` (see
/// `CallOverlay`, which pushes the full-screen in-call UI as a real route)
/// push/pop on the app's root Navigator.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final hasSeenWelcome = ref.read(onboardingControllerProvider);
      final location = state.matchedLocation;
      const publicRoutes = {'/welcome', '/login', '/register'};

      if (authState.isLoading) {
        // Only bounce to the splash screen for the initial session check on
        // cold start. A sign-in/sign-up submission from these screens also
        // sets this same loading state — redirecting away then would unmount
        // the screen mid-request, silently swallowing whatever error comes
        // back. Let those screens show their own inline spinner instead.
        if (publicRoutes.contains(location)) return null;
        return location == '/splash' ? null : '/splash';
      }

      final user = authState.value;
      final isLoggedIn = user != null;
      if (!isLoggedIn) {
        // First-time install: show the welcome carousel instead of dropping
        // straight into the login screen.
        if (!hasSeenWelcome) {
          return location == '/welcome' ? null : '/welcome';
        }
        if (location == '/welcome') return '/login';
        return publicRoutes.contains(location) ? null : '/login';
      }

      final isDoctor = user.role == 'doctor';
      final homeRoot = isDoctor ? '/doctor-home' : '/home';

      if (location == '/splash' || publicRoutes.contains(location)) {
        return homeRoot;
      }
      // Keep a patient out of the doctor shell and vice versa.
      if (isDoctor && location.startsWith('/home')) return homeRoot;
      if (!isDoctor && location.startsWith('/doctor-home')) return homeRoot;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/search',
        builder: (context, state) =>
            DoctorsListScreen(initialSpecialty: state.extra as String?),
      ),
      GoRoute(path: '/categories', builder: (context, state) => const AllCategoriesScreen()),
      GoRoute(path: '/ai-search', builder: (context, state) => const AiSymptomSearchScreen()),
      GoRoute(
        path: '/doctors/:id',
        builder: (context, state) => DoctorDetailScreen(doctorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:doctorId',
        builder: (context, state) => BookAppointmentScreen(
          doctorId: state.pathParameters['doctorId']!,
        ),
      ),
      GoRoute(
        path: '/chat/:otherUserId',
        builder: (context, state) {
          final args = state.extra as ChatArgs?;
          return ChatScreen(
            otherUserId: state.pathParameters['otherUserId']!,
            otherUserName: args?.name ?? 'Chat',
            otherUserImage: args?.image,
          );
        },
      ),
      GoRoute(path: '/new-chat', builder: (context, state) => const NewChatScreen()),
      GoRoute(path: '/calls', builder: (context, state) => const CallsScreen()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (context, state) => const PatientHomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/home/chats', builder: (context, state) => const ChatListScreen())],
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
      GoRoute(
        path: '/doctor-home/reviews',
        builder: (context, state) => const DoctorReviewsScreen(),
      ),
      GoRoute(
        path: '/doctor-home/prescriptions/new',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return NewPrescriptionScreen(
            patientId: extra['patientId'] as String? ?? '',
            patientName: extra['patientName'] as String? ?? 'Patient',
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => DoctorHomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/doctor-home', builder: (context, state) => const DoctorDashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/doctor-home/chats', builder: (context, state) => const ChatListScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/doctor-home/appointments',
                builder: (context, state) => const DoctorAppointmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/doctor-home/earnings',
                builder: (context, state) => const DoctorEarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/doctor-home/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
