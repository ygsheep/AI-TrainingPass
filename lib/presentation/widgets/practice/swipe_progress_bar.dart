import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Swipe Progress Bar
/// Displays practice progress with current position and answered count
class SwipeProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final int answered;

  const SwipeProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double progress = total > 0 ? current / total : 0.0;
    final double answeredProgress = total > 0 ? answered / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$current / $total',
              style: AppTypography.labelLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            Text(
              '已答 $answered',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar with two layers
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Answered progress (bottom layer - semi-transparent success)
            if (answeredProgress > 0)
              FractionallySizedBox(
                widthFactor: answeredProgress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

            // Current progress (top layer - primary)
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact version for app bar
class CompactSwipeProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const CompactSwipeProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$current / $total',
      style: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
