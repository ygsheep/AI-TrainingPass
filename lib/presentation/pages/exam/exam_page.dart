import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/touch_targets.dart';
import '../../../../core/constants/app_config.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/appbars/app_top_bar.dart';
import '../../widgets/questions/question_card.dart';
import '../../widgets/common/progress_bar.dart';
import '../../widgets/common/countdown_timer.dart';
import '../../widgets/common/score_display.dart';
import '../../widgets/exam/exam_question_list_dialog.dart';
import '../../providers/exam_provider.dart';
import '../../providers/question_provider.dart';
import '../../../../data/models/user_answer.dart';

/// Exam Page - Simplified version
class ExamPage extends ConsumerStatefulWidget {
  final int questionCount;
  final int durationMinutes;
  final String? category;
  final int? passScore;

  const ExamPage({
    super.key,
    this.questionCount = AppConfig.defaultExamQuestionCount,
    this.durationMinutes = AppConfig.defaultExamDurationMinutes,
    this.category,
    this.passScore = AppConfig.defaultPassScore,
  });

  @override
  ConsumerState<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends ConsumerState<ExamPage> {
  int _currentIndex = 0;
  String? _selectedAnswer;
  final Map<int, String> _answers = {};
  final Set<int> _answeredQuestions = {};
  bool _showResult = false;
  int? _finalScore;
  bool? _isPassed;
  int? _correctCount;  // Added to store actual correct count from result

  // Track time spent per question (in seconds)
  final Map<int, int> _questionTimeSpent = {};
  DateTime? _currentQuestionStartTime;

  // Getters that depend on examState are now computed in build method
  bool get _hasPrevious => _currentIndex > 0;

  Future<void> _startExam() async {
    AppLogger.debug('📝 _startExam: questionCount=${widget.questionCount}');
    final started = await ref.read(activeExamProvider.notifier).startExam(
          questionCount: widget.questionCount,
        );

    // If started successfully, update config to match widget params
    if (started) {
      AppLogger.debug('📝 Exam started, updating config: duration=${widget.durationMinutes}');
      ref.read(activeExamProvider.notifier).updateConfig(
            duration: widget.durationMinutes,
            passScore: widget.passScore ?? 60,
          );
    } else {
      AppLogger.debug('❌ Failed to start exam');
    }
  }

  void _selectAnswer(String answer) {
    final examState = ref.read(activeExamProvider);
    if (examState == null) return;

    final question = examState.questions[_currentIndex];
    String newAnswer;

    if (question.isMultipleChoice) {
      // 多选题：支持多选，用 | 分隔
      final currentAnswers = _selectedAnswer?.split('|') ?? [];
      if (currentAnswers.contains(answer)) {
        // 取消选择
        newAnswer = currentAnswers.where((a) => a != answer).join('|');
      } else {
        // 添加选择
        final newAnswers = [...currentAnswers, answer]..sort();
        newAnswer = newAnswers.join('|');
      }
    } else {
      // 单选题和其他题型：直接替换
      newAnswer = answer;
    }

    setState(() {
      _selectedAnswer = newAnswer.isEmpty ? null : newAnswer;
      if (_selectedAnswer != null) {
        _answers[_currentIndex] = _selectedAnswer!;
        _answeredQuestions.add(_currentIndex);
      } else {
        _answers.remove(_currentIndex);
        _answeredQuestions.remove(_currentIndex);
      }
    });
  }

  void _goToNext() {
    final examState = ref.read(activeExamProvider);
    if (examState != null && _currentIndex < examState.questions.length - 1) {
      // Record time spent on current question before moving
      _recordCurrentQuestionTime();

      setState(() {
        _currentIndex++;
        _selectedAnswer = _answers[_currentIndex];
        _currentQuestionStartTime = DateTime.now();
      });
    }
  }

  void _goToPrevious() {
    if (_hasPrevious) {
      // Record time spent on current question before moving
      _recordCurrentQuestionTime();

      setState(() {
        _currentIndex--;
        _selectedAnswer = _answers[_currentIndex];
        _currentQuestionStartTime = DateTime.now();
      });
    }
  }

  /// Record time spent on current question
  void _recordCurrentQuestionTime() {
    if (_currentQuestionStartTime != null) {
      final duration = DateTime.now().difference(_currentQuestionStartTime!);
      _questionTimeSpent[_currentIndex] = (_questionTimeSpent[_currentIndex] ?? 0) + duration.inSeconds;
    }
  }

  void _goToQuestion(int index) {
    final examState = ref.read(activeExamProvider);
    if (examState != null && index >= 0 && index < examState.questions.length) {
      // Record time spent on current question before jumping
      if (index != _currentIndex) {
        _recordCurrentQuestionTime();
      }

      setState(() {
        _currentIndex = index;
        _selectedAnswer = _answers[_currentIndex];
        _currentQuestionStartTime = DateTime.now();
      });
    }
  }

  void _showQuestionList() {
    ExamQuestionListDialog.show(
      context: context,
      currentIndex: _currentIndex,
      totalCount: widget.questionCount,
      answeredIndices: _answeredQuestions,
      onQuestionSelected: _goToQuestion,
      onSubmit: _submitExam,
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出考试'),
        content: const Text('确定要退出考试吗？当前进度将不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定退出'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      // Clear exam state before exiting
      ref.read(activeExamProvider.notifier).endExam();
      context.go('/');
    }
  }

  Future<void> _submitExam() async {
    final examState = ref.read(activeExamProvider);
    if (examState == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提交试卷'),
        content: Text(
          '已完成 ${_answeredQuestions.length}/${examState.questions.length} 道题\n\n'
          '确定要提交试卷吗？提交后无法修改答案。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认提交'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Record time for current question before submitting
    _recordCurrentQuestionTime();

    AppLogger.debug('📝 Submitting exam: ${examState.questions.length} questions');

    // Set submitting state to show loading indicator
    ref.read(activeExamProvider.notifier).state = examState.copyWith(
      isSubmitting: true,
    );

    // Convert local answers map to UserAnswerModel list
    final userAnswers = <UserAnswerModel>[];
    for (int i = 0; i < examState.questions.length; i++) {
      final question = examState.questions[i];
      final userAnswer = _answers[i];

      if (userAnswer != null) {
        final isCorrect = userAnswer == question.answer;
        userAnswers.add(UserAnswerModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          questionId: question.id,
          userAnswer: userAnswer,
          isCorrect: isCorrect,
          timeSpent: _questionTimeSpent[i] ?? 0,
          answeredAt: DateTime.now(),
        ));
      }
    }

    // Update exam state with answers before submitting
    ref.read(activeExamProvider.notifier).state = examState.copyWith(
      answers: userAnswers,
    );

    // Submit exam using the provider (this saves to history)
    // Note: submitExam() will set isSubmitting internally
    final result = await ref.read(activeExamProvider.notifier).submitExam();

    if (result != null && result.success) {
      AppLogger.debug('✅ Exam submitted successfully: ${result.score} points, passed=${result.passed}');

      setState(() {
        _showResult = true;
        _finalScore = result.score;
        _isPassed = result.passed;
        _correctCount = result.correctCount;  // Store correct count from result
      });
    } else {
      AppLogger.debug('❌ Exam submission failed: ${result?.error ?? "Unknown error"}');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：${result?.error ?? "未知错误"}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final examState = ref.watch(activeExamProvider);

    // Debug: Log when exam state changes
    AppLogger.debug('📝 ExamPage.build: examState=${examState != null ? "EXISTS (${examState!.questions.length} questions)" : "NULL"}');

    // If no exam state, wait for it to be set by exam setup
    // DO NOT start emergency exam as it will override the properly configured exam
    if (examState == null) {
      // Show loading while waiting for exam state
      return Scaffold(
        appBar: AppTopBar(
          automaticallyImplyLeading: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载考试...'),
              SizedBox(height: 8),
              Text(
                '如果没有自动跳转，请返回考试设置页面重新开始',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Debug: Log received questions on first build
    if (_currentIndex == 0 && _answeredQuestions.isEmpty && _selectedAnswer == null) {
      // Initialize start time for first question
      _currentQuestionStartTime = DateTime.now();

      AppLogger.debug('📋 ExamPage displaying ${examState.questions.length} questions:');
      for (int i = 0; i < examState.questions.length && i < 30; i++) {
        final q = examState.questions[i];
        AppLogger.debug('  [$i] type=${q.type}, originalType=${q.originalType ?? 'N/A'}');
      }
    }

    return PopScope(
      canPop: _showResult, // Allow back button only when showing result
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !_showResult) {
          // Prevent default back navigation and show confirmation
          await _confirmExit(context);
        }
      },
      child: Scaffold(
        appBar: AppTopBar(
          automaticallyImplyLeading: _showResult,
          leading: _showResult
              ? null
              : null, // Disable default back button during exam
          actions: [
            // Exit button
            if (!_showResult && !examState.isSubmitting)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => _confirmExit(context),
                tooltip: '退出考试',
              ),
            // Question list button
            if (!_showResult && !examState.isSubmitting)
              IconButton(
                icon: const Icon(Icons.grid_view_rounded),
                onPressed: _showQuestionList,
                tooltip: '答题情况',
              ),
          ],
        ),
        body: Stack(
          children: [
            _showResult
              ? _ExamResultScreen(
                  score: _finalScore ?? 0,
                  totalScore: 100,
                  correctCount: _correctCount ?? 0,
                  totalCount: widget.questionCount,
                  isPassed: _isPassed ?? false,
                  onBack: () {
                    ref.read(activeExamProvider.notifier).endExam();
                    context.go('/');
                  },
                )
              : Column(
                  children: [
                    // Timer and progress
                    Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TouchTargets.paddingMedium,
                    vertical: TouchTargets.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CountdownTimer(
                          duration: Duration(minutes: examState.duration),
                          onTimeUp: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '已答：${_answeredQuestions.length}/${examState.questions.length}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TouchTargets.paddingMedium,
                    vertical: TouchTargets.paddingSmall,
                  ),
                  child: ProgressBar(
                    progress: (_currentIndex + 1) / examState.questions.length,
                    current: _currentIndex + 1,
                    total: examState.questions.length,
                  ),
                ),
                Expanded(
                  child: examState.questions.isEmpty
                      ? const Center(child: Text('题目为空'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(TouchTargets.paddingMedium),
                          child: QuestionCard(
                            key: ValueKey(examState.questions[_currentIndex].id),
                            question: examState.questions[_currentIndex],
                            selectedAnswer: _selectedAnswer,
                            showResult: false,
                            onAnswerSelected: _selectAnswer,
                          ),
                        ),
                ),
                _BottomControls(
                  currentIndex: _currentIndex,
                  totalCount: examState.questions.length,
                  answeredQuestions: _answeredQuestions,
                  hasNext: _currentIndex < examState.questions.length - 1,
                  hasPrevious: _hasPrevious,
                  hasAnswered: _answeredQuestions.contains(_currentIndex),
                  onNext: _goToNext,
                  onPrevious: _goToPrevious,
                  onSubmit: _submitExam,
                ),
              ],
            ),
            // Loading overlay when submitting
            if (examState.isSubmitting && !_showResult)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '正在提交试卷...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExamResultScreen extends StatelessWidget {
  final int score;
  final int totalScore;
  final int correctCount;
  final int totalCount;
  final bool isPassed;
  final VoidCallback onBack;

  const _ExamResultScreen({
    required this.score,
    required this.totalScore,
    required this.correctCount,
    required this.totalCount,
    required this.isPassed,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TouchTargets.paddingLarge),
          child: Column(
            children: [
              ScoreDisplay(
                score: score,
                totalScore: totalScore,
                correctCount: correctCount,
                totalCount: totalCount,
                isPassed: isPassed,
              ),
              const SizedBox(height: 48),
              Text(
                isPassed ? '恭喜通过！' : '再接再厉！',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('返回首页'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, TouchTargets.minimumSize),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final Set<int> answeredQuestions;
  final bool hasNext;
  final bool hasPrevious;
  final bool hasAnswered;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Future<void> Function() onSubmit;

  const _BottomControls({
    required this.currentIndex,
    required this.totalCount,
    required this.answeredQuestions,
    required this.hasNext,
    required this.hasPrevious,
    required this.hasAnswered,
    required this.onNext,
    required this.onPrevious,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(TouchTargets.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasPrevious ? onPrevious : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('上一题'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, TouchTargets.minimumSize),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasNext
                    ? onNext
                    : () async {
                        // Prevent multiple submissions
                        // Note: In production, you'd want to add loading state
                        await onSubmit();
                      },
                icon: Icon(hasNext ? Icons.arrow_forward : Icons.check_rounded),
                label: Text(hasNext ? '下一题' : '提交试卷'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasNext ? AppColors.primary : AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, TouchTargets.minimumSize),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
