import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/touch_targets.dart';
import '../../widgets/questions/question_card.dart';
import '../../providers/wrong_book_provider.dart';

/// Wrong Question Detail Page
/// Shows detailed view of a wrong question with option to mark as mastered
class WrongQuestionDetailPage extends ConsumerWidget {
  final String id;

  const WrongQuestionDetailPage({
    super.key,
    required this.id,
  });

  Future<void> _markAsMastered(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(wrongBookProvider.notifier).markAsMastered(id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '已标记为已掌握' : '标记失败，请查看控制台'),
          duration: const Duration(seconds: 2),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      // Navigate back after marking
      if (success) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;

    final wrongQuestionAsync = ref.watch(wrongQuestionProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text('错题详情', style: TextStyle(color: textColor)),
        foregroundColor: textColor,
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          wrongQuestionAsync.when(
            data: (wrongQuestion) {
              if (wrongQuestion == null || wrongQuestion.mastered) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                onPressed: () => _markAsMastered(context, ref),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('标记掌握'),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: wrongQuestionAsync.when(
        data: (wrongQuestion) {
          if (wrongQuestion == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '未找到错题',
                    style: AppTypography.titleMedium,
                  ),
                ],
              ),
            );
          }

          final question = wrongQuestion.question;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(TouchTargets.paddingMedium),
            child: QuestionCard(
              question: question,
              correctAnswer: question.answer,
              showResult: true,
              isReview: true,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
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
    );
  }
}
