/// Hive Service for IO platforms (Android, iOS, Windows, macOS, Linux)
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/storage_keys.dart';

/// Hive Service for mobile/desktop platforms
/// Uses file system storage
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _isInitialized = false;
  Directory? _hiveDir;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory('${appDocDir.path}/trainingpass_hive');
    _hiveDir = hiveDir;

    // Create the directory if it doesn't exist
    if (!await hiveDir.exists()) {
      await hiveDir.create(recursive: true);
    }

    await Hive.initFlutter(hiveDir.path);

    // Note: Questions are stored as JSON maps, no adapters needed

    await Future.wait([
      Hive.openBox(StorageKeys.userDataBox),
      Hive.openBox(StorageKeys.questionBankBox),
      Hive.openBox(StorageKeys.appConfigBox),
    ]);

    _isInitialized = true;
  }

  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }

  Future<void> clearAll() async {
    await Hive.box(StorageKeys.userDataBox).clear();
    await Hive.box(StorageKeys.questionBankBox).clear();
    await Hive.box(StorageKeys.appConfigBox).clear();
  }

  /// Deletes the entire Hive storage directory from filesystem
  /// Use this when migrating data formats or clearing all data
  Future<void> clearStorage() async {
    await close();
    if (_hiveDir != null && await _hiveDir!.exists()) {
      await _hiveDir!.delete(recursive: true);
      _hiveDir = null;
    }
  }

  Box get userDataBox => Hive.box(StorageKeys.userDataBox);
  Box get questionBankBox => Hive.box(StorageKeys.questionBankBox);
  Box get appConfigBox => Hive.box(StorageKeys.appConfigBox);

  T? getUserData<T>(String key) {
    return userDataBox.get(key);
  }

  Future<void> putUserData<T>(String key, T value) async {
    await userDataBox.put(key, value);
  }

  Future<void> deleteUserData(String key) async {
    await userDataBox.delete(key);
  }

  T? getQuestionBankData<T>(String key) {
    return questionBankBox.get(key);
  }

  Future<void> putQuestionBankData<T>(String key, T value) async {
    await questionBankBox.put(key, value);
  }

  T? getAppConfigData<T>(String key) {
    return appConfigBox.get(key);
  }

  Future<void> putAppConfigData<T>(String key, T value) async {
    await appConfigBox.put(key, value);
  }
}
