import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/question_filter.dart';
import '../../widgets/questions/question_swipe_card.dart';
import '../../widgets/practice/swipe_progress_bar.dart';
import '../../widgets/practice/question_list_dialog.dart';
import '../../providers/practice_swipe_provider.dart';

/// Practice Swipe Page
/// Card-based practice mode with swipe navigation
class PracticeSwipePage extends ConsumerStatefulWidget {
  final String? category;
  final QuestionFilter? initialFilter;
  final String? mode;  // 'random' or null
  final int? count;    // Random mode: number of questions to load

  const PracticeSwipePage({
    super.key,
    this.category,
    this.initialFilter,
    this.mode,
    this.count,
  });

  @override
  ConsumerState<PracticeSwipePage> createState() => _PracticeSwipePageState();
}

class _PracticeSwipePageState extends ConsumerState<PracticeSwipePage>
    with WidgetsBindingObserver {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);

    // Initialize practice session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePractice();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveProgress();
    }
  }

  Future<void> _initializePractice() async {
    // Check for saved progress and show dialog if exists
    // TODO: Implement progress restoration

    if (widget.mode == 'random') {
      // Random practice mode: Load fixed number of random questions
      await ref.read(practiceSwipeProvider.notifier).loadRandomBatch(
        count: widget.count ?? 50,
        types: ['single', 'multiple', 'judge'], // Only these types for random practice
      );
    } else {
      // Normal practice mode: Load with pagination
      await ref.read(practiceSwipeProvider.notifier).loadInitialBatch(
        category: widget.category,
        filter: widget.initialFilter,
      );
    }
  }

  void _saveProgress() {
    // TODO: Implement progress saving
  }

  void _onPageChanged(int index) {
    ref.read(practiceSwipeProvider.notifier).onPageChanged(index);
  }

  void _showQuestionList() {
    final state = ref.read(practiceSwipeProvider);
    final provider = ref.read(practiceSwipeProvider.notifier);

    QuestionListDialog.show(
      context: context,
      currentIndex: state.currentIndex,
      totalCount: state.totalCount,
      statuses: provider.getAllQuestionStatuses(),
      onQuestionSelected: (index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final swipeState = ref.watch(practiceSwipeProvider);

    // Loading state
    if (swipeState.isLoading && swipeState.summaries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          automaticallyImplyLeading: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (swipeState.error != null && swipeState.summaries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          automaticallyImplyLeading: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败：${swipeState.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _initializePractice(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (swipeState.summaries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          automaticallyImplyLeading: true,
        ),
        body: Center(
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
                '暂无题目',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Main content
    return Scaffold(
      appBar: _buildAppBar(swipeState),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
            ),
            child: SwipeProgressBar(
              current: swipeState.currentIndex + 1,
              total: swipeState.totalCount,
              answered: swipeState.answeredCount,
            ),
          ),

          // PageView with question cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: swipeState.summaries.length + (swipeState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Loading indicator at the end
                if (index >= swipeState.summaries.length) {
                  ref.read(practiceSwipeProvider.notifier).loadNextBatch();
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Question card
                final summary = swipeState.summaries[index];
                final question = swipeState.questionCache[summary.id];

                if (question == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final isSelected = index == swipeState.currentIndex;
                final hasAnswered = swipeState.answeredIndices.contains(index);
                final userAnswer = swipeState.userAnswers[index];

                // CRITICAL: Only use swipeState.selectedAnswer when:
                // 1. It's the CURRENT page (isSelected)
                // 2. The question is NOT answered yet (!hasAnswered)
                // 3. The selected answer matches the current question type
                // Otherwise always use userAnswer (which is null for new questions)
                String? selectedAnswer;
                if (isSelected && !hasAnswered && swipeState.selectedAnswer != null) {
                  // Additional safety check: verify this answer belongs to current question
                  // For single choice: answer should be a single letter (A, B, C, D)
                  // For multiple choice: answer contains | separator
                  final currentQuestion = swipeState.questionCache[summary.id];
                  if (currentQuestion != null) {
                    // Only use selectedAnswer if it's not from a previous question
                    selectedAnswer = swipeState.selectedAnswer;
                  }
                } else {
                  selectedAnswer = userAnswer;
                }

                return QuestionSwipeCard(
                  key: ObjectKey(question.id),  // Use ObjectKey instead of ValueKey for guaranteed state reset
                  question: question,
                  selectedAnswer: selectedAnswer,
                  showResult: isSelected && swipeState.showResult,
                  onAnswerSelected: isSelected ? (answer) {
                    ref.read(practiceSwipeProvider.notifier).selectAnswer(answer);
                  } : null,
                );
              },
            ),
          ),

          // Bottom controls
          _buildBottomControls(swipeState),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(PracticeSwipeState state) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.pop();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getTitle(),
            style: AppTypography.titleMedium,
          ),
          Text(
            '${state.currentIndex + 1} / ${state.totalCount}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // Question list button
        IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          onPressed: _showQuestionList,
          tooltip: '答题情况',
        ),
        // Bookmark button
        IconButton(
          icon: Icon(
            state.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          ),
          onPressed: () {
            ref.read(practiceSwipeProvider.notifier).toggleBookmark();
          },
          tooltip: '收藏',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomControls(PracticeSwipeState state) {
    final hasAnswered = state.answeredIndices.contains(state.currentIndex);
    final showResult = state.showResult;
    final question = state.currentQuestion;
    final isMultipleChoice = question?.isMultipleChoice ?? false;
    final isEssay = question?.isEssay ?? false;
    final requiresManualSubmit = isMultipleChoice || isEssay;
    final hasSelection = state.selectedAnswer != null && state.selectedAnswer!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.currentIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.chevron_left, size: 20),
                label: const Text('上一题', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Next/Submit button - behavior changes based on question type
            Expanded(
              flex: 2,
              child: _buildNextSubmitButton(state, requiresManualSubmit, hasSelection, hasAnswered, showResult),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSubmitButton(
    PracticeSwipeState state,
    bool requiresManualSubmit,
    bool hasSelection,
    bool hasAnswered,
    bool showResult,
  ) {
    final currentQuestion = state.currentQuestion;

    // For essay questions: show "Next" when empty, "Submit" when has content
    if (currentQuestion?.isEssay == true && !showResult) {
      if (!hasSelection) {
        // No input - show Next button
        final canContinue = state.currentIndex < state.summaries.length - 1;
        final isCompleted = hasAnswered && showResult;

        return ElevatedButton.icon(
          onPressed: canContinue
              ? () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
          icon: const Icon(Icons.chevron_right, size: 20),
          label: const Text('下一题', style: TextStyle(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
      } else {
        // Has input - show Submit button
        return ElevatedButton.icon(
          onPressed: () {
            ref.read(practiceSwipeProvider.notifier).submitAnswer();
          },
          icon: const Icon(Icons.check_circle, size: 20),
          label: const Text('提交答案', style: TextStyle(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
      }
    }

    // For multiple choice: show "Submit Answer" when not submitted
    if (currentQuestion?.isMultipleChoice == true && !showResult) {
      return ElevatedButton.icon(
        onPressed: hasSelection
            ? () {
                ref.read(practiceSwipeProvider.notifier).submitAnswer();
              }
            : null,
        icon: const Icon(Icons.check_circle, size: 20),
        label: const Text('提交答案', style: TextStyle(fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasSelection ? AppColors.primary : AppColors.textTertiary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      );
    }

    // For single choice and already submitted: show "Continue" or "Next"
    final canContinue = state.currentIndex < state.summaries.length - 1;
    final isCompleted = hasAnswered && showResult;

    return ElevatedButton.icon(
      onPressed: canContinue
          ? () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          : null,
      icon: const Icon(Icons.chevron_right, size: 20),
      label: Text(
        isCompleted ? '继续' : '下一题',
        style: const TextStyle(fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCompleted ? AppColors.success : AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }


  String _getTitle() {
    final category = widget.category;
    if (category == null || category == 'all') return '练习模式';

    const names = {
      'foundation': '基础知识',
      'operate': '操作系统',
      'data': '数据库',
      'ml': '机器学习',
      'nlp': '自然语言',
      'dl': '深度学习',
    };
    return names[category] ?? '练习模式';
  }
}
