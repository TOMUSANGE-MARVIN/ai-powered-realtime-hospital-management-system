import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/pill_nav_bar.dart';

const patientNavItems = [
  PillNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home),
  PillNavItem(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble),
  PillNavItem(
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  PillNavItem(icon: Icons.person_outline, selectedIcon: Icons.person),
];

/// Branch root for each [patientNavItems] entry, in the same order as the
/// shell's branches — lets screens outside the shell show the same nav.
const patientNavPaths = [
  '/home',
  '/home/chats',
  '/home/appointments',
  '/home/profile',
];

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

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
        items: patientNavItems,
      ),
    );
  }
}
