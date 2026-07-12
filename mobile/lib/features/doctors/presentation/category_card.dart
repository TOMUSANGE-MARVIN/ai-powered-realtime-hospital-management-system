import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/doctor.dart';

const categoryIcons = <String, IconData>{
  'Internal Medicine': Icons.medical_services,
  'Pediatrics': Icons.child_care,
  'Orthopedic Surgery': Icons.accessibility_new,
  'Cardiology': Icons.favorite,
  'Obstetrics & Gynecology': Icons.pregnant_woman,
  'Emergency Medicine': Icons.emergency,
};

/// A colored category chip — used on the home dashboard's horizontal
/// scroller and the "All Categories" grid. Tapping opens the search screen
/// pre-filtered to this specialty (the "doctors in that category" screen).
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.specialty,
    this.width = 86,
    this.showCount = false,
  });

  final Specialty specialty;
  final double width;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final accent = specialtyAccent(specialty.name);
    return SoftCard(
      onTap: () => context.push('/search', extra: specialty.name),
      color: accent.background,
      padding: const EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: accent.foreground.withValues(alpha: 0.35), width: 1.2),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(
                categoryIcons[specialty.name] ?? Icons.local_hospital,
                color: accent.foreground,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              specialty.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: accent.foreground,
              ),
            ),
            if (showCount)
              Text(
                '${specialty.count} doctor${specialty.count == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 10, color: accent.foreground.withValues(alpha: 0.8)),
              ),
          ],
        ),
      ),
    );
  }
}
