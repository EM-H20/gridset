import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/suggestion/providers/suggestion_notifier.dart';
import 'package:gridset/features/suggestion/providers/suggestion_state.dart';
import 'package:gridset/flow/flow_selection_provider.dart';

void main() {
  group('SuggestionNotifier', () {
    test('media < 2 → empty state', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(flowSelectionNotifierProvider.notifier).setMedia(const []);

      final s = c.read(suggestionNotifierProvider);
      expect(s, isA<SuggestionStateEmpty>());
    });

    test('media >= 2 → loaded with suggestions', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      const items = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
        MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
      ];
      c.read(flowSelectionNotifierProvider.notifier).setMedia(items);

      final s = c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
      expect(s.suggestions, isNotEmpty);
      expect(s.selectedIndex, 0);
      expect(s.media.length, 3);
    });

    test('selectIndex 갱신', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      const items = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
        MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
      ];
      c.read(flowSelectionNotifierProvider.notifier).setMedia(items);

      // 진입
      final s0 = c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
      // 사전조건 단정 — 알고리즘이 N=3 에서 최소 2개 이상 후보를 내야
      // selectIndex 의미가 있다. 회귀 시 silent skip 방지.
      expect(s0.suggestions.length, greaterThanOrEqualTo(2),
          reason: 'N=3 입력은 다중 후보를 보장해야 함');

      c.read(suggestionNotifierProvider.notifier).selectIndex(1);
      final s1 =
          c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
      expect(s1.selectedIndex, 1);
    });

    test('loadMore — cursor 진행 시 suggestions 누적', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      const items = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
        MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
      ];
      c.read(flowSelectionNotifierProvider.notifier).setMedia(items);

      final s0 = c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
      final initial = s0.suggestions.length;

      // 사전조건 단정 — 첫 batch 가 cursor 를 줘야 loadMore 검증 의미. cursor 가
      // 없으면 알고리즘이 first-batch-only 로 회귀했다는 신호.
      expect(s0.cursor, isNotNull,
          reason: 'N=3 첫 batch 는 후속 cursor 를 반환해야 함');

      c.read(suggestionNotifierProvider.notifier).loadMore();
      final s1 = c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
      expect(s1.suggestions.length, greaterThan(initial));
    });
  });
}
