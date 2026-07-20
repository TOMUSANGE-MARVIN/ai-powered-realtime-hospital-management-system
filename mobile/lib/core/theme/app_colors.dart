import 'package:flutter/material.dart';

/// Shared visual constants for the teal brand design language, derived from
/// the Ask Musawo logo (assets/images/illustrations/ask-musawo-logo.svg).
const kCardRadius = 22.0;
const kPillRadius = 999.0;

const seedTeal = Color(0xFF128A8B);
const tealBackground = Color(0xFFF2FAFA);
const darkTealBackground = Color(0xFF102828);

/// The brand's coral→teal diagonal hero gradient.
const heroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF47C7B), Color(0xFF128A8B)],
);

class SpecialtyAccent {
  const SpecialtyAccent(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

const _specialtyAccents = <String, SpecialtyAccent>{
  'Internal Medicine': SpecialtyAccent(Color(0xFFE3F2FD), Color(0xFF2196F3)),
  'Pediatrics': SpecialtyAccent(Color(0xFFE0F7F4), Color(0xFF12B8A6)),
  'Orthopedic Surgery': SpecialtyAccent(Color(0xFFFFF3E0), Color(0xFFFF9800)),
  'Cardiology': SpecialtyAccent(Color(0xFFFDE3EC), Color(0xFFE91E63)),
  'Obstetrics & Gynecology': SpecialtyAccent(Color(0xFFF3E5FF), Color(0xFF9C27B0)),
  'Emergency Medicine': SpecialtyAccent(Color(0xFFFFE3E3), Color(0xFFF44336)),
};

const _defaultAccent = SpecialtyAccent(Color(0xFFE0F2F2), seedTeal);

/// Distinct pastel-background/vivid-icon color pair per specialty, matching
/// the reference design's colorful category chips. Falls back to a neutral
/// teal tint for any specialty not in the seeded set.
SpecialtyAccent specialtyAccent(String? specialty) {
  if (specialty == null) return _defaultAccent;
  return _specialtyAccents[specialty] ?? _defaultAccent;
}

const _colorAccents = <String, SpecialtyAccent>{
  'blue': SpecialtyAccent(Color(0xFFE3F2FD), Color(0xFF2196F3)),
  'teal': SpecialtyAccent(Color(0xFFE0F7F4), Color(0xFF12B8A6)),
  'orange': SpecialtyAccent(Color(0xFFFFF3E0), Color(0xFFFF9800)),
  'pink': SpecialtyAccent(Color(0xFFFDE3EC), Color(0xFFE91E63)),
  'purple': SpecialtyAccent(Color(0xFFF3E5FF), Color(0xFF9C27B0)),
  'red': SpecialtyAccent(Color(0xFFFFE3E3), Color(0xFFF44336)),
  'indigo': SpecialtyAccent(Color(0xFFE8EAF6), Color(0xFF3F51B5)),
  'amber': SpecialtyAccent(Color(0xFFFFF8E1), Color(0xFFFFA000)),
  'lavender': _defaultAccent,
};

/// Same background/foreground pastel-pair concept as [specialtyAccent], but
/// keyed by an admin-picked `colorKey` (see [Category]) instead of a
/// specialty name string — used for admin-managed categories.
SpecialtyAccent accentForColorKey(String? colorKey) {
  if (colorKey == null) return _defaultAccent;
  return _colorAccents[colorKey] ?? _defaultAccent;
}
