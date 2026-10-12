import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class AppNetworkImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Color fallbackColor;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.fallbackColor = const Color(0xFFE5E7EB),
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageWebState();
}

class _AppNetworkImageWebState extends State<AppNetworkImage> {
  static int _seq = 0;

  late final String _viewType;

  static String _fitCss(BoxFit fit) {
    if (fit == BoxFit.cover) return 'cover';
    if (fit == BoxFit.contain) return 'contain';
    if (fit == BoxFit.fill) return 'fill';
    if (fit == BoxFit.none) return 'none';
    if (fit == BoxFit.scaleDown) return 'scale-down';
    return 'contain';
  }

  static String _colorToCss(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return 'rgb($r,$g,$b)';
  }

  @override
  void initState() {
    super.initState();
    _viewType = 'ani-${_seq++}';

    final url = widget.url;
    final fitCss = _fitCss(widget.fit);
    final br = widget.borderRadius;
    final bg = _colorToCss(widget.fallbackColor);

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int id) {
      final container = web.document.createElement('div') as web.HTMLDivElement
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = bg
        ..style.borderRadius = br > 0 ? '${br}px' : '0';

      final img = web.document.createElement('img') as web.HTMLImageElement
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = fitCss
        ..style.display = 'block';

      img.addEventListener(
        'error',
        ((web.Event _) => img.style.display = 'none').toJS,
      );

      container.appendChild(img);
      return container;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
