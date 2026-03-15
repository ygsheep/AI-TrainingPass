import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/constants/touch_targets.dart';
import '../../widgets/cards/home_card.dart';
import '../../widgets/cards/stat_card.dart';
import '../../providers/exam_provider.dart';
import '../../providers/wrong_book_provider.dart';

/// Home Page
/// Main dashboard for the quiz app with responsive layout
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    // Watch providers for statistics
    final examStatsAsync = ref.watch(examStatisticsProvider);
    final wrongBook = ref.watch(wrongBookProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar (only on mobile - hidden on tablet/desktop by top nav)
            if (isMobile)
              SliverToBoxAdapter(
                child: _AppBar(isDark: isDark),
              ),

            // Content
            SliverPadding(
              padding: EdgeInsets.all(Responsive.getPadding(context)),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Welcome Section
                  _WelcomeSection(isDark: isDark),

                  SizedBox(height: isMobile ? 16 : 24),

                  // Statistics Section
                  _StatisticsSection(
                    examStatsAsync: examStatsAsync,
                    wrongBookCount: wrongBook.totalCount,
                    isMobile: isMobile,
                  ),

                  SizedBox(height: isMobile ? 16 : 24),

                  // Main Action Card - constrained width on larger screens
                  _buildMainCard(context, isMobile, isDark),

                  SizedBox(height: isMobile ? 16 : 24),

                  // Secondary Actions Grid
                  HomeGridLayout(
                    children: [
                      HomeCard(
                        title: '模拟考试',
                        subtitle: '限时测试，检验水平',
                        icon: Icons.quiz_rounded,
                        onTap: () => context.go('/exam-setup'),
                      ),
                      HomeCard(
                        title: '错题本',
                        subtitle: '复习错题，查漏补缺',
                        icon: Icons.bookmark_rounded,
                        onTap: () => context.go('/wrong-book'),
                      ),
                      HomeCard(
                        title: '历史记录',
                        subtitle: '查看答题历史',
                        icon: Icons.history_rounded,
                        onTap: () => context.push('/history'),
                      ),
                      HomeCard(
                        title: '题库更新',
                        subtitle: '导入最新题库',
                        icon: Icons.cloud_download_rounded,
                        onTap: () => context.push('/question-update'),
                      ),
                    ],
                  ),

                  // Bottom padding for navigation bar
                  SizedBox(height: isMobile ? 190 : 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, bool isMobile, bool isDark) {
    final card = HomeCard(
      title: '开始练习',
      subtitle: '随时答题，巩固知识',
      icon: Icons.play_arrow_rounded,
      isPrimary: true,
      onTap: () => context.go('/practice'),
    );

    // Make the main card wider on larger screens, left-aligned
    if (!isMobile) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SizedBox(
          width: double.infinity,
          child: card,
        ),
      );
    }
    return card;
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('功能开发中...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// Custom App Bar
class _AppBar extends StatelessWidget {
  final bool isDark;

  const _AppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo area
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TrainingPass',
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          // Settings button
          Semantics(
            button: true,
            label: '设置',
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              iconSize: 24,
              onPressed: () => context.go('/settings'),
              tooltip: '设置',
              style: IconButton.styleFrom(
                minimumSize: const Size(
                  TouchTargets.iconButtonMedium,
                  TouchTargets.iconButtonMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Welcome Section
class _WelcomeSection extends StatelessWidget {
  final bool isDark;

  const _WelcomeSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '欢迎回来',
          style: AppTypography.labelLarge.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '准备好开始学习了吗？',
          style: AppTypography.headlineLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Statistics Section
/// Displays 6 stat cards in responsive grid (2x3 on mobile, 3x2 on tablet/desktop)
class _StatisticsSection extends StatelessWidget {
  final AsyncValue examStatsAsync;
  final int wrongBookCount;
  final bool isMobile;

  const _StatisticsSection({
    required this.examStatsAsync,
    required this.wrongBookCount,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return examStatsAsync.when(
      data: (stats) => _buildStatsGrid(context, stats),
      loading: () => _buildStatsSkeleton(context),
      error: (_, __) => _buildStatsError(context),
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic stats) {
    // Calculate pass rate
    final passRate = stats.totalExams > 0
        ? (stats.passedExams / stats.totalExams * 100).toStringAsFixed(0)
        : '0';

    final screenWidth = MediaQuery.of(context).size.width;
    final columns = screenWidth < 600 ? 2 : 3;
    final spacing = screenWidth < 600 ? 10.0 : 16.0;
    final outerPadding = Responsive.getPadding(context);

    // Calculate available width for grid
    final availableWidth = screenWidth - (outerPadding * 2) - (spacing * (columns + 1));
    final cardWidth = availableWidth / columns;

    // Calculate aspect ratio based on card width
    // Smaller cards need smaller ratio to maintain content visibility
    double targetHeight;
    if (screenWidth < 320) {
      targetHeight = 95;
    } else if (screenWidth < 390) {
      targetHeight = 98;
    } else if (screenWidth < 440) {
      targetHeight = 102;
    } else if (screenWidth < 600) {
      targetHeight = 106;
    } else {
      targetHeight = 110;
    }

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: cardWidth / targetHeight,
      children: [
        StatCard(
          label: '总考试',
          value: stats.totalExams.toString(),
          icon: Icons.quiz_rounded,
          color: AppColors.info,
          onTap: () => context.push('/history'),
        ),
        StatCard(
          label: '平均正确率',
          value: '${stats.averageAccuracy.toStringAsFixed(0)}%',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          onTap: () => context.push('/history'),
        ),
        StatCard(
          label: '及格率',
          value: '$passRate%',
          icon: Icons.verified_rounded,
          color: AppColors.success,
          onTap: () => context.push('/history'),
        ),
        StatCard(
          label: '最高分',
          value: stats.bestScore.toString(),
          icon: Icons.star_rounded,
          color: AppColors.warning,
          onTap: () => context.push('/history'),
        ),
        StatCard(
          label: '错题数',
          value: wrongBookCount.toString(),
          icon: Icons.bookmark_rounded,
          color: AppColors.error,
          onTap: () => context.go('/wrong-book'),
        ),
        StatCard(
          label: '连续及格',
          value: stats.currentStreak.toString(),
          icon: Icons.local_fire_department_rounded,
          color: AppColors.info,
          onTap: () => context.push('/history'),
        ),
      ],
    );
  }

  Widget _buildStatsSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = screenWidth < 600 ? 2 : 3;
    final spacing = screenWidth < 600 ? 10.0 : 16.0;
    final outerPadding = Responsive.getPadding(context);

    // Calculate available width for grid
    final availableWidth = screenWidth - (outerPadding * 2) - (spacing * (columns + 1));
    final cardWidth = availableWidth / columns;

    // Calculate aspect ratio based on card width
    // Smaller cards need smaller ratio to maintain content visibility
    double targetHeight;
    if (screenWidth < 320) {
      targetHeight = 95;
    } else if (screenWidth < 390) {
      targetHeight = 98;
    } else if (screenWidth < 440) {
      targetHeight = 102;
    } else if (screenWidth < 600) {
      targetHeight = 106;
    } else {
      targetHeight = 110;
    }

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: cardWidth / targetHeight,
      children: List.generate(
        6,
        (_) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsError(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Text(
            '统计数据加载失败',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
