/// Download Utility for Web Platform
import 'dart:html' as html;

/// Download a string as a file on web platform
Future<void> downloadString(String content, String filename) async {
  final blob = html.Blob([content], 'application/json');
  final url = html.Url.createObjectUrl(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}
