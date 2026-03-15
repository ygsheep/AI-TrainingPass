import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'core/utils/app_logger.dart';
import 'data/datasources/local/hive_service.dart';
import 'data/services/question_initialization.dart';
import 'presentation/providers/config_provider.dart';
import 'presentation/providers/question_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.debug('🚀 Starting TrainingPass...');

  // Initialize Hive with error handling for old data format
  final hiveService = HiveService();
  try {
    await hiveService.initialize();
  } on HiveError catch (e) {
    // If we get a typeId error, clear old data from filesystem and retry
    if (e.message.contains('typeId')) {
      AppLogger.debug('Old data format detected, clearing storage...');
      await hiveService.clearStorage();
      await hiveService.initialize();
    } else {
      rethrow;
    }
  }

  // Ensure question bank is initialized BEFORE starting the app
  // This prevents race conditions between Hive write and Provider read
  final initSuccess = await QuestionInitialization.ensureInitialized();
  if (!initSuccess) {
    AppLogger.debug('⚠️ Warning: Question initialization may have issues');
  }

  AppLogger.debug('✅ Initialization complete, starting app...');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Pre-load settings and questions to avoid loading on first page access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userSettingsProvider.notifier).loadSettings();
      ref.read(questionBankProvider.notifier).loadQuestionBank();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(userSettingsProvider);
    final settings = settingsState.settings;

    // Determine theme mode from settings
    ThemeMode themeMode;
    if (settings != null) {
      switch (settings.themeMode) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          themeMode = ThemeMode.system;
          break;
      }
    } else {
      themeMode = ThemeMode.system;
    }

    // Get text size scale
    final textSize = settings?.textSize ?? 1;
    final double textScaleFactor;
    switch (textSize) {
      case 0:
        textScaleFactor = 0.9;  // Small
        break;
      case 2:
        textScaleFactor = 1.1;  // Large
        break;
      case 1:
      default:
        textScaleFactor = 1.0;  // Medium (default)
        break;
    }

    return MaterialApp.router(
      title: 'TrainingPass',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Text scale factor for font size
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child!,
        );
      },

      // Router
      routerConfig: AppRouter.router,
    );
  }
}
