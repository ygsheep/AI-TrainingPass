import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../domain/entities/question.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/touch_targets.dart';
import '../buttons/option_button.dart';

/// Question Card Widget
/// Displays a question with options for answering
class QuestionCard extends StatelessWidget {
  final Question question;
  final String? selectedAnswer;
  final String? correctAnswer;
  final bool showResult;
  final ValueChanged<String>? onAnswerSelected;
  final bool isReview;

  const QuestionCard({
    super.key,
    required this.question,
    this.selectedAnswer,
    this.correctAnswer,
    this.showResult = false,
    this.onAnswerSelected,
    this.isReview = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(TouchTargets.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(TouchTargets.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category and type badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                // Display all categories
                ...question.category.map((cat) => _CategoryBadge(category: cat)),
                _TypeBadge(type: question.type, originalType: question.originalType),
                if (question.difficulty != null) _DifficultyBadge(level: question.difficulty!),
              ],
            ),
            const SizedBox(height: TouchTargets.paddingMedium),

            // Image display (before question text)
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: TouchTargets.paddingMedium),
                child: _QuestionImage(imageUrl: question.imageUrl!),
              ),

            // Question text
            Text(
              question.question,
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: TouchTargets.paddingLarge),

            // Options
            if (question.options != null && question.options!.isNotEmpty)
              ...question.options!.asMap().entries.map((entry) {
                final index = entry.key;
                final optionText = entry.value;
                final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
                final answerKey = optionLabel;

                // For multiple choice, check if the answer contains this option
                final isMulti = question.isMultipleChoice;
                final isSelected = isMulti
                    ? (selectedAnswer?.split('|') ?? []).contains(answerKey)
                    : selectedAnswer == answerKey;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OptionButton(
                    label: optionLabel,
                    text: optionText,
                    isSelected: isSelected,
                    isCorrect: correctAnswer?.contains(answerKey) ?? false,
                    showResult: showResult,
                    isMultipleChoice: isMulti,
                    onTap: onAnswerSelected != null && !showResult
                        ? () => onAnswerSelected!(answerKey)
                        : null,
                  ),
                );
              }),

            // For fill-in-the-blank questions (deprecated, use isEssay)
            if (question.isFill && !isReview)
              Padding(
                padding: const EdgeInsets.only(top: TouchTargets.paddingMedium),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '请输入答案',
                    border: const OutlineInputBorder(),
                    enabled: !showResult,
                  ),
                  onChanged: onAnswerSelected,
                ),
              ),

            // For essay questions (简答题)
            if (question.isEssay && !isReview)
              Padding(
                padding: const EdgeInsets.only(top: TouchTargets.paddingMedium),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '请输入答案（关键词匹配评分）',
                    border: const OutlineInputBorder(),
                    enabled: !showResult,
                  ),
                  maxLines: 3,
                  onChanged: onAnswerSelected,
                ),
              ),


            // Explanation
            if (showResult && question.explanation != null && question.explanation!.isNotEmpty) ...[
              const SizedBox(height: TouchTargets.paddingLarge),
              Container(
                padding: const EdgeInsets.all(TouchTargets.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '解析',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.explanation!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Category Badge Widget
class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        category,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Type Badge Widget
class _TypeBadge extends StatelessWidget {
  final String type;
  final String? originalType;

  const _TypeBadge({required this.type, this.originalType});

  String get typeLabel {
    // 优先显示原始中文题型
    if (originalType != null) {
      return originalType!;
    }
    switch (type) {
      case 'single':
        return '单选';
      case 'multiple':
        return '多选';
      case 'judge':
        return '判断';
      case 'essay':
        return '简答';
      case 'fill':
        return '填空';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        typeLabel,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.info,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Question Image Widget
/// Displays Base64 encoded images from JSON data
class _QuestionImage extends StatelessWidget {
  final String imageUrl;

  const _QuestionImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    try {
      // Extract the Base64 data (format: "data:image/png;base64,iVBORw0KGgo...")
      final base64Data = imageUrl.split(',').last;
      final imageBytes = base64Decode(base64Data);

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          imageBytes,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _errorWidget();
          },
        ),
      );
    } catch (e) {
      return _errorWidget();
    }
  }

  Widget _errorWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            '图片加载失败',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Difficulty Badge Widget
class _DifficultyBadge extends StatelessWidget {
  final int level;

  const _DifficultyBadge({required this.level});

  String get label {
    switch (level) {
      case 1:
        return '简单';
      case 2:
        return '中等';
      case 3:
        return '困难';
      default:
        return '$level';
    }
  }

  Color get color {
    switch (level) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
