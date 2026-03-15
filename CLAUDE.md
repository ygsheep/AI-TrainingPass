# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TrainingPass is a Flutter quiz/exam application supporting mobile (Android/iOS), desktop (Windows/macOS/Linux), and web platforms. It implements Clean Architecture with Riverpod state management, featuring question banks, practice modes, timed exams, and wrong question tracking.

## Essential Commands

### Code Generation (Required after model changes)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running the App
```bash
# Web
flutter run -d chrome --web-port=8080

# Mobile (requires connected device/emulator)
flutter run

# Desktop
flutter run -d windows    # or macos, linux
```

### Building
```bash
flutter build web
flutter build apk
flutter build windows
```

### Linting and Analysis
```bash
flutter analyze
dart format .
```

## Architecture

### Clean Architecture Layers

```
lib/
├── main.dart              # App entry point, Hive & question initialization
├── app/                   # Router configuration, app theme
├── core/                  # Shared utilities (theme, colors, constants, breakpoints)
├── domain/                # Business logic (entities, use cases, repository interfaces)
├── data/                  # Data layer (models, repositories, datasources)
└── presentation/          # UI layer (pages, widgets, providers)
```

**Data Flow:** UI → Riverpod Providers → Use Cases → Repository → DataSource → Hive Storage

### Platform-Specific Implementations

The app uses conditional exports for platform differences:

- **File Service**: `file_service_io.dart` (mobile/desktop) vs `file_service_web.dart` (web)
- **Hive Service**: `hive_service_io.dart` vs `hive_service_web.dart`
- Conditional import pattern: `export 'default.dart' if (dart.library.io) 'io_implementation.dart'`

**Web Compatibility Notes:**
- No `path_provider` on web - use platform-specific implementations
- Hive uses IndexedDB on web
- When adding file operations, always add platform-specific variants

### State Management with Riverpod

**Code Generation Required:** All providers use `@riverpod` annotations and require `build_runner` to generate.

**Key Providers:**
- `questionBankProvider` - Question bank state and loading
- `activeExamProvider` - Active exam session management
- `examHistoryProvider` - Exam history records
- `wrongBookProvider` - Wrong question tracking
- `userSettingsProvider` - User preferences (theme, font size)
- `appConfigProvider` - App configuration

**Critical Pattern:** Never call loading methods (like `loadQuestionBank()`) in `build()` methods - this causes circular dependency errors. Use `WidgetsBinding.instance.addPostFrameCallback()` instead.

```dart
// WRONG - causes circular dependency
@override
SomeState build() {
  ref.watch(provider);
  ref.read(provider.notifier).loadData(); // ❌
  return state;
}

// CORRECT
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(provider.notifier).loadData(); // ✅
  });
}
```

### Repository Pattern

Repositories abstract data access:
- `QuestionRepositoryBase` (interface) in `domain/repositories/`
- `QuestionRepositoryImpl` in `data/repositories/`
- Datasources handle actual storage (Hive)

### Entity vs Model Separation

- **Entities** (`domain/entities/`): Pure business objects without serialization logic
- **Models** (`data/models/`): Data objects with JSON serialization (`@JsonSerializable`), Hive adapters

When adding new data:
1. Create entity in `domain/entities/`
2. Create model in `data/models/` with `@JsonSerializable()`
3. Add repository method in both interface and implementation
4. Create datasource method
5. Run `dart run build_runner build`

### Navigation (GoRouter)

**Shell Route Structure:** Bottom navigation persists across main routes:
```dart
/              → HomePage
/practice      → PracticePage
/exam          → ExamPage
/wrong-book    → WrongBookPage
/settings      → SettingsPage
```

**Full Screen Routes:** No bottom navigation
```dart
/exam-setup    → ExamSetupPage (modal)
```

**Router Caching:** `AppRouter.router` is cached to prevent GlobalKey conflicts. Always use `AppRouter.router` (getter) rather than creating new instances.

### Hive Storage

**Important Notes:**
- Questions stored as JSON maps, NOT using Hive adapters
- `QuestionOption` has NO `@HiveType` annotation - pure JSON serialization
- Use `@JsonSerializable(explicitToJson: true)` for nested objects
- Box keys defined in `core/constants/storage_keys.dart`

**Migration:** If Hive throws `typeId` errors, old data format exists. The app handles this in `main.dart` by catching the error and clearing storage.

### Theme System

Material 3-based with custom Swiss Modernism design:
- Light/dark theme support
- User settings control theme mode and text scale factor
- Theme applied dynamically in `MyApp.build()` based on `userSettingsProvider`
- All tokens in `core/theme/`

### Responsive Design

Breakpoints in `core/constants/breakpoints.dart`:
- Mobile: < 600px
- Tablet: 600-1200px
- Desktop: > 1200px

Use `LayoutBuilder` or `MediaQuery` to adapt layouts.

## Common Patterns

### Adding a New Question Type
1. Update `QuestionModel` type field in `data/models/question.dart`
2. Add handling in `question_card.dart` UI
3. Update answer validation logic in `submit_answer.dart` use case
4. Run code generation

### Adding Settings
1. Add field to `UserSettings` in `data/models/user_settings.dart`
2. Update persistence in `ConfigRepositoryImpl`
3. Add UI control in `settings_page.dart`
4. Run code generation

### Platform-Specific Code
```dart
// In file_service.dart
export 'default.dart' if (dart.library.io) 'io_implementation.dart'
                                    if (dart.library.html) 'web_implementation.dart';
```

## Known Issues & Solutions

### Hive Adapter Errors
- **Error:** "Cannot write, unknown type: QuestionOption"
- **Cause:** Trying to store objects with Hive adapters instead of JSON
- **Solution:** Ensure `QuestionOption` has NO Hive annotations, use `@JsonSerializable(explicitToJson: true)` on parent model

### Provider Circular Dependencies
- **Error:** "Bad state: Tried to read the state of an uninitialized provider"
- **Cause:** Calling load methods in `build()`
- **Solution:** Use `WidgetsBinding.instance.addPostFrameCallback()` in `initState()` or first build

### Type Casting Errors with Hive
- **Error:** "LinkedMap<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>'"
- **Solution:** Use `Map<String, dynamic>.from(data)` instead of `as Map<String, dynamic>`

### Time Formatting on Web
- **Error:** "Closure: (num) => JSNumber" in countdown display
- **Cause:** `remainder` property used incorrectly
- **Solution:** Use `.remainder(60)` not just `.remainder`

## Testing Question Bank

The app includes 756 questions loaded from `assets/data/questions.json` on first launch. To reload:
1. Clear browser storage (DevTools → Application → Clear all)
2. Or call `hiveService.clearAll()` programmatically
