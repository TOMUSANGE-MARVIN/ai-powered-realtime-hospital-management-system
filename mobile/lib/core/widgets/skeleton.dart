import 'package:flutter/material.dart';

/// A gently shimmering gray placeholder box — the building block for screen
/// skeletons. Shape it (via `width`/`height`/`borderRadius`) to roughly
/// match the real content it's standing in for, so the loading state reads
/// as "this page is here, filling in" instead of a generic spinner.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 8,
  });

  /// A circular skeleton (for avatars) — `size` sets both width and height.
  const SkeletonBox.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = size / 2;

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, base.withValues(alpha: 0.4), _controller.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// A single skeleton list row: circular avatar + two lines of text, matching
/// the common `ListTile`-shaped rows used across the app's list screens
/// (doctors, chats, calls, appointments, reviews).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SkeletonBox.circle(size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: MediaQuery.sizeOf(context).width * 0.4),
                const SizedBox(height: 8),
                SkeletonBox(width: MediaQuery.sizeOf(context).width * 0.6, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertical stack of [count] [SkeletonListTile]s — the standard "loading
/// list" placeholder for chat/appointment/doctor/review/call screens.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => const SkeletonListTile(),
    );
  }
}

/// A generic form-shaped skeleton — a header block (e.g. an avatar/title
/// row) followed by a handful of field-shaped bars — for screens whose
/// initial load blocks a form rather than a list (e.g. booking, prefilled
/// edit screens).
class SkeletonForm extends StatelessWidget {
  const SkeletonForm({super.key, this.fieldCount = 4});

  final int fieldCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            const SkeletonBox.circle(size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: MediaQuery.sizeOf(context).width * 0.4),
                  const SizedBox(height: 8),
                  SkeletonBox(width: MediaQuery.sizeOf(context).width * 0.3, height: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        ...List.generate(
          fieldCount,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonBox(width: double.infinity, height: 52, borderRadius: 12),
          ),
        ),
      ],
    );
  }
}

/// A vertical stack of tall rounded-card placeholders, standing in for
/// `Card`-based rows (appointments, reviews, prescriptions) that are too
/// tall/detailed for a plain [SkeletonListTile].
///
/// A bare [Column] with no padding/scrolling of its own, so it composes
/// cleanly both as a full-screen `loading:` builder (wrap in `Padding` and
/// let the screen's own scaffold handle scrolling) and nested inside
/// another scrollable alongside other skeleton blocks.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key, this.count = 4, this.cardHeight = 96});

  final int count;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          SkeletonBox(width: double.infinity, height: cardHeight, borderRadius: 14),
        ],
      ],
    );
  }
}

/// A grid of square-ish rounded placeholders, standing in for card grids
/// (e.g. the categories browser) while they load.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.crossAxisCount = 3, this.itemCount = 9});

  final int crossAxisCount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          const SkeletonBox(width: double.infinity, height: double.infinity, borderRadius: 16),
    );
  }
}

/// A skeleton for a chat conversation — alternating left/right rounded
/// bubbles of varying width, standing in for message history while it
/// loads.
class SkeletonChat extends StatelessWidget {
  const SkeletonChat({super.key});

  static const _widths = [0.55, 0.4, 0.65, 0.35, 0.5];

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _widths.length,
      itemBuilder: (context, index) {
        final fromMe = index.isOdd;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Align(
            alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
            child: SkeletonBox(
              width: maxWidth * _widths[index],
              height: 36,
              borderRadius: 16,
            ),
          ),
        );
      },
    );
  }
}
