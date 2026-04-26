/// Grid Suggestor v1 — 자동 레이아웃 제안 알고리즘.
///
/// 공개 API. 외부 모듈은 이 배럴만 import.
/// 내부 구현 파일을 직접 import 하지 말 것.
///
/// 의존성 규칙:
/// - `flutter/` 패키지 import 금지 (순수 Dart, 온디바이스).
/// - `package:meta` 까지만 허용. Freezed/json codegen 은 빌드 의존, 런타임 의존 없음.
library;

// 배럴 export 는 각 모델/함수 작성 후 채움 (Task 2~11).
export 'models/media_item.dart' show MediaItem, MediaType;
export 'models/canvas_ratio.dart' show CanvasRatio;
export 'models/grid_node.dart' show GridNode, Split, Leaf, SplitAxis, cellIdsOf;
export 'models/named_template.dart' show NamedTemplate;
