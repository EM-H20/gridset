import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/flow/flow_selection_provider.dart';

void main() {
  group('FlowSelectionNotifier', () {
    test('initial state — canvas 9:16, media 비어있음', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(flowSelectionNotifierProvider);

      expect(state.canvas, const CanvasRatio.portrait916());
      expect(state.media, isEmpty);
    });

    test('setCanvas 가 canvas 만 갱신, media 보존', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(flowSelectionNotifierProvider.notifier)
          .setCanvas(const CanvasRatio.square());

      final s = container.read(flowSelectionNotifierProvider);
      expect(s.canvas, const CanvasRatio.square());
      expect(s.media, isEmpty);
    });

    test('setMedia 가 media 만 갱신, canvas 보존', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const items = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
      ];

      container.read(flowSelectionNotifierProvider.notifier).setMedia(items);

      final s = container.read(flowSelectionNotifierProvider);
      expect(s.media, items);
      expect(s.canvas, const CanvasRatio.portrait916()); // 디폴트 보존
    });
  });
}
