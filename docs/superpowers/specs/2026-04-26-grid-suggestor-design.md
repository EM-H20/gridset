# Grid Suggestor v1 — Design Spec

**Date:** 2026-04-26
**Scope:** 자동 레이아웃 제안 알고리즘 모듈 (`lib/cores/grid_suggestor/`) — UI 없이 순수 Dart 코어. PRD §9-2-1 ~ §9-2-3 구현 + /dev 갤러리에 큐레이션 검증 카탈로그 추가.
**Constraint:** 온디바이스(외부 호출 없음, 로그인 없음, 외부 의존성 추가 없음).
**Source:** `docs/PRD.md` §F00, §9-2-1 ~ §9-2-3, §11.
**Depends on:** `docs/superpowers/specs/2026-04-25-home-and-dev-gallery-design.md` (`/dev` 갤러리 — 카탈로그 섹션 신규 추가 위치).
**Consumed by (post-spec):** Suggestion 화면(다음 spec 사이클), Editor 화면(F02-F06 의 초깃값), v1.x "내 템플릿"(F16) 후보 트리 직렬화.

---

## 1. 결정 요약

| 항목 | 결정 | 근거 |
| --- | --- | --- |
| 입력 미디어 범위 | 사진+영상 입력 모델, v1 가중치 1.0 통일 | 알고리즘 정확도 먼저, 영상 가중치(PRD §9-2-1)는 v1.x에서 켤 훅(`weightOf` 함수 인자)만 노출 |
| 템플릿 정의 위치 | Dart `const` 코드 상수 + sealed class | 온디바이스 0-runtime alloc, 컴파일타임 enumeration, JSON 파싱·검증 부담 회피 |
| 자료구조 | N-ary BSP 트리 (`Split` / `Leaf` sealed class) | "좌1+우3" 같은 비대칭 패턴 표현 가능, 평면 V/H 집합으로는 표현 불가, 에디터 forward-compatible |
| 매핑 탐색 | 브루트포스 N! permutation | N≤9 라 ~150-300ms 예측, 헝가리안(O(N³))은 v1.x 측정 후 결정 |
| Loss 함수 | `Σ wₘ(σ(i)) × |ln(cellARᵢ) - ln(mediaARσ(i))|` (wₘ = 미디어 가중치) | 가로 2배/세로 2배 차이를 대칭으로 평가 — 사람 perception 과 일치 |
| 다양성 dedup | 큐레이션(1차) + fingerprint(2차) | 큐레이션 책임이 1차, ±10% 위치 fingerprint 가 안전망 |
| "다른 제안 보기" API | 함수형 cursor (immutable) | Riverpod 친화, 결정성 명시, mutable state 회피 |
| 분할 위치 화이트리스트 | `{1/4, 1/3, 0.4, 0.5, 0.6, 2/3, 3/4}` 7개로 고정 | PRD §9-2-3 스냅 가이드(½, ⅓, ⅔) + 4분할 균등(¼, ¾) 수용. 큐레이션 일관성 |
| N별 템플릿 개수 | N=2~9 합계 약 31개 (보수적) | PRD "후보 3~5개" + dedup 안전망. KPI 보고 v1.x 에서 확장 |
| 시각 검증 도구 | 기존 `/dev` 갤러리에 "Grid Templates" 섹션 신규 | PRD §13 "최상" 리스크(자동 제안 품질) 시각 iterate 루프 |
| 외부 의존성 | **없음** (순수 Dart, `flutter/` import 금지) | 온디바이스 + 모듈 재사용성 + 테스트 비용 최소화 |
| 에러 정책 | 잘못된 입력 즉시 `ArgumentError` (silent recovery 안 함) | 알고리즘은 깊은 레이어 — 호출부가 분기/경고 책임 |

---

## 2. 아키텍처

### 2-1. 모듈 위치 — `lib/cores/grid_suggestor/`

`features/` 가 아닌 `cores/` 인 이유:

- **순수 Dart, 위젯 의존 0** → 가장 낮은 레이어
- **여러 features 가 소비**: Suggestion 화면(F00), Editor 화면(F02-F06 초깃값), 향후 "내 템플릿"(F16)
- CLAUDE.md 디렉터리 규칙(`cores = 공통 유틸/상수`, `features = 기능별 모듈`) 정합

### 2-2. 파일 트리

```
lib/cores/grid_suggestor/
├── grid_suggestor.dart                # 공개 API 배럴 (re-export)
├── models/
│   ├── media_item.dart                # 입력 모델 (Freezed)
│   ├── canvas_ratio.dart              # 9:16 / 1:1 / 4:5 / 16:9 + custom (sealed)
│   ├── grid_node.dart                 # BSP sealed class (Split | Leaf)
│   ├── named_template.dart            # 큐레이션 래퍼 (name + tree + cellIds)
│   ├── grid_suggestion.dart           # 출력 모델 (Freezed)
│   └── suggest_cursor.dart            # cursor 모델 (Freezed)
├── templates/
│   ├── grid_templates.dart            # final Map<int, List<NamedTemplate>> (UnmodifiableMapView 로 노출)
│   ├── _n2_templates.dart             # private — N=2 큐레이션
│   ├── _n3_templates.dart
│   ├── _n4_templates.dart
│   ├── _n5_templates.dart
│   ├── _n6_templates.dart
│   ├── _n7_templates.dart
│   ├── _n8_templates.dart
│   └── _n9_templates.dart
├── geometry/
│   └── cell_geometry.dart             # BSP 트리 → cellId → bbox 매핑 + 종횡비 계산
├── matching/
│   └── media_to_cell_matcher.dart     # 셀↔미디어 매핑 (브루트포스 N!) + log loss
├── ranking/
│   └── candidate_ranker.dart          # 정렬 + fingerprint dedup
└── suggester.dart                     # 진입점: suggest(...)

test/cores/grid_suggestor/
├── validate_test.dart                 # 입력 검증
├── cell_geometry_test.dart            # bbox 계산 골든
├── matcher_test.dart                  # 매핑 + loss 함수 골든
├── ranker_test.dart                   # 정렬 + dedup
├── templates_test.dart                # 큐레이션 8 invariant
├── suggester_test.dart                # 통합 + 결정성 + cursor + golden
├── suggester_perf_test.dart           # 성능 (N=9 < 300ms)
└── fixtures/
    ├── photos_4_mixed.dart
    ├── photos_6_mixed.dart
    ├── photos_9_mixed.dart
    └── ...                                # N=2,3,5,7,8 보조 fixture (golden 테스트용)

lib/features/dev/widgets/
└── grid_template_preview.dart         # 신규 — BSP → 시각 위젯 변환 (dev 갤러리 전용)

lib/features/dev/dev_gallery_page.dart  # 수정 — "Grid Templates" 섹션 추가
```

### 2-3. 의존성 규칙

- **`lib/cores/grid_suggestor/` 는 `flutter/` 패키지 import 금지.** `package:meta` (annotations) 정도까지만. Freezed/json_serializable codegen 은 OK (런타임 의존 0).
- **`features/` 는 `grid_suggestor.dart` 배럴만 import**. 내부 파일 직접 import 금지 → 향후 리팩터 자유.
- **`/dev` 갤러리는 예외적으로 `templates/grid_templates.dart` 직접 참조** (카탈로그 렌더링용 데이터 소비). 다른 features 는 카탈로그 직접 접근 금지.
- **새 외부 패키지 추가 0**. `freezed`, `json_serializable`, `build_runner` 는 이미 `pubspec.yaml` 에 존재.

### 2-4. 빌드 산출물

- Freezed codegen: `media_item`, `canvas_ratio`, `grid_suggestion`, `suggest_cursor` (`*.freezed.dart`, `*.g.dart`)
- `GridNode` 는 sealed class 직접 작성 (Freezed 미사용 — 재귀 + `const` 생성자 + assert 가 모두 필요해서 Freezed 의 codegen 모델이 잘 안 맞음)

---

## 3. 데이터 모델

### 3-1. 입력 — `MediaItem`

```dart
@freezed
class MediaItem with _$MediaItem {
  const factory MediaItem({
    required String id,             // 호출부가 부여 (photo_manager AssetEntity.id 등)
    required MediaType type,        // photo | video
    required double aspectRatio,    // W / H. 양수, 유한.
    int? durationMs,                // 영상일 때만, photo 면 null
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}

enum MediaType { photo, video }
```

- `aspectRatio` 는 항상 `W/H`. 호출부가 EXIF orientation 반영 후 넘김 (알고리즘은 회전 알 바 없음).
- `durationMs` 는 v1 에선 알고리즘이 사용하지 않음(영상 가중치 1.0). 입력 모델에만 미리 뚫어두어 v1.x 영상 싱크(F07)·가중치(1.5) 작업 시 호환성 유지.

### 3-2. 캔버스 비율 — `CanvasRatio`

```dart
sealed class CanvasRatio {
  const CanvasRatio();
  double get value; // W / H

  const factory CanvasRatio.portrait916()  = _R916;   // 9/16   = 0.5625
  const factory CanvasRatio.square()       = _R11;    // 1
  const factory CanvasRatio.portrait45()   = _R45;    // 4/5    = 0.8
  const factory CanvasRatio.landscape169() = _R169;   // 16/9   ≈ 1.778
  const factory CanvasRatio.custom(double w, double h) = _RCustom;
}
```

- `enum` 대신 sealed 인 이유: PRD §F10 "커스텀" 지원.
- `value` 는 W/H 양수 — 음수/0 은 `assert` 로 차단.

### 3-3. BSP 트리 — `GridNode` (N-ary)

```dart
sealed class GridNode {
  const GridNode();
}

final class Split extends GridNode {
  final SplitAxis axis;
  final List<double> positions;   // 0..1, 오름차순, length >= 1
  final List<GridNode> children;  // length == positions.length + 1

  // ⚠ Dart 한계 (3.x 시점): const constructor 의 assert 안에서 List.length 접근 불가.
  // 따라서 Split 은 const 가 아니다. 모든 인스턴스는 일반 (non-const) 생성.
  // 이는 NamedTemplate / kGridTemplates 도 final 로 만드는 이유.
  Split({
    required this.axis,
    required this.positions,
    required this.children,
  })  : assert(positions.isNotEmpty),
        assert(children.length == positions.length + 1);
}

final class Leaf extends GridNode {
  final int cellId; // 0..N-1, 트리 내 유일
  const Leaf(this.cellId);
}

enum SplitAxis { vertical, horizontal }
```

**N-ary 인 이유**: "우측 3등분" 같은 패턴을 한 노드에서 1:1 표현. 디자이너 의도 매핑이 직관적이고 트리 깊이가 얕아 traversal 빠름.

**invariant** (templates_test.dart 에서 자동 검증):
- 각 템플릿 트리의 leaf 개수 == N
- 각 템플릿의 cellId 집합 == `{0, 1, ..., N-1}` (중복/누락 없음)
- `Split.positions` 의 모든 값 ∈ 화이트리스트 + strictly ascending

### 3-4. 큐레이션 래퍼 — `NamedTemplate`

```dart
class NamedTemplate {
  final String name;       // "n4_left1right3"
  final GridNode tree;
  final List<int> cellIds; // 0..N-1, 트리 traversal 결과 캐시 (테스트/디버깅)

  const NamedTemplate({
    required this.name,
    required this.tree,
    required this.cellIds,
  });
}
```

- `name` 이 `GridSuggestion.templateName` 으로 그대로 들어가 텔레메트리/dedup 에서 사용됨.
- `cellIds` 는 트리 traversal 캐시 (중복 계산 방지) — 컴파일타임 const 단계에서 디자이너 의도 순서대로 부여.

### 3-5. 출력 — `GridSuggestion`

```dart
@freezed
class GridSuggestion with _$GridSuggestion {
  const factory GridSuggestion({
    required GridNode tree,                    // 셀 cellId 부여 완료된 BSP 트리
    required Map<int, String> mediaByCellId,   // cellId → MediaItem.id
    required double loss,                      // 매핑 품질 (낮을수록 좋음, 디버깅/텔레메트리)
    required String templateName,              // "n4_left1right3" 등 식별자
  }) = _GridSuggestion;
}
```

- `loss` / `templateName` 을 살려둔 이유: PRD §1 KPI ("자동 제안 수락률 70%", "선 드래그 사용률 30%") 측정에 호출부가 사용. v2.0 Firebase Analytics 도입 시 그대로 이벤트 attribute 로 흘림.

### 3-6. Cursor — `SuggestCursor`

```dart
@freezed
class SuggestCursor with _$SuggestCursor {
  const factory SuggestCursor({
    required Set<String> shownTemplateNames,  // 이미 본 템플릿 이름들
    required int batchIndex,                  // 0=첫 호출, 1/2/3 = "다른 제안 보기" 1·2·3회 (PRD: 추가 최대 3회)
  }) = _SuggestCursor;
}
```

- 첫 호출은 `cursor: null` 로 시작.
- 알고리즘 내부에서 `cursor == null` → `SuggestCursor(shownTemplateNames: {}, batchIndex: 0)` 으로 초기화.
- `batchIndex >= 3` (= 4번째 batch 까지 본 상태) 이면 다음 호출 시 `nextCursor: null` 반환 (PRD 한도 도달).
- **실용적 주의**: N별 후보 수가 ~3-5개 라 `maxResults=3` 일 때 1-2 batch 로 풀 소진되는 게 일반적. batchIndex 한도(3회)는 이론적 안전망 — 실제 사용에선 풀 소진이 먼저 발동.

### 3-7. 공개 API

```dart
// suggester.dart
({List<GridSuggestion> suggestions, SuggestCursor? nextCursor}) suggest({
  required List<MediaItem> media,
  required CanvasRatio canvas,
  SuggestCursor? cursor,                              // null = 첫 호출
  double Function(MediaItem item)? weightOf,          // null = 모두 1.0
  int maxResults = 3,
});
```

- 함수형 cursor — immutable, Riverpod `Notifier` 가 cursor 만 들고 있으면 됨.
- `weightOf` 가 v1.x 영상 가중치 1.5 진입점. v1 호출부는 `null` 패스.
- `nextCursor == null` → 후보 풀 소진 또는 3회 한도 도달.
- 반환은 record `(suggestions: ..., nextCursor: ...)` — 호출부에서 패턴 매칭 자연스러움.

---

## 4. 알고리즘 단계

### 4-1. 전체 파이프라인 (7-step)

```
suggest(media, canvas, cursor, weightOf, maxResults)
  │
  ├─ Step 1.  입력 검증 & 정규화        [validate]
  ├─ Step 2.  N→후보 템플릿 가져오기     [templateLookup]   ← cursor.shownTemplateNames 제외
  ├─ Step 3.  각 템플릿의 셀 bbox 계산   [cellGeometry]
  ├─ Step 4.  셀↔미디어 매핑 (브루트포스 N!) + loss [matcher]
  ├─ Step 5.  loss 정렬 + 다양성 dedup   [ranker]
  ├─ Step 6.  top maxResults 추출        [pick]
  └─ Step 7.  cursor 갱신                [advanceCursor]
```

각 step 은 **순수 함수** — sub-package 별 파일로 분리, 각자 단위 테스트.

### 4-2. Step 1 — 입력 검증

| 케이스 | 처리 |
| --- | --- |
| `media.length < 2` | `ArgumentError("media must have ≥ 2 items, got ${media.length}")` |
| `media.length > 9` | `ArgumentError("media must have ≤ 9 items, got ${media.length}")` |
| `aspectRatio <= 0` 또는 `isNaN` 또는 `isInfinite` | `ArgumentError("aspectRatio must be positive finite, got $value at index $i")` |
| 동일 `id` 중복 | `ArgumentError("media items must have unique ids, duplicate: $id")` |
| `weightOf(item) < 0` | `ArgumentError("weight must be non-negative, got $w for $id")` |

N=1 은 알고리즘 책임 외 — 호출부가 PRD §5-6 ("한 장이면 자르지 않고 그대로") 처리.

### 4-3. Step 2 — 후보 템플릿 lookup

```dart
final candidates = kGridTemplates[media.length]!  // N 보장됨 (Step 1 통과)
    .where((t) => !cursor.shownTemplateNames.contains(t.name))
    .toList();
```

- `cursor == null` → 빈 set 으로 초기화되어 모든 후보 노출.
- 후보 0개면 `(suggestions: [], nextCursor: null)` 즉시 반환.

### 4-4. Step 3 — 셀 bbox & 종횡비

BSP 트리를 root bbox `(0, 0, 1, 1)` 부터 재귀 traversal. 각 Leaf 의 normalized bbox `(x, y, w, h)` 계산:

```dart
Map<int, Rect> cellBBoxes(GridNode tree, {Rect bounds = const Rect.fromLTWH(0,0,1,1)}) {
  switch (tree) {
    case Leaf(:final cellId):
      return {cellId: bounds};
    case Split(:final axis, :final positions, :final children):
      // axis 에 따라 bounds 를 positions 로 분할 → 각 child 재귀
      // 결과 Map 들을 합침
      ...
  }
}
```

**셀 종횡비**:
```
cellAspectRatio = (w * canvas.value) / h
```

예: 캔버스 9:16 (`canvas.value = 0.5625`), 셀 정규화 크기 `(0.5, 1.0)` → cellAR = `0.5 * 0.5625 / 1.0 = 0.28` (세로로 길쭉).

### 4-5. Step 4 — 매핑 + Loss

**Loss 함수 (log 비율 차이의 가중합)**:

```
loss(σ) = Σᵢ wₘ(σ(i)) × |ln(cellAspectᵢ) - ln(mediaAspectσ(i))|
```

- 가로 2배 차이와 세로 2배 차이가 perceptually 동일하게 평가됨 (`ln(2) = -ln(0.5)`).
- 영상 가중치 훅(`weightOf`) 이 곱셈으로 자연스럽게 반영 — v1.x 에서 영상에 1.5 주면 영상이 큰 셀로 가도록 편향.

**탐색 — 브루트포스 N! permutation**:

- N=9 → 362,880 permutations × 9 비교 = ~3.3M ops × 후보 템플릿 수.
- 후보 8개 가정 시 ~26M ops, 모바일 ~150-300ms. PRD §11 `< 3초` 충분.
- 헝가리안 O(N³) 이 ~500배 빠르지만 v1 에선 불필요. v1.x 에서 측정 후 교체.
- **결정성**: 동률 발생 시 첫 번째 permutation 채택 (정렬 순서로 자연스러움).

```dart
({List<int> mapping, double loss}) bestMapping(
  List<double> cellAspects,
  List<({String id, double aspect, double weight})> media,
) {
  // 모든 N! permutation 평가, 최소 loss 채택
}
```

### 4-6. Step 5 — 다양성 dedup (2 layer)

PRD §9-2-1 step 4 가 "분할 방향 동일 + 선 위치 ±10% 이내면 중복" 으로 명세.

**1차 — 큐레이션 책임 (주)**: 템플릿 정의 시 의도적으로 다양한 패턴만 만들어서 dedup 이 거의 불필요하게. `/dev` 갤러리에서 시각 확인.

**2차 — fingerprint 안전망 (보조)**: 트리에서 모든 `Split` 의 `(axis, rounded(position, 0.1))` 를 정렬해 fingerprint string 생성. 같은 fingerprint 후보 중 loss 가 더 낮은 쪽만 살림.

```dart
String _fingerprint(GridNode node) {
  // axis + rounded(positions, 0.1) 를 트리 순서대로 직렬화
  // 예: "V@0.5(L,H@0.3,0.7(L,L,L))"
}
```

큐레이션이 잘되면 안전망은 거의 발동 안 하지만, 사람 실수에 대한 컴파일 후 안전 보장.

### 4-7. Step 6 — top maxResults

`loss` 오름차순 정렬 → 상위 `maxResults` (기본 3) 추출. 동률 시 `templateName` 알파벳 오름차순.

### 4-8. Step 7 — cursor 갱신

```dart
final picked = ranked.take(maxResults).toList();
final nextShown = {
  ...cursor.shownTemplateNames,
  ...picked.map((s) => s.templateName),
};
// 다음 호출에서 보여줄 템플릿이 남아있는지 lookahead.
// 풀 소진 직후 호출은 빈 결과 + nextCursor null 로 빠지지만, 그 호출에서 cursor 가
// 갱신되지 않아 호출부의 cursor 변수가 이전 batch 의 non-null 값으로 남는다.
// 이번 batch 에서 풀이 소진되는 경계를 잡아 즉시 nextCursor=null 을 반환해야
// 호출부가 한 번의 응답으로 종료를 인지할 수 있다.
final nextAvailable = allTemplates
    .where((t) => !nextShown.contains(t.name))
    .isNotEmpty;
final nextCursor =
    (picked.isEmpty || cursor.batchIndex >= 3 || !nextAvailable)
    ? null  // 풀 소진 또는 PRD 한도 도달 (첫 호출 + 다른 제안 3회)
    : SuggestCursor(
        shownTemplateNames: nextShown,
        batchIndex: cursor.batchIndex + 1,
      );
```

### 4-9. 성능 예산

| 항목 | 목표 | 예측 |
| --- | --- | --- |
| `suggest()` total (N=9) | < 3초 (PRD §11) | ~150-300ms (모바일) |
| 첫 호출 cold start | < 500ms | const 템플릿이라 lazy load 0 |
| 메모리 | - | const 트리 + N×후보수 매핑, < 1MB |

---

## 5. 큐레이션 카탈로그

### 5-1. 분할 위치 화이트리스트

```dart
const _allowedPositions = <double>{
  1/4,    // 0.25 — 4-row/4-col 균등 분할용
  1/3,    // 0.333...
  0.4,
  0.5,
  0.6,
  2/3,    // 0.666...
  3/4,    // 0.75 — 4-row/4-col 균등 분할용
};
```

- PRD §9-2-3 에디터 스냅 가이드(½, ⅓, ⅔)에 4분할 균등용 ¼·¾ 추가.
- 모든 `Split.positions` 의 각 값은 이 set 에 속해야 함 (templates_test.dart 강제).
- 부동소수 비교는 `1e-9` 이내 절대오차로 (1/3, 2/3 무한소수 대응).
- v1.x 사용자 데이터 보고 set 확장 가능 (e.g., 황금비 0.382/0.618, 5분할 ⅕·⅖·⅗·⅘).

### 5-2. N별 템플릿 개수 (보수적 시작)

> 표는 **목표 하한** 만 정의. 실제 패턴 list 는 plan/큐레이션 단계에서 `/dev` 갤러리 시각 iterate 로 확정. templates_test invariant #2 가 N별 ≥3 을 강제, 이 spec 의 합계 ~31개는 plan 분량 추정용.

| N | 목표 개수 (≥) | 큐레이션 방향 |
| --- | --- | --- |
| 2 | 3 | 등분(V½, H½) + 비대칭(V60-40 등) |
| 3 | 4 | 3-등분 + L자 변형 |
| 4 | 5 | 2×2 + 1+3 변형(상/하/좌/우) + 4분할 균등 (¼ 화이트리스트 활용) |
| 5 | 4 | 2+3 / 1+1+3 / 1+4 변형. 5분할 균등은 화이트리스트 외라 v1 제외 |
| 6 | 5 | 2×3, 3×2 + 1+5 / 2+4 변형 |
| 7 | 4 | 1+6 / 3+4 / 1+3+3 — 큐레이션 가장 어려운 N |
| 8 | 3 | 4×2, 2×4 + 1+7 변형 |
| 9 | 3 | 3×3 + 1+8 변형(좌1, 상1) |
| **합 (≥)** | **~31** | |

이 ~31개를 v1 에 박아두고, 출시 후 KPI(자동 제안 수락률 70%) 관찰하며 v1.x 에서 확장.

### 5-3. 작명 컨벤션

```dart
// templates/_n4_templates.dart
final _n4_grid2x2 = NamedTemplate(
  name: 'n4_grid2x2',
  tree: Split(
    axis: SplitAxis.horizontal,
    positions: [0.5],
    children: [
      Split(axis: SplitAxis.vertical, positions: [0.5], children: [Leaf(0), Leaf(1)]),
      Split(axis: SplitAxis.vertical, positions: [0.5], children: [Leaf(2), Leaf(3)]),
    ],
  ),
  cellIds: [0, 1, 2, 3],
);

final _n4_left1right3 = NamedTemplate(
  name: 'n4_left1right3',
  tree: Split(
    axis: SplitAxis.vertical,
    positions: [0.5],
    children: [
      Leaf(0),
      Split(
        axis: SplitAxis.horizontal,
        positions: [1/3, 2/3],
        children: [Leaf(1), Leaf(2), Leaf(3)],
      ),
    ],
  ),
  cellIds: [0, 1, 2, 3],
);
```

- 식별자: `_n{N}_{descriptiveName}`, snake_case, IDE grep 친화.
- private (`_` 접두어). 외부엔 `kGridTemplates` 한 곳에서만 노출.
- cellId 는 0,1,2... 순으로 자연스러운 시각 순서(좌→우, 상→하)와 일치 — 매핑 알고리즘이 사용자가 "왼쪽 위" 라고 인식하는 셀에 첫 미디어를 배정하도록.

### 5-4. 카탈로그 entry point

```dart
// templates/grid_templates.dart
import 'dart:collection';

final Map<int, List<NamedTemplate>> kGridTemplates =
    UnmodifiableMapView<int, List<NamedTemplate>>({
  2: UnmodifiableListView<NamedTemplate>(_n2Templates),
  3: UnmodifiableListView<NamedTemplate>(_n3Templates),
  4: UnmodifiableListView<NamedTemplate>(_n4Templates),
  5: UnmodifiableListView<NamedTemplate>(_n5Templates),
  6: UnmodifiableListView<NamedTemplate>(_n6Templates),
  7: UnmodifiableListView<NamedTemplate>(_n7Templates),
  8: UnmodifiableListView<NamedTemplate>(_n8Templates),
  9: UnmodifiableListView<NamedTemplate>(_n9Templates),
});
```

각 `_nXTemplates` 는 해당 파일 상단의 `final` list. lazy 로딩 없음, 모듈 로드 시 1회 초기화.
`Split` 이 const 불가능하므로 `const Map`/`const list` 가 모두 불가능 — `UnmodifiableMapView`/`UnmodifiableListView` 로 외부 mutation 방지.

### 5-5. /dev 갤러리 — "Grid Templates" 섹션 신규

기존 `lib/features/dev/dev_gallery_page.dart` 의 섹션 리스트에 추가:

```
[colors] [typography] [buttons] [grid templates ★ 신규]
```

`lib/features/dev/widgets/grid_template_preview.dart` (신규) 가 `GridNode` 를 받아 시각 위젯으로 렌더:

```
┌──────────────────────┐
│  n4_left1right3      │ ← 템플릿 이름 (AppTextStyles.body_16)
│ ┌─────┬──────┐       │
│ │     │  ▢   │       │
│ │  ▢  ├──────┤       │ ← 트리 시각화 (정사각/캔버스비율 컨테이너)
│ │     │  ▢   │       │   각 셀에 cellId 번호 작게
│ │     ├──────┤       │
│ │     │  ▢   │       │
│ └─────┴──────┘       │
│ canvas: 9:16 ▾       │ ← 비율 토글 (셀 종횡비 시각 영향)
└──────────────────────┘
```

- **모든 캔버스 비율 토글** 로 동일 템플릿이 9:16 / 1:1 / 4:5 / 16:9 / custom 에서 어떻게 보이는지 즉시 시각 확인.
- N 별로 묶어서 한 줄에 N=2 (3개), N=3 (4개) ... 식으로 grid 배치.
- 색상/텍스트는 `AppColors`/`AppTextStyles`/`AppSpacing` 만 사용 (CLAUDE.md 디자인 시스템 룰).
- 이 섹션이 큐레이션 작업의 **WYSIWYG 편집기** 역할 — 코드 수정 → 핫리로드 → 시각 확인 루프.

알고리즘 모듈은 `flutter/` import 금지지만, **`/dev` 갤러리 위젯은 알고리즘 모듈에서 데이터만 가져오는 소비자** 라 의존 방향 OK.

---

## 6. 에러 정책 + 테스트 전략

### 6-1. 에러 정책

**원칙**: silent recovery 안 함. 알고리즘은 깊은 레이어 → 호출부가 분기/경고 책임.

| 케이스 | 처리 |
| --- | --- |
| `media.length < 2` 또는 `> 9` | `ArgumentError` |
| `aspectRatio <= 0` / `NaN` / `Infinite` | `ArgumentError` |
| 동일 `id` 중복 | `ArgumentError` |
| `weightOf` 음수 반환 | `ArgumentError` |

### 6-2. 정상 종료 엣지 케이스

| 케이스 | 동작 |
| --- | --- |
| 모든 미디어 동일 종횡비 | loss tie → templateName 알파벳 순 tie-breaking |
| `cursor.shownTemplateNames` 가 N 의 모든 템플릿 포함 | `(suggestions: [], nextCursor: null)` |
| `cursor.batchIndex == 3` (4번째 = 마지막 정상 batch) | 정상 batch 반환 + `nextCursor: null` |
| `cursor.batchIndex >= 4` (한도 초과 cursor 들어옴) | `(suggestions: [], nextCursor: null)` 방어적 |
| 캔버스 비율 극단 (`custom(1, 100)`) | 정상 동작. 매핑 품질만 저하. 호출부 sanity check 권장 |
| N=1 호출 | **알고리즘 책임 외** (PRD §5-6, 호출부 single-item bypass) |

### 6-3. 테스트 5-Layer

**Layer 1 — 입력 검증** (`validate_test.dart`)

위 6-1 표 모든 케이스 `expect(() => suggest(...), throwsA(isA<ArgumentError>()))`. ~10 케이스.

**Layer 2 — 순수 함수 단위** (`cell_geometry_test.dart`, `matcher_test.dart`, `ranker_test.dart`)

각 sub-package 가 순수 함수라 입출력 골든 비교가 자연스러움.

```dart
// cell_geometry_test.dart 예시
test('n4_grid2x2 cell bboxes (canvas 1:1)', () {
  final bboxes = cellBBoxes(_n4_grid2x2.tree);
  expect(bboxes[0], const Rect.fromLTWH(0,    0,    0.5, 0.5));
  expect(bboxes[1], const Rect.fromLTWH(0.5,  0,    0.5, 0.5));
  expect(bboxes[2], const Rect.fromLTWH(0,    0.5,  0.5, 0.5));
  expect(bboxes[3], const Rect.fromLTWH(0.5,  0.5,  0.5, 0.5));
});

// matcher_test.dart 예시 — log loss 검증
test('log loss prefers matching aspect ratios', () {
  final cells = [2.0, 0.5];                                        // 가로 셀, 세로 셀
  final media = [
    (id: 'w', aspect: 2.0, weight: 1.0),
    (id: 't', aspect: 0.5, weight: 1.0),
  ];
  final result = bestMapping(cells, media);
  expect(result.mapping, [0, 1]);                                  // w → 셀0(가로), t → 셀1(세로)
  expect(result.loss, closeTo(0, 1e-9));                           // 완벽 매칭
});
```

**Layer 3 — 큐레이션 무결성** (`templates_test.dart`)

8 invariant 자동 검증:

| # | 검증 | 실패 시 의미 |
| --- | --- | --- |
| 1 | `kGridTemplates.keys == {2,3,4,5,6,7,8,9}` | N 누락 |
| 2 | 각 N 의 템플릿 list 길이 ≥ 3 | 후보 부족 (PRD: "3~5개") |
| 3 | 각 템플릿 leaf 개수 == N | 트리 구조 오류 |
| 4 | 각 템플릿 `cellIds == 0..N-1` 정확히 | cellId 중복/누락 |
| 5 | 각 `Split.positions` 의 모든 값 ∈ `_allowedPositions` | ratio 화이트리스트 위반 |
| 6 | 각 `Split.positions` 가 strictly ascending | invariant 위배 |
| 7 | 같은 N 안에서 fingerprint 충돌 없음 | 중복 큐레이션 |
| 8 | `name` 이 `n{N}_` 으로 시작 | 작명 컨벤션 위반 |

**Layer 4 — 통합 + golden** (`suggester_test.dart`)

```dart
test('determinism: same input → same output', () {
  final input = _fixture4Photos;
  final r1 = suggest(media: input, canvas: const CanvasRatio.portrait916());
  final r2 = suggest(media: input, canvas: const CanvasRatio.portrait916());
  expect(
    r1.suggestions.map((s) => s.templateName).toList(),
    r2.suggestions.map((s) => s.templateName).toList(),
  );
});

test('cursor: pool exhaustion eventually returns null nextCursor', () {
  // N=4 는 ~5 templates → maxResults=3 이면 2 batch 로 풀 소진 예상
  SuggestCursor? cursor;
  var batches = 0;
  while (batches < 4) {                        // PRD 한도(첫호출+3회=4 batch) 안에서
    final r = suggest(
      media: _fixture4Photos,
      canvas: const CanvasRatio.square(),
      cursor: cursor,
    );
    if (r.suggestions.isEmpty) break;
    batches++;
    cursor = r.nextCursor;
    if (cursor == null) break;                 // 풀 소진 또는 한도 도달
  }
  expect(cursor, isNull, reason: 'cursor must terminate within PRD 4-batch limit');
  expect(batches, greaterThanOrEqualTo(1));
});

test('cursor: PRD limit enforced even with infinite hypothetical pool', () {
  // maxResults=1 + 큰 N 으로 한도 도달 케이스 분리 검증
  SuggestCursor? cursor;
  final seen = <String>{};
  for (var i = 0; i < 4; i++) {
    final r = suggest(
      media: _fixture6Photos,
      canvas: const CanvasRatio.square(),
      cursor: cursor,
      maxResults: 1,
    );
    if (r.suggestions.isEmpty) break;
    seen.addAll(r.suggestions.map((s) => s.templateName));
    cursor = r.nextCursor;
  }
  expect(cursor, isNull, reason: 'PRD: 첫 호출 + 다른 제안 3회 = 최대 4 batch');
});

test('golden: N=4 portrait916 first suggestion is grid2x2', () {
  final r = suggest(
    media: _fixture4Photos,
    canvas: const CanvasRatio.portrait916(),
  );
  expect(r.suggestions.first.templateName, 'n4_grid2x2');
});
```

Golden 은 N=2..9 각각 대표 fixture 1개 → 첫 suggestion 의 templateName 고정. 큐레이션 의도 변경 시 골든도 의도적 업데이트 (실패하면 PR 리뷰 게이트).

**Layer 5 — 성능 측정** (`suggester_perf_test.dart`)

```dart
test('perf: N=9 within 300ms on test runner', () {
  final input = _fixture9MixedAspect;
  final sw = Stopwatch()..start();
  for (var i = 0; i < 10; i++) {
    suggest(media: input, canvas: const CanvasRatio.portrait916());
  }
  sw.stop();
  final avg = sw.elapsedMilliseconds / 10;
  print('avg N=9 suggest: ${avg}ms');
  expect(avg, lessThan(300));   // 테스트 러너 기준 — 모바일은 더 빠름
});
```

테스트 러너(macOS host) 기준 300ms. PRD `< 3초 (모바일)` 에 10x 마진. CI noise 크면 expect 빼고 print 만 (회귀 감지용 baseline).

### 6-4. 커버리지 목표

`~/.claude/rules/testing.md` = 80% 최소. 알고리즘 모듈은 순수 함수 + sealed class 라 **95%+ 자연스럽게 도달** 예상. `flutter test --coverage` + `lcov` 로 측정.

---

## 7. 호출부 통합 가이드 (참고용 — Suggestion 화면 spec 에서 본격 다룸)

이 spec 의 책임은 알고리즘 모듈이지만, 다음 사이클의 Suggestion 화면이 어떻게 쓸지 짧은 예시:

```dart
// Suggestion 화면의 Riverpod Notifier 예시
class SuggestionNotifier extends Notifier<SuggestionState> {
  @override
  SuggestionState build() => const SuggestionState.empty();

  void loadInitial(List<MediaItem> media, CanvasRatio canvas) {
    final r = suggest(media: media, canvas: canvas);
    state = SuggestionState(
      media: media,
      canvas: canvas,
      suggestions: r.suggestions,
      cursor: r.nextCursor,
    );
  }

  void loadMore() {
    if (state.cursor == null) return;                    // 풀 소진
    final r = suggest(
      media: state.media,
      canvas: state.canvas,
      cursor: state.cursor!,
    );
    state = state.copyWith(
      suggestions: [...state.suggestions, ...r.suggestions],
      cursor: r.nextCursor,
    );
  }
}
```

호출부는 함수 한두 번 호출이 끝. cursor 의 immutable 한 진행만 들고 있으면 됨.

---

## 8. 작업 분량 추정

| Phase | 분량 | 비고 |
| --- | --- | --- |
| 데이터 모델 + Freezed codegen | ~2시간 | MediaItem / CanvasRatio / GridNode / GridSuggestion / SuggestCursor / NamedTemplate |
| `cellGeometry` + `matcher` + `ranker` 구현 | ~4시간 | 순수 함수, 단위 테스트 동시 |
| 템플릿 ~31개 const 정의 | ~3시간 | 한 줄당 평균 5분 × 31 |
| `/dev` 갤러리 미리보기 위젯 + 비율 토글 | ~3시간 | BSP → Widget 변환 + 시각 카탈로그 |
| 무결성 테스트 8종 + 통합·golden·perf | ~3시간 | Layer 3-5 |
| 시각 iterate (큐레이션 품질 다듬기) | ~3시간 | /dev 갤러리에서 ugly 찾아 교체 |
| **합계** | **~18시간** | 알고리즘 ~10h + 큐레이션·갤러리 ~8h |

plan 단계에서 phase 분리 권장:
1. **Phase A** — 데이터 모델 + 알고리즘 코어 (~6h, 테스트 동반)
2. **Phase B** — 큐레이션 카탈로그 ~31개 (~3h)
3. **Phase C** — `/dev` 갤러리 통합 (~3h)
4. **Phase D** — 시각 iterate + 품질 다듬기 (~3h)
5. **Phase E** — perf/golden/integration 마감 (~3h)

각 phase 가 독립 PR 가능. A 만 머지돼도 다음 사이클(Suggestion 화면) 시작 가능.

---

## 9. 향후 마이그레이션 경로 (이 spec 의 forward-compatibility)

| 미래 작업 | 이 spec 의 어디가 받침대인지 |
| --- | --- |
| F07 영상 자동 싱크 | `MediaItem.durationMs` 필드 + `weightOf` 함수 인자 → 알고리즘 본체 변경 0, 호출부에서 `weightOf` 만 채우면 됨 |
| F02-F06 에디터 | `GridSuggestion.tree` (BSP) 가 에디터 내부 표현으로 그대로 사용 가능. 선 드래그 = 한 `Split.positions[i]` 수정 |
| F11 되돌리기/다시하기 | `GridNode` 가 immutable + `const` 라 history stack 그대로 push/pop |
| F16 "내 템플릿" | `NamedTemplate` 직렬화(JSON) → 사용자 정의 카탈로그를 런타임에 `kGridTemplates` 와 합침 |
| 헝가리안 매핑 (성능) | `bestMapping()` 시그니처 유지 + 내부만 교체 |
| v2.0 Firebase Analytics | `GridSuggestion.loss` / `templateName` 이 이미 출력에 있어 호출부에서 이벤트 attribute 로 흘림 |

---

## 10. PRD 매핑

| PRD 섹션 | 이 spec 에서 어떻게 다뤘나 |
| --- | --- |
| §F00 자동 레이아웃 제안 | 본 spec 전체 |
| §9-2-1 알고리즘 5단계 | §4 (7-step 으로 분해) |
| §9-2-2 그리드 데이터 구조 | §3-3 — 평면 V/H 한계를 BSP 트리로 일반화. PRD 의 V/H 표현은 균형 BSP 의 특수 케이스로 호환 |
| §9-2-3 선 이동 제약 | §5-1 분할 위치 화이트리스트(½, ⅓, ⅔)와 정합 |
| §9-2-4 영상 자동 싱크 | 알고리즘 책임 외(렌더 파이프라인). v1.x 진입점은 `weightOf` 훅 |
| §11 비기능 (성능 < 3초) | §4-9 + §6-3 Layer 5 perf test |
| §13 "최상" 리스크 (자동 제안 품질) | §5-2 보수적 큐레이션 + §5-5 /dev 갤러리 시각 iterate |
| §1 KPI 측정 | §3-5 `loss`/`templateName` 출력 + §9 v2.0 Analytics 마이그레이션 경로 |
