import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/question_summary.dart';
import '../../domain/entities/question_filter.dart';
import '../../domain/repositories/question_repository.dart';
import 'question_provider.dart';

part 'practice_list_provider.g.dart';

/// Practice List State
@sealed
class PracticeListState {
  /// List of question summaries
  final List<QuestionSummary> summaries;

  /// Currently selected question index
  final int selectedIndex;

  /// Current page number (0-based)
  final int currentPage;

  /// Number of items per page
  final int pageSize;

  /// Total count of questions
  final int totalCount;

  /// Whether there are more items to load
  final bool hasMore;

  /// Whether currently loading
  final bool isLoading;

  /// Whether loading more items
  final bool isLoadingMore;

  /// Error message if any
  final String? error;

  /// Current filter
  final QuestionFilter? currentFilter;

  /// Current search keyword
  final String? searchKeyword;

  /// Whether in search mode
  final bool isSearchMode;

  const PracticeListState({
    this.summaries = const [],
    this.selectedIndex = -1,
    this.currentPage = 0,
    this.pageSize = 50,
    this.totalCount = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentFilter,
    this.searchKeyword,
    this.isSearchMode = false,
  });

  /// Copy with method
  PracticeListState copyWith({
    List<QuestionSummary>? summaries,
    int? selectedIndex,
    int? currentPage,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    QuestionFilter? currentFilter,
    String? searchKeyword,
    bool? isSearchMode,
    // Use nullable bool to allow setting to null
    Object? currentFilterNull,
    Object? searchKeywordNull,
  }) {
    return PracticeListState(
      summaries: summaries ?? this.summaries,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentFilter: currentFilterNull == null ? currentFilter : null as QuestionFilter?,
      searchKeyword: searchKeywordNull == null ? searchKeyword : null as String?,
      isSearchMode: isSearchMode ?? this.isSearchMode,
    );
  }

  /// Get currently selected summary
  QuestionSummary? get selectedSummary {
    if (selectedIndex >= 0 && selectedIndex < summaries.length) {
      return summaries[selectedIndex];
    }
    return null;
  }
}

/// Practice List Provider
/// Manages question summaries list with pagination and filtering
@riverpod
class PracticeList extends _$PracticeList {
  @override
  PracticeListState build() {
    return const PracticeListState();
  }

  /// Load question summaries (first page or refresh)
  Future<void> loadSummaries({
    QuestionFilter? filter,
    bool refresh = false,
  }) async {
    // Clear existing data if refreshing
    if (refresh) {
      state = state.copyWith(
        summaries: [],
        currentPage: 0,
        isLoading: true,
        error: null,
      );
    } else if (state.summaries.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final repository = ref.read(questionRepositoryProvider);

      // Get total count first
      final totalCount = await repository.getQuestionCount(filter: filter);

      // Get summaries for current page
      final summaries = await repository.getQuestionSummaries(
        offset: state.currentPage * state.pageSize,
        limit: state.pageSize,
        filter: filter,
      );

      final hasMore = (state.currentPage + 1) * state.pageSize < totalCount;

      state = state.copyWith(
        summaries: summaries,
        totalCount: totalCount,
        hasMore: hasMore,
        isLoading: false,
        error: null,
        currentFilter: filter,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more summaries (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = ref.read(questionRepositoryProvider);
      final nextPage = state.currentPage + 1;

      final summaries = await repository.getQuestionSummaries(
        offset: nextPage * state.pageSize,
        limit: state.pageSize,
        filter: state.currentFilter,
      );

      final hasMore = (nextPage + 1) * state.pageSize < state.totalCount;

      state = state.copyWith(
        summaries: [...state.summaries, ...summaries],
        currentPage: nextPage,
        hasMore: hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Search questions by keyword
  Future<void> searchQuestions(String keyword) async {
    if (keyword.trim().isEmpty) {
      clearSearch();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      searchKeyword: keyword,
      isSearchMode: true,
      error: null,
    );

    try {
      final repository = ref.read(questionRepositoryProvider);

      final summaries = await repository.searchQuestions(
        keyword,
        offset: 0,
        limit: state.pageSize,
      );

      state = state.copyWith(
        summaries: summaries,
        totalCount: summaries.length,
        hasMore: false, // Search results are not paginated for now
        isLoading: false,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear search and return to normal mode
  void clearSearch() {
    state = state.copyWith(
      searchKeyword: null,
      isSearchMode: false,
      summaries: [],
      currentPage: 0,
    );
    loadSummaries(filter: state.currentFilter);
  }

  /// Apply filter and reload
  Future<void> applyFilter(QuestionFilter filter) async {
    state = state.copyWith(
      summaries: [],
      currentPage: 0,
      currentFilter: filter,
    );
    await loadSummaries(filter: filter);
  }

  /// Clear filter and reload all
  Future<void> clearFilter() async {
    await applyFilter(const QuestionFilter());
  }

  /// Select a question by index
  void selectIndex(int index) {
    if (index >= 0 && index < state.summaries.length) {
      state = state.copyWith(selectedIndex: index);
    }
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(selectedIndex: -1);
  }

  /// Refresh current list
  Future<void> refresh() async {
    await loadSummaries(
      filter: state.currentFilter,
      refresh: true,
    );
  }
}
