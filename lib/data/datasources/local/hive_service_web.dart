/// Hive Service for Web platform
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/storage_keys.dart';

/// Hive Service for web platform
/// Uses IndexedDB (through hive_flutter) for storage
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Web: Initialize Hive without path (uses IndexedDB)
    await Hive.initFlutter();

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

  /// Clears all Hive storage
  /// For web, this just clears all boxes since we can't delete IndexedDB directly
  Future<void> clearStorage() async {
    await clearAll();
  }

  Future<void> clearAll() async {
    await Hive.box(StorageKeys.userDataBox).clear();
    await Hive.box(StorageKeys.questionBankBox).clear();
    await Hive.box(StorageKeys.appConfigBox).clear();
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
