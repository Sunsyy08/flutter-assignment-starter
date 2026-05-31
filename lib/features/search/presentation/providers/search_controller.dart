import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../watchlist/data/providers/watchlist_repository_provider.dart';
import '../../../watchlist/domain/models/watchlist_models.dart';
import '../../../watchlist/domain/repositories/watchlist_repository.dart';
import '../../../watchlist/presentation/providers/favorite_ids_controller.dart';

final searchControllerProvider =
NotifierProvider<SearchController, SearchUiState>(SearchController.new);

class SearchController extends Notifier<SearchUiState> {
  WatchlistRepository get _repository => ref.read(watchlistRepositoryProvider);

  Timer? _toastTimer;
  int _requestSequence = 0;

  @override
  SearchUiState build() {
    ref.onDispose(() => _toastTimer?.cancel());

    // favoriteIdsControllerProvider를 listen해서
    // 즐겨찾기 상태가 바뀔 때마다 현재 검색 결과의 isFavorite를 다시 매핑
    // 예: 관심목록 화면에서 삭제해도 검색 결과 하트가 바로 반영됨
    ref.listen(favoriteIdsControllerProvider, (previous, next) {
      _applyFavoriteIds(next.valueOrNull);
    });

    return const SearchUiState();
  }

  Future<void> setQuery(String query) async {
    _requestSequence += 1;
    final currentRequestId = _requestSequence;
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      _toastTimer?.cancel();
      state = state.copyWith(
        query: query,
        results: const AsyncData(<StockSearchItem>[]),
        selectedItemId: null,
        toast: null,
      );
      return;
    }

    final existingResults = state.results;
    final loadingResults = existingResults.hasValue
        ? const AsyncLoading<List<StockSearchItem>>().copyWithPrevious(
      existingResults,
    )
        : const AsyncLoading<List<StockSearchItem>>();

    state = state.copyWith(
      query: query,
      results: loadingResults,
      selectedItemId: null,
      toast: null,
    );

    final result = await AsyncValue.guard(
          () => _repository.searchStocks(query: trimmedQuery),
    );
    if (currentRequestId != _requestSequence) {
      return;
    }

    // 검색 결과가 나온 직후 현재 즐겨찾기 상태를 읽어서 isFavorite 동기화
    // 검색 직후에도 하트 상태가 정확히 반영되도록
    final currentFavoriteIds =
        ref.read(favoriteIdsControllerProvider).valueOrNull;

    state = state.copyWith(
      results: currentFavoriteIds != null
          ? AsyncData(_applyFavorites(result.valueOrNull ?? [], currentFavoriteIds))
          : result,
      selectedItemId: null,
    );
  }

  void clearQuery() {
    _requestSequence += 1;
    _toastTimer?.cancel();
    state = state.copyWith(
      query: '',
      results: const AsyncData(<StockSearchItem>[]),
      selectedItemId: null,
      toast: null,
    );
  }

  void setFocused(bool isFocused) {
    if (state.isFocused == isFocused) {
      return;
    }
    state = state.copyWith(isFocused: isFocused);
  }

  void toggleSelection(StockSearchItem item) {
    state = state.copyWith(
      selectedItemId: state.selectedItemId == item.id ? null : item.id,
    );
  }

  void clearSelection() {
    if (state.selectedItemId == null) {
      return;
    }
    state = state.copyWith(selectedItemId: null);
  }

  Future<bool> toggleFavorite(StockSearchItem item) async {
    final isAdded = await ref
        .read(favoriteIdsControllerProvider.notifier)
        .toggle(item.id);

    // toggle 이후 최신 favorite 상태를 현재 검색 결과에 다시 반영
    // 추가 시 토스트 표시, 제거 시 토스트 닫기
    final currentFavoriteIds =
        ref.read(favoriteIdsControllerProvider).valueOrNull;
    _applyFavoriteIds(currentFavoriteIds);

    if (isAdded) {
      // 즐겨찾기 추가 시 토스트 표시
      _showToast(const SearchToastData(message: '관심그룹에 추가되었습니다.'));
    } else {
      // 즐겨찾기 제거 시 토스트 숨김
      dismissToast();
    }

    return isAdded;
  }

  void dismissToast() {
    _toastTimer?.cancel();
    if (state.toast == null) {
      return;
    }
    state = state.copyWith(toast: null);
  }

  void _showToast(SearchToastData toast) {
    _toastTimer?.cancel();
    state = state.copyWith(toast: toast);
    // 2초 후 자동으로 토스트 사라짐
    _toastTimer = Timer(const Duration(seconds: 2), dismissToast);
  }

  void _applyFavoriteIds(Set<String>? favoriteIds) {
    // favoriteIds에 맞게 현재 results의 isFavorite를 다시 매핑
    // 다른 화면에서 즐겨찾기가 바뀌어도 검색 결과에 즉시 반영됨
    if (favoriteIds == null) return;

    final currentResults = state.results.valueOrNull;
    if (currentResults == null) return;

    final updatedResults = _applyFavorites(currentResults, favoriteIds);

    // 즐겨찾기에서 제거된 경우 선택 상태도 정리
    final selectedStillFavorite = state.selectedItemId == null ||
        updatedResults.any((item) => item.id == state.selectedItemId);

    state = state.copyWith(
      results: AsyncData(updatedResults),
      selectedItemId: selectedStillFavorite ? state.selectedItemId : null,
    );
  }

  // 검색 결과 리스트에 즐겨찾기 상태를 적용하는 헬퍼
  List<StockSearchItem> _applyFavorites(
      List<StockSearchItem> results,
      Set<String> favoriteIds,
      ) {
    return results
        .map((item) => item.copyWith(isFavorite: favoriteIds.contains(item.id)))
        .toList();
  }
}

@immutable
class SearchUiState {
  const SearchUiState({
    this.query = '',
    this.results = const AsyncData(<StockSearchItem>[]),
    this.selectedItemId,
    this.isFocused = false,
    this.toast,
  });

  final String query;
  final AsyncValue<List<StockSearchItem>> results;
  final String? selectedItemId;
  final bool isFocused;
  final SearchToastData? toast;

  SearchUiState copyWith({
    String? query,
    AsyncValue<List<StockSearchItem>>? results,
    Object? selectedItemId = _sentinel,
    bool? isFocused,
    Object? toast = _sentinel,
  }) {
    return SearchUiState(
      query: query ?? this.query,
      results: results ?? this.results,
      selectedItemId: selectedItemId == _sentinel
          ? this.selectedItemId
          : selectedItemId as String?,
      isFocused: isFocused ?? this.isFocused,
      toast: toast == _sentinel ? this.toast : toast as SearchToastData?,
    );
  }
}

@immutable
class SearchToastData {
  const SearchToastData({required this.message});

  final String message;
}

const _sentinel = Object();