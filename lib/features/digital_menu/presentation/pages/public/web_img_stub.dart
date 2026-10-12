import 'package:flutter/widgets.dart';

Widget buildWebImg(String url, BoxFit fit, Widget? fallback) => Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
    );
