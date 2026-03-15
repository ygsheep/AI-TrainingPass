import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/question_filter.dart';
import '../../../providers/practice_list_provider.dart';

/// Filter Panel Widget
/// Collapsible panel with search and filter options
class FilterPanel extends ConsumerStatefulWidget {
  final List<String> availableCategories;

  const FilterPanel({
    super.key,
    this.availableCategories = const [],
  });

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> {
  final TextEditingController _searchController = TextEditingController();
  final _filterKey = GlobalKey();

  // Current filter values
  String? _selectedCategory;
  String? _selectedType;
  int? _selectedDifficulty;
  AnswerStatus? _selectedAnswerStatus;
  bool _onlyWrongBook = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current filter from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentFilter = ref.read(practiceListProvider).currentFilter;
      if (currentFilter != null) {
        setState(() {
          _selectedCategory = currentFilter.category;
          _selectedType = currentFilter.type;
          _selectedDifficulty = currentFilter.difficulty;
          _selectedAnswerStatus = currentFilter.answerStatus;
          _onlyWrongBook = currentFilter.inWrongBook ?? false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final filter = QuestionFilter(
      category: _selectedCategory,
      type: _selectedType,
      difficulty: _selectedDifficulty,
      answerStatus: _selectedAnswerStatus,
      inWrongBook: _onlyWrongBook ? true : null,
    );
    ref.read(practiceListProvider.notifier).applyFilter(filter);
  }

  void _clearFilter() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _selectedDifficulty = null;
      _selectedAnswerStatus = null;
      _onlyWrongBook = false;
    });
    ref.read(practiceListProvider.notifier).clearFilter();
  }

  void _performSearch(String query) {
    ref.read(practiceListProvider.notifier).searchQuestions(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: ExpansionTile(
        key: _filterKey,
        title: Text(
          '筛选条件',
          style: AppTypography.titleSmall,
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                _buildSearchBar(context),
                const SizedBox(height: 16),
                // Category filter
                _buildFilterSection(
                  context,
                  title: '分类',
                  options: ['全部', ...widget.availableCategories],
                  selected: _selectedCategory ?? '全部',
                  onSelect: (value) {
                    setState(() {
                      _selectedCategory = value == '全部' ? null : value;
                    });
                    _applyFilter();
                  },
                ),
                const SizedBox(height: 16),
                // Type filter
                _buildFilterSection(
                  context,
                  title: '题型',
                  options: ['全部', '单选', '多选', '判断', '填空'],
                  selected: _selectedType ?? '全部',
                  onSelect: (value) {
                    setState(() {
                      _selectedType = value == '全部' ? null : value;
                    });
                    _applyFilter();
                  },
                ),
                const SizedBox(height: 16),
                // Difficulty filter
                _buildFilterSection(
                  context,
                  title: '难度',
                  options: ['全部', '简单', '中等', '困难'],
                  selected: _getDifficultyLabel(_selectedDifficulty),
                  onSelect: (value) {
                    setState(() {
                      _selectedDifficulty = _parseDifficulty(value);
                    });
                    _applyFilter();
                  },
                ),
                const SizedBox(height: 16),
                // Status filter
                _buildFilterSection(
                  context,
                  title: '状态',
                  options: ['全部', '未做', '正确', '错误', '错题本'],
                  selected: _getAnswerStatusLabel(_selectedAnswerStatus),
                  onSelect: (value) {
                    setState(() {
                      if (value == '错题本') {
                        _onlyWrongBook = true;
                        _selectedAnswerStatus = null;
                      } else {
                        _onlyWrongBook = false;
                        _selectedAnswerStatus = _parseAnswerStatus(value);
                      }
                    });
                    _applyFilter();
                  },
                ),
                const SizedBox(height: 16),
                // Clear filter button
                Center(
                  child: TextButton.icon(
                    onPressed: _clearFilter,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('清除筛选'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索题目内容或ID...',
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(practiceListProvider.notifier).clearSearch();
                },
              )
            : null,
        filled: true,
        fillColor: isDark
            ? AppColors.darkCard
            : AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      style: AppTypography.bodyMedium,
      onChanged: _performSearch,
      onSubmitted: _performSearch,
    );
  }

  Widget _buildFilterSection(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onSelect(option),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.lightBorder,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getDifficultyLabel(int? level) {
    switch (level) {
      case 1:
        return '简单';
      case 2:
        return '中等';
      case 3:
        return '困难';
      default:
        return '全部';
    }
  }

  int? _parseDifficulty(String label) {
    switch (label) {
      case '简单':
        return 1;
      case '中等':
        return 2;
      case '困难':
        return 3;
      default:
        return null;
    }
  }

  String _getAnswerStatusLabel(AnswerStatus? status) {
    if (_onlyWrongBook) return '错题本';
    switch (status) {
      case AnswerStatus.notAnswered:
        return '未做';
      case AnswerStatus.correct:
        return '正确';
      case AnswerStatus.wrong:
        return '错误';
      case AnswerStatus.all:
      default:
        return '全部';
    }
  }

  AnswerStatus? _parseAnswerStatus(String label) {
    switch (label) {
      case '未做':
        return AnswerStatus.notAnswered;
      case '正确':
        return AnswerStatus.correct;
      case '错误':
        return AnswerStatus.wrong;
      case '全部':
      default:
        return AnswerStatus.all;
    }
  }
}
