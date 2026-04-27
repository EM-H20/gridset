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

    // 회귀 테스트 — picker 흐름 race:
    // PhotoPicker._onNext 는 ref.read(...).setMedia() 만 호출하고 push 한다.
    // 그 사이엔 누구도 flow 를 watch 하지 않는다 → autoDispose 였다면 microtask
    // 한 번 흐른 뒤 state 가 default 로 초기화되어 SuggestionPage 가 _Empty 를
    // 보게 된다. keepAlive: true 가 보장되어야 picker→suggestion 사이에서
    // media 가 살아남는다.
    test(
      'listener 없이 setMedia 후 microtask 가 흘러도 media 보존 (picker→suggestion race)',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        const items = [
          MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
          MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
          MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
        ];

        // picker 가 하는 동작과 동일: notifier 만 read 하고 listener 등록 없이 set.
        container.read(flowSelectionNotifierProvider.notifier).setMedia(items);

        // push → 다음 화면 build 까지의 microtask gap 을 시뮬레이션.
        await Future<void>.delayed(Duration.zero);

        // Suggestion 이 처음으로 watch 한 시점.
        final s = container.read(flowSelectionNotifierProvider);
        expect(s.media, items);
      },
    );
  });
}
