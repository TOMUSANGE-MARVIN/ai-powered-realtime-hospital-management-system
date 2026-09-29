import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/doctor.dart';

const iconForKey = <String, IconData>{
  'internal_medicine': Icons.medical_services,
  'pediatrics': Icons.child_care,
  'orthopedics': Icons.accessibility_new,
  'cardiology': Icons.favorite,
  'obstetrics_gynecology': Icons.pregnant_woman,
  'emergency_medicine': Icons.emergency,
  'neurology': Icons.psychology,
  'dermatology': Icons.face,
  'general': Icons.local_hospital,
};

/// A colored category chip — used on the home dashboard's horizontal
/// scroller and the "All Categories" grid. Tapping opens the search screen
/// pre-filtered to this specialty (the "doctors in that category" screen).
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    this.count = 0,
    this.width = 86,
    this.showCount = false,
    this.tinted = false,
  });

  final Category category;
  final int count;
  final double width;
  final bool showCount;

  /// Home-dashboard style: pastel-tinted card, larger icon, doctor count.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final accent = accentForColorKey(category.colorKey);
    if (tinted) return _buildTinted(context, accent);
    return SoftCard(
      onTap: () => context.push('/search', extra: category.name),
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(kCardRadius),
      borderSide: BorderSide(
        color: accent.foreground.withValues(alpha: 0.2),
        width: 1.2,
      ),
      showShadow: false,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconForKey[category.iconKey] ?? Icons.local_hospital,
                color: accent.foreground,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (showCount)
              Text(
                '$count doctor${count == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTinted(BuildContext context, SpecialtyAccent accent) {
    return SoftCard(
      onTap: () => context.push('/search', extra: category.name),
      color: accent.background.withValues(alpha: 0.45),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      borderRadius: BorderRadius.circular(kCardRadius),
      borderSide: BorderSide(color: accent.foreground.withValues(alpha: 0.18)),
      showShadow: false,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconForKey[category.iconKey] ?? Icons.local_hospital,
                color: accent.foreground,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkTealBackground,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$count doctor${count == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7A7A)),
            ),
          ],
        ),
      ),
    );
  }
}
