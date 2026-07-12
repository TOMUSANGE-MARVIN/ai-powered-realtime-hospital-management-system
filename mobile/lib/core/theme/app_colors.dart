import 'package:flutter/material.dart';

/// Shared visual constants for the purple/lavender design language.
const kCardRadius = 22.0;
const kPillRadius = 999.0;

const seedPurple = Color(0xFF6C5DD3);
const lavenderBackground = Color(0xFFF4F2FC);
const darkPurpleBackground = Color(0xFF1A1730);

/// The reference design's signature pink→purple diagonal hero gradient.
const heroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFF8FB1), Color(0xFF6C5DD3)],
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

const _defaultAccent = SpecialtyAccent(Color(0xFFEDEBFA), seedPurple);

/// Distinct pastel-background/vivid-icon color pair per specialty, matching
/// the reference design's colorful category chips. Falls back to a neutral
/// lavender for any specialty not in the seeded set.
SpecialtyAccent specialtyAccent(String? specialty) {
  if (specialty == null) return _defaultAccent;
  return _specialtyAccents[specialty] ?? _defaultAccent;
}
