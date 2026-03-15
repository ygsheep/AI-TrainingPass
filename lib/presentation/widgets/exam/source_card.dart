import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/source_statistics.dart';

/// Source Selection Card
/// Shows detailed statistics for a question source
class SourceCard extends StatelessWidget {
  final SourceStatistics statistics;
  final bool isSelected;
  final VoidCallback onTap;

  const SourceCard({
    super.key,
    required this.statistics,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${statistics.displayName}: ${statistics.totalCount}题',
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.05)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with checkbox
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statistics.displayName,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface)
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${statistics.totalCount}题',
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary)
                                  .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Type distribution
                Text(
                  '题型分布',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildTypeChips(statistics, isDark),
                ),

                // Exam history (if available)
                if (statistics.history != null) ...[
                  const SizedBox(height: 16),
                  _ExamHistoryStats(history: statistics.history!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTypeChips(SourceStatistics stats, bool isDark) {
    final typeNames = {
      'single': '单选',
      'multiple': '多选',
      'judge': '判断',
      'essay': '简答',
    };

    return stats.typeDistribution.entries.map((entry) {
      final type = entry.key;
      final count = entry.value;
      final name = typeNames[type] ?? type;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Text(
          '$name $count',
          style: AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),
      );
    }).toList();
  }
}

/// Exam History Stats Widget
class _ExamHistoryStats extends StatelessWidget {
  final ExamHistoryStats history;

  const _ExamHistoryStats({required this.history});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (history.examCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '历史记录',
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '平均分',
                  value: '${history.averageScore.toStringAsFixed(1)}',
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '最高分',
                  value: '${history.highestScore}',
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '及格率',
                  value: '${history.passRatePercentage.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '已考 ${history.examCount} 次',
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
