import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cores/grid_suggestor/grid_suggestor.dart';
import 'flow_selection.dart';

part 'flow_selection_provider.g.dart';

/// 흐름 공유 상태 Notifier.
///
/// - `home → CTA` 진입 시 canvas/media 셋업
/// - `home` 으로 돌아가면 라우트 dispose → autoDispose → build() 재호출
///   (명시 reset 불필요).
@Riverpod(keepAlive: false)
class FlowSelectionNotifier extends _$FlowSelectionNotifier {
  @override
  FlowSelection build() =>
      const FlowSelection(canvas: CanvasRatio.portrait916());

  void setCanvas(CanvasRatio ratio) =>
      state = state.copyWith(canvas: ratio);

  void setMedia(List<MediaItem> items) =>
      state = state.copyWith(media: items);
}
