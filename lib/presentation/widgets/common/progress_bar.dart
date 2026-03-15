import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Progress Bar Widget
/// Displays progress for exam completion or question bank loading
class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int current;
  final int total;
  final String? label;
  final bool showPercentage;
  final Color? color;
  final Color? backgroundColor;
  final double height;

  const ProgressBar({
    super.key,
    required this.progress,
    this.current = 0,
    this.total = 0,
    this.label,
    this.showPercentage = true,
    this.color,
    this.backgroundColor,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progressColor = color ?? AppColors.primary;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.lightSurface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        if (label != null || showPercentage || total > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              if (showPercentage && total > 0)
                Text(
                  '$current/$total',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              if (showPercentage && total == 0)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTypography.labelMedium.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        if (label != null || showPercentage || total > 0)
          const SizedBox(height: 8),

        // Progress bar
        Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Circular Progress Widget
/// Displays circular progress for exams or loading states
class CircularProgressWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int current;
  final int total;
  final String? centerText;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  const CircularProgressWidget({
    super.key,
    required this.progress,
    this.current = 0,
    this.total = 0,
    this.centerText,
    this.size = 80,
    this.strokeWidth = 8,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progressColor = color ?? AppColors.primary;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.lightSurface);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(bgColor),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          // Center text
          Center(
            child: Text(
              centerText ?? '${(progress * 100).toInt()}%',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step Progress Widget
/// Displays progress as steps for question navigation
class StepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<bool>? completedSteps;
  final ValueChanged<int>? onStepTapped;
  final Color? activeColor;
  final Color? completedColor;
  final Color? inactiveColor;

  const StepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.completedSteps,
    this.onStepTapped,
    this.activeColor,
    this.completedColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final active = activeColor ?? AppColors.primary;
    final completed = completedColor ?? AppColors.success;
    final inactive = inactiveColor ??
        (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Row(
      children: List.generate(totalSteps, (index) {
        final steps = completedSteps;
        final bool isCompleted;
        if (steps != null && index < steps.length) {
          isCompleted = steps[index];
        } else {
          isCompleted = false;
        }
        final isActive = index == currentStep;

        return Expanded(
          child: GestureDetector(
            onTap: onStepTapped != null ? () => onStepTapped!(index) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step circle - wrap in Flexible to allow shrinking
                Flexible(
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? active
                            : isCompleted
                                ? completed
                                : Colors.transparent,
                        border: Border.all(
                          color: isActive
                              ? active
                              : isCompleted
                                  ? completed
                                  : inactive,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isActive
                            ? Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white : Colors.white,
                                ),
                              )
                            : isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: completed,
                                  )
                                : FittedBox(
                                    child: Text(
                                      '${index + 1}',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: isActive
                                            ? active
                                            : isCompleted
                                                ? completed
                                                : inactive,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                  ),
                ),
                // Connector line - use Flexible with minimum width
                if (index < totalSteps - 1)
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted ? completed : inactive,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
