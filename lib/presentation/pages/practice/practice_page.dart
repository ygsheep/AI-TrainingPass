import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/question_provider.dart';
import '../../providers/practice_swipe_provider.dart';
import '../../providers/wrong_book_provider.dart';

/// Practice Page - Entry point for practice modes
/// Swiss Modernism design with clean grid layout and statistics
class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionBank = ref.watch(questionBankProvider);
    final wrongBookState = ref.watch(wrongBookProvider);

    // 统计各题型数量
    final singleChoiceCount = questionBank.questions.where((q) => q.type == 'single').length;
    final multipleChoiceCount = questionBank.questions.where((q) => q.type == 'multiple').length;
    final judgeCount = questionBank.questions.where((q) => q.type == 'judge').length;
    final essayCount = questionBank.questions.where((q) => q.type == 'essay').length;

    final totalQuestions = questionBank.questions.length;
    final wrongQuestionCount = wrongBookState.totalCount;
    final masteredWrongCount = wrongBookState.questions
        .where((q) => q.mastered)
        .length;

    // 获取已做题目数量（需要从 repository 获取答案数据）
    final answeredCount = _getAnsweredCount(ref);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with transparent background
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
              title: Text(
                '练习模式',
                style: AppTypography.headlineSmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Stats Summary Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkCard
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: '总题数',
                      value: '$totalQuestions',
                      icon: Icons.quiz,
                      color: AppColors.primary,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    _StatItem(
                      label: '错题',
                      value: '$wrongQuestionCount',
                      icon: Icons.bookmark,
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                '快速练习',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Quick Practice Cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: _getChildAspectRatio(context),
              ),
              delegate: SliverChildListDelegate([
                // 随机练习 - Random Practice
                _PracticeModeCard(
                  title: '随机练习',
                  description: '随机抽取题目进行练习',
                  icon: Icons.shuffle,
                  color: AppColors.warning,
                  stats: _PracticeStats(
                    total: totalQuestions,
                    completed: answeredCount,
                    label: '已做',
                  ),
                  onTap: () => _navigateToRandomPractice(context, ref),
                ),

                // 错题练习 - Wrong Questions Only
                _PracticeModeCard(
                  title: '错题练习',
                  description: '重点练习错题本中的题目',
                  icon: Icons.bookmark_outline,
                  color: AppColors.error,
                  stats: _PracticeStats(
                    total: wrongQuestionCount,
                    completed: masteredWrongCount,
                    label: '已掌握',
                  ),
                  onTap: () => _navigateToWrongPractice(context),
                  isEmpty: wrongQuestionCount == 0,
                  emptyMessage: '暂无错题',
                ),
              ]),
            ),
          ),

          // Category Practice Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                '分类练习',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Category Selection
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _CategoryGrid(
                categories: questionBank.categories,
                ref: ref,
              ),
            ),
          ),

          // Question Type Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                '题型练习',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Question Type Cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getQuestionTypeCrossAxisCount(context),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: _getQuestionTypeAspectRatio(context),
              ),
              delegate: SliverChildListDelegate([
                // 单选题
                _QuestionTypeCard(
                  title: '单选题',
                  description: '只有一个正确答案',
                  icon: Icons.radio_button_checked,
                  color: AppColors.primary,
                  count: singleChoiceCount,
                  onTap: () => _navigateToTypePractice(context, ref, 'single'),
                ),

                // 多选题
                _QuestionTypeCard(
                  title: '多选题',
                  description: '多个正确答案',
                  icon: Icons.check_box,
                  color: AppColors.success,
                  count: multipleChoiceCount,
                  onTap: () => _navigateToTypePractice(context, ref, 'multiple'),
                ),

                // 判断题
                _QuestionTypeCard(
                  title: '判断题',
                  description: '正确或错误',
                  icon: Icons.thumbs_up_down,
                  color: AppColors.info,
                  count: judgeCount,
                  onTap: () => _navigateToTypePractice(context, ref, 'judge'),
                ),

                // 简答题
                _QuestionTypeCard(
                  title: '简答题',
                  description: '关键词匹配评分',
                  icon: Icons.edit_note,
                  color: AppColors.warning,
                  count: essayCount,
                  onTap: () => _navigateToTypePractice(context, ref, 'essay'),
                ),
              ]),
            ),
          ),

          // Bottom spacing
          SliverToBoxAdapter(
            child: _buildBottomSpacing(context),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    return 2;
  }

  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1.3;
    return 1.4;
  }

  int _getQuestionTypeCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    return 4;
  }

  double _getQuestionTypeAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1.1;
    return 1.3;
  }

  void _navigateToRandomPractice(BuildContext context, WidgetRef ref) {
    // 直接导航到练习页面，标记为随机模式，从所有分类中随机抽取50题
    context.push('/practice-swipe?mode=random&count=50');
  }

  void _navigateToWrongPractice(BuildContext context) {
    context.go('/wrong-book');
  }

  void _navigateToTypePractice(BuildContext context, WidgetRef ref, String type) {
    // Navigate to type practice - filter will be created from query parameter in router
    context.push('/practice-swipe?category=all&type=$type');
  }

  /// Get count of answered questions
  /// Note: This is a simplified version that returns 0 because getting answer status
  /// requires async operations. In a full implementation, you would:
  /// 1. Add answered count to QuestionBank state
  /// 2. Update it when answers are submitted
  /// 3. Cache the count in the provider
  int _getAnsweredCount(WidgetRef ref) {
    // TODO: Implement proper answered count tracking
    // For now, return 0 to avoid async complexity in sync context
    return 0;
  }

  /// Build responsive bottom spacing
  double _getBottomSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 120; // Mobile
    if (width < 900) return 60;  // Tablet
    return 40;                   // Desktop
  }

  Widget _buildBottomSpacing(BuildContext context) {
    return SizedBox(height: _getBottomSpacing(context));
  }
}

/// Practice Mode Card with Statistics
class _PracticeModeCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final _PracticeStats stats;
  final VoidCallback onTap;
  final bool isEmpty;
  final String? emptyMessage;

  const _PracticeModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.stats,
    required this.onTap,
    this.isEmpty = false,
    this.emptyMessage,
  });

  @override
  State<_PracticeModeCard> createState() => _PracticeModeCardState();
}

class _PracticeModeCardState extends State<_PracticeModeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.isEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: isDisabled ? null : (_) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTapCancel: isDisabled ? null : () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTap: isDisabled ? null : widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            decoration: BoxDecoration(
              color: isDark
                  ? (isDisabled ? AppColors.darkSurface : AppColors.darkCard)
                  : (isDisabled ? Colors.grey[100] : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDisabled
                    ? Colors.transparent
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: 1.5,
              ),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: widget.color.withValues(alpha: _isPressed ? 0.15 : 0.08),
                        blurRadius: _isPressed ? 8 : 20,
                        offset: Offset(0, _isPressed ? 2 : 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Status Row
                Row(
                  children: [
                    // Icon Container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSmallScreen ? 48 : 56,
                      height: isSmallScreen ? 48 : 56,
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? (isDark
                                ? AppColors.darkSurface
                                : Colors.grey[200])
                            : widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                      ),
                      child: Icon(
                        widget.icon,
                        color: isDisabled
                            ? (isDark
                                ? AppColors.darkTextTertiary
                                : Colors.grey[400])
                            : widget.color,
                        size: isSmallScreen ? 24 : 28,
                      ),
                    ),
                    const Spacer(),
                    // Empty State Badge
                    if (isDisabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.emptyMessage ?? '暂无数据',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : Colors.grey[500],
                            ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 20),

                // Title
                Text(
                  widget.title,
                  style: AppTypography.titleLarge.copyWith(
                    color: isDisabled
                        ? (isDark
                            ? AppColors.darkTextTertiary
                            : Colors.grey[500])
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 18 : null,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),

                // Description
                Text(
                  widget.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDisabled
                        ? (isDark
                            ? AppColors.darkTextTertiary
                            : Colors.grey[500])
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                    fontSize: isSmallScreen ? 12 : null,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 20),

                // Statistics Bar
                if (!isDisabled)
                  _StatsBar(
                    stats: widget.stats,
                    color: widget.color,
                    isDark: isDark,
                    isSmallScreen: isSmallScreen,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Statistics Bar Widget
class _StatsBar extends StatelessWidget {
  final _PracticeStats stats;
  final Color color;
  final bool isDark;
  final bool isSmallScreen;

  const _StatsBar({
    required this.stats,
    required this.color,
    required this.isDark,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = stats.total > 0 ? stats.completed / stats.total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${stats.completed}/${stats.total}',
              style: AppTypography.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : null,
              ),
            ),
            Text(
              stats.label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontSize: isSmallScreen ? 10 : null,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 10),

        // Progress Bar
        Container(
          height: isSmallScreen ? 4 : 6,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Stat Item Widget for Summary Card
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),

        // Value
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),

        // Label
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Practice Stats Data Class
class _PracticeStats {
  final int total;
  final int completed;
  final String label;

  const _PracticeStats({
    required this.total,
    required this.completed,
    required this.label,
  });
}

/// Category Grid - Displays category selection chips
class _CategoryGrid extends StatelessWidget {
  final List<String> categories;
  final WidgetRef ref;

  const _CategoryGrid({
    required this.categories,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((category) {
        final data = _getCategoryDataFor(category);

        return InkWell(
          onTap: () => _navigateToCategory(context, category),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  data.icon,
                  size: 18,
                  color: data.color,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCategoryDisplayNameFor(category),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getCategoryDisplayNameFor(String category) {
    if (category == 'all') return '全部';
    return category;
  }

  _CategoryData _getCategoryDataFor(String category) {
    // 为常见预设分类提供图标和颜色
    const predefinedData = {
      'foundation': _CategoryData(Icons.school, AppColors.primary),
      'operate': _CategoryData(Icons.memory, AppColors.warning),
      'network': _CategoryData(Icons.wifi, AppColors.info),
      'database': _CategoryData(Icons.storage, AppColors.success),
      'middleware': _CategoryData(Icons.layers, AppColors.error),
      'security': _CategoryData(Icons.security, AppColors.primary),
      'architecture': _CategoryData(Icons.account_tree, AppColors.warning),
    };

    if (predefinedData.containsKey(category)) {
      return predefinedData[category]!;
    }

    // 动态分类：根据分类名生成一致的图标和颜色
    final iconList = [
      Icons.category,
      Icons.book,
      Icons.science,
      Icons.computer,
      Icons.psychology,
      Icons.analytics,
      Icons.query_stats,
      Icons.smart_toy,
    ];

    final colorList = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];

    final hash = category.hashCode;
    final icon = iconList[hash.abs() % iconList.length];
    final color = colorList[hash.abs() % colorList.length];

    return _CategoryData(icon, color);
  }

  void _navigateToCategory(BuildContext context, String category) {
    // Load questions for the selected category
    ref.read(practiceSwipeProvider.notifier).loadInitialBatch(
      category: category,
      pageSize: 50,
    );
    // Navigate to category practice - use push to allow back navigation
    context.push('/practice-swipe?category=$category');
  }
}

/// Category Data Class
class _CategoryData {
  final IconData icon;
  final Color color;

  const _CategoryData(this.icon, this.color);
}

/// Question Type Card - Compact card for question type selection
class _QuestionTypeCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _QuestionTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  State<_QuestionTypeCard> createState() => _QuestionTypeCardState();
}

class _QuestionTypeCardState extends State<_QuestionTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.5,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),

                // Title and Count
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: AppTypography.labelMedium.copyWith(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  widget.description,
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
