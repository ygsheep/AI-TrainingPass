import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Parameter Adjuster Widget
/// Allows fine-tuning of exam parameters
class ParameterAdjuster extends StatelessWidget {
  final int durationMinutes;
  final int totalQuestions;
  final Map<String, int> typeAllocation;
  final int passScore;
  final Function(int) onDurationChanged;
  final Function(int) onTotalQuestionsChanged;
  final Function(String, int) onTypeAllocationChanged;
  final Function(int) onPassScoreChanged;

  const ParameterAdjuster({
    super.key,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.typeAllocation,
    required this.passScore,
    required this.onDurationChanged,
    required this.onTotalQuestionsChanged,
    required this.onTypeAllocationChanged,
    required this.onPassScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '参数调整',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '考试时长',
          child: _SliderInput(
            value: durationMinutes.toDouble(),
            min: 10,
            max: 180,
            step: 5,
            unit: '分钟',
            onChanged: (value) => onDurationChanged(value.toInt()),
          ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: '题目数量 (共$totalQuestions题)',
          child: Column(
            children: [
              _TypeAllocationInput(
                label: '单选题',
                value: typeAllocation['single'] ?? 0,
                maxValue: 200,
                onChanged: (value) => onTypeAllocationChanged('single', value),
              ),
              const SizedBox(height: 12),
              _TypeAllocationInput(
                label: '多选题',
                value: typeAllocation['multiple'] ?? 0,
                maxValue: 100,
                onChanged: (value) => onTypeAllocationChanged('multiple', value),
              ),
              const SizedBox(height: 12),
              _TypeAllocationInput(
                label: '判断题',
                value: typeAllocation['judge'] ?? 0,
                maxValue: 100,
                onChanged: (value) => onTypeAllocationChanged('judge', value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: '及格分数',
          child: _SliderInput(
            value: passScore.toDouble(),
            min: 0,
            max: 100,
            step: 5,
            unit: '分',
            onChanged: (value) => onPassScoreChanged(value.toInt()),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SliderInput extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final Function(double) onChanged;

  const _SliderInput({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Text(
              '${value.toInt()}',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${min.toInt()}-$max.toInt()',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          activeColor: AppColors.primary,
          onChanged: (value) {
            // Snap to step
            final snappedValue = (value / step).round() * step;
            onChanged(snappedValue.clamp(min, max));
          },
        ),
      ],
    );
  }
}

class _TypeAllocationInput extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Function(int) onChanged;

  const _TypeAllocationInput({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: maxValue.toDouble(),
            divisions: maxValue,
            activeColor: AppColors.primary,
            onChanged: (value) {
              onChanged(value.toInt());
            },
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '$value题',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        // Increment/Decrement buttons
        _IconButton(
          icon: Icons.remove,
          onTap: value > 0 ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 4),
        _IconButton(
          icon: Icons.add,
          onTap: value < maxValue ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: onTap != null
          ? AppColors.primary.withValues(alpha: 0.1)
          : (isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface)
              .withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: onTap != null
                ? AppColors.primary
                : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary)
                    .withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
