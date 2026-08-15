import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'skeleton.dart';

/// Gates a dashboard-style screen (several independent providers feeding
/// different sections) behind a single loading state, so the whole screen
/// appears at once instead of each section popping in with its own spinner
/// as its data happens to arrive.
///
/// Only the *first* load blocks on every provider in [values] — once each
/// has produced at least one value (including a cached one), the screen
/// renders immediately even if a background refresh is in flight, so pull-
/// to-refresh doesn't re-hide already-visible content behind a spinner.
class DashboardGate extends StatelessWidget {
  const DashboardGate({
    super.key,
    required this.values,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final List<AsyncValue<Object?>> values;
  final WidgetBuilder builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Skeleton shown while [values] are still loading. Defaults to a generic
  /// list skeleton; pass a screen-shaped skeleton for a closer match to the
  /// real layout underneath.
  final WidgetBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    // hasValue/hasError is true even while a subsequent refresh is loading,
    // so this only blocks on the very first fetch of each provider.
    final stillLoading = values.any((v) => v.isLoading && !v.hasValue && !v.hasError);
    if (stillLoading) {
      return loadingBuilder?.call(context) ?? const SkeletonList();
    }
    final firstError = values.where((v) => v.hasError && !v.hasValue).firstOrNull;
    if (firstError != null && errorBuilder != null) {
      return errorBuilder!(context, firstError.error!);
    }
    return builder(context);
  }
}
