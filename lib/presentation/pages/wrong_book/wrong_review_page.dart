import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/touch_targets.dart';
import '../../widgets/questions/question_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../providers/wrong_book_provider.dart';

/// Wrong Review Page
/// Review wrong questions in a swipe-like interface
class WrongReviewPage extends ConsumerStatefulWidget {
  final String? category;

  const WrongReviewPage({
    super.key,
    this.category,
  });

  @override
  ConsumerState<WrongReviewPage> createState() => _WrongReviewPageState();
}

class _WrongReviewPageState extends ConsumerState<WrongReviewPage> {
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _isLoading = true;
  final List<dynamic> _questions = [];
  final List<String> _wrongQuestionIds = [];
  bool _showQuestionList = false;

  @override
  void initState() {
    super.initState();
    // Load questions after first frame to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });

    final provider = ref.read(wrongBookProvider.notifier);

    // Load all wrong questions for review (not mastered ones)
    // Pass limit: null to load all questions instead of paginated
    await provider.loadWrongQuestions(
      category: widget.category == '全部' ? null : widget.category,
      masteredOnly: false,
      limit: null, // Load all questions for review
    );

    // Get the updated state
    final updatedState = ref.read(wrongBookProvider);
    final wrongQuestions = updatedState.questions;

    // Extract questions and their IDs
    for (final wq in wrongQuestions) {
      // Skip mastered questions in review mode
      if (wq.mastered) continue;
      _questions.add(wq.question);
      _wrongQuestionIds.add(wq.id); // Use WrongQuestion.id, not questionId
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswer = answer;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _questions.isEmpty) return;

    final currentQuestion = _questions[_currentIndex];
    final wrongQuestionId = _wrongQuestionIds[_currentIndex];
    final isCorrect = _selectedAnswer == currentQuestion.answer;

    // Record the review attempt
    ref.read(wrongBookProvider.notifier).addReviewAttempt(
      wrongQuestionId: wrongQuestionId,
      wasCorrect: isCorrect,
    );

    // Move to next question or complete
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      // Review complete - navigate back
      if (mounted) {
        context.pop();
        // Show completion message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('复习完成！'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedAnswer = null;
      });
    }
  }

  void _goToQuestion(int index) {
    setState(() {
      _currentIndex = index;
      _selectedAnswer = null;
      _showQuestionList = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('复习错题', style: TextStyle(color: textColor)),
          foregroundColor: textColor,
          backgroundColor: bgColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('复习错题', style: TextStyle(color: textColor)),
          foregroundColor: textColor,
          backgroundColor: bgColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: EmptyState(
          title: '没有需要复习的错题',
          subtitle: '继续加油！',
          icon: Icons.check_circle_outline_rounded,
          onAction: () => context.pop(),
          actionLabel: '返回',
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('复习错题 (${_currentIndex + 1}/${_questions.length})', style: TextStyle(color: textColor)),
        foregroundColor: textColor,
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          // Question list button (icon only)
          IconButton(
            icon: const Icon(Icons.list_rounded),
            tooltip: '题目列表',
            onPressed: () {
              setState(() {
                _showQuestionList = true;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(TouchTargets.paddingMedium),
                  child: QuestionCard(
                    question: currentQuestion,
                    selectedAnswer: _selectedAnswer,
                    correctAnswer: currentQuestion.answer,
                    showResult: _selectedAnswer != null,
                    onAnswerSelected: _selectAnswer,
                  ),
                ),
              ),
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(TouchTargets.paddingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurface
                      : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Previous button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _currentIndex > 0 ? _goToPrevious : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('上一题'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next/Submit button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedAnswer != null ? _submitAnswer : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: _selectedAnswer != null
                              ? AppColors.primary
                              : null,
                          foregroundColor: _selectedAnswer != null
                              ? Colors.white
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentIndex < _questions.length - 1 ? '下一题' : '完成复习',
                            ),
                            if (_selectedAnswer != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Question list drawer
          if (_showQuestionList)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showQuestionList = false;
                });
              },
              child: Container(
                color: Colors.black54,
                child: _buildQuestionListSheet(isDark, textColor, bgColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionListSheet(bool isDark, Color textColor, Color bgColor) {
    return GestureDetector(
      onTap: () {}, // Prevent closing when tapping on the sheet
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '题目列表',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showQuestionList = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Question list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    final question = _questions[index];
                    return Card(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? BorderSide(color: AppColors.primary, width: 2)
                            : BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkSurface
                                  : Colors.grey[300]),
                          foregroundColor: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          question.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? AppColors.primary
                                : textColor,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => _goToQuestion(index),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
