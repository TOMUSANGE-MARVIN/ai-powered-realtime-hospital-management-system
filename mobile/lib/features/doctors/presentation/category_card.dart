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
    // Home cards all use the brand teal for a consistent look.
    if (tinted) return _buildTinted(context, brandAccent);
    return SoftCard(
      onTap: () => context.push('/search', extra: category.name),
      color: context.palette.card,
      padding: const EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(kCardRadius),
      borderSide: BorderSide(
        color: accent.foreground.withValues(alpha: 0.2),
        width: 1.2,
      ),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.backgroundOf(context),
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
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.palette.ink,
              ),
            ),
            if (showCount)
              Text(
                '$count doctor${count == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 10, color: context.palette.muted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTinted(BuildContext context, SpecialtyAccent accent) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (blurb, blurbIcon) =
        _blurbForKey[category.iconKey] ??
        ('Find the right doctor', Icons.healing_rounded);
    final surface = dark
        ? accent.foreground.withValues(alpha: 0.12)
        : Color.alphaBlend(
            accent.background.withValues(alpha: 0.6),
            Colors.white,
          );
    return Semantics(
      button: true,
      label: '${category.name}, $count doctor${count == 1 ? '' : 's'}. $blurb',
      excludeSemantics: true,
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCardRadius),
          side: BorderSide(color: accent.foreground.withValues(alpha: 0.16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/search', extra: category.name),
          child: SizedBox(
            width: width,
            child: Stack(
              children: [
                // Soft wave (Gemini-generated mask) tinted per category.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/specialties/wave.webp',
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    color: accent.foreground.withValues(
                      alpha: dark ? 0.10 : 0.09,
                    ),
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconBubble(
                            icon:
                                iconForKey[category.iconKey] ??
                                Icons.local_hospital,
                            accent: accent,
                          ),
                          const Spacer(),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: accent.foreground.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: dark
                                  ? accent.foreground
                                  : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$count doctor${count == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.foreground.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(kCardRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(blurbIcon, size: 14, color: accent.foreground),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                blurb,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                  color: accent.foreground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What each specialty covers, in plain words, for the chip on home cards.
const _blurbForKey = <String, (String, IconData)>{
  'internal_medicine': (
    'Adult & chronic care',
    Icons.medical_information_rounded,
  ),
  'pediatrics': ('Babies & children', Icons.child_friendly_rounded),
  'orthopedics': ('Bones, joints & muscles', Icons.directions_walk_rounded),
  'cardiology': ('Heart & blood vessels', Icons.monitor_heart_rounded),
  'obstetrics_gynecology': ("Women's health", Icons.female_rounded),
  'emergency_medicine': ('Urgent & critical care', Icons.bolt_rounded),
  'neurology': ('Brain & nerves', Icons.psychology_alt_rounded),
  'dermatology': ('Skin, hair & nails', Icons.spa_rounded),
  'general': ('Everyday health', Icons.healing_rounded),
};

/// Large pastel circle holding the specialty icon, with a few small dots
/// around it for texture.
class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.accent});

  final IconData icon;
  final SpecialtyAccent accent;

  @override
  Widget build(BuildContext context) {
    Widget dot(double size, double alpha) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.foreground.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
    return SizedBox(
      width: 72,
      height: 68,
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 4,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accent.foreground.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent.foreground, size: 30),
            ),
          ),
          Positioned(left: 0, bottom: 10, child: dot(7, 0.22)),
          Positioned(right: 0, top: 6, child: dot(6, 0.25)),
          Positioned(left: 14, top: 0, child: dot(4, 0.2)),
        ],
      ),
    );
  }
}
