import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PillNavItem {
  const PillNavItem({required this.icon, this.selectedIcon});

  final IconData icon;
  final IconData? selectedIcon;
}

/// Floating, icon-only bottom navigation matching the reference design: a
/// rounded pill detached from the screen edge, where the selected
/// destination renders as a filled circular button and the rest are plain
/// gray icons. No text labels — keeps 5+ destinations (the doctor side)
/// comfortably fitting without crowding.
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(kPillRadius),
            boxShadow: [
              BoxShadow(
                color: seedPurple.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavIcon(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.item, required this.selected, required this.onTap});

  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: selected ? 46 : 40,
        height: selected ? 46 : 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? scheme.primary : Colors.transparent,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          selected ? (item.selectedIcon ?? item.icon) : item.icon,
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: selected ? 22 : 24,
        ),
      ),
    );
  }
}
