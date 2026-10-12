import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final _registered = <String>{};

Widget buildWebImage(String url, BoxFit fit) {
  final viewId = 'sf-img-${url.hashCode}';

  if (!_registered.contains(viewId)) {
    _registered.add(viewId);
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final img = web.document.createElement('img') as web.HTMLImageElement;
      img.src = url;
      img.style.width = '100%';
      img.style.height = '100%';
      img.style.objectFit = switch (fit) {
        BoxFit.contain  => 'contain',
        BoxFit.fill     => 'fill',
        BoxFit.fitWidth => 'scale-down',
        _               => 'cover',
      };
      img.style.display = 'block';
      return img;
    });
  }

  return HtmlElementView(viewType: viewId);
}
