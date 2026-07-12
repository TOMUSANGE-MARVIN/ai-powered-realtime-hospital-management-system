import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/pill_nav_bar.dart';

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
        items: const [
          PillNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home),
          PillNavItem(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble),
          PillNavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month),
          PillNavItem(icon: Icons.person_outline, selectedIcon: Icons.person),
        ],
      ),
    );
  }
}
