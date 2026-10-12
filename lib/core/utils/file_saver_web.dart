// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;

Future<String?> saveExportFile(List<int> bytes, String filename) async {
  if (bytes.isEmpty) return null;
  try {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final blob = html.Blob([data]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    return filename;
  } catch (e) {
    debugPrint('[Export] Web download failed: $e');
    return null;
  }
}
