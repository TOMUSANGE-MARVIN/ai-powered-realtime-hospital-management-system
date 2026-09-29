import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The "What did the doctor help you?" answers on a review, as small tags.
class ReviewHelpTags extends StatelessWidget {
  const ReviewHelpTags({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: seedTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(kPillRadius),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: seedTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
