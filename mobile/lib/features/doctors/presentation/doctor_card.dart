import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Maps a doctor's specialization/department text to a representative icon
/// for the small badge on their card. Best-effort keyword match against real
/// doctor data — falls back to a generic medical icon rather than inventing
/// a specialty.
IconData iconForSpecialization(String? specialization, String? department) {
  final text = (specialization ?? department ?? '').toLowerCase();
  if (text.contains('cardio')) return Icons.favorite_rounded;
  if (text.contains('pediatric') || text.contains('paediatric')) {
    return Icons.child_care_rounded;
  }
  if (text.contains('orthop')) return Icons.accessibility_new_rounded;
  if (text.contains('obstetric') || text.contains('gynec') || text.contains('gynaec')) {
    return Icons.pregnant_woman_rounded;
  }
  if (text.contains('emergency')) return Icons.emergency_rounded;
  if (text.contains('neuro')) return Icons.psychology_rounded;
  if (text.contains('derma')) return Icons.face_retouching_natural_rounded;
  if (text.contains('dental') || text.contains('dentist')) {
    return Icons.sentiment_satisfied_alt_rounded;
  }
  if (text.contains('internal medicine') || text.contains('general')) {
    return Icons.monitor_heart_rounded;
  }
  return Icons.local_hospital_rounded;
}

/// Renders a doctor's uploaded profile photo, or a neutral initials avatar
/// when no image has been set (or it fails to load) — never a stock photo.
class DoctorImage extends StatelessWidget {
  const DoctorImage({super.key, required this.url, required this.name});

  final String? url;
  final String name;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: seedTeal.withValues(alpha: 0.08),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: seedTeal),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: seedTeal.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: seedTeal,
        ),
      ),
    );
  }
}
