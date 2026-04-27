import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cores/grid_suggestor/grid_suggestor.dart';
import 'flow_selection.dart';

part 'flow_selection_provider.g.dart';

/// 흐름 공유 상태 Notifier.
///
/// - `home → CTA` 진입 시 canvas/media 셋업
/// - picker (canvas/photo) 화면들은 `ref.read(...).setX()` 만 호출하므로
///   listener 가 없다. `keepAlive: true` 로 두어야 picker → suggestion 이동
///   사이의 microtask 동안 state 가 보존된다 (autoDispose 였다면 race 로
///   media 가 default 로 초기화됨).
/// - 흐름 시작 시점 (home 두 CTA) 에서 명시적으로 media/canvas 를 reset 해
///   이전 흐름 잔재를 제거한다.
@Riverpod(keepAlive: true)
class FlowSelectionNotifier extends _$FlowSelectionNotifier {
  @override
  FlowSelection build() =>
      const FlowSelection(canvas: CanvasRatio.portrait916());

  void setCanvas(CanvasRatio ratio) =>
      state = state.copyWith(canvas: ratio);

  void setMedia(List<MediaItem> items) =>
      state = state.copyWith(media: items);
}
