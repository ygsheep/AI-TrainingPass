import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/touch_targets.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/appbars/app_top_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../providers/wrong_book_provider.dart';

/// Wrong Book Page
/// Review and practice wrong questions
class WrongBookPage extends ConsumerStatefulWidget {
  const WrongBookPage({super.key});

  @override
  ConsumerState<WrongBookPage> createState() => _WrongBookPageState();
}

class _WrongBookPageState extends ConsumerState<WrongBookPage> {
  String _selectedCategory = '全部';
  bool _showMasteredOnly = false;
  bool _showReviewOnly = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load wrong questions when page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWrongQuestions();
    });
    // Setup scroll listener for auto-loading
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final wrongBookState = ref.read(wrongBookProvider);
    if (wrongBookState.isLoadingMore || !wrongBookState.hasMore) {
      return;
    }

    // Load more when near bottom (within 200px)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    await ref.read(wrongBookProvider.notifier).loadMore();
  }

  Future<void> _loadWrongQuestions() async {
    await ref.read(wrongBookProvider.notifier).loadWrongQuestions(
          category: _selectedCategory == '全部' ? null : _selectedCategory,
          masteredOnly: _showMasteredOnly,
          needsReviewOnly: _showReviewOnly,
        );
  }

  Future<void> _refresh() async {
    await _loadWrongQuestions();
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadWrongQuestions();
  }

  void _toggleMasteredFilter() {
    setState(() {
      _showMasteredOnly = !_showMasteredOnly;
    });
    _loadWrongQuestions();
  }

  void _toggleReviewFilter() {
    setState(() {
      _showReviewOnly = !_showReviewOnly;
    });
    _loadWrongQuestions();
  }

  void _markAsMastered(String questionId) async {
    AppLogger.debug('🎯 _markAsMastered called: questionId=$questionId');
    final success = await ref.read(wrongBookProvider.notifier).markAsMastered(questionId);
    AppLogger.debug('🎯 markAsMastered result: success=$success');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '已标记为已掌握' : '标记失败，请查看控制台'),
          duration: const Duration(seconds: 2),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _startReview() {
    final category = _selectedCategory == '全部' ? null : _selectedCategory;
    if (category != null) {
      context.push('/wrong-review?category=$category');
    } else {
      context.push('/wrong-review');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final wrongBookState = ref.watch(wrongBookProvider);
    final wrongQuestions = wrongBookState.questions;

    return Scaffold(
      appBar: AppTopBar(
        title: '错题本',
        automaticallyImplyLeading: true,
        actions: [
          // Review button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: wrongQuestions.isNotEmpty
                  ? _startReview
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('开始复习'),
              style: TextButton.styleFrom(
                minimumSize: const Size(80, TouchTargets.minimumSize),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(TouchTargets.paddingMedium),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: '全部',
                        isSelected: _selectedCategory == '全部',
                        onTap: () => _filterByCategory('全部'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '单选',
                        isSelected: _selectedCategory == '单选',
                        onTap: () => _filterByCategory('单选'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '多选',
                        isSelected: _selectedCategory == '多选',
                        onTap: () => _filterByCategory('多选'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '判断',
                        isSelected: _selectedCategory == '判断',
                        onTap: () => _filterByCategory('判断'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '填空',
                        isSelected: _selectedCategory == '填空',
                        onTap: () => _filterByCategory('填空'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Filter toggles
                Row(
                  children: [
                    FilterChip(
                      label: const Text('只看已掌握'),
                      selected: _showMasteredOnly,
                      onSelected: (_) => _toggleMasteredFilter(),
                      checkmarkColor: AppColors.success,
                      selectedColor: AppColors.success.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('需复习'),
                      selected: _showReviewOnly,
                      onSelected: (_) => _toggleReviewFilter(),
                      checkmarkColor: AppColors.warning,
                      selectedColor: AppColors.warning.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Question list
          Expanded(
            child: wrongBookState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : wrongBookState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '加载失败',
                              style: AppTypography.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              wrongBookState.error!,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : wrongQuestions.isEmpty
                        ? EmptyState.noWrongQuestions(
                            onPractice: () => context.go('/practice'),
                          )
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(TouchTargets.paddingMedium),
                              itemCount: wrongQuestions.length + (wrongBookState.hasMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: TouchTargets.paddingMedium),
                              itemBuilder: (context, index) {
                                // Show loading indicator at the bottom
                                if (index == wrongQuestions.length) {
                                  return wrongBookState.isLoadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }

                                final wrongQuestion = wrongQuestions[index];
                                final question = wrongQuestion.question;

                                return _WrongQuestionCard(
                                  question: question,
                                  wrongQuestion: wrongQuestion,
                                  onMarkMastered: () =>
                                      _markAsMastered(wrongQuestion.id),
                                  onTap: () => _showQuestionDetail(wrongQuestion),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showQuestionDetail(dynamic wrongQuestion) {
    context.push('/wrong-question-detail/${wrongQuestion.id}');
  }
}

/// Wrong Question Card
class _WrongQuestionCard extends StatelessWidget {
  final dynamic question;
  final dynamic wrongQuestion;
  final VoidCallback onMarkMastered;
  final VoidCallback onTap;

  const _WrongQuestionCard({
    required this.question,
    required this.wrongQuestion,
    required this.onMarkMastered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mastered = wrongQuestion.mastered ?? false;
    final needsReview = wrongQuestion.needsReview() ?? false;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(TouchTargets.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      question.type,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category badge
                  if (question.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        question.category.first,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Status badges
                  if (mastered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '已掌握',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (needsReview && !mastered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '需复习',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Question text
              Text(
                question.question,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  // Wrong count
                  Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '答错 ${wrongQuestion.wrongAnswerCount ?? 1} 次',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Review count
                  Icon(
                    Icons.visibility_rounded,
                    size: 16,
                    color: AppColors.info.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '复习 ${wrongQuestion.reviewCount ?? 0} 次',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Mark mastered button
                  if (!mastered)
                    TextButton.icon(
                      onPressed: onMarkMastered,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('掌握'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(60, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter Chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
    );
  }
}
