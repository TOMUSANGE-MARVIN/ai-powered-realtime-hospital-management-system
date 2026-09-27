import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/auth_controller.dart';
import '../../features/doctor/presentation/doctor_home_shell.dart';
import '../../features/home/presentation/home_shell.dart';
import 'pill_nav_bar.dart';

/// Drop-in bottom nav for screens that live outside [HomeShell]/
/// [DoctorHomeShell] (detail screens, search, settings, etc.) — resolves the
/// signed-in user's role to show the matching pill nav, with no tab
/// highlighted since none of these routes is itself a shell branch root.
/// Tapping a tab jumps to that tab's branch root.
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDoctor = ref.watch(authControllerProvider).value?.role == 'doctor';
    final items = isDoctor ? doctorNavItems : patientNavItems;
    final paths = isDoctor ? doctorNavPaths : patientNavPaths;

    return PillNavBar(
      currentIndex: -1,
      onTap: (index) => context.go(paths[index]),
      items: items,
    );
  }
}
