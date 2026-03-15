/// Download Utility for IO platforms (Android, iOS, Windows, macOS, Linux)
/// On IO platforms, files are saved to the app's documents directory

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Download a string as a file on IO platforms
Future<void> downloadString(String content, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = p.join(directory.path, filename);
  final file = File(filePath);
  await file.writeAsString(content);
}
