import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/question_summary.dart';

/// Question List Item Widget
/// Displays a question summary in the list with badges and status
class QuestionListItem extends StatelessWidget {
  final QuestionSummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  const QuestionListItem({
    super.key,
    required this.summary,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isSelected, isDark),
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : Colors.transparent,
              width: 4,
            ),
            bottom: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: ID + badges + status icon
            _buildFirstRow(context),
            const SizedBox(height: 8),
            // Second row: Title
            _buildTitle(context),
            const SizedBox(height: 8),
            // Third row: Difficulty + wrong book icon
            _buildThirdRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstRow(BuildContext context) {
    return Row(
      children: [
        // Question ID
        Text(
          '#${summary.id}',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        // Category Badge
        _CategoryBadge(category: summary.category),
        const SizedBox(width: 4),
        // Type Badge
        _TypeBadge(type: summary.type),
        const Spacer(),
        // Status Icon
        _StatusIcon(
          hasAnswered: summary.hasAnswered,
          isCorrect: summary.isCorrect,
          wrongCount: summary.wrongCount,
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    final title = summary.title ?? '...';
    return Text(
      title,
      style: AppTypography.bodyMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildThirdRow(BuildContext context) {
    return Row(
      children: [
        if (summary.difficulty != null)
          _DifficultyBadge(level: summary.difficulty!),
        if (summary.inWrongBook) ...[
          const SizedBox(width: 8),
          const _WrongBookIcon(),
        ],
      ],
    );
  }

  Color _getBackgroundColor(bool isSelected, bool isDark) {
    if (isSelected) {
      return isDark
          ? AppColors.primary.withValues(alpha: 0.2)
          : AppColors.primary.withValues(alpha: 0.1);
    }
    return isDark ? AppColors.darkCard : Colors.white;
  }
}

/// Category Badge Widget
class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(category);

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colorMap = {
      'Java': AppColors.primary,
      'Python': const Color(0xFF388E3C),
      'JavaScript': const Color(0xFFF57C00),
      'Database': const Color(0xFF7B1FA2),
    };
    return colorMap[category] ?? AppColors.textSecondary;
  }
}

/// Type Badge Widget
class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final labelMap = {
      'single': '单选',
      'multiple': '多选',
      'judge': '判断',
      'fill': '填空',
    };
    final label = labelMap[type] ?? type;

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF424242)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isDark
              ? const Color(0xFFB3B3B3)
              : const Color(0xFF666666),
        ),
      ),
    );
  }
}

/// Difficulty Badge Widget
class _DifficultyBadge extends StatelessWidget {
  final int level;

  const _DifficultyBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = _getDifficultyColor(level);
    final label = _getDifficultyLabel(level);

    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_cellular_alt,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return AppColors.success; // Green for easy
      case 2:
        return AppColors.warning; // Orange for medium
      case 3:
        return AppColors.error; // Red for hard
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDifficultyLabel(int level) {
    switch (level) {
      case 1:
        return '简单';
      case 2:
        return '中等';
      case 3:
        return '困难';
      default:
        return '';
    }
  }
}

/// Status Icon Widget
class _StatusIcon extends StatelessWidget {
  final bool hasAnswered;
  final bool isCorrect;
  final int wrongCount;

  const _StatusIcon({
    required this.hasAnswered,
    required this.isCorrect,
    required this.wrongCount,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasAnswered) {
      return Icon(
        Icons.circle_outlined,
        size: 16,
        color: AppColors.textTertiary,
      );
    }

    if (isCorrect) {
      return Icon(
        Icons.check_circle,
        size: 16,
        color: AppColors.success,
      );
    }

    // Wrong answer - show error icon with count if > 1
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cancel,
          size: 16,
          color: AppColors.error,
        ),
        if (wrongCount > 1) ...[
          const SizedBox(width: 2),
          Text(
            '$wrongCount',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.error,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

/// Wrong Book Icon Widget
class _WrongBookIcon extends StatelessWidget {
  const _WrongBookIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.bookmark,
      size: 14,
      color: AppColors.warning,
    );
  }
}
