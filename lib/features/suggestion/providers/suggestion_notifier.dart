import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../cores/grid_suggestor/grid_suggestor.dart';
import '../../../flow/flow_selection_provider.dart';
import 'suggestion_state.dart';

part 'suggestion_notifier.g.dart';

/// 후보 화면 상태 — flowSelection 을 watch 해서 진입 시 자동 suggest 호출.
///
/// `keepAlive: false` — suggestion 라우트 떠나면 초기화.
@Riverpod(keepAlive: false)
class SuggestionNotifier extends _$SuggestionNotifier {
  @override
  SuggestionState build() {
    final flow = ref.watch(flowSelectionNotifierProvider);
    if (flow.media.length < 2) {
      return const SuggestionState.empty();
    }
    try {
      final r = suggest(media: flow.media, canvas: flow.canvas);
      if (r.suggestions.isEmpty) {
        return const SuggestionState.empty();
      }
      return SuggestionState.loaded(
        media: flow.media,
        canvas: flow.canvas,
        suggestions: r.suggestions,
        selectedIndex: 0,
        cursor: r.nextCursor,
      );
    } on ArgumentError catch (e) {
      return SuggestionState.error(
        e.message?.toString() ?? '입력 검증 실패',
      );
    }
  }

  void selectIndex(int i) {
    final s = state;
    if (s is! SuggestionStateLoaded) return;
    if (i < 0 || i >= s.suggestions.length) return;
    state = s.copyWith(selectedIndex: i);
  }

  /// "다른 제안" — cursor 가 있으면 새 batch append.
  /// cursor null 이면 no-op (호출부가 disabled 처리).
  void loadMore() {
    final s = state;
    if (s is! SuggestionStateLoaded) return;
    if (s.cursor == null) return;
    try {
      final r = suggest(
        media: s.media,
        canvas: s.canvas,
        cursor: s.cursor!,
      );
      state = s.copyWith(
        suggestions: [...s.suggestions, ...r.suggestions],
        cursor: r.nextCursor,
      );
    } on ArgumentError {
      // 발생 거의 0
    }
  }
}
