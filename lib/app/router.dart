import '../core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/practice/practice_page.dart';
import '../presentation/pages/practice/practice_swipe_page.dart';
import '../presentation/pages/practice/category_select_page.dart';
import '../presentation/pages/exam/exam_page.dart';
import '../presentation/pages/exam/exam_setup_page.dart';
import '../presentation/pages/wrong_book/wrong_book_page.dart';
import '../presentation/pages/wrong_book/wrong_question_detail_page.dart';
import '../presentation/pages/wrong_book/wrong_review_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/history/history_page.dart';
import '../presentation/pages/history/exam_detail_page.dart';
import '../presentation/pages/question_update/question_update_page.dart';
import '../presentation/widgets/navigation/bottom_nav_bar.dart';
import '../presentation/widgets/navigation/adaptive_navigation.dart';
import '../domain/entities/question_filter.dart';
import '../core/constants/app_config.dart';

/// Application Router Configuration
/// Uses go_router for declarative navigation
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter? _cachedRouter;

  static GoRouter get router {
    return _cachedRouter ??= _createRouter();
  }

  static GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      routes: [
        // Main shell route with bottom navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomePage(),
              ),
            ),
            GoRoute(
              path: '/practice',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PracticePage(),
              ),
            ),
            GoRoute(
              path: '/exam-setup',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ExamSetupPage(),
              ),
            ),
            GoRoute(
              path: '/wrong-book',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: WrongBookPage(),
              ),
            ),
            GoRoute(
              path: '/history',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HistoryPage(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
              ),
            ),
          ],
        ),

        // Full screen routes (without bottom nav)
        GoRoute(
          path: '/exam',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            // Get exam parameters from URL or use defaults
            final durationParam = state.uri.queryParameters['duration'];
            final questionsParam = state.uri.queryParameters['questions'];
            final passScoreParam = state.uri.queryParameters['passScore'];

            final duration = int.tryParse(durationParam ?? '') ??
                AppConfig.defaultExamDurationMinutes;
            final questionCount = int.tryParse(questionsParam ?? '') ??
                AppConfig.defaultExamQuestionCount;
            final passScore = int.tryParse(passScoreParam ?? '') ??
                AppConfig.defaultPassScore;

            // Debug logging
            AppLogger.debug('🔗 Router /exam: duration=$durationParam, questions=$questionsParam, passScore=$passScoreParam');
            AppLogger.debug('🔗 Router parsed: duration=$duration, questions=$questionCount, passScore=$passScore');

            return MaterialPage(
              child: ExamPage(
                durationMinutes: duration,
                questionCount: questionCount,
                passScore: passScore,
              ),
            );
          },
        ),
        GoRoute(
          path: '/exam-detail/:id',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final recordId = state.pathParameters['id'] ?? '';
            return MaterialPage(
              child: ExamDetailPage(recordId: recordId),
            );
          },
        ),
        GoRoute(
          path: '/category-select',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final title = state.uri.queryParameters['title'];
            final subtitle = state.uri.queryParameters['subtitle'];
            final mode = state.uri.queryParameters['mode'];
            return MaterialPage(
              child: CategorySelectPage(
                title: title ?? '选择分类',
                subtitle: subtitle,
                mode: mode,
              ),
            );
          },
        ),
        GoRoute(
          path: '/practice-swipe',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final category = state.uri.queryParameters['category'];
            final type = state.uri.queryParameters['type'];
            final mode = state.uri.queryParameters['mode']; // 'random' or null
            final count = int.tryParse(state.uri.queryParameters['count'] ?? '50') ?? 50;

            // Create filter from type parameter
            final filter = type != null ? QuestionFilter(type: type) : null;

            return MaterialPage(
              child: PracticeSwipePage(
                category: category,
                initialFilter: filter,
                mode: mode,
                count: count,
              ),
            );
          },
        ),
        // Wrong question detail page
        GoRoute(
          path: '/wrong-question-detail/:id',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return MaterialPage(
              child: WrongQuestionDetailPage(id: id),
            );
          },
        ),
        // Wrong review page
        GoRoute(
          path: '/wrong-review',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final category = state.uri.queryParameters['category'];
            return MaterialPage(
              child: WrongReviewPage(category: category),
            );
          },
        ),
        // Question update page (full screen, without bottom nav)
        GoRoute(
          path: '/question-update',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            return const MaterialPage(
              child: QuestionUpdatePage(),
            );
          },
        ),
      ],
      errorBuilder: (context, state) => const NotFoundPage(),
    );
  }
}

/// Main Shell with Adaptive Navigation
/// Uses BottomNavBar on mobile, TopNavBar on tablet/desktop
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      currentIndex: _getCurrentIndex(context),
      onTap: (index) => _onTap(context, index),
      items: BottomNavBar.defaultItems,
      child: child,
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case '/':
        return 0;
      case '/practice':
        return 1;
      case '/exam-setup':
        return 2;
      case '/wrong-book':
        return 3;
      case '/history':
        return 3; // Wrong book and history share the same position
      case '/settings':
        return 4;
      default:
        return 0;
    }
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/practice');
        break;
      case 2:
        context.go('/exam-setup');
        break;
      case 3:
        context.go('/wrong-book');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}

/// 404 Not Found Page
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: const Center(child: Text('404 - 页面未找到')),
    );
  }
}
