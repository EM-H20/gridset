import 'package:freezed_annotation/freezed_annotation.dart';

import 'grid_node.dart';

part 'grid_suggestion.freezed.dart';

/// 알고리즘 출력 단위 — 한 후보 레이아웃.
///
/// `tree` 는 cellId 부여된 BSP 트리 (NamedTemplate.tree 와 동일 구조).
/// `mediaByCellId` 는 cellId → MediaItem.id 매핑.
/// `loss` 는 매핑 품질 (낮을수록 좋음, 디버깅/텔레메트리/dedup tie-breaking 에 사용).
/// `templateName` 은 후보 식별자 (NamedTemplate.name).
///
/// JSON 직렬화 미지원 — GridNode (sealed class) 가 Freezed 미사용이라 toJson/fromJson 패스.
/// v1.x F16 "내 템플릿" 도입 시 GridNode 전용 직렬화 helper 추가.
@freezed
class GridSuggestion with _$GridSuggestion {
  const factory GridSuggestion({
    required GridNode tree,
    required Map<int, String> mediaByCellId,
    required double loss,
    required String templateName,
  }) = _GridSuggestion;
}
