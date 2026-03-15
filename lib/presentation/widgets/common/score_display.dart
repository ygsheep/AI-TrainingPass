import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Score Display Widget
/// Displays exam score with visual feedback
class ScoreDisplay extends StatelessWidget {
  final int score;
  final int? totalScore;
  final int? correctCount;
  final int? totalCount;
  final bool isPassed;
  final String? grade;
  final bool showDetails;
  final double? size;

  const ScoreDisplay({
    super.key,
    required this.score,
    this.totalScore,
    this.correctCount,
    this.totalCount,
    required this.isPassed,
    this.grade,
    this.showDetails = true,
    this.size,
  });

  /// Get color based on score
  Color _getScoreColor(BuildContext context) {
    if (isPassed) {
      return AppColors.success;
    } else if (score >= 40) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  /// Get grade label (A, B, C, D, F)
  static String getGrade(int score, {int maxScore = 100}) {
    final percentage = score / maxScore;
    if (percentage >= 0.9) return 'A';
    if (percentage >= 0.8) return 'B';
    if (percentage >= 0.7) return 'C';
    if (percentage >= 0.6) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displaySize = size ?? 60;
    final scoreColor = _getScoreColor(context);
    final displayGrade = grade ?? getGrade(score, maxScore: totalScore ?? 100);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular score display
        SizedBox(
          width: displaySize * 2,
          height: displaySize * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: displaySize * 2,
                height: displaySize * 2,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: displaySize / 8,
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.darkSurface : Colors.grey.shade300,
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: displaySize * 2,
                height: displaySize * 2,
                child: CircularProgressIndicator(
                  value: (totalScore != null ? score / totalScore! : score / 100).clamp(0.0, 1.0),
                  strokeWidth: displaySize / 8,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Score number
                  Text(
                    score.toString(),
                    style: AppTypography.displayLarge.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                      fontSize: displaySize * 0.5,
                    ),
                  ),
                  // Grade badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scoreColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      displayGrade,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Pass/Fail badge
                  if (totalScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPassed
                            ? AppColors.success
                            : AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPassed ? '及格' : '不及格',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Details row
        if (showDetails) ...[
          if (correctCount != null && totalCount != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DetailItem(
                  label: '正确',
                  value: correctCount.toString(),
                  color: AppColors.success,
                ),
                const SizedBox(width: 24),
                _DetailItem(
                  label: '错误',
                  value: (totalCount! - correctCount!).toString(),
                  color: AppColors.error,
                ),
                const SizedBox(width: 24),
                _DetailItem(
                  label: '正确率',
                  value: '${((correctCount! / totalCount!) * 100).toInt()}%',
                  color: AppColors.primary,
                ),
              ],
            ),
        ],
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
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

/// Score Card Widget
/// Horizontal card version of score display
class ScoreCard extends StatelessWidget {
  final int score;
  final int totalScore;
  final int correctCount;
  final int totalCount;
  final bool isPassed;
  final String? examName;
  final DateTime? date;

  const ScoreCard({
    super.key,
    required this.score,
    required this.totalScore,
    required this.correctCount,
    required this.totalCount,
    required this.isPassed,
    this.examName,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scoreColor = isPassed ? AppColors.success : AppColors.error;
    final grade = ScoreDisplay.getGrade(score, maxScore: totalScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Grade circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scoreColor,
              ),
              child: Center(
                child: Text(
                  grade,
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Score details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    examName ?? '考试成绩',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
                        : '',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '$score分',
                        style: AppTypography.titleLarge.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' / $totalScore分',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPassed ? '及格' : '不及格',
                          style: AppTypography.labelSmall.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatChip(
                        label: '正确',
                        value: correctCount,
                        total: totalCount,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: '错误',
                        value: totalCount - correctCount,
                        total: totalCount,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: '正确率',
                        value: 0,
                        total: 0,
                        percentage: correctCount / totalCount,
                        isPercentage: true,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final double? percentage;
  final bool isPercentage;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    this.percentage,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = isPercentage
        ? '${(percentage! * 100).toInt()}%'
        : '$value/$total';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $displayValue',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
