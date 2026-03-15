import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/touch_targets.dart';

/// Exam Summary Widget
/// Shows configuration summary and validation
class ExamSummary extends StatelessWidget {
  final int totalAvailable;
  final Map<String, int> availableByType;
  final int requiredTotal;
  final Map<String, int> requiredByType;
  final String? validationError;
  final bool isStarting;

  const ExamSummary({
    super.key,
    required this.totalAvailable,
    required this.availableByType,
    required this.requiredTotal,
    required this.requiredByType,
    this.validationError,
    this.isStarting = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isValid = validationError == null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle_outline : Icons.error_outline,
                color: isValid ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isValid ? '配置有效' : '配置有误',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isValid ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Available questions
          _StatRow(
            label: '可用题目',
            value: '$totalAvailable题',
            isSufficient: totalAvailable >= requiredTotal,
          ),

          // Type breakdown
          ...availableByType.entries.map((entry) {
            final type = entry.key;
            final available = entry.value;
            final required = requiredByType[type] ?? 0;
            final typeName = _getTypeDisplayName(type);

            if (required == 0) return const SizedBox.shrink();

            return _StatRow(
              label: '  └ $typeName',
              value: '$available/$required题',
              isSufficient: available >= required,
            );
          }).toList(),

          // Validation error
          if (validationError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      validationError!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    const names = {
      'single': '单选题',
      'multiple': '多选题',
      'judge': '判断题',
      'essay': '简答题',
    };
    return names[type] ?? type;
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSufficient;

  const _StatRow({
    required this.label,
    required this.value,
    required this.isSufficient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isSufficient
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Start Exam Button
class StartExamButton extends StatelessWidget {
  final bool isValid;
  final bool isLoading;
  final VoidCallback onPressed;

  const StartExamButton({
    super.key,
    required this.isValid,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isValid && !isLoading ? onPressed : null,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(
          isLoading ? '生成题目中...' : '开始考试',
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: (isValid
                  ? AppColors.primary
                  : AppColors.textSecondary)
              .withValues(alpha: 0.3),
          minimumSize: const Size(double.infinity, TouchTargets.minimumSize),
          padding: const EdgeInsets.symmetric(
            horizontal: TouchTargets.paddingLarge,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
