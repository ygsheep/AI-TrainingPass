import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../presentation/providers/exam_provider.dart';
import '../../../presentation/widgets/cards/exam_record_card.dart';

/// History Page
/// Displays exam history with filtering and pagination
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  bool _passedOnly = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Load history on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(examHistoryProvider.notifier).loadHistory(passedOnly: _passedOnly);
    });
    // Setup scroll listener for auto-loading
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final historyState = ref.read(examHistoryProvider);
    if (!historyState.hasMore) return;

    // Load more when near bottom (within 200px)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadHistory({bool? passedOnly}) {
    ref.read(examHistoryProvider.notifier).loadHistory(
          passedOnly: passedOnly ?? _passedOnly,
        );
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    await ref.read(examHistoryProvider.notifier).loadMore();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条考试记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete the record
    final success = await ref.read(examHistoryProvider.notifier).deleteRecord(recordId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '记录已删除' : '删除失败'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      // Refresh the list
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final historyState = ref.watch(examHistoryProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            if (isMobile)
              SliverToBoxAdapter(
                child: _AppBar(isDark: isDark),
              ),

            // Content
            SliverPadding(
              padding: EdgeInsets.all(Responsive.getPadding(context)),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Page Title
                  if (!isMobile)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        '历史记录',
                        style: AppTypography.headlineLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),

                  // Filter Bar
                  _FilterBar(
                    passedOnly: _passedOnly,
                    onFilterChanged: (value) {
                      setState(() {
                        _passedOnly = value;
                      });
                      _loadHistory(passedOnly: value);
                    },
                    onReset: () {
                      setState(() {
                        _passedOnly = false;
                      });
                      _loadHistory(passedOnly: false);
                    },
                  ),

                  SizedBox(height: isMobile ? 16 : 24),

                  // History List
                  _buildHistoryList(historyState, isDark, _deleteRecord),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(ExamHistoryState state, bool isDark, Future<void> Function(String) onDelete) {
    if (state.isLoading && state.records.isEmpty) {
      return const _LoadingState();
    }

    if (state.error != null && state.records.isEmpty) {
      return _ErrorState(
        message: state.error ?? '加载失败',
        onRetry: () => _loadHistory(),
      );
    }

    if (state.records.isEmpty) {
      return _EmptyState(
        passedOnly: _passedOnly,
        onReset: () {
          setState(() {
            _passedOnly = false;
          });
          _loadHistory(passedOnly: false);
        },
      );
    }

    return Column(
      children: [
        // Record count
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                '共 ${state.totalCount} 条记录',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Records
        ...state.records.map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExamRecordCard(
                record: record,
                onTap: () => _showRecordDetail(record),
                onDelete: () => onDelete(record.id),
              ),
            )),

        // Loading more indicator
        if (_isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '加载更多...',
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
      ],
    );
  }

  void _showRecordDetail(dynamic record) {
    context.go('/exam-detail/${record.id}');
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
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/'),
            tooltip: '返回',
          ),
          const SizedBox(width: 8),
          Text(
            '历史记录',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter Bar
class _FilterBar extends StatelessWidget {
  final bool passedOnly;
  final ValueChanged<bool> onFilterChanged;
  final VoidCallback onReset;

  const _FilterBar({
    required this.passedOnly,
    required this.onFilterChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Filter Icon
          Icon(
            Icons.filter_list_rounded,
            size: 20,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),

          // Passed Only Filter
          FilterChip(
            label: const Text('仅显示通过'),
            selected: passedOnly,
            onSelected: onFilterChanged,
            checkmarkColor: AppColors.success,
            selectedColor: AppColors.success.withValues(alpha: 0.15),
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: passedOnly
                  ? AppColors.success
                  : (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder)
                      .withValues(alpha: 0.5),
            ),
          ),

          const Spacer(),

          // Reset Button
          if (passedOnly)
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('重置'),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading State
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Error State
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty State
class _EmptyState extends StatelessWidget {
  final bool passedOnly;
  final VoidCallback onReset;

  const _EmptyState({
    required this.passedOnly,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passedOnly
                  ? Icons.filter_list_off_rounded
                  : Icons.history_rounded,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              passedOnly ? '没有通过的考试记录' : '还没有考试记录',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            if (passedOnly) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重置筛选'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
