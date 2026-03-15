import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/utils/app_logger.dart';
import '../../providers/exam_provider.dart';
import '../../providers/question_provider.dart';
import '../../../data/models/exam_record.dart';
import '../../../domain/entities/question.dart';

/// Detail Filter Enum
enum _DetailFilter { all, correct, wrong, unanswered }

/// Exam Detail Page
/// Displays detailed information about a completed exam attempt
class ExamDetailPage extends ConsumerStatefulWidget {
  final String recordId;

  const ExamDetailPage({
    super.key,
    required this.recordId,
  });

  @override
  ConsumerState<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends ConsumerState<ExamDetailPage> {
  _DetailFilter _filter = _DetailFilter.all;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('📋 ExamDetailPage: Loading record ${widget.recordId}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final recordAsync = ref.watch(examRecordProvider(widget.recordId));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            if (isMobile)
              SliverToBoxAdapter(
                child: _AppBar(isDark: isDark),
              ),

            // Content
            recordAsync.when(
              data: (record) {
                if (record == null) {
                  return SliverFillRemaining(
                    child: _ErrorState(
                      message: '考试记录不存在',
                      onBack: () => context.pop(),
                    ),
                  );
                }
                return _ExamDetailContent(
                  record: record,
                  filter: _filter,
                  onFilterChanged: (filter) => setState(() => _filter = filter),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorState(
                  message: '加载失败: $error',
                  onBack: () => context.pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exam Detail Content
class _ExamDetailContent extends ConsumerWidget {
  final ExamRecordModel record;
  final _DetailFilter filter;
  final ValueChanged<_DetailFilter> onFilterChanged;

  const _ExamDetailContent({
    required this.record,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch question bank to ensure it's loaded
    final questionBankState = ref.watch(questionBankProvider);

    // Show loading while question bank is loading
    if (questionBankState.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Load questions using the notifier
    final questionBankNotifier = ref.read(questionBankProvider.notifier);
    final questions = <Question>[];

    AppLogger.debug('📋 Looking for ${record.questionIds.length} questions');
    AppLogger.debug('📋 QuestionBank has ${questionBankState.questions.length} questions');

    for (final questionId in record.questionIds) {
      final question = questionBankNotifier.getQuestionById(questionId);
      if (question != null) {
        questions.add(question);
      }
    }

    AppLogger.debug('📋 Loaded ${questions.length} questions for detail view');

    final filteredQuestions = _getFilteredQuestions(questions);

    return SliverPadding(
      padding: EdgeInsets.all(Responsive.getPadding(context)),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Page Title
          Text(
            '答题详情',
            style: AppTypography.headlineLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Score Card
          _ScoreCard(record: record, isDark: isDark),
          const SizedBox(height: 24),

          // Filter Bar
          _FilterBar(
            filter: filter,
            onFilterChanged: onFilterChanged,
            totalCount: questions.length,
            correctCount: record.correctCount,
            wrongCount: questions.length - record.answers.length - record.correctCount,
            unansweredCount: record.unansweredCount,
          ),
          const SizedBox(height: 16),

          // Question List
          if (filteredQuestions.isEmpty)
            _EmptyFilterState(filter: filter)
          else
            ...filteredQuestions.map((qa) => _QuestionAnswerCard(
              questionWithAnswer: qa,
              isDark: isDark,
            )),
        ]),
      ),
    );
  }

  List<_QuestionWithAnswer> _getFilteredQuestions(List<Question> questions) {
    final answersMap = {for (var a in record.answers) a.questionId: a};

    List<_QuestionWithAnswer> result = [];

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final answer = answersMap[question.id];

      // Determine answer status
      _AnswerStatus status;
      if (answer == null) {
        status = _AnswerStatus.unanswered;
      } else if (answer.isCorrect) {
        status = _AnswerStatus.correct;
      } else {
        status = _AnswerStatus.wrong;
      }

      result.add(_QuestionWithAnswer(
        question: question,
        userAnswer: answer,
        status: status,
        index: i,
      ));
    }

    // Apply filter
    switch (filter) {
      case _DetailFilter.correct:
        return result.where((qa) => qa.status == _AnswerStatus.correct).toList();
      case _DetailFilter.wrong:
        return result.where((qa) => qa.status == _AnswerStatus.wrong).toList();
      case _DetailFilter.unanswered:
        return result.where((qa) => qa.status == _AnswerStatus.unanswered).toList();
      case _DetailFilter.all:
        return result;
    }
  }
}

/// Question with Answer wrapper
class _QuestionWithAnswer {
  final Question question;
  final dynamic userAnswer;  // UserAnswerModel?
  final _AnswerStatus status;
  final int index;

  const _QuestionWithAnswer({
    required this.question,
    required this.userAnswer,
    required this.status,
    required this.index,
  });
}

/// Answer Status Enum
enum _AnswerStatus { correct, wrong, unanswered }

/// Score Card
class _ScoreCard extends StatelessWidget {
  final ExamRecordModel record;
  final bool isDark;

  const _ScoreCard({
    required this.record,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = record.passed ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: record.passed
              ? [AppColors.success.withValues(alpha: 0.1), AppColors.success.withValues(alpha: 0.05)]
              : [AppColors.error.withValues(alpha: 0.1), AppColors.error.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${record.score}',
                style: AppTypography.displayLarge.copyWith(
                  color: scoreColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 48,
                ),
              ),
              Text(
                ' / 100',
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pass/Fail Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.passed ? '及格' : '不及格',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: '正确',
                value: record.correctCount.toString(),
                color: AppColors.success,
              ),
              _StatItem(
                label: '错误',
                value: (record.totalCount - record.correctCount).toString(),
                color: AppColors.error,
              ),
              _StatItem(
                label: '用时',
                value: record.formattedDuration,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stat Item
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Filter Bar
class _FilterBar extends StatelessWidget {
  final _DetailFilter filter;
  final ValueChanged<_DetailFilter> onFilterChanged;
  final int totalCount;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;

  const _FilterBar({
    required this.filter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Filter Icon
          Icon(
            Icons.filter_list_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),

          // Filter Chips
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: '全部',
                  count: totalCount,
                  isSelected: filter == _DetailFilter.all,
                  onTap: () => onFilterChanged(_DetailFilter.all),
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                _FilterChip(
                  label: '正确',
                  count: correctCount,
                  isSelected: filter == _DetailFilter.correct,
                  onTap: () => onFilterChanged(_DetailFilter.correct),
                  color: AppColors.success,
                ),
                _FilterChip(
                  label: '错误',
                  count: wrongCount,
                  isSelected: filter == _DetailFilter.wrong,
                  onTap: () => onFilterChanged(_DetailFilter.wrong),
                  color: AppColors.error,
                ),
                _FilterChip(
                  label: '未答',
                  count: unansweredCount,
                  isSelected: filter == _DetailFilter.unanswered,
                  onTap: () => onFilterChanged(_DetailFilter.unanswered),
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter Chip
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? color : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Empty Filter State
class _EmptyFilterState extends StatelessWidget {
  final _DetailFilter filter;

  const _EmptyFilterState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String message;
    IconData icon;

    switch (filter) {
      case _DetailFilter.correct:
        message = '没有正确的题目';
        icon = Icons.check_circle_outline;
        break;
      case _DetailFilter.wrong:
        message = '没有错误的题目';
        icon = Icons.cancel_outlined;
        break;
      case _DetailFilter.unanswered:
        message = '没有未作答的题目';
        icon = Icons.radio_button_unchecked;
        break;
      default:
        message = '没有题目';
        icon = Icons.quiz_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(icon, size: 64, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Question Answer Card
class _QuestionAnswerCard extends ConsumerWidget {
  final _QuestionWithAnswer questionWithAnswer;
  final bool isDark;

  const _QuestionAnswerCard({
    required this.questionWithAnswer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qa = questionWithAnswer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _StatusIcon(status: qa.status),
              const SizedBox(width: 8),
              Text(
                '第 ${qa.index + 1} 题',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (qa.userAnswer != null)
                Text(
                  (qa.userAnswer as dynamic).timeSpent >= 60
                      ? '${(qa.userAnswer as dynamic).timeSpent ~/ 60}分${(qa.userAnswer as dynamic).timeSpent % 60}秒'
                      : '${(qa.userAnswer as dynamic).timeSpent}秒',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Question
          Text(
            qa.question.question,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Options (if any)
          if (qa.question.options != null && qa.question.options!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...qa.question.options!.asMap().entries.map((entry) {
              final idx = entry.key;
              final opt = entry.value;
              final optionLabel = String.fromCharCode(65 + idx); // A, B, C, D...

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$optionLabel. ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        opt,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 12),

          // Answer Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Answer
                _AnswerRow(
                  label: '你的答案',
                  answer: qa.userAnswer?.userAnswer ?? '未作答',
                  isCorrect: qa.status == _AnswerStatus.correct,
                ),
                const SizedBox(height: 8),

                // Correct Answer
                _AnswerRow(
                  label: '正确答案',
                  answer: qa.question.answer ?? '无',
                  isCorrect: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (questionWithAnswer.status) {
      case _AnswerStatus.correct:
        return AppColors.success;
      case _AnswerStatus.wrong:
        return AppColors.error;
      case _AnswerStatus.unanswered:
        return Colors.grey;
    }
  }
}

/// Status Icon
class _StatusIcon extends StatelessWidget {
  final _AnswerStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case _AnswerStatus.correct:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        break;
      case _AnswerStatus.wrong:
        icon = Icons.cancel_rounded;
        color = AppColors.error;
        break;
      case _AnswerStatus.unanswered:
        icon = Icons.radio_button_unchecked_rounded;
        color = Colors.grey;
        break;
    }

    return Icon(icon, size: 20, color: color);
  }
}

/// Answer Row
class _AnswerRow extends StatelessWidget {
  final String label;
  final String answer;
  final bool isCorrect;

  const _AnswerRow({
    required this.label,
    required this.answer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label：',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            answer,
            style: AppTypography.bodyMedium.copyWith(
              color: isCorrect
                  ? AppColors.success
                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom App Bar
class _AppBar extends StatelessWidget {
  final bool isDark;

  const _AppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/history'),
            tooltip: '返回',
          ),
          const SizedBox(width: 8),
          Text(
            '答题详情',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error State
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _ErrorState({
    required this.message,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('返回历史记录'),
            ),
          ],
        ),
      ),
    );
  }
}
