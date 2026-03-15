import 'package:flutter/material.dart';
import '../../../data/models/exam_record.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Exam Record Card
/// Displays a single exam record with Swiss Modernism style
class ExamRecordCard extends StatelessWidget {
  final ExamRecordModel record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExamRecordCard({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passedColor = record.passed ? AppColors.success : AppColors.error;

    return Semantics(
      button: true,
      label: '考试记录: ${record.config.name}, 得分: ${record.score}',
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.formattedDate,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        _buildStatusBadge(isDark, passedColor),
                        if (onDelete != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: '删除',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            iconSize: 18,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Exam Name
                Text(
                  record.config.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Score and Stats Row
                Row(
                  children: [
                    _buildStatItem(
                      context,
                      label: '得分',
                      value: '${record.score}分',
                      valueColor: passedColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      context,
                      label: '正确率',
                      value: '${record.accuracy.toStringAsFixed(0)}%',
                      valueColor: record.accuracy >= 60
                          ? AppColors.success
                          : AppColors.error,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    _buildStatItem(
                      context,
                      label: '用时',
                      value: record.formattedDuration,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        record.passed ? '通过' : '未通过',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: valueColor ??
                (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
