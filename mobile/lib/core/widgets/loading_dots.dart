import 'package:flutter/material.dart';

/// The app's in-progress indicator for actions — a button that's submitting,
/// an upload, a voice note fetching. Three softly pulsing dots instead of a
/// spinner; content that's loading uses skeletons (see skeleton.dart).
///
/// Takes the surrounding icon/text color by default, so it reads correctly
/// on filled (white) and outlined (teal) buttons alike.
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key, this.color, this.size = 7});

  final Color? color;

  /// Diameter of each dot.
  final double size;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ??
        IconTheme.of(context).color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.primary;

    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: widget.size * 0.6),
              Opacity(
                opacity: _opacityFor(i),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Each dot peaks a third of a cycle after the previous one.
  double _opacityFor(int index) {
    final phase = (_controller.value - index / 3) % 1.0;
    final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.3 + 0.7 * wave;
  }
}
