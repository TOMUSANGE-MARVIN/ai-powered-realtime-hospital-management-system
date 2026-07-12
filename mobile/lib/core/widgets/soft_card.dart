import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A rounded, softly-shadowed container matching the app's card language —
/// use in place of raw `Container` + `BoxDecoration` so ad hoc surfaces
/// (category chips, stat tiles, promo banners) look consistent with the
/// centrally-themed `Card` used everywhere else.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius,
    this.borderSide,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(kCardRadius);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: seedPurple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: color ?? scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: radius, side: borderSide ?? BorderSide.none),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
