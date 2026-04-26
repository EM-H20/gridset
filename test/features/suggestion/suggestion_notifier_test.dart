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
      if (s0.suggestions.length >= 2) {
        c.read(suggestionNotifierProvider.notifier).selectIndex(1);
        final s1 =
            c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
        expect(s1.selectedIndex, 1);
      }
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

      if (s0.cursor != null) {
        c.read(suggestionNotifierProvider.notifier).loadMore();
        final s1 =
            c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
        expect(s1.suggestions.length, greaterThan(initial));
      }
    });
  });
}
