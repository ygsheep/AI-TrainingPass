import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/touch_targets.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/appbars/app_top_bar.dart';
import '../../widgets/exam/template_selector.dart';
import '../../widgets/exam/source_card.dart';
import '../../widgets/exam/parameter_adjuster.dart';
import '../../widgets/exam/exam_summary.dart';
import '../../providers/exam_setup_provider.dart';
import '../../providers/exam_provider.dart';

/// Exam Setup Page
/// Configure exam settings before starting
class ExamSetupPage extends ConsumerStatefulWidget {
  const ExamSetupPage({super.key});

  @override
  ConsumerState<ExamSetupPage> createState() => _ExamSetupPageState();
}

class _ExamSetupPageState extends ConsumerState<ExamSetupPage> {
  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(examSetupProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final router = GoRouter.of(context);

    ref.listen<ExamSetupState>(examSetupProvider, (previous, next) {
      // Navigate to exam page when exam starts successfully (only if examStartSuccess is true)
      if (previous?.isStartingExam == true && next.isStartingExam == false && next.examStartSuccess) {
        // Exam started successfully, navigate with parameters
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Navigate with exam parameters as query params
          // This ensures the exam page gets the correct config even if provider state is lost
          final params = '?duration=${next.durationMinutes}'
              '&questions=${next.totalQuestions}'
              '&passScore=${next.passScore}';
          router.go('/exam$params');
          AppLogger.debug('✅ ExamSetup: Navigating to /exam$params with ${next.durationMinutes}min, ${next.totalQuestions}questions');
        });
      }
    });

    return Scaffold(
      appBar: AppTopBar(
        title: '考试设置',
        automaticallyImplyLeading: true,
        actions: [
          // Start exam button in app bar
          Padding(
            padding: const EdgeInsets.only(right: TouchTargets.paddingMedium),
            child: FilledButton.icon(
              onPressed: setupState.isLoading ||
                      setupState.isStartingExam ||
                      !setupState.isValid
                  ? null
                  : _handleStartExam,
              icon: setupState.isStartingExam
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('开始考试'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(100, TouchTargets.minimumSize),
              ),
            ),
          ),
        ],
      ),
      body: setupState.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width < Breakpoints.tablet
                    ? TouchTargets.paddingMedium
                    : TouchTargets.paddingLarge,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use constrained box on larger screens
                  final child = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Template Selector
                      TemplateSelector(
                        selectedTemplate: setupState.selectedTemplate,
                        onTemplateSelected: (template) {
                          ref
                              .read(examSetupProvider.notifier)
                              .selectTemplate(template);
                        },
                      ),
                      const SizedBox(height: 32),

                      // Source Selection
                      Text(
                        '题库来源',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...setupState.sourceStatistics.entries.map((entry) {
                        final source = entry.key;
                        final stats = entry.value;
                        final isSelected =
                            setupState.selectedSources.contains(source);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SourceCard(
                            statistics: stats,
                            isSelected: isSelected,
                            onTap: () {
                              ref
                                  .read(examSetupProvider.notifier)
                                  .toggleSource(source);
                            },
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 32),

                      // Parameter Adjuster
                      ParameterAdjuster(
                        durationMinutes: setupState.durationMinutes,
                        totalQuestions: setupState.totalQuestions,
                        typeAllocation: setupState.typeAllocation,
                        passScore: setupState.passScore,
                        onDurationChanged: (value) {
                          ref
                              .read(examSetupProvider.notifier)
                              .updateDuration(value);
                        },
                        onTotalQuestionsChanged: (value) {
                          ref
                              .read(examSetupProvider.notifier)
                              .updateTotalQuestions(value);
                        },
                        onTypeAllocationChanged: (type, count) {
                          ref
                              .read(examSetupProvider.notifier)
                              .updateTypeAllocation(type, count);
                        },
                        onPassScoreChanged: (value) {
                          ref
                              .read(examSetupProvider.notifier)
                              .updatePassScore(value);
                        },
                      ),
                      const SizedBox(height: 32),

                      // Summary
                      ExamSummary(
                        totalAvailable: setupState.totalAvailableQuestions,
                        availableByType: setupState.availableByType,
                        requiredTotal: setupState.totalQuestions,
                        requiredByType: setupState.typeAllocation,
                        validationError: setupState.validationError,
                        isStarting: setupState.isStartingExam,
                      ),
                      const SizedBox(height: 24),

                      // Start button (for mobile, below summary)
                      if (constraints.maxWidth < Breakpoints.tablet)
                        StartExamButton(
                          isValid: setupState.isValid,
                          isLoading: setupState.isStartingExam,
                          onPressed: _handleStartExam,
                        ),
                    ],
                  );

                  // Constrain width on larger screens
                  if (constraints.maxWidth >= Breakpoints.desktop) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: Breakpoints.maxContentWidth,
                        ),
                        child: child,
                      ),
                    );
                  }

                  return child;
                },
              ),
            ),
    );
  }

  Future<void> _handleStartExam() async {
    final success = await ref.read(examSetupProvider.notifier).startExam();

    if (!success && mounted) {
      // Show error snackbar
      final state = ref.read(examSetupProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.validationError ?? '启动考试失败'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: '关闭',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}
