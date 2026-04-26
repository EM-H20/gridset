import 'package:freezed_annotation/freezed_annotation.dart';

part 'suggest_cursor.freezed.dart';

/// "다른 제안 보기" 진행 상태 — immutable cursor.
///
/// PRD §9-2-1 step 5: 첫 호출 + 다른 제안 3회 = 최대 4 batch.
/// `batchIndex`: 0 = 첫 호출, 1/2/3 = "다른 제안 보기" 1·2·3회.
/// `batchIndex >= 3` 인 cursor 가 들어오면 알고리즘이 nextCursor: null 반환.
///
/// `shownTemplateNames` 는 unmodifiable 로 사용 권장 — 호출부가 mutate 하면 알고리즘 결정성 깨짐.
@freezed
class SuggestCursor with _$SuggestCursor {
  const factory SuggestCursor({
    required Set<String> shownTemplateNames,
    required int batchIndex,
  }) = _SuggestCursor;
}
