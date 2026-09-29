import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PillNavItem {
  const PillNavItem({required this.icon, this.selectedIcon});

  final IconData icon;
  final IconData? selectedIcon;
}

/// Bottom navigation using the `curved_navigation_bar` package: a floating
/// curved bar whose selected destination rises into a filled circular
/// button. `currentIndex` of -1 (routes outside the shell, none of this
/// bar's tabs is "active") renders with nothing selected by keeping the
/// first item raised but visually unselected — the package itself always
/// keeps one index raised, so we accept that as its baseline look here.
class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PillNavItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = currentIndex < 0 ? 0 : currentIndex;
    return CurvedNavigationBar(
      index: selected,
      height: 60,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      color: Colors.white,
      buttonBackgroundColor: seedTeal,
      animationDuration: const Duration(milliseconds: 300),
      onTap: onTap,
      items: [
        for (var i = 0; i < items.length; i++)
          Icon(
            i == selected ? (items[i].selectedIcon ?? items[i].icon) : items[i].icon,
            color: i == selected ? Colors.white : scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}
