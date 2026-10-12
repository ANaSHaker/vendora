import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

Widget buildWebImg(String url, BoxFit fit, Widget? fallback) {
  final objectFit =
      fit == BoxFit.contain ? 'contain' : fit == BoxFit.fill ? 'fill' : 'cover';
  return HtmlElementView.fromTagName(
    tagName: 'img',
    onElementCreated: (element) {
      final img = element as web.HTMLImageElement;
      img.src = url;
      img.style.width = '100%';
      img.style.height = '100%';
      img.style.objectFit = objectFit;
      img.style.display = 'block';
    },
  );
}
