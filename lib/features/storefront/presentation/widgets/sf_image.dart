import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter
import 'sf_image_web.dart' if (dart.library.io) 'sf_image_stub.dart';

/// Renders images using native HTML <img> on web (avoids Flutter CORS issues),
/// and Image.network on native platforms.
class SfImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit  fit;
  final Widget? fallback;

  const SfImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final src = url;
    if (src == null || src.isEmpty) {
      return fallback ?? _box(null);
    }

    if (kIsWeb) {
      return SizedBox(
        width: width,
        height: height,
        child: buildWebImage(src, fit),
      );
    }

    return Image.network(
      src,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback ?? _box(null),
    );
  }

  Widget _box(Color? color) => SizedBox(
    width: width,
    height: height,
    child: ColoredBox(color: color ?? Colors.transparent),
  );
}
