import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/question_provider.dart';
import '../../providers/practice_swipe_provider.dart';

/// Category Selection Page
/// Allows users to select a category for practice
class CategorySelectPage extends ConsumerWidget {
  final String? title;
  final String? subtitle;
  final String? mode;

  const CategorySelectPage({
    super.key,
    this.title,
    this.subtitle,
    this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(questionBankProvider).categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? '选择分类'),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (subtitle != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Text(
                subtitle!,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
          ],
          ...categories.map((category) => _CategoryTile(
                category: category,
                onTap: () => _selectCategory(context, ref, category),
              )),
          const SizedBox(height: 16),
          // "All Categories" option
          _CategoryTile(
            category: 'all',
            onTap: () => _selectCategory(context, ref, 'all'),
          ),
        ],
      ),
    );
  }

  void _selectCategory(BuildContext context, WidgetRef ref, String category) {
    // Load questions for the selected category
    ref.read(practiceSwipeProvider.notifier).loadInitialBatch(
      category: category,
      pageSize: 50,
    );

    // Navigate to practice swipe page with mode parameter
    final modeParam = mode == 'random' ? '&mode=random' : '';
    context.push('/practice-swipe?category=$category$modeParam');
  }
}

/// Category Tile Widget
class _CategoryTile extends StatelessWidget {
  final String category;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Display Chinese category names directly, with predefined mapping for 'all'
    final displayNames = {
      'all': '全部题目',
    };

    // Predefined icons and colors for common categories
    final icons = {
      'all': Icons.apps,
      '理论知识': Icons.school,
      '机器学习': Icons.psychology,
      '深度学习': Icons.auto_awesome,
      '自然语言处理': Icons.chat,
      '数据标注': Icons.edit_note,
      '算法': Icons.functions,
      '计算机视觉': Icons.visibility,
      '职业道德': Icons.verified_user,
    };

    final colors = {
      'all': AppColors.primary,
      '理论知识': AppColors.info,
      '机器学习': AppColors.warning,
      '深度学习': AppColors.error,
      '自然语言处理': AppColors.primary,
      '数据标注': AppColors.success,
      '算法': AppColors.info,
      '计算机视觉': AppColors.warning,
      '职业道德': AppColors.success,
    };

    // Get display name - use Chinese directly or fallback to predefined
    final displayName = displayNames[category] ?? category;
    final icon = icons[category] ?? _getDynamicIcon(category);
    final color = colors[category] ?? _getDynamicColor(category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Category name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category == 'all' ? '所有分类的题目' : '点击开始练习',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDynamicIcon(String category) {
    final iconList = [
      Icons.category,
      Icons.book,
      Icons.science,
      Icons.computer,
      Icons.analytics,
      Icons.query_stats,
      Icons.smart_toy,
      Icons.lightbulb,
    ];
    final hash = category.hashCode;
    return iconList[hash.abs() % iconList.length];
  }

  Color _getDynamicColor(String category) {
    final colorList = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];
    final hash = category.hashCode;
    return colorList[hash.abs() % colorList.length];
  }
}
