import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/exam_config.dart';

/// Template Selection Card
class TemplateCard extends StatelessWidget {
  final ExamTemplate template;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const TemplateCard({
    super.key,
    required this.template,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title: $subtitle',
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
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
                // Icon and selected indicator
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : (isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightSurface)
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary)
                                .withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '已选',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Template Selector - Horizontal scrollable list
class TemplateSelector extends StatelessWidget {
  final ExamTemplate selectedTemplate;
  final Function(ExamTemplate) onTemplateSelected;

  const TemplateSelector({
    super.key,
    required this.selectedTemplate,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '考试模板',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            // Ensure the ListView takes available width
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                width: 280,
                child: TemplateCard(
                  template: ExamTemplate.standard,
                  title: '标准考试',
                  subtitle: '90分钟 · 100题',
                  icon: Icons.timer_outlined,
                  isSelected: selectedTemplate == ExamTemplate.standard,
                  onTap: () => onTemplateSelected(ExamTemplate.standard),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 280,
                child: TemplateCard(
                  template: ExamTemplate.quick,
                  title: '快速测试',
                  subtitle: '30分钟 · 30题',
                  icon: Icons.flash_on_outlined,
                  isSelected: selectedTemplate == ExamTemplate.quick,
                  onTap: () => onTemplateSelected(ExamTemplate.quick),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 280,
                child: TemplateCard(
                  template: ExamTemplate.practice,
                  title: '练习模式',
                  subtitle: '60分钟 · 50题',
                  icon: Icons.edit_outlined,
                  isSelected: selectedTemplate == ExamTemplate.practice,
                  onTap: () => onTemplateSelected(ExamTemplate.practice),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 280,
                child: TemplateCard(
                  template: ExamTemplate.custom,
                  title: '自定义',
                  subtitle: '自由配置参数',
                  icon: Icons.tune_outlined,
                  isSelected: selectedTemplate == ExamTemplate.custom,
                  onTap: () => onTemplateSelected(ExamTemplate.custom),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
