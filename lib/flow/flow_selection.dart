import 'package:freezed_annotation/freezed_annotation.dart';

import '../cores/grid_suggestor/grid_suggestor.dart';

part 'flow_selection.freezed.dart';

/// 흐름 공유 상태 — canvas-picker / photo-picker / suggestion 라우트가 공유.
///
/// JSON 직렬화 미지원: `CanvasRatio` 가 sealed class (Freezed 미사용).
/// `MediaItem` 도 cores 모델, 흐름 메모리 한정이라 직렬화 불필요.
@freezed
class FlowSelection with _$FlowSelection {
  const factory FlowSelection({
    required CanvasRatio canvas,
    @Default(<MediaItem>[]) List<MediaItem> media,
  }) = _FlowSelection;
}
