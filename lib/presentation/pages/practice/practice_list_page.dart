import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/practice_mode.dart';
import '../../providers/question_provider.dart';
import '../../providers/practice_list_provider.dart';
import '../../providers/practice_session_provider.dart';
import '../../widgets/appbars/app_top_bar.dart';
import '../../widgets/questions/question_card.dart';
import '../../widgets/common/progress_bar.dart';
import '../../widgets/common/empty_state.dart';
import 'widgets/filter_panel.dart';
import 'widgets/question_list_item.dart';

/// Practice List Page
/// Responsive layout with question list panel and detail panel
class PracticeListPage extends ConsumerStatefulWidget {
  final PracticeMode? mode;
  final String? category;

  const PracticeListPage({
    super.key,
    this.mode,
    this.category,
  });

  @override
  ConsumerState<PracticeListPage> createState() => _PracticeListPageState();
}

class _PracticeListPageState extends ConsumerState<PracticeListPage> {
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load questions when page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });

    // Setup scroll listener for pagination
    _listScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _listScrollController.removeListener(_onScroll);
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    // Get categories for filter
    final categories = ref.read(questionBankProvider).categories;

    // Start session if mode is provided
    if (widget.mode != null) {
      await ref.read(practiceSessionProvider.notifier).startSession(
            mode: widget.mode!,
            category: widget.category,
          );
    } else {
      // Just load the list
      await ref.read(practiceListProvider.notifier).loadSummaries();
    }

    // Update filter panel categories if needed
    // (In a real app, you might want to pass categories to the filter panel)
  }

  void _onScroll() {
    if (_listScrollController.position.pixels >=
        _listScrollController.position.maxScrollExtent - 200) {
      ref.read(practiceListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Use responsive layout based on screen width
    if (width >= Breakpoints.desktop) {
      return _DesktopLayout(
        listPanel: _buildListPanel(),
        detailPanel: _buildDetailPanel(),
      );
    } else if (width >= Breakpoints.tablet) {
      return _TabletLayout(
        listPanel: _buildListPanel(),
        detailPanel: _buildDetailPanel(),
      );
    } else {
      return _MobileLayout(listPanel: _buildListPanel());
    }
  }

  /// Build the left list panel
  Widget _buildListPanel() {
    final listState = ref.watch(practiceListProvider);
    final categories = ref.watch(questionBankProvider).categories;

    return Column(
      children: [
        // Header
        _ListHeader(
          title: widget.mode?.displayName ?? '题目列表',
          totalCount: listState.totalCount,
          loadedCount: listState.summaries.length,
        ),
        // Filter panel
        FilterPanel(availableCategories: categories),
        // Question list
        Expanded(
          child: _buildQuestionList(listState),
        ),
      ],
    );
  }

  /// Build the question list
  Widget _buildQuestionList(PracticeListState listState) {
    if (listState.isLoading && listState.summaries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (listState.error != null && listState.summaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败：${listState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(practiceListProvider.notifier).refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (listState.summaries.isEmpty) {
      return EmptyState.noQuestions();
    }

    return ListView.builder(
      controller: _listScrollController,
      itemCount: listState.summaries.length +
          (listState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= listState.summaries.length) {
          // Loading indicator at the bottom
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final summary = listState.summaries[index];
        final selectedIndex = ref.watch(practiceListProvider).selectedIndex;

        return QuestionListItem(
          summary: summary,
          isSelected: index == selectedIndex,
          onTap: () => _selectQuestion(index),
        );
      },
    );
  }

  /// Build the right detail panel
  Widget _buildDetailPanel() {
    final listState = ref.watch(practiceListProvider);
    final selectedSummary = listState.selectedSummary;

    if (selectedSummary == null) {
      return _EmptyDetailPanel();
    }

    // Check if question is in cache
    final sessionState = ref.watch(practiceSessionProvider);
    final question = sessionState.questionCache[selectedSummary.id];

    if (question == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return _QuestionDetailPanel(
      question: question,
      currentIndex: listState.selectedIndex,
      totalCount: listState.summaries.length,
      answeredQuestions: sessionState.answeredQuestions,
      hasPrevious: listState.selectedIndex > 0,
      hasNext: listState.selectedIndex < listState.summaries.length - 1,
      onPrevious: () => _selectQuestion(listState.selectedIndex - 1),
      onNext: () => _selectQuestion(listState.selectedIndex + 1),
    );
  }

  /// Select a question
  Future<void> _selectQuestion(int index) async {
    final listState = ref.read(practiceListProvider);
    if (index < 0 || index >= listState.summaries.length) return;

    // Update list selection
    ref.read(practiceListProvider.notifier).selectIndex(index);

    // Load question detail (lazy loading)
    final summary = listState.summaries[index];
    final sessionState = ref.read(practiceSessionProvider);

    if (!sessionState.questionCache.containsKey(summary.id)) {
      // Load the question
      final repository = ref.read(questionRepositoryProvider);
      final question = await repository.getQuestionById(summary.id);

      if (question != null) {
        ref.read(practiceSessionProvider.notifier).state =
            sessionState.copyWith(
          questionCache: {
            ...sessionState.questionCache,
            summary.id: question,
          },
        );
      }
    }
  }
}

/// Desktop Layout (>=1024px)
class _DesktopLayout extends StatelessWidget {
  final Widget listPanel;
  final Widget detailPanel;

  const _DesktopLayout({
    required this.listPanel,
    required this.detailPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: '练习模式',
        automaticallyImplyLeading: true,
      ),
      body: Row(
        children: [
          // Left panel - Question list (400px)
          SizedBox(
            width: 400,
            child: listPanel,
          ),
          // Divider
          const VerticalDivider(width: 1),
          // Right panel - Question detail (flex)
          Expanded(
            child: detailPanel,
          ),
        ],
      ),
    );
  }
}

/// Tablet Layout (768-1024px)
class _TabletLayout extends StatelessWidget {
  final Widget listPanel;
  final Widget detailPanel;

  const _TabletLayout({
    required this.listPanel,
    required this.detailPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: '练习模式',
        automaticallyImplyLeading: true,
      ),
      body: Row(
        children: [
          // Left panel - Question list (35%)
          FractionallySizedBox(
            widthFactor: 0.35,
            child: listPanel,
          ),
          // Divider
          const VerticalDivider(width: 1),
          // Right panel - Question detail (flex)
          Expanded(
            child: detailPanel,
          ),
        ],
      ),
    );
  }
}

/// Mobile Layout (<768px)
/// Shows list only, tapping navigates to detail page
class _MobileLayout extends StatelessWidget {
  final Widget listPanel;

  const _MobileLayout({
    required this.listPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: '题目列表',
        automaticallyImplyLeading: true,
      ),
      body: listPanel,
    );
  }
}

/// List Header Widget
class _ListHeader extends StatelessWidget {
  final String title;
  final int totalCount;
  final int loadedCount;

  const _ListHeader({
    required this.title,
    required this.totalCount,
    required this.loadedCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleMedium,
            ),
          ),
          Text(
            '$loadedCount/$totalCount',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty Detail Panel Widget
class _EmptyDetailPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              '选择一道题目开始练习',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Question Detail Panel Widget
class _QuestionDetailPanel extends StatelessWidget {
  final dynamic question; // Question entity
  final int currentIndex;
  final int totalCount;
  final Set<int> answeredQuestions;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _QuestionDetailPanel({
    required this.question,
    required this.currentIndex,
    required this.totalCount,
    required this.answeredQuestions,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnswered = answeredQuestions.contains(currentIndex);

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
              ),
            ),
          ),
          child: ProgressBar(
            progress: (currentIndex + 1) / totalCount,
            current: currentIndex + 1,
            total: totalCount,
            label: '答题进度',
          ),
        ),
        // Question card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: QuestionCard(
              question: question,
              selectedAnswer: null,
              correctAnswer: hasAnswered ? question.answer as String? : null,
              showResult: hasAnswered,
              onAnswerSelected: hasAnswered ? null : (_) {},
            ),
          ),
        ),
        // Bottom controls
        _DetailPanelControls(
          hasPrevious: hasPrevious,
          hasNext: hasNext,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
      ],
    );
  }
}

/// Detail Panel Controls
class _DetailPanelControls extends StatelessWidget {
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DetailPanelControls({
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasPrevious ? onPrevious : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('上一题'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Next button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasNext ? onNext : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('下一题'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
