import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Renders the legal documents' plain format: "## " headings, "- " bullet
/// points and blank-line-separated paragraphs (the same format admins edit
/// on the web).
class LegalText extends StatelessWidget {
  const LegalText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(
      fontSize: 14.5,
      height: 1.5,
      color: context.palette.ink,
    );
    final blocks = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      if (line.startsWith('## ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 6),
            child: Text(
              line.substring(3),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.palette.ink,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, right: 10),
                  child: Icon(Icons.circle, size: 5, color: seedTeal),
                ),
                Expanded(child: Text(line.substring(2), style: body)),
              ],
            ),
          ),
        );
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(line, style: body),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }
}

/// "Last updated 1 Oct 2026" under a document title.
class LegalUpdatedLine extends StatelessWidget {
  const LegalUpdatedLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: context.palette.muted, fontSize: 12.5),
  );
}
