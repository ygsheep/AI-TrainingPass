import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/practice_swipe_provider.dart';

/// Question List Dialog
/// Shows all questions with their status in a grid layout
class QuestionListDialog extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final List<QuestionStatus> statuses;
  final ValueChanged<int> onQuestionSelected;

  const QuestionListDialog({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.statuses,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate statistics
    final correctCount = statuses.where((s) => s == QuestionStatus.correct).length;
    final wrongCount = statuses.where((s) => s == QuestionStatus.wrong).length;
    final unansweredCount = statuses.where((s) => s == QuestionStatus.unanswered).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '答题情况',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Statistics row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: '正确',
                        count: correctCount,
                        color: AppColors.success,
                        icon: Icons.check_circle,
                      ),
                      _StatItem(
                        label: '错误',
                        count: wrongCount,
                        color: AppColors.error,
                        icon: Icons.cancel,
                      ),
                      _StatItem(
                        label: '未做',
                        count: unansweredCount,
                        color: AppColors.textTertiary,
                        icon: Icons.radio_button_unchecked,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Question grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    final status = index < statuses.length ? statuses[index] : QuestionStatus.unanswered;
                    final isCurrent = index == currentIndex;

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onQuestionSelected(index);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent
                              ? Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                )
                              : null,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Footer with legend
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(color: AppColors.success, label: '正确'),
                  const SizedBox(width: 16),
                  _LegendItem(color: AppColors.error, label: '错误'),
                  const SizedBox(width: 16),
                  _LegendItem(color: AppColors.textTertiary, label: '未做'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.correct:
        return AppColors.success;
      case QuestionStatus.wrong:
        return AppColors.error;
      case QuestionStatus.unanswered:
        return AppColors.textTertiary;
    }
  }

  /// Show the dialog
  static Future<void> show({
    required BuildContext context,
    required int currentIndex,
    required int totalCount,
    required List<QuestionStatus> statuses,
    required ValueChanged<int> onQuestionSelected,
  }) {
    return showDialog(
      context: context,
      builder: (context) => QuestionListDialog(
        currentIndex: currentIndex,
        totalCount: totalCount,
        statuses: statuses,
        onQuestionSelected: onQuestionSelected,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: AppTypography.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
