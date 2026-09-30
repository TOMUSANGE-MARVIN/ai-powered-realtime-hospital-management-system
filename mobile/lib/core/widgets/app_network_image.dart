import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'skeleton.dart';

/// Image provider for any remote picture (profile photos, avatars): cached
/// on disk, so it still shows offline once it has been seen.
ImageProvider appNetworkImageProvider(String url) =>
    CachedNetworkImageProvider(url);

/// The app's one way to show a remote image: disk-cached for offline use,
/// with a skeleton while it loads and a quiet placeholder if it can't.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.error,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Shown when the image can't be loaded (offline and never cached, or a
  /// broken link). Defaults to a broken-image icon.
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, _) => SkeletonBox(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        borderRadius: 0,
      ),
      errorWidget: (context, _, _) =>
          error ??
          SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, size: 32),
            ),
          ),
    );
  }
}
