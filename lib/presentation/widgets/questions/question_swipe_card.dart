import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/question.dart';
import '../../providers/config_provider.dart';

/// Question Swipe Card
/// Displays a single question in the swipe interface
class QuestionSwipeCard extends ConsumerStatefulWidget {
  final Question question;
  final String? selectedAnswer;
  final bool showResult;
  final ValueChanged<String>? onAnswerSelected;

  const QuestionSwipeCard({
    super.key,
    required this.question,
    this.selectedAnswer,
    this.showResult = false,
    this.onAnswerSelected,
  });

  @override
  ConsumerState<QuestionSwipeCard> createState() => _QuestionSwipeCardState();
}

class _QuestionSwipeCardState extends ConsumerState<QuestionSwipeCard> {
  String? _localSelectedAnswer;
  String? _currentQuestionId;

  @override
  void initState() {
    super.initState();
    // CRITICAL: Only initialize with selectedAnswer if:
    // 1. showResult is true (already answered)
    // 2. AND selectedAnswer is not null
    // For new questions, ALWAYS start with null to prevent inheritance
    if (widget.showResult && widget.selectedAnswer != null) {
      _localSelectedAnswer = widget.selectedAnswer;
    } else {
      _localSelectedAnswer = null;
    }
    _currentQuestionId = widget.question.id;
  }

  @override
  void didUpdateWidget(QuestionSwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // CRITICAL: When question changes, ALWAYS reset _localSelectedAnswer
    // unless we're showing a previously submitted answer
    if (widget.question.id != oldWidget.question.id) {
      setState(() {
        // Only preserve selectedAnswer if:
        // 1. showResult is true (question was already answered)
        // 2. AND selectedAnswer is not null
        // Otherwise, always reset to null to prevent inheritance
        if (widget.showResult && widget.selectedAnswer != null) {
          _localSelectedAnswer = widget.selectedAnswer;
        } else {
          _localSelectedAnswer = null;
        }
        _currentQuestionId = widget.question.id;
      });
      return;
    }

    // Same question: sync only if not showing result
    // This prevents clearing user's current selection
    if (!widget.showResult && widget.selectedAnswer != oldWidget.selectedAnswer) {
      setState(() {
        _localSelectedAnswer = widget.selectedAnswer;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsState = ref.watch(userSettingsProvider);
    final showExplanations = settingsState.settings?.showExplanations ?? true;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags row
              _buildTagsRow(context),
              const SizedBox(height: 16),

              // Question content (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image display (before question text)
                      if (widget.question.imageUrl != null && widget.question.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _QuestionImage(imageUrl: widget.question.imageUrl!),
                        ),

                      // Question text
                      Text(
                        widget.question.question,
                        style: AppTypography.headlineSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options or input based on question type
                      if (widget.question.isSingleChoice ||
                          widget.question.isMultipleChoice)
                        ..._buildOptions(context, isDark),

                      if (widget.question.isJudge)
                        _buildJudgeButtons(context, isDark),

                      if (widget.question.isFill || widget.question.isEssay)
                        _buildFillInput(context, isDark),

                      // Result display
                      if (widget.showResult) ...[
                        const SizedBox(height: 24),
                        _buildResultBanner(context, isDark),
                      ],

                      // Explanation (based on settings)
                      if (widget.showResult &&
                          showExplanations &&
                          widget.question.explanation != null &&
                          widget.question.explanation!.isNotEmpty)
                        _buildExplanationCard(context, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        // Display all categories
        ...widget.question.category.map((cat) => _CategoryBadge(category: cat)),
        _TypeBadge(type: widget.question.type, originalType: widget.question.originalType),
        if (widget.question.difficulty != null)
          _DifficultyBadge(level: widget.question.difficulty!),
      ],
    );
  }

  List<Widget> _buildOptions(BuildContext context, bool isDark) {
    final options = widget.question.options ?? [];
    final correctAnswers = widget.question.answer?.split('|') ?? [];

    return List.generate(options.length, (index) {
      final optionText = options[index];
      final optionLabel = String.fromCharCode(65 + index); // A, B, C, D...

      // Selection display logic:
      // - For answered questions (showResult=true): show all selections
      // - For new questions (showResult=false): only show if explicitly selected
      // This is checked by comparing with local state, which is reset on question change
      final isSelected = _localSelectedAnswer == optionLabel;
      final isCorrect = correctAnswers.contains(optionLabel);

      final isMulti = widget.question.isMultipleChoice;
      final selectedAnswers = _localSelectedAnswer?.split('|') ?? <String>[];
      final isMultiSelected = selectedAnswers.contains(optionLabel);

      return RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OptionCard(
            key: ValueKey('option_$index'), // Unique key for each option
            label: optionLabel,
            text: optionText,
            isSelected: isMulti ? isMultiSelected : isSelected,
            isCorrect: widget.showResult ? isCorrect : null,
            showResult: widget.showResult,
            isMultipleChoice: isMulti,
            onTap: widget.onAnswerSelected == null || widget.showResult
                ? null
                : () {
                  if (isMulti) {
                    final current = selectedAnswers.toList();
                    if (current.contains(optionLabel)) {
                      current.remove(optionLabel);
                    } else {
                      current.add(optionLabel);
                    }
                    current.sort();
                    setState(() {
                      _localSelectedAnswer = current.join('|');
                    });
                    widget.onAnswerSelected!(_localSelectedAnswer!);
                  } else {
                    setState(() {
                      _localSelectedAnswer = optionLabel;
                    });
                    widget.onAnswerSelected!(optionLabel);
                  }
                },
          ),
        ),
      );
    });
  }

  Widget _buildJudgeButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _JudgeButton(
            label: '正确',
            value: 'A',
            isSelected: _localSelectedAnswer == 'A',
            isCorrect: widget.showResult
                ? widget.question.answer?.toUpperCase() == 'A'
                : null,
            showResult: widget.showResult,
            onTap: widget.onAnswerSelected == null || widget.showResult
                ? null
                : () {
                    setState(() => _localSelectedAnswer = 'A');
                    widget.onAnswerSelected!('A');
                  },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _JudgeButton(
            label: '错误',
            value: 'B',
            isSelected: _localSelectedAnswer == 'B',
            isCorrect: widget.showResult
                ? widget.question.answer?.toUpperCase() == 'B'
                : null,
            showResult: widget.showResult,
            onTap: widget.onAnswerSelected == null || widget.showResult
                ? null
                : () {
                    setState(() => _localSelectedAnswer = 'B');
                    widget.onAnswerSelected!('B');
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildFillInput(BuildContext context, bool isDark) {
    return TextField(
      enabled: widget.onAnswerSelected != null && !widget.showResult,
      decoration: InputDecoration(
        hintText: '请输入答案',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
      ),
      onChanged: widget.onAnswerSelected == null || widget.showResult
          ? null
          : (value) {
              setState(() => _localSelectedAnswer = value);
              widget.onAnswerSelected!(value);
            },
    );
  }

  Widget _buildResultBanner(BuildContext context, bool isDark) {
    // For essay questions, show match percentage instead of correct/incorrect
    if (widget.question.isEssay) {
      return _buildEssayResultBanner(context, isDark);
    }

    final isCorrect = _checkIsCorrect();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? AppColors.success : AppColors.error,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? AppColors.success : AppColors.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCorrect ? '回答正确！' : '回答错误',
              style: AppTypography.titleMedium.copyWith(
                color: isCorrect ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '正确答案: ${widget.question.answer ?? '未知'}',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                softWrap: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEssayResultBanner(BuildContext context, bool isDark) {
    final matchResult = _calculateEssayMatch();

    // Determine color based on match percentage
    Color bannerColor;
    Color textColor;
    IconData icon;

    if (matchResult.percentage >= 80) {
      bannerColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      icon = Icons.check_circle;
    } else if (matchResult.percentage >= 50) {
      bannerColor = AppColors.warning.withValues(alpha: 0.1);
      textColor = AppColors.warning;
      icon = Icons.info;
    } else {
      bannerColor = AppColors.error.withValues(alpha: 0.1);
      textColor = AppColors.error;
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: textColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '匹配度: ${matchResult.percentage.toStringAsFixed(0)}%',
                      style: AppTypography.titleMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (matchResult.matchedCount > 0)
                      Text(
                        '匹配 ${matchResult.matchedCount}/${matchResult.totalCount} 个关键词',
                        style: AppTypography.bodyMedium.copyWith(
                          color: textColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.question.answer != null && widget.question.answer!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '参考答案',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.question.answer!,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
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

  /// Calculate essay answer match result
  ({int matchedCount, int totalCount, double percentage}) _calculateEssayMatch() {
    if (_localSelectedAnswer == null ||
        widget.question.answer == null ||
        widget.question.answer!.isEmpty) {
      return (matchedCount: 0, totalCount: 1, percentage: 0);
    }

    final correctAnswer = widget.question.answer!.toLowerCase();
    final userAnswerLower = _localSelectedAnswer!.toLowerCase();

    // Extract keywords from correct answer
    final keywords = correctAnswer
        .replaceAll(RegExp(r'[；;。、,．．\(\)（）\[\]【】]'), ' ')
        .split(' ')
        .where((w) => w.trim().length >= 2)
        .toSet();

    if (keywords.isEmpty) {
      return (matchedCount: 0, totalCount: 1, percentage: 0);
    }

    // Count matched keywords
    int matchedCount = 0;
    for (final keyword in keywords) {
      if (userAnswerLower.contains(keyword)) {
        matchedCount++;
      }
    }

    final percentage = (matchedCount / keywords.length) * 100;
    return (
      matchedCount: matchedCount,
      totalCount: keywords.length,
      percentage: percentage,
    );
  }

  Widget _buildExplanationCard(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '解析',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.question.explanation ?? '暂无解析',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  bool _checkIsCorrect() {
    if (_localSelectedAnswer == null) return false;
    if (widget.question.isSingleChoice || widget.question.isFill) {
      // Trim both answers to handle potential whitespace issues
      final trimmedUser = _localSelectedAnswer!.trim();
      final trimmedCorrect = widget.question.answer?.trim();
      final isCorrect = trimmedUser == trimmedCorrect;

      // Debug logging
      if (widget.question.isSingleChoice && !isCorrect) {
        print('❌ Single choice check failed for question: ${widget.question.id}');
        print('   User answer: "$_localSelectedAnswer" -> "$trimmedUser"');
        print('   Correct answer: "${widget.question.answer}" -> "$trimmedCorrect"');
      }

      return isCorrect;
    }
    if (widget.question.isMultipleChoice) {
      final userAnswers = _localSelectedAnswer!.split('|')..sort();
      final correctAnswers = widget.question.answer?.split('|') ?? []..sort();
      if (userAnswers.length != correctAnswers.length) return false;
      return userAnswers.every((a) => correctAnswers.contains(a));
    }
    if (widget.question.isJudge) {
      return _localSelectedAnswer!.toUpperCase() ==
          widget.question.answer?.toUpperCase();
    }
    if (widget.question.isEssay) {
      // Essay questions are auto-graded by keyword matching
      // This is handled by the submit_answer use case
      // For UI display purposes, we show the result based on what was submitted
      return false; // Actual scoring happens server-side in use case
    }
    return false;
  }
}

/// Option Card Widget
class _OptionCard extends StatefulWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool? isCorrect;
  final bool showResult;
  final bool isMultipleChoice;
  final VoidCallback? onTap;

  const _OptionCard({
    Key? key,
    required this.label,
    required this.text,
    required this.isSelected,
    this.isCorrect,
    required this.showResult,
    this.isMultipleChoice = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color borderColor;

    if (widget.showResult) {
      if (widget.isCorrect == true) {
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        borderColor = AppColors.success;
      } else if (widget.isSelected && widget.isCorrect == false) {
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        borderColor = AppColors.error;
      } else {
        backgroundColor = isDark ? AppColors.darkCard : Colors.white;
        borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      }
    } else {
      if (widget.isSelected) {
        backgroundColor = AppColors.primary.withValues(alpha: 0.1);
        borderColor = AppColors.primary;
      } else {
        backgroundColor = isDark ? AppColors.darkCard : Colors.white;
        borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Option label
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Option content
            Expanded(
              child: Text(
                widget.text,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            // Status icon
            if (widget.showResult && widget.isCorrect == true)
              Icon(Icons.check_circle, color: AppColors.success),
            if (widget.showResult &&
                widget.isSelected &&
                widget.isCorrect == false)
              Icon(Icons.cancel, color: AppColors.error),
            if (!widget.showResult && widget.isSelected)
              Icon(
                widget.isMultipleChoice
                    ? Icons.check_box
                    : Icons.radio_button_checked,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Judge Button Widget
class _JudgeButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final bool? isCorrect;
  final bool showResult;
  final VoidCallback? onTap;

  const _JudgeButton({
    required this.label,
    required this.value,
    required this.isSelected,
    this.isCorrect,
    required this.showResult,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color borderColor;
    Color? textColor;

    if (showResult) {
      if (isCorrect == true) {
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        borderColor = AppColors.success;
        textColor = AppColors.success;
      } else if (isSelected && isCorrect == false) {
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        borderColor = AppColors.error;
        textColor = AppColors.error;
      } else {
        backgroundColor = isDark ? AppColors.darkCard : Colors.white;
        borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      }
    } else {
      if (isSelected) {
        backgroundColor = AppColors.primary.withValues(alpha: 0.1);
        borderColor = AppColors.primary;
        textColor = AppColors.primary;
      } else {
        backgroundColor = isDark ? AppColors.darkCard : Colors.white;
        borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.titleLarge.copyWith(
              color: textColor ??
                  (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Category Badge
class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    // Category is already stored as Chinese, display directly
    return _Badge(
      label: category,
      color: AppColors.primary,
    );
  }
}

/// Type Badge
class _TypeBadge extends StatelessWidget {
  final String type;
  final String? originalType;

  const _TypeBadge({required this.type, this.originalType});

  @override
  Widget build(BuildContext context) {
    // Prefer original Chinese type name if available
    if (originalType != null && originalType!.isNotEmpty) {
      return _Badge(
        label: originalType!,
        color: AppColors.info,
      );
    }

    final typeNames = {
      'single': '单选',
      'multiple': '多选',
      'judge': '判断',
      'essay': '简答',
      'fill': '填空',
    };
    return _Badge(
      label: typeNames[type] ?? type,
      color: AppColors.info,
    );
  }
}

/// Difficulty Badge
class _DifficultyBadge extends StatelessWidget {
  final int level;

  const _DifficultyBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final labels = ['简单', '中等', '困难'];
    final colors = [
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];
    return _Badge(
      label: labels[level - 1],
      color: colors[level - 1],
    );
  }
}

/// Base Badge Widget
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
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
