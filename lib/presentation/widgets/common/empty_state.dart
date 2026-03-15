import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Empty State Widget
/// Displays when there's no data to show
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateType type;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.type = EmptyStateType.general,
  });

  /// Empty state for wrong questions
  factory EmptyState.noWrongQuestions({VoidCallback? onPractice}) {
    return EmptyState(
      type: EmptyStateType.success,
      icon: Icons.check_circle_outline_rounded,
      title: '太棒了！',
      subtitle: '你还没有错题，继续保持！',
      actionLabel: '去练习',
      onAction: onPractice,
    );
  }

  /// Empty state for exam history
  factory EmptyState.noExamHistory({VoidCallback? onStartExam}) {
    return EmptyState(
      type: EmptyStateType.info,
      icon: Icons.quiz_outlined,
      title: '暂无考试记录',
      subtitle: '开始第一次模拟考试吧',
      actionLabel: '开始考试',
      onAction: onStartExam,
    );
  }

  /// Empty state for question bank
  factory EmptyState.noQuestions({VoidCallback? onImport}) {
    return EmptyState(
      type: EmptyStateType.warning,
      icon: Icons.folder_open_rounded,
      title: '题库为空',
      subtitle: '请先导入题目数据',
      actionLabel: '导入题库',
      onAction: onImport,
    );
  }

  /// Empty state for search results
  const EmptyState.noSearchResults({
    super.key,
    this.title = '未找到结果',
    this.subtitle = '试试其他搜索条件',
  }) : type = EmptyStateType.general,
       icon = Icons.search_off_rounded,
       actionLabel = null,
       onAction = null;

  /// Empty state for network error
  const EmptyState.networkError({
    super.key,
    VoidCallback? onRetry,
  }) : type = EmptyStateType.error,
       icon = Icons.wifi_off_rounded,
       title = '网络连接失败',
       subtitle = '请检查网络设置后重试',
       actionLabel = '重试',
       onAction = onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayIcon = icon ?? _getDefaultIcon();
    final displayColor = _getColor();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: isDark ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                displayIcon,
                size: 40,
                color: displayColor,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: displayColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case EmptyStateType.success:
        return Icons.check_circle_outline_rounded;
      case EmptyStateType.error:
        return Icons.error_outline_rounded;
      case EmptyStateType.warning:
        return Icons.warning_amber_rounded;
      case EmptyStateType.info:
        return Icons.info_outline_rounded;
      case EmptyStateType.general:
        return Icons.inbox_rounded;
    }
  }

  Color _getColor() {
    switch (type) {
      case EmptyStateType.success:
        return AppColors.success;
      case EmptyStateType.error:
        return AppColors.error;
      case EmptyStateType.warning:
        return AppColors.warning;
      case EmptyStateType.info:
        return AppColors.primary;
      case EmptyStateType.general:
        return AppColors.textSecondary;
    }
  }
}

enum EmptyStateType {
  general,
  success,
  error,
  warning,
  info,
}

/// Empty State with Illustration
/// For more visual empty states
class EmptyStateIllustration extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String illustrationAsset;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateIllustration({
    super.key,
    required this.title,
    this.subtitle,
    required this.illustrationAsset,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Image.asset(
              illustrationAsset,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline Empty State
/// Smaller version for use in cards/lists
class InlineEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onAction;

  const InlineEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 32,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                child: const Text('刷新'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading State Placeholder
/// Shows while content is being loaded
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(),
          ),
          SizedBox(height: 16),
          Text('加载中...'),
        ],
      ),
    );
  }
}
