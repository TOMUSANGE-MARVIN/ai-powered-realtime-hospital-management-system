import 'package:flutter/material.dart';

/// Shared visual constants for the teal brand design language, derived from
/// the Ask Musawo logo (assets/images/illustrations/ask-musawo-logo.svg).
/// Corner radius for every card, button, input, chip and pill — kept tight
/// on purpose; only avatars and icon badges are fully round.
const kCardRadius = 4.0;
const kPillRadius = kCardRadius;

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

  /// The light-mode pastel. Use [backgroundOf] in widgets so dark mode gets
  /// a deep tint of [foreground] instead of a glaring pastel.
  final Color background;
  final Color foreground;

  Color backgroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? foreground.withValues(alpha: 0.18)
      : background;
}

const _specialtyAccents = <String, SpecialtyAccent>{
  'Internal Medicine': SpecialtyAccent(Color(0xFFE3F2FD), Color(0xFF2196F3)),
  'Pediatrics': SpecialtyAccent(Color(0xFFE0F7F4), Color(0xFF12B8A6)),
  'Orthopedic Surgery': SpecialtyAccent(Color(0xFFFFF3E0), Color(0xFFFF9800)),
  'Cardiology': SpecialtyAccent(Color(0xFFFDE3EC), Color(0xFFE91E63)),
  'Obstetrics & Gynecology': SpecialtyAccent(
    Color(0xFFF3E5FF),
    Color(0xFF9C27B0),
  ),
  'Emergency Medicine': SpecialtyAccent(Color(0xFFFFE3E3), Color(0xFFF44336)),
};

const _defaultAccent = brandAccent;

/// The teal pastel/vivid pair used for home cards so they all share the
/// brand colour instead of per-category accents.
const brandAccent = SpecialtyAccent(Color(0xFFE0F2F2), seedTeal);

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

/// The app's named colours, with a light and a dark value for each, so
/// screens never hard-code a colour that only works in light mode. Read with
/// `context.palette` (see [PaletteContext]).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.page,
    required this.card,
    required this.ink,
    required this.muted,
    required this.border,
    required this.tint,
    required this.dangerTint,
    required this.dangerBorder,
    required this.warningTint,
    required this.skeleton,
    required this.navBar,
  });

  /// Page background behind cards.
  final Color page;

  /// Cards, sheets, bars, incoming chat bubbles, input fills.
  final Color card;

  /// Titles and primary text.
  final Color ink;

  /// Secondary text, captions, hints, inactive icons.
  final Color muted;

  /// Hairline borders and dividers.
  final Color border;

  /// Brand-tinted panel / icon circle (the pale teal in light mode).
  final Color tint;

  /// Red-tinted panel behind errors and destructive secondary actions.
  final Color dangerTint;
  final Color dangerBorder;

  /// Amber-tinted panel behind warnings.
  final Color warningTint;

  /// Placeholder grey for skeletons.
  final Color skeleton;

  /// Bottom navigation bar.
  final Color navBar;

  static const light = AppPalette(
    page: tealBackground,
    card: Colors.white,
    ink: darkTealBackground,
    muted: Color(0xFF6B7A7A),
    border: Color(0xFFDDE9E9),
    tint: Color(0xFFE0F2F2),
    dangerTint: Color(0xFFFFE9E9),
    dangerBorder: Color(0xFFF6C4C4),
    warningTint: Color(0xFFFFF8E1),
    skeleton: Color(0xFFE3ECEC),
    navBar: Colors.white,
  );

  static const dark = AppPalette(
    page: Color(0xFF0B1A1A),
    card: Color(0xFF142626),
    ink: Color(0xFFE4F1F1),
    muted: Color(0xFF9DB1B1),
    border: Color(0xFF2A4242),
    tint: Color(0xFF1B3A3A),
    dangerTint: Color(0xFF3A1D1D),
    dangerBorder: Color(0xFF6B2E2E),
    warningTint: Color(0xFF3A2F14),
    skeleton: Color(0xFF223838),
    navBar: Color(0xFF142626),
  );

  @override
  AppPalette copyWith({
    Color? page,
    Color? card,
    Color? ink,
    Color? muted,
    Color? border,
    Color? tint,
    Color? dangerTint,
    Color? dangerBorder,
    Color? warningTint,
    Color? skeleton,
    Color? navBar,
  }) => AppPalette(
    page: page ?? this.page,
    card: card ?? this.card,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    border: border ?? this.border,
    tint: tint ?? this.tint,
    dangerTint: dangerTint ?? this.dangerTint,
    dangerBorder: dangerBorder ?? this.dangerBorder,
    warningTint: warningTint ?? this.warningTint,
    skeleton: skeleton ?? this.skeleton,
    navBar: navBar ?? this.navBar,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      page: l(page, other.page),
      card: l(card, other.card),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      border: l(border, other.border),
      tint: l(tint, other.tint),
      dangerTint: l(dangerTint, other.dangerTint),
      dangerBorder: l(dangerBorder, other.dangerBorder),
      warningTint: l(warningTint, other.warningTint),
      skeleton: l(skeleton, other.skeleton),
      navBar: l(navBar, other.navBar),
    );
  }
}

extension PaletteContext on BuildContext {
  /// The current theme's [AppPalette] — `context.palette.ink` etc.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
