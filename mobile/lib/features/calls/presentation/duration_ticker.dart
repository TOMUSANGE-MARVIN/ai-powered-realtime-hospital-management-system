import 'dart:async';

import 'package:flutter/material.dart';

/// Live "mm:ss" elapsed-time label, ticking once a second — shared by
/// [InCallScreen] and [MinimizedCallCard] so there's one timer
/// implementation instead of two.
class DurationTicker extends StatefulWidget {
  const DurationTicker({super.key, required this.connectedAt, this.style});

  final DateTime connectedAt;
  final TextStyle? style;

  @override
  State<DurationTicker> createState() => _DurationTickerState();
}

class _DurationTickerState extends State<DurationTicker> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.connectedAt);
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
      style: widget.style ?? const TextStyle(color: Colors.white70, fontSize: 15),
    );
  }
}
