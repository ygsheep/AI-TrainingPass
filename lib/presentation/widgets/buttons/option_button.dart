import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/touch_targets.dart';

/// Option Button Widget
/// Used for selecting answer options in questions
class OptionButton extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final bool isMultipleChoice;
  final VoidCallback? onTap;

  const OptionButton({
    super.key,
    required this.label,
    required this.text,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
    this.isMultipleChoice = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine border and background colors based on state
    Color borderColor;
    Color backgroundColor;
    Color textColor;
    Color labelColor;

    if (showResult) {
      if (isCorrect) {
        borderColor = AppColors.success;
        backgroundColor = AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1);
        textColor = AppColors.success;
        labelColor = AppColors.success;
      } else if (isSelected) {
        borderColor = AppColors.error;
        backgroundColor = AppColors.error.withValues(alpha: isDark ? 0.2 : 0.1);
        textColor = AppColors.error;
        labelColor = AppColors.error;
      } else {
        borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        backgroundColor = Colors.transparent;
        textColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
        labelColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
      }
    } else if (isSelected) {
      borderColor = AppColors.primary;
      backgroundColor = AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1);
      textColor = AppColors.primary;
      labelColor = AppColors.primary;
    } else {
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      backgroundColor = Colors.transparent;
      textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
      labelColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TouchTargets.paddingMedium,
          vertical: TouchTargets.paddingMedium,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isSelected || showResult ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Option label (A, B, C, D, etc.)
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: labelColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Option text
            Expanded(
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: textColor,
                  fontWeight: isSelected || showResult
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            // Selection icon (when not showing result but is selected)
            if (!showResult && isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                isMultipleChoice ? Icons.check_box : Icons.radio_button_checked,
                color: AppColors.primary,
                size: 20,
              ),
            ],
            // Result icon
            if (showResult) ...[
              const SizedBox(width: 8),
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Multi-select Option Button
/// Used for multiple choice questions
class MultiOptionButton extends StatefulWidget {
  final String label;
  final String text;
  final Set<String> selectedOptions;
  final bool isCorrect;
  final bool showResult;
  final ValueChanged<bool> onTap;

  const MultiOptionButton({
    super.key,
    required this.label,
    required this.text,
    required this.selectedOptions,
    this.isCorrect = false,
    this.showResult = false,
    required this.onTap,
  });

  @override
  State<MultiOptionButton> createState() => _MultiOptionButtonState();
}

class _MultiOptionButtonState extends State<MultiOptionButton> {
  bool get isSelected => widget.selectedOptions.contains(widget.label);

  @override
  Widget build(BuildContext context) {
    return OptionButton(
      label: widget.label,
      text: widget.text,
      isSelected: isSelected,
      isCorrect: widget.isCorrect,
      showResult: widget.showResult,
      onTap: widget.showResult ? null : () => widget.onTap(!isSelected),
    );
  }
}
