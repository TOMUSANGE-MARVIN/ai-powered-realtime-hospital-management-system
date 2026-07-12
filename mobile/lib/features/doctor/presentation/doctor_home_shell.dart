import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/pill_nav_bar.dart';

class DoctorHomeShell extends StatelessWidget {
  const DoctorHomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: PillNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          PillNavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
          PillNavItem(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble),
          PillNavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month),
          PillNavItem(icon: Icons.payments_outlined, selectedIcon: Icons.payments),
          PillNavItem(icon: Icons.person_outline, selectedIcon: Icons.person),
        ],
      ),
    );
  }
}
