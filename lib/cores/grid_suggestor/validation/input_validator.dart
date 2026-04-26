import '../models/media_item.dart';

/// suggest() 입력 검증. 잘못된 입력은 즉시 ArgumentError.
///
/// 검증 항목 (spec §6-1):
/// - 2 ≤ N ≤ 9
/// - 모든 aspectRatio 양의 유한값
/// - 모든 id 유일
/// - weightOf(item) 유한값 + ≥ 0 (NaN/Infinity 차단으로 정렬 안정성 보장)
void validateSuggestInput({
  required List<MediaItem> media,
  required double Function(MediaItem item)? weightOf,
}) {
  final n = media.length;
  if (n < 2) {
    throw ArgumentError('media must have ≥ 2 items, got $n');
  }
  if (n > 9) {
    throw ArgumentError('media must have ≤ 9 items, got $n');
  }
  for (var i = 0; i < media.length; i++) {
    final ar = media[i].aspectRatio;
    if (ar <= 0 || !ar.isFinite) {
      throw ArgumentError(
        'aspectRatio must be positive finite, got $ar at index $i',
      );
    }
  }
  final ids = <String>{};
  for (final m in media) {
    if (!ids.add(m.id)) {
      throw ArgumentError(
        'media items must have unique ids, duplicate: ${m.id}',
      );
    }
  }
  if (weightOf != null) {
    for (final m in media) {
      final w = weightOf(m);
      // NaN/Infinity 도 차단 — loss 계산/정렬 단계 비결정성 방지.
      if (!w.isFinite || w < 0) {
        throw ArgumentError(
          'weight must be finite non-negative, got $w for ${m.id}',
        );
      }
    }
  }
}
