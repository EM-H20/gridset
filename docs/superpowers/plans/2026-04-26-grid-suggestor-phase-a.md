# Grid Suggestor v1 — Phase A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `lib/cores/grid_suggestor/` 코어 알고리즘 — 데이터 모델 + cellGeometry + matcher + ranker + validator + suggester 통합 + N=2 stub 템플릿 3개 + 단위/통합 테스트 통과까지.

**Architecture:** 순수 Dart 모듈, `flutter/` 패키지 import 금지, `package:meta` + Freezed codegen 만 사용. BSP 트리(`Split`/`Leaf` sealed class) 가 자료구조 코어. 함수형 cursor 패턴(immutable). 7-step pipeline (validate → templateLookup → cellGeometry → matcher → ranker → pick → advanceCursor) 을 sub-package 별 순수 함수로 분리.

**Tech Stack:** Dart 3.x (sealed class + record), Freezed, json_serializable, build_runner, flutter_test (host runner).

**Spec:** `docs/superpowers/specs/2026-04-26-grid-suggestor-design.md`

**Phase Scope:** **Phase A 만**. Phase B (전체 큐레이션 N=3..9), Phase C (dev 갤러리), Phase D (시각 iterate), Phase E (golden·perf 마감) 은 별도 후속 plan 사이클.

**Phase A Deliverable Definition (DoD):**
- `flutter analyze` 무경고
- `flutter test test/cores/grid_suggestor/` 전체 통과
- `suggest()` 호출 시 N=2 입력에 대해 정상 동작 (3개 stub 템플릿 중 매핑된 결과 반환)
- 모듈 외부에서 `import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';` 한 줄로 모든 공개 API 접근 가능
- 코드 커버리지 측정 — 알고리즘 모듈 ≥ 90%

---

## File Structure

### Create

| 경로 | 책임 |
| --- | --- |
| `lib/cores/grid_suggestor/grid_suggestor.dart` | 공개 API 배럴 (re-export 만) |
| `lib/cores/grid_suggestor/models/media_item.dart` | 입력 — Freezed `MediaItem` + `MediaType` enum |
| `lib/cores/grid_suggestor/models/canvas_ratio.dart` | sealed `CanvasRatio` (4 프리셋 + custom) |
| `lib/cores/grid_suggestor/models/grid_node.dart` | sealed `GridNode` (`Split`/`Leaf`) + `SplitAxis` enum + `cellIdsOf()` traversal helper |
| `lib/cores/grid_suggestor/models/named_template.dart` | 큐레이션 래퍼 — `NamedTemplate` |
| `lib/cores/grid_suggestor/models/grid_suggestion.dart` | 출력 — Freezed `GridSuggestion` |
| `lib/cores/grid_suggestor/models/suggest_cursor.dart` | Freezed `SuggestCursor` |
| `lib/cores/grid_suggestor/templates/grid_templates.dart` | `kGridTemplates` Map (Phase A 는 N=2 만) |
| `lib/cores/grid_suggestor/templates/_n2_templates.dart` | private — N=2 템플릿 3개 |
| `lib/cores/grid_suggestor/geometry/cell_geometry.dart` | BSP → Map<cellId, Rect> + 셀 종횡비 계산 |
| `lib/cores/grid_suggestor/matching/media_to_cell_matcher.dart` | log loss + 브루트포스 N! `bestMapping()` |
| `lib/cores/grid_suggestor/ranking/candidate_ranker.dart` | 정렬 + fingerprint dedup |
| `lib/cores/grid_suggestor/validation/input_validator.dart` | `validateSuggestInput()` — `ArgumentError` 던지는 검증 |
| `lib/cores/grid_suggestor/suggester.dart` | 진입점 `suggest(...)` 7-step 통합 |
| `test/cores/grid_suggestor/media_item_test.dart` | |
| `test/cores/grid_suggestor/canvas_ratio_test.dart` | |
| `test/cores/grid_suggestor/grid_node_test.dart` | |
| `test/cores/grid_suggestor/named_template_test.dart` | |
| `test/cores/grid_suggestor/cell_geometry_test.dart` | |
| `test/cores/grid_suggestor/matcher_test.dart` | |
| `test/cores/grid_suggestor/ranker_test.dart` | |
| `test/cores/grid_suggestor/validate_test.dart` | |
| `test/cores/grid_suggestor/templates_n2_test.dart` | N=2 무결성 (전체 8 invariant 는 Phase B 마지막에) |
| `test/cores/grid_suggestor/suggester_test.dart` | 통합 + 결정성 + cursor |
| `test/cores/grid_suggestor/fixtures/photos.dart` | 테스트 fixture 모음 |

### Modify

없음 (Phase A 는 신규 모듈만, 호출부는 Phase B 이후).

---

## Pre-flight: 빌드 환경 확인

- [ ] **Step 0-1: 코드 생성기 실행 환경 확인**

  Run (저장소 루트에서):
  ```bash
  flutter pub get
  ```
  Expected: dependencies 다 받아짐, 에러 없음.

- [ ] **Step 0-2: build_runner watch 시작 (별도 터미널에서 백그라운드 유지)**

  Run:
  ```bash
  dart run build_runner watch --delete-conflicting-outputs
  ```
  Expected: `[INFO] Succeeded after ...` 메시지. 이후 모든 `*.freezed.dart`, `*.g.dart` 자동 생성.

  > 이 명령은 plan 실행 동안 백그라운드 유지. 매 task commit 전 `flutter analyze` 가 정상이면 codegen 동기화 OK.

---

## Task 1: 폴더 구조 + 배럴 + 의존성 룰

**Files:**
- Create: `lib/cores/grid_suggestor/grid_suggestor.dart`

- [ ] **Step 1-1: 디렉터리 생성**

  Run:
  ```bash
  mkdir -p lib/cores/grid_suggestor/{models,templates,geometry,matching,ranking,validation}
  mkdir -p test/cores/grid_suggestor/fixtures
  ```
  Expected: 디렉터리 트리 생성됨.

- [ ] **Step 1-2: 빈 배럴 파일 작성**

  Create `lib/cores/grid_suggestor/grid_suggestor.dart`:
  ```dart
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
  ```

- [ ] **Step 1-3: 분석 통과 확인**

  Run:
  ```bash
  flutter analyze lib/cores/grid_suggestor/
  ```
  Expected: `No issues found!`.

- [ ] **Step 1-4: Commit**

  Run:
  ```bash
  git add lib/cores/grid_suggestor/grid_suggestor.dart
  git commit -m "chore : scaffold lib/cores/grid_suggestor/ 폴더 구조 및 공개 배럴 (#1)"
  ```

---

## Task 2: `MediaItem` 모델 (Freezed)

**Files:**
- Create: `lib/cores/grid_suggestor/models/media_item.dart`
- Test: `test/cores/grid_suggestor/media_item_test.dart`
- Modify: `lib/cores/grid_suggestor/grid_suggestor.dart` (배럴 export 추가)

- [ ] **Step 2-1: 실패하는 테스트 작성**

  Create `test/cores/grid_suggestor/media_item_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('MediaItem', () {
      test('photo: durationMs 는 null 허용', () {
        const item = MediaItem(
          id: 'p1',
          type: MediaType.photo,
          aspectRatio: 1.5,
        );
        expect(item.id, 'p1');
        expect(item.type, MediaType.photo);
        expect(item.aspectRatio, 1.5);
        expect(item.durationMs, isNull);
      });

      test('video: durationMs 가 들어감', () {
        const item = MediaItem(
          id: 'v1',
          type: MediaType.video,
          aspectRatio: 0.5625,
          durationMs: 5000,
        );
        expect(item.type, MediaType.video);
        expect(item.durationMs, 5000);
      });

      test('동일 값으로 만든 두 인스턴스는 == ', () {
        const a = MediaItem(id: 'x', type: MediaType.photo, aspectRatio: 1.0);
        const b = MediaItem(id: 'x', type: MediaType.photo, aspectRatio: 1.0);
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('JSON round-trip', () {
        const original = MediaItem(
          id: 'v1',
          type: MediaType.video,
          aspectRatio: 1.778,
          durationMs: 3000,
        );
        final json = original.toJson();
        final restored = MediaItem.fromJson(json);
        expect(restored, equals(original));
      });
    });
  }
  ```

- [ ] **Step 2-2: 테스트 실행 — 실패 확인**

  Run:
  ```bash
  flutter test test/cores/grid_suggestor/media_item_test.dart
  ```
  Expected: 컴파일 실패 (`MediaItem` not defined).

- [ ] **Step 2-3: `MediaItem` 구현**

  Create `lib/cores/grid_suggestor/models/media_item.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'media_item.freezed.dart';
  part 'media_item.g.dart';

  /// 알고리즘 입력 미디어 단위.
  ///
  /// `aspectRatio` 는 W/H, 양의 유한값. 호출부가 EXIF orientation 반영 후 넘김.
  /// `durationMs` 는 영상에서만 사용. v1 알고리즘은 무시 (가중치 1.0).
  @freezed
  class MediaItem with _$MediaItem {
    const factory MediaItem({
      required String id,
      required MediaType type,
      required double aspectRatio,
      int? durationMs,
    }) = _MediaItem;

    factory MediaItem.fromJson(Map<String, dynamic> json) =>
        _$MediaItemFromJson(json);
  }

  enum MediaType { photo, video }
  ```

- [ ] **Step 2-4: 배럴에 export 추가**

  Modify `lib/cores/grid_suggestor/grid_suggestor.dart` — 배럴 export 영역에 추가:
  ```dart
  export 'models/media_item.dart' show MediaItem, MediaType;
  ```

- [ ] **Step 2-5: 테스트 통과 확인**

  Run:
  ```bash
  flutter test test/cores/grid_suggestor/media_item_test.dart
  ```
  Expected: 모든 테스트 PASS (`+4: All tests passed!`).

- [ ] **Step 2-6: Commit**

  Run:
  ```bash
  git add lib/cores/grid_suggestor/models/media_item.dart \
          lib/cores/grid_suggestor/models/media_item.freezed.dart \
          lib/cores/grid_suggestor/models/media_item.g.dart \
          lib/cores/grid_suggestor/grid_suggestor.dart \
          test/cores/grid_suggestor/media_item_test.dart
  git commit -m "feat : MediaItem 입력 모델 (Freezed) + JSON round-trip 테스트 (#1)"
  ```

---

## Task 3: `CanvasRatio` sealed class

**Files:**
- Create: `lib/cores/grid_suggestor/models/canvas_ratio.dart`
- Test: `test/cores/grid_suggestor/canvas_ratio_test.dart`
- Modify: 배럴

- [ ] **Step 3-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/canvas_ratio_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('CanvasRatio', () {
      test('portrait916 = 9/16', () {
        expect(const CanvasRatio.portrait916().value, closeTo(9 / 16, 1e-12));
      });

      test('square = 1', () {
        expect(const CanvasRatio.square().value, 1.0);
      });

      test('portrait45 = 4/5', () {
        expect(const CanvasRatio.portrait45().value, closeTo(0.8, 1e-12));
      });

      test('landscape169 = 16/9', () {
        expect(const CanvasRatio.landscape169().value, closeTo(16 / 9, 1e-12));
      });

      test('custom(3, 2) = 1.5', () {
        expect(const CanvasRatio.custom(3, 2).value, closeTo(1.5, 1e-12));
      });

      test('custom: 동일 값으로 만든 인스턴스는 ==', () {
        expect(
          const CanvasRatio.custom(3, 2),
          equals(const CanvasRatio.custom(3, 2)),
        );
      });

      test('custom: w<=0 또는 h<=0 은 assert 로 막힘', () {
        expect(() => CanvasRatio.custom(0, 1), throwsA(isA<AssertionError>()));
        expect(() => CanvasRatio.custom(1, 0), throwsA(isA<AssertionError>()));
        expect(() => CanvasRatio.custom(-1, 1), throwsA(isA<AssertionError>()));
      });
    });
  }
  ```

- [ ] **Step 3-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/canvas_ratio_test.dart`
  Expected: 컴파일 실패.

- [ ] **Step 3-3: 구현**

  Create `lib/cores/grid_suggestor/models/canvas_ratio.dart`:
  ```dart
  /// 캔버스 종횡비 — 알고리즘이 셀 종횡비 계산 시 사용.
  ///
  /// PRD §F10: 9:16 / 1:1 / 4:5 / 16:9 + custom 지원.
  /// `value` 는 W / H 양의 유한값.
  sealed class CanvasRatio {
    const CanvasRatio();
    double get value;

    const factory CanvasRatio.portrait916() = _R916;
    const factory CanvasRatio.square() = _R11;
    const factory CanvasRatio.portrait45() = _R45;
    const factory CanvasRatio.landscape169() = _R169;
    const factory CanvasRatio.custom(double w, double h) = _RCustom;
  }

  final class _R916 extends CanvasRatio {
    const _R916();
    @override
    double get value => 9 / 16;
  }

  final class _R11 extends CanvasRatio {
    const _R11();
    @override
    double get value => 1;
  }

  final class _R45 extends CanvasRatio {
    const _R45();
    @override
    double get value => 4 / 5;
  }

  final class _R169 extends CanvasRatio {
    const _R169();
    @override
    double get value => 16 / 9;
  }

  final class _RCustom extends CanvasRatio {
    final double w;
    final double h;
    const _RCustom(this.w, this.h)
        : assert(w > 0, 'w must be positive'),
          assert(h > 0, 'h must be positive');

    @override
    double get value => w / h;

    @override
    bool operator ==(Object other) =>
        other is _RCustom && other.w == w && other.h == h;

    @override
    int get hashCode => Object.hash(w, h);
  }
  ```

- [ ] **Step 3-4: 배럴 export**

  Modify `lib/cores/grid_suggestor/grid_suggestor.dart`:
  ```dart
  export 'models/canvas_ratio.dart' show CanvasRatio;
  ```

- [ ] **Step 3-5: 테스트 통과**

  Run: `flutter test test/cores/grid_suggestor/canvas_ratio_test.dart`
  Expected: 모든 테스트 PASS.

- [ ] **Step 3-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/models/canvas_ratio.dart \
          lib/cores/grid_suggestor/grid_suggestor.dart \
          test/cores/grid_suggestor/canvas_ratio_test.dart
  git commit -m "feat : CanvasRatio sealed class (4 프리셋 + custom) + assertion 테스트 (#1)"
  ```

---

## Task 4: `GridNode` BSP sealed class + cellIds traversal

**Files:**
- Create: `lib/cores/grid_suggestor/models/grid_node.dart`
- Test: `test/cores/grid_suggestor/grid_node_test.dart`
- Modify: 배럴

- [ ] **Step 4-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/grid_node_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('GridNode', () {
      test('Leaf == Leaf 동일 cellId', () {
        expect(const Leaf(0), equals(const Leaf(0)));
        expect(const Leaf(0).hashCode, const Leaf(0).hashCode);
      });

      test('Leaf 다른 cellId 는 ≠', () {
        expect(const Leaf(0), isNot(equals(const Leaf(1))));
      });

      test('Split: positions 와 children 길이 mismatch 는 assert', () {
        expect(
          () => Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(0)],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('Split: positions 비어있으면 assert', () {
        expect(
          () => Split(
            axis: SplitAxis.vertical,
            positions: const [],
            children: const [Leaf(0), Leaf(1)],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('cellIdsOf: 단일 Leaf', () {
        expect(cellIdsOf(const Leaf(0)), [0]);
      });

      test('cellIdsOf: 깊이 1 split 2-way', () {
        const tree = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        expect(cellIdsOf(tree), [0, 1]);
      });

      test('cellIdsOf: 중첩 트리', () {
        const tree = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [
            Leaf(0),
            Split(
              axis: SplitAxis.horizontal,
              positions: [1 / 3, 2 / 3],
              children: [Leaf(1), Leaf(2), Leaf(3)],
            ),
          ],
        );
        expect(cellIdsOf(tree), [0, 1, 2, 3]);
      });
    });
  }
  ```

- [ ] **Step 4-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/grid_node_test.dart`
  Expected: 컴파일 실패.

- [ ] **Step 4-3: 구현**

  Create `lib/cores/grid_suggestor/models/grid_node.dart`:
  ```dart
  /// BSP (Binary Space Partition) 트리 — 그리드 레이아웃의 자료구조.
  ///
  /// `Split` 노드: 한 축으로 N-way 분할. positions 길이 + 1 == children 길이.
  /// `Leaf` 노드: 미디어가 들어갈 셀. cellId 는 트리 내 0..N-1 유일.
  ///
  /// PRD §9-2-2 의 평면 V/H 표현은 균형 BSP 트리의 특수 케이스.
  /// 비대칭 패턴("좌1+우3" 등)은 BSP 만 표현 가능.
  sealed class GridNode {
    const GridNode();
  }

  final class Split extends GridNode {
    final SplitAxis axis;
    final List<double> positions;
    final List<GridNode> children;

    // ⚠ Dart 한계: const constructor 의 assert 안에서 List.length 접근 불가.
    // 따라서 Split 은 const 가 아닌 일반 생성자. 모든 NamedTemplate / kGridTemplates 도 final.
    Split({
      required this.axis,
      required this.positions,
      required this.children,
    })  : assert(positions.isNotEmpty, 'positions must not be empty'),
          assert(
            children.length == positions.length + 1,
            'children.length must equal positions.length + 1',
          );

    @override
    bool operator ==(Object other) =>
        other is Split &&
        other.axis == axis &&
        _listEquals(other.positions, positions) &&
        _listEquals(other.children, children);

    @override
    int get hashCode =>
        Object.hash(axis, Object.hashAll(positions), Object.hashAll(children));
  }

  final class Leaf extends GridNode {
    final int cellId;
    const Leaf(this.cellId);

    @override
    bool operator ==(Object other) => other is Leaf && other.cellId == cellId;

    @override
    int get hashCode => cellId.hashCode;
  }

  enum SplitAxis { vertical, horizontal }

  /// 트리 내 모든 Leaf 의 cellId 를 in-order 로 수집.
  ///
  /// 큐레이션 무결성 검증(invariant: cellIds == 0..N-1) 과 NamedTemplate.cellIds 캐시에 사용.
  List<int> cellIdsOf(GridNode node) {
    final result = <int>[];
    void visit(GridNode n) {
      switch (n) {
        case Leaf(:final cellId):
          result.add(cellId);
        case Split(:final children):
          for (final c in children) {
            visit(c);
          }
      }
    }
    visit(node);
    return result;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  ```

- [ ] **Step 4-4: 배럴 export**

  Modify `grid_suggestor.dart`:
  ```dart
  export 'models/grid_node.dart' show GridNode, Split, Leaf, SplitAxis, cellIdsOf;
  ```

- [ ] **Step 4-5: 테스트 통과**

  Run: `flutter test test/cores/grid_suggestor/grid_node_test.dart`
  Expected: 모든 테스트 PASS.

- [ ] **Step 4-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/models/grid_node.dart \
          lib/cores/grid_suggestor/grid_suggestor.dart \
          test/cores/grid_suggestor/grid_node_test.dart
  git commit -m "feat : GridNode sealed class (Split/Leaf) + cellIdsOf traversal (#1)"
  ```

---

## Task 5: `NamedTemplate` 큐레이션 래퍼

**Files:**
- Create: `lib/cores/grid_suggestor/models/named_template.dart`
- Test: `test/cores/grid_suggestor/named_template_test.dart`
- Modify: 배럴

- [ ] **Step 5-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/named_template_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('NamedTemplate', () {
      test('cellIds 가 트리 traversal 결과와 일치하면 OK', () {
        const t = NamedTemplate(
          name: 'n2_v_half',
          tree: Split(
            axis: SplitAxis.vertical,
            positions: [0.5],
            children: [Leaf(0), Leaf(1)],
          ),
          cellIds: [0, 1],
        );
        expect(t.name, 'n2_v_half');
        expect(t.cellIds, [0, 1]);
      });

      test('cellIds 와 트리 traversal 결과가 mismatch 면 assert', () {
        expect(
          () => NamedTemplate(
            name: 'broken',
            tree: Split(  // Dart 한계: Split 은 non-const
              axis: SplitAxis.vertical,
              positions: const [0.5],
              children: const [Leaf(0), Leaf(1)],
            ),
            cellIds: const [0, 2], // 1 이어야 함
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('동일 값으로 만든 두 NamedTemplate 은 ==', () {
        const a = NamedTemplate(
          name: 'n2_v_half',
          tree: Split(
            axis: SplitAxis.vertical,
            positions: [0.5],
            children: [Leaf(0), Leaf(1)],
          ),
          cellIds: [0, 1],
        );
        const b = NamedTemplate(
          name: 'n2_v_half',
          tree: Split(
            axis: SplitAxis.vertical,
            positions: [0.5],
            children: [Leaf(0), Leaf(1)],
          ),
          cellIds: [0, 1],
        );
        expect(a, equals(b));
      });
    });
  }
  ```

- [ ] **Step 5-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/named_template_test.dart`
  Expected: 컴파일 실패.

- [ ] **Step 5-3: 구현**

  Create `lib/cores/grid_suggestor/models/named_template.dart`:
  ```dart
  import 'grid_node.dart';

  /// 큐레이션 템플릿 래퍼 — 이름 + BSP 트리 + cellIds traversal 캐시.
  ///
  /// `name` 은 `n{N}_{descriptiveName}` 컨벤션 (snake_case).
  /// `cellIds` 는 트리 traversal 결과의 const 캐시 — templates_test 가 일치 검증.
  ///
  /// const 단계에서 cellIds traversal 을 강제하기 어려워 assert 로 mismatch 검증.
  class NamedTemplate {
    final String name;
    final GridNode tree;
    final List<int> cellIds;

    const NamedTemplate({
      required this.name,
      required this.tree,
      required this.cellIds,
    });

    @override
    bool operator ==(Object other) =>
        other is NamedTemplate &&
        other.name == name &&
        other.tree == tree &&
        _listEq(other.cellIds, cellIds);

    @override
    int get hashCode => Object.hash(name, tree, Object.hashAll(cellIds));
  }

  bool _listEq<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  ```

  > **참고**: const 생성자라 traversal 강제 assert 는 못 박음. 대신 templates_test 의 invariant #4 (`cellIds == cellIdsOf(tree)`) 가 검증. mismatch 케이스 테스트는 `NamedTemplate` 자체가 아니라 templates_test 에서.

  Step 5-1 의 두 번째 테스트("mismatch 면 assert") 는 const 한계로 `NamedTemplate` 단독에서 검증 불가. **테스트를 수정** — Step 5-3 직후로 옮겨 다음과 같이 변경:

  Modify `test/cores/grid_suggestor/named_template_test.dart` — 두 번째 test 를 다음으로 교체:
  ```dart
  test('cellIds 와 cellIdsOf(tree) 비교 헬퍼로 mismatch 감지', () {
    const broken = NamedTemplate(
      name: 'broken',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: [0.5],
        children: [Leaf(0), Leaf(1)],
      ),
      cellIds: [0, 2],
    );
    expect(broken.cellIds, isNot(equals(cellIdsOf(broken.tree))));
  });
  ```

- [ ] **Step 5-4: 배럴 export**

  Modify `grid_suggestor.dart`:
  ```dart
  export 'models/named_template.dart' show NamedTemplate;
  ```

- [ ] **Step 5-5: 테스트 통과**

  Run: `flutter test test/cores/grid_suggestor/named_template_test.dart`
  Expected: 모든 테스트 PASS.

- [ ] **Step 5-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/models/named_template.dart \
          lib/cores/grid_suggestor/grid_suggestor.dart \
          test/cores/grid_suggestor/named_template_test.dart
  git commit -m "feat : NamedTemplate 큐레이션 래퍼 (name + tree + cellIds 캐시) (#1)"
  ```

---

## Task 6: `GridSuggestion` + `SuggestCursor` (Freezed)

**Files:**
- Create: `lib/cores/grid_suggestor/models/grid_suggestion.dart`
- Create: `lib/cores/grid_suggestor/models/suggest_cursor.dart`
- Test: `test/cores/grid_suggestor/grid_suggestion_test.dart` (필수 안 만들고 통합 테스트 시 검증)
- Modify: 배럴

> **TDD 변형 사유**: `GridSuggestion`/`SuggestCursor` 는 단순 데이터 holder. Freezed codegen 자체가 동작 검증. 별도 단위 테스트보다 Task 11 통합 테스트에서 사용으로 검증하는 게 DRY.

- [ ] **Step 6-1: `GridSuggestion` 구현**

  Create `lib/cores/grid_suggestor/models/grid_suggestion.dart`:
  ```dart
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
  ```

- [ ] **Step 6-2: `SuggestCursor` 구현**

  Create `lib/cores/grid_suggestor/models/suggest_cursor.dart`:
  ```dart
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
  ```

- [ ] **Step 6-3: 배럴 export**

  Modify `grid_suggestor.dart`:
  ```dart
  export 'models/grid_suggestion.dart' show GridSuggestion;
  export 'models/suggest_cursor.dart' show SuggestCursor;
  ```

- [ ] **Step 6-4: 빌드 통과 확인 (codegen)**

  Run:
  ```bash
  flutter analyze lib/cores/grid_suggestor/
  ```
  Expected: `No issues found!` (build_runner watch 가 `.freezed.dart` 자동 생성).

- [ ] **Step 6-5: Commit**

  ```bash
  git add lib/cores/grid_suggestor/models/grid_suggestion.dart \
          lib/cores/grid_suggestor/models/grid_suggestion.freezed.dart \
          lib/cores/grid_suggestor/models/suggest_cursor.dart \
          lib/cores/grid_suggestor/models/suggest_cursor.freezed.dart \
          lib/cores/grid_suggestor/grid_suggestor.dart
  git commit -m "feat : GridSuggestion + SuggestCursor (Freezed) 출력/cursor 모델 (#1)"
  ```

---

## Task 7: `cellGeometry` — bbox + 종횡비 계산

**Files:**
- Create: `lib/cores/grid_suggestor/geometry/cell_geometry.dart`
- Test: `test/cores/grid_suggestor/cell_geometry_test.dart`
- Modify: 배럴

- [ ] **Step 7-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/cell_geometry_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('cellBBoxes', () {
      test('단일 Leaf — 전체 bbox', () {
        final bboxes = cellBBoxes(const Leaf(0));
        expect(bboxes[0]?.left, 0);
        expect(bboxes[0]?.top, 0);
        expect(bboxes[0]?.width, 1);
        expect(bboxes[0]?.height, 1);
      });

      test('V½ — 좌우 반반', () {
        const tree = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        final bboxes = cellBBoxes(tree);
        expect(bboxes[0]?.left, 0);
        expect(bboxes[0]?.width, 0.5);
        expect(bboxes[1]?.left, 0.5);
        expect(bboxes[1]?.width, 0.5);
      });

      test('H½ — 상하 반반', () {
        const tree = Split(
          axis: SplitAxis.horizontal,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        final bboxes = cellBBoxes(tree);
        expect(bboxes[0]?.top, 0);
        expect(bboxes[0]?.height, 0.5);
        expect(bboxes[1]?.top, 0.5);
        expect(bboxes[1]?.height, 0.5);
      });

      test('중첩 — V½ 좌1 + 우 H⅓-등분 (n4_left1right3)', () {
        const tree = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [
            Leaf(0),
            Split(
              axis: SplitAxis.horizontal,
              positions: [1 / 3, 2 / 3],
              children: [Leaf(1), Leaf(2), Leaf(3)],
            ),
          ],
        );
        final bboxes = cellBBoxes(tree);
        // 좌측 큰 셀
        expect(bboxes[0]?.left, 0);
        expect(bboxes[0]?.width, 0.5);
        expect(bboxes[0]?.height, 1);
        // 우측 상단
        expect(bboxes[1]?.left, 0.5);
        expect(bboxes[1]?.top, 0);
        expect(bboxes[1]?.width, 0.5);
        expect(bboxes[1]?.height, closeTo(1 / 3, 1e-12));
        // 우측 하단
        expect(bboxes[3]?.top, closeTo(2 / 3, 1e-12));
        expect(bboxes[3]?.height, closeTo(1 / 3, 1e-12));
      });
    });

    group('cellAspectRatios', () {
      test('square 캔버스 — 셀 종횡비 = 정규화 비율', () {
        const tree = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        final ars = cellAspectRatios(tree, const CanvasRatio.square());
        expect(ars[0], closeTo(0.5, 1e-12)); // 0.5w / 1h * 1
        expect(ars[1], closeTo(0.5, 1e-12));
      });

      test('portrait916 캔버스 — 셀 종횡비 = w/h × canvas', () {
        const tree = Leaf(0);
        final ars = cellAspectRatios(tree, const CanvasRatio.portrait916());
        // 1w / 1h × 9/16 = 9/16
        expect(ars[0], closeTo(9 / 16, 1e-12));
      });
    });
  }
  ```

- [ ] **Step 7-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/cell_geometry_test.dart`
  Expected: 컴파일 실패.

- [ ] **Step 7-3: 구현**

  Create `lib/cores/grid_suggestor/geometry/cell_geometry.dart`:
  ```dart
  import '../models/canvas_ratio.dart';
  import '../models/grid_node.dart';

  /// 알고리즘 모듈 전용 normalized rectangle (0..1 좌표계).
  ///
  /// Flutter `Rect` 를 쓸 수 없는 이유: `lib/cores/grid_suggestor/` 는 `flutter/` import 금지 (spec §2-3).
  /// 외부 호출자가 Flutter Rect 로 변환하고 싶으면 `Rect.fromLTWH(c.left, c.top, c.width, c.height)`.
  class CellRect {
    final double left;
    final double top;
    final double width;
    final double height;
    const CellRect(this.left, this.top, this.width, this.height);

    @override
    bool operator ==(Object other) =>
        other is CellRect &&
        other.left == left &&
        other.top == top &&
        other.width == width &&
        other.height == height;

    @override
    int get hashCode => Object.hash(left, top, width, height);
  }

  /// BSP 트리의 각 Leaf 에 대한 normalized bounding box.
  ///
  /// 입력 트리가 정상이면 반환 Map 의 cellId set 은 cellIdsOf(node) 와 일치.
  Map<int, CellRect> cellBBoxes(GridNode root) {
    final result = <int, CellRect>{};
    _visit(root, const CellRect(0, 0, 1, 1), result);
    return result;
  }

  /// 각 Leaf 의 셀 종횡비 = (정규화 너비 × canvas.value) / 정규화 높이.
  ///
  /// 알고리즘이 미디어 종횡비와 비교할 값.
  Map<int, double> cellAspectRatios(GridNode root, CanvasRatio canvas) {
    final bboxes = cellBBoxes(root);
    final canvasV = canvas.value;
    return bboxes.map(
      (id, r) => MapEntry(id, (r.width * canvasV) / r.height),
    );
  }

  void _visit(GridNode node, CellRect bounds, Map<int, CellRect> out) {
    switch (node) {
      case Leaf(:final cellId):
        out[cellId] = bounds;
      case Split(:final axis, :final positions, :final children):
        final segments = _segmentsAlong(positions);
        for (var i = 0; i < children.length; i++) {
          final (start, end) = segments[i];
          final childBounds = switch (axis) {
            SplitAxis.vertical => CellRect(
                bounds.left + bounds.width * start,
                bounds.top,
                bounds.width * (end - start),
                bounds.height,
              ),
            SplitAxis.horizontal => CellRect(
                bounds.left,
                bounds.top + bounds.height * start,
                bounds.width,
                bounds.height * (end - start),
              ),
          };
          _visit(children[i], childBounds, out);
        }
    }
  }

  /// positions [0.3, 0.7] → [(0, 0.3), (0.3, 0.7), (0.7, 1)]
  List<(double, double)> _segmentsAlong(List<double> positions) {
    final result = <(double, double)>[];
    var prev = 0.0;
    for (final p in positions) {
      result.add((prev, p));
      prev = p;
    }
    result.add((prev, 1.0));
    return result;
  }
  ```

- [ ] **Step 7-4: 배럴 export**

  Modify `grid_suggestor.dart`:
  ```dart
  export 'geometry/cell_geometry.dart' show cellBBoxes, cellAspectRatios, CellRect;
  ```

- [ ] **Step 7-5: 테스트 통과**

  Run: `flutter test test/cores/grid_suggestor/cell_geometry_test.dart`
  Expected: 모든 테스트 PASS.

- [ ] **Step 7-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/geometry/ \
          lib/cores/grid_suggestor/grid_suggestor.dart \
          test/cores/grid_suggestor/cell_geometry_test.dart
  git commit -m "feat : cellBBoxes/cellAspectRatios + CellRect (BSP→geometry) (#1)"
  ```

---

## Task 8: `matcher` — log loss + 브루트포스 N!

**Files:**
- Create: `lib/cores/grid_suggestor/matching/media_to_cell_matcher.dart`
- Test: `test/cores/grid_suggestor/matcher_test.dart`
- Modify: 배럴

- [ ] **Step 8-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/matcher_test.dart`:
  ```dart
  import 'dart:math';

  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('bestMapping', () {
      test('완벽 매칭 — 가로 셀에 가로 미디어, 세로 셀에 세로 미디어', () {
        final result = bestMapping(
          cellAspects: [2.0, 0.5],
          mediaAspects: [2.0, 0.5],
          mediaWeights: [1.0, 1.0],
        );
        expect(result.mapping, [0, 1]); // media[0]→cell[0], media[1]→cell[1]
        expect(result.loss, closeTo(0, 1e-9));
      });

      test('완벽 매칭 — 미디어 순서 뒤집어도 매핑 옳게', () {
        final result = bestMapping(
          cellAspects: [2.0, 0.5],
          mediaAspects: [0.5, 2.0],
          mediaWeights: [1.0, 1.0],
        );
        expect(result.mapping, [1, 0]); // media[1](2.0)→cell[0], media[0](0.5)→cell[1]
        expect(result.loss, closeTo(0, 1e-9));
      });

      test('log loss: 가로 2배 차이와 세로 2배 차이 동등', () {
        // cell=2.0, media=4.0: |ln(2)-ln(4)| = ln(2)
        // cell=0.5, media=0.25: |ln(0.5)-ln(0.25)| = ln(2)
        final r1 = bestMapping(
          cellAspects: [2.0],
          mediaAspects: [4.0],
          mediaWeights: [1.0],
        );
        final r2 = bestMapping(
          cellAspects: [0.5],
          mediaAspects: [0.25],
          mediaWeights: [1.0],
        );
        expect(r1.loss, closeTo(ln2, 1e-9));
        expect(r2.loss, closeTo(ln2, 1e-9));
        expect(r1.loss, closeTo(r2.loss, 1e-9));
      });

      test('weight 가 큰 미디어가 더 잘 맞는 셀로 가도록 편향', () {
        // 셀 [10, 1.0]: 첫 셀이 매우 가로
        // 미디어 [1.0(weight=10), 10(weight=1)]:
        //   weight 무시 → media[1](10)→cell[0]
        //   weight 1×10 = 미디어[0]을 잘못된 셀로 보내면 loss 폭증 → 실제로는 그냥 절대 loss 따름
        // 사실 weight 는 절대값에만 영향. 매핑 자체가 바뀌려면 분기 발생해야.
        // 단순 검증: weight 1 vs 10 일 때 loss 가 weight 비례
        final lowWeight = bestMapping(
          cellAspects: [2.0],
          mediaAspects: [1.0],
          mediaWeights: [1.0],
        );
        final highWeight = bestMapping(
          cellAspects: [2.0],
          mediaAspects: [1.0],
          mediaWeights: [10.0],
        );
        expect(highWeight.loss, closeTo(lowWeight.loss * 10, 1e-9));
      });

      test('N=4 브루트포스 — 24 permutations 평가', () {
        final result = bestMapping(
          cellAspects: [2.0, 2.0, 0.5, 0.5],
          mediaAspects: [0.5, 0.5, 2.0, 2.0],
          mediaWeights: [1.0, 1.0, 1.0, 1.0],
        );
        // 가로 미디어 2개를 가로 셀 2개에 (순서 무관)
        expect(result.loss, closeTo(0, 1e-9));
      });
    });
  }
  ```

- [ ] **Step 8-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/matcher_test.dart`
  Expected: 컴파일 실패.

- [ ] **Step 8-3: 구현**

  Create `lib/cores/grid_suggestor/matching/media_to_cell_matcher.dart`:
  ```dart
  import 'dart:math';

  /// 셀 ↔ 미디어 매핑 결과.
  ///
  /// `mapping[i]` = i 번째 셀에 배정된 미디어 인덱스.
  /// `loss` = log 비율 차이의 가중합 (낮을수록 좋음).
  class MappingResult {
    final List<int> mapping;
    final double loss;
    const MappingResult({required this.mapping, required this.loss});
  }

  /// 모든 N! permutation 을 평가해 최소 loss 매핑 반환.
  ///
  /// Loss 함수: `Σᵢ wₘ(σ(i)) × |ln(cellAspectᵢ) - ln(mediaAspectσ(i))|`
  /// - log 비율 차이로 가로/세로 비율 비대칭을 대칭으로 평가.
  /// - 미디어 가중치는 v1 에서 모두 1.0, v1.x 에서 영상에 1.5.
  ///
  /// N≤9 라 ~362,880 permutations × 9 비교 = ~3.3M ops, 모바일 < 300ms.
  /// tie 발생 시 첫 번째 permutation 채택 (브루트포스 lexicographic 순).
  MappingResult bestMapping({
    required List<double> cellAspects,
    required List<double> mediaAspects,
    required List<double> mediaWeights,
  }) {
    assert(cellAspects.length == mediaAspects.length);
    assert(cellAspects.length == mediaWeights.length);
    final n = cellAspects.length;
    if (n == 0) {
      return const MappingResult(mapping: [], loss: 0);
    }

    final cellLogs = cellAspects.map(log).toList();
    final mediaLogs = mediaAspects.map(log).toList();

    var bestLoss = double.infinity;
    List<int>? bestPerm;

    final indices = List<int>.generate(n, (i) => i);
    void recurse(List<int> current, Set<int> used) {
      if (current.length == n) {
        var loss = 0.0;
        for (var i = 0; i < n; i++) {
          final mi = current[i];
          loss += mediaWeights[mi] * (cellLogs[i] - mediaLogs[mi]).abs();
        }
        if (loss < bestLoss) {
          bestLoss = loss;
          bestPerm = List.of(current);
        }
        return;
      }
      for (final i in indices) {
        if (used.contains(i)) continue;
        current.add(i);
        used.add(i);
        recurse(current, used);
        current.removeLast();
        used.remove(i);
      }
    }

    recurse(<int>[], <int>{});
    return MappingResult(mapping: bestPerm!, loss: bestLoss);
  }
  ```

- [ ] **Step 8-4: 배럴 export**

  Modify `grid_suggestor.dart`:
  ```dart
  export 'matching/media_to_cell_matcher.dart' show bestMapping, MappingResult;
  ```

- [ ] **Step 8-5: 테스트 통과**

  Run: `flutter test test/cores/grid_suggestor/matcher_test.dart`
  Expected: 모든 테스트 PASS.

- [ ] **Step 8-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/matching/ \
          lib/cores/grid_suggestor/grid_suggestor.dart \
          test/cores/grid_suggestor/matcher_test.dart
  git commit -m "feat : bestMapping (log loss + 브루트포스 N!) + MappingResult (#1)"
  ```

---

## Task 9: `ranker` — 정렬 + fingerprint dedup

**Files:**
- Create: `lib/cores/grid_suggestor/ranking/candidate_ranker.dart`
- Test: `test/cores/grid_suggestor/ranker_test.dart`
- Modify: 배럴

- [ ] **Step 9-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/ranker_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('treeFingerprint', () {
      test('동일 트리 → 동일 fingerprint', () {
        const a = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        const b = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        expect(treeFingerprint(a), treeFingerprint(b));
      });

      test('positions ±10% 이내 → 동일 fingerprint (rounding)', () {
        const a = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        const b = Split(
          axis: SplitAxis.vertical,
          positions: [0.55], // 5% 차이 — 같은 0.1 buckets
          children: [Leaf(0), Leaf(1)],
        );
        expect(treeFingerprint(a), treeFingerprint(b));
      });

      test('axis 다르면 fingerprint 다름', () {
        const a = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        const b = Split(
          axis: SplitAxis.horizontal,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        expect(treeFingerprint(a), isNot(treeFingerprint(b)));
      });

      test('positions 0.2 차이 → 다른 fingerprint', () {
        const a = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        const b = Split(
          axis: SplitAxis.vertical,
          positions: [0.7],
          children: [Leaf(0), Leaf(1)],
        );
        expect(treeFingerprint(a), isNot(treeFingerprint(b)));
      });
    });

    group('rankCandidates', () {
      test('loss 오름차순 정렬', () {
        final candidates = [
          _candidate(name: 'b', loss: 2.0),
          _candidate(name: 'a', loss: 1.0),
          _candidate(name: 'c', loss: 3.0),
        ];
        final ranked = rankCandidates(candidates);
        expect(ranked.map((c) => c.templateName).toList(), ['a', 'b', 'c']);
      });

      test('loss 동률 시 templateName 알파벳 순', () {
        final candidates = [
          _candidate(name: 'banana', loss: 1.0),
          _candidate(name: 'apple', loss: 1.0),
          _candidate(name: 'cherry', loss: 1.0),
        ];
        final ranked = rankCandidates(candidates);
        expect(
          ranked.map((c) => c.templateName).toList(),
          ['apple', 'banana', 'cherry'],
        );
      });

      test('fingerprint 동일 후보 중 더 낮은 loss 만 살아남음', () {
        const sameTree = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: [Leaf(0), Leaf(1)],
        );
        final candidates = [
          GridSuggestion(
            tree: sameTree,
            mediaByCellId: const {0: 'm1', 1: 'm2'},
            loss: 2.0,
            templateName: 'high_loss',
          ),
          GridSuggestion(
            tree: sameTree,
            mediaByCellId: const {0: 'm1', 1: 'm2'},
            loss: 1.0,
            templateName: 'low_loss',
          ),
        ];
        final ranked = rankCandidates(candidates);
        expect(ranked.length, 1);
        expect(ranked.first.templateName, 'low_loss');
      });
    });
  }

  GridSuggestion _candidate({required String name, required double loss}) {
    return GridSuggestion(
      tree: const Leaf(0),
      mediaByCellId: const {0: 'm1'},
      loss: loss,
      templateName: name,
    );
  }
  ```

- [ ] **Step 9-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/ranker_test.dart`
  Expected: 컴파일 실패.

- [ ] **Step 9-3: 구현**

  Create `lib/cores/grid_suggestor/ranking/candidate_ranker.dart`:
  ```dart
  import '../models/grid_node.dart';
  import '../models/grid_suggestion.dart';

  /// 트리 구조 fingerprint — fingerprint 동일하면 "구조적으로 비슷한 후보".
  ///
  /// PRD §9-2-1 step 4: "분할 방향 동일 + 선 위치 ±10% 이내면 중복".
  /// positions 를 0.1 buckets 으로 라운딩해 ±5% 가 동일 bucket 으로 매핑.
  String treeFingerprint(GridNode node) {
    final buf = StringBuffer();
    void visit(GridNode n) {
      switch (n) {
        case Leaf():
          buf.write('L');
        case Split(:final axis, :final positions, :final children):
          buf.write(axis == SplitAxis.vertical ? 'V' : 'H');
          buf.write('@');
          for (var i = 0; i < positions.length; i++) {
            if (i > 0) buf.write(',');
            // 0.1 단위 라운딩 (1 → 0.1, 5 → 0.5, 9 → 0.9)
            final bucket = (positions[i] * 10).round() / 10;
            buf.write(bucket.toStringAsFixed(1));
          }
          buf.write('(');
          for (var i = 0; i < children.length; i++) {
            if (i > 0) buf.write(',');
            visit(children[i]);
          }
          buf.write(')');
      }
    }
    visit(node);
    return buf.toString();
  }

  /// 후보 정렬 + fingerprint dedup.
  ///
  /// 1) fingerprint 동일 후보 중 loss 가장 낮은 것만 살림.
  /// 2) loss 오름차순 정렬 (동률 시 templateName 알파벳 오름차순).
  List<GridSuggestion> rankCandidates(List<GridSuggestion> candidates) {
    // Step 1: fingerprint dedup
    final byFp = <String, GridSuggestion>{};
    for (final c in candidates) {
      final fp = treeFingerprint(c.tree);
      final existing = byFp[fp];
      if (existing == null || c.loss < existing.loss) {
        byFp[fp] = c;
      } else if (c.loss == existing.loss && c.templateName.compareTo(existing.templateName) < 0) {
        // tie 시 alphabetical 우선 — 결정성 보장
        byFp[fp] = c;
      }
    }

    // Step 2: loss + name 정렬
    final list = byFp.values.toList()
      ..sort((a, b) {
        final cmp = a.loss.compareTo(b.loss);
        if (cmp != 0) return cmp;
        return a.templateName.compareTo(b.templateName);
      });

    return list;
  }
  ```

- [ ] **Step 9-4: 배럴 export**

  Modify `grid_suggestor.dart`:
  ```dart
  export 'ranking/candidate_ranker.dart' show treeFingerprint, rankCandidates;
  ```

- [ ] **Step 9-5: 테스트 통과**

  Run: `flutter test test/cores/grid_suggestor/ranker_test.dart`
  Expected: 모든 테스트 PASS.

- [ ] **Step 9-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/ranking/ \
          lib/cores/grid_suggestor/grid_suggestor.dart \
          test/cores/grid_suggestor/ranker_test.dart
  git commit -m "feat : rankCandidates + treeFingerprint (정렬 + fingerprint dedup) (#1)"
  ```

---

## Task 10: `validator` — 입력 검증 (`ArgumentError` 7종)

**Files:**
- Create: `lib/cores/grid_suggestor/validation/input_validator.dart`
- Test: `test/cores/grid_suggestor/validate_test.dart`
- Modify: 배럴

- [ ] **Step 10-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/validate_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('validateSuggestInput', () {
      const validMedia = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 0.75),
      ];

      test('정상 입력 — 통과', () {
        expect(
          () => validateSuggestInput(media: validMedia, weightOf: null),
          returnsNormally,
        );
      });

      test('N < 2 → ArgumentError', () {
        const media = [MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0)];
        expect(
          () => validateSuggestInput(media: media, weightOf: null),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('≥ 2'))),
        );
      });

      test('N > 9 → ArgumentError', () {
        final media = List.generate(
          10,
          (i) => MediaItem(id: '$i', type: MediaType.photo, aspectRatio: 1.0),
        );
        expect(
          () => validateSuggestInput(media: media, weightOf: null),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('≤ 9'))),
        );
      });

      test('aspectRatio <= 0 → ArgumentError', () {
        const media = [
          MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 0),
          MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1),
        ];
        expect(
          () => validateSuggestInput(media: media, weightOf: null),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('positive finite'))),
        );
      });

      test('aspectRatio NaN → ArgumentError', () {
        final media = [
          MediaItem(id: 'a', type: MediaType.photo, aspectRatio: double.nan),
          const MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1),
        ];
        expect(
          () => validateSuggestInput(media: media, weightOf: null),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('aspectRatio Infinity → ArgumentError', () {
        final media = [
          MediaItem(id: 'a', type: MediaType.photo, aspectRatio: double.infinity),
          const MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1),
        ];
        expect(
          () => validateSuggestInput(media: media, weightOf: null),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('동일 id 중복 → ArgumentError', () {
        const media = [
          MediaItem(id: 'dup', type: MediaType.photo, aspectRatio: 1),
          MediaItem(id: 'dup', type: MediaType.photo, aspectRatio: 1),
        ];
        expect(
          () => validateSuggestInput(media: media, weightOf: null),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('unique'))),
        );
      });

      test('weightOf 음수 반환 → ArgumentError', () {
        expect(
          () => validateSuggestInput(
            media: validMedia,
            weightOf: (item) => -1.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('non-negative'))),
        );
      });
    });
  }
  ```

- [ ] **Step 10-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/validate_test.dart`
  Expected: 컴파일 실패.

- [ ] **Step 10-3: 구현**

  Create `lib/cores/grid_suggestor/validation/input_validator.dart`:
  ```dart
  import '../models/media_item.dart';

  /// suggest() 입력 검증. 잘못된 입력은 즉시 ArgumentError.
  ///
  /// 검증 항목 (spec §6-1):
  /// - 2 ≤ N ≤ 9
  /// - 모든 aspectRatio 양의 유한값
  /// - 모든 id 유일
  /// - weightOf(item) ≥ 0
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
        if (w < 0) {
          throw ArgumentError(
            'weight must be non-negative, got $w for ${m.id}',
          );
        }
      }
    }
  }
  ```

- [ ] **Step 10-4: 배럴 export**

  Modify `grid_suggestor.dart`:
  ```dart
  export 'validation/input_validator.dart' show validateSuggestInput;
  ```

- [ ] **Step 10-5: 테스트 통과**

  Run: `flutter test test/cores/grid_suggestor/validate_test.dart`
  Expected: 모든 테스트 PASS.

- [ ] **Step 10-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/validation/ \
          lib/cores/grid_suggestor/grid_suggestor.dart \
          test/cores/grid_suggestor/validate_test.dart
  git commit -m "feat : validateSuggestInput (7종 ArgumentError) + 검증 테스트 (#1)"
  ```

---

## Task 11: `suggester` 통합 + N=2 stub 템플릿 + 통합 테스트

**Files:**
- Create: `lib/cores/grid_suggestor/templates/_n2_templates.dart`
- Create: `lib/cores/grid_suggestor/templates/grid_templates.dart`
- Create: `lib/cores/grid_suggestor/suggester.dart`
- Create: `test/cores/grid_suggestor/templates_n2_test.dart`
- Create: `test/cores/grid_suggestor/fixtures/photos.dart`
- Create: `test/cores/grid_suggestor/suggester_test.dart`
- Modify: 배럴

- [ ] **Step 11-1: N=2 템플릿 3개 정의**

  Create `lib/cores/grid_suggestor/templates/_n2_templates.dart`:
  ```dart
  import '../models/grid_node.dart';
  import '../models/named_template.dart';

  /// N=2 큐레이션 — V½, H½, V60-40 3개.
  ///
  /// Phase A 의 stub 큐레이션. Phase B 에서 패턴 다양화·시각 iterate.
  /// Dart 제약상 (Split non-const) 모든 템플릿은 final 로 초기화.
  final n2Templates = <NamedTemplate>[
    NamedTemplate(
      name: 'n2_v_half',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      ),
      cellIds: const [0, 1],
    ),
    NamedTemplate(
      name: 'n2_h_half',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      ),
      cellIds: const [0, 1],
    ),
    NamedTemplate(
      name: 'n2_v_60_40',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.6],
        children: const [Leaf(0), Leaf(1)],
      ),
      cellIds: const [0, 1],
    ),
  ];
  ```

- [ ] **Step 11-2: 카탈로그 entry point**

  Create `lib/cores/grid_suggestor/templates/grid_templates.dart`:
  ```dart
  import 'dart:collection';

  import '../models/named_template.dart';
  import '_n2_templates.dart';

  /// N → 큐레이션된 템플릿 list.
  ///
  /// Phase A 는 N=2 만. Phase B 에서 N=3..9 추가 시 새 N별 파일을 만들고
  /// 이 Map 의 정적 선언에 추가.
  /// 외부에서 Map/List 변경을 막기 위해 [UnmodifiableMapView]·[UnmodifiableListView] 로 노출.
  /// 무결성 invariant 는 templates_test 에서 검증.
  final Map<int, List<NamedTemplate>> kGridTemplates =
      UnmodifiableMapView<int, List<NamedTemplate>>({
    2: UnmodifiableListView<NamedTemplate>(n2Templates),
  });
  ```

- [ ] **Step 11-3: N=2 무결성 테스트**

  Create `test/cores/grid_suggestor/templates_n2_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
  // _allowedPositions 비교용 — 화이트리스트 검증은 Phase B 마무리에서 본격 강화.
  // 여기서는 N=2 가 ½, 0.6 만 사용하는지 직접 검증.

  void main() {
    group('n2Templates 무결성', () {
      test('정확히 3개', () {
        expect(kGridTemplates[2], hasLength(3));
      });

      test('각 템플릿의 leaf 개수 == 2', () {
        for (final t in kGridTemplates[2]!) {
          expect(cellIdsOf(t.tree), hasLength(2), reason: '${t.name} leaf count');
        }
      });

      test('각 템플릿의 cellIds == [0, 1]', () {
        for (final t in kGridTemplates[2]!) {
          expect(t.cellIds, [0, 1], reason: '${t.name} cellIds');
          expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
        }
      });

      test('이름이 n2_ 로 시작', () {
        for (final t in kGridTemplates[2]!) {
          expect(t.name, startsWith('n2_'));
        }
      });

      test('fingerprint 충돌 없음', () {
        final fps = kGridTemplates[2]!.map((t) => treeFingerprint(t.tree)).toList();
        expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
      });
    });
  }
  ```

- [ ] **Step 11-4: 테스트 통과 확인 (템플릿)**

  Run: `flutter test test/cores/grid_suggestor/templates_n2_test.dart`
  Expected: 모든 테스트 PASS.

- [ ] **Step 11-5: fixture 작성**

  Create `test/cores/grid_suggestor/fixtures/photos.dart`:
  ```dart
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  /// 2장 사진 — 가로 한 장, 세로 한 장.
  const photos2Mixed = <MediaItem>[
    MediaItem(id: 'p_wide', type: MediaType.photo, aspectRatio: 1.5),
    MediaItem(id: 'p_tall', type: MediaType.photo, aspectRatio: 0.667),
  ];

  /// 2장 모두 정사각.
  const photos2Square = <MediaItem>[
    MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.0),
    MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.0),
  ];
  ```

- [ ] **Step 11-6: `suggester.dart` 통합 함수 작성**

  Create `lib/cores/grid_suggestor/suggester.dart`:
  ```dart
  import 'geometry/cell_geometry.dart';
  import 'matching/media_to_cell_matcher.dart';
  import 'models/canvas_ratio.dart';
  import 'models/grid_node.dart';
  import 'models/grid_suggestion.dart';
  import 'models/media_item.dart';
  import 'models/named_template.dart';
  import 'models/suggest_cursor.dart';
  import 'ranking/candidate_ranker.dart';
  import 'templates/grid_templates.dart';
  import 'validation/input_validator.dart';

  /// 자동 레이아웃 제안 — Phase A 진입점.
  ///
  /// 7-step pipeline (spec §4-1):
  /// 1) validate, 2) templateLookup, 3) cellGeometry, 4) matcher, 5) ranker,
  /// 6) pick top maxResults, 7) advance cursor.
  ///
  /// PRD §9-2-1 step 5: 첫 호출 + 다른 제안 3회 = 최대 4 batch.
  /// nextCursor == null 이면 풀 소진 또는 PRD 한도 도달.
  ({List<GridSuggestion> suggestions, SuggestCursor? nextCursor}) suggest({
    required List<MediaItem> media,
    required CanvasRatio canvas,
    SuggestCursor? cursor,
    double Function(MediaItem item)? weightOf,
    int maxResults = 3,
  }) {
    // Step 1: validate
    validateSuggestInput(media: media, weightOf: weightOf);

    // cursor 초기화
    final activeCursor = cursor ?? const SuggestCursor(
      shownTemplateNames: {},
      batchIndex: 0,
    );

    // PRD 한도 초과 cursor 방어
    if (activeCursor.batchIndex >= 4) {
      return (suggestions: const [], nextCursor: null);
    }

    // Step 2: templateLookup
    final allTemplates = kGridTemplates[media.length] ?? const [];
    final available = allTemplates
        .where((t) => !activeCursor.shownTemplateNames.contains(t.name))
        .toList();
    if (available.isEmpty) {
      return (suggestions: const [], nextCursor: null);
    }

    // 미디어 정규화
    final mediaAspects = media.map((m) => m.aspectRatio).toList();
    final mediaWeights = media
        .map((m) => weightOf?.call(m) ?? 1.0)
        .toList();

    // Step 3-4: 각 템플릿마다 cellAspects + bestMapping
    final candidates = <GridSuggestion>[];
    for (final template in available) {
      final aspectsByCell = cellAspectRatios(template.tree, canvas);
      // template.cellIds 순서 유지하며 cellAspects 추출
      final cellAspects = template.cellIds.map((id) => aspectsByCell[id]!).toList();

      final mapping = bestMapping(
        cellAspects: cellAspects,
        mediaAspects: mediaAspects,
        mediaWeights: mediaWeights,
      );

      final mediaByCellId = <int, String>{};
      for (var i = 0; i < template.cellIds.length; i++) {
        mediaByCellId[template.cellIds[i]] = media[mapping.mapping[i]].id;
      }

      candidates.add(GridSuggestion(
        tree: template.tree,
        mediaByCellId: mediaByCellId,
        loss: mapping.loss,
        templateName: template.name,
      ));
    }

    // 5·6단계: 랭킹 + dedup + top maxResults
    final ranked = rankCandidates(candidates).take(maxResults).toList();

    // 7단계: cursor 갱신
    // PRD 한도(4 batch) 또는 다음 batch 에 더 이상 보여줄 템플릿이 없으면 null.
    final nextShown = {
      ...activeCursor.shownTemplateNames,
      ...ranked.map((s) => s.templateName),
    };
    final nextAvailable = allTemplates
        .where((t) => !nextShown.contains(t.name))
        .isNotEmpty;
    final atLimit = activeCursor.batchIndex >= 3 ||
        ranked.isEmpty ||
        !nextAvailable;
    final nextCursor = atLimit
        ? null
        : SuggestCursor(
            shownTemplateNames: nextShown,
            batchIndex: activeCursor.batchIndex + 1,
          );

    return (suggestions: ranked, nextCursor: nextCursor);
  }
  ```

- [ ] **Step 11-7: 배럴에 suggester export 추가**

  Modify `grid_suggestor.dart`:
  ```dart
  export 'suggester.dart' show suggest;
  ```

- [ ] **Step 11-8: 통합 테스트 작성**

  Create `test/cores/grid_suggestor/suggester_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  import 'fixtures/photos.dart';

  void main() {
    group('suggest() — N=2 통합', () {
      test('정상 입력 — suggestions 반환됨', () {
        final r = suggest(
          media: photos2Mixed,
          canvas: const CanvasRatio.square(),
        );
        expect(r.suggestions, isNotEmpty);
        expect(r.suggestions.length, lessThanOrEqualTo(3));
      });

      test('각 suggestion 의 mediaByCellId 가 모든 cellId 커버', () {
        final r = suggest(
          media: photos2Mixed,
          canvas: const CanvasRatio.square(),
        );
        for (final s in r.suggestions) {
          expect(s.mediaByCellId.keys.toSet(), {0, 1});
          expect(s.mediaByCellId.values.toSet(), {'p_wide', 'p_tall'});
        }
      });

      test('결정성 — 같은 입력 같은 출력', () {
        final r1 = suggest(
          media: photos2Mixed,
          canvas: const CanvasRatio.square(),
        );
        final r2 = suggest(
          media: photos2Mixed,
          canvas: const CanvasRatio.square(),
        );
        expect(
          r1.suggestions.map((s) => s.templateName).toList(),
          r2.suggestions.map((s) => s.templateName).toList(),
        );
        expect(
          r1.suggestions.map((s) => s.loss).toList(),
          r2.suggestions.map((s) => s.loss).toList(),
        );
      });

      test('cursor: 풀 소진까지 batch 진행하면 결국 nextCursor null', () {
        SuggestCursor? cursor;
        final allShown = <String>{};
        var batches = 0;
        while (batches < 4) {
          final r = suggest(
            media: photos2Mixed,
            canvas: const CanvasRatio.square(),
            cursor: cursor,
            maxResults: 1, // batch 당 1개씩 → cursor 한도 도달까지 진행
          );
          if (r.suggestions.isEmpty) break;
          allShown.addAll(r.suggestions.map((s) => s.templateName));
          batches++;
          cursor = r.nextCursor;
          if (cursor == null) break;
        }
        expect(cursor, isNull, reason: 'cursor 가 결국 null 이 되어야 함');
        expect(batches, greaterThanOrEqualTo(1));
      });

      test('canvas 비율 다르면 매핑이 달라질 수 있음 (loss 변화 확인)', () {
        final rSquare = suggest(
          media: photos2Mixed,
          canvas: const CanvasRatio.square(),
        );
        final rPortrait = suggest(
          media: photos2Mixed,
          canvas: const CanvasRatio.portrait916(),
        );
        // 첫 suggestion 의 loss 가 다르거나 templateName 이 달라야 함
        expect(
          rSquare.suggestions.first.loss != rPortrait.suggestions.first.loss ||
              rSquare.suggestions.first.templateName !=
                  rPortrait.suggestions.first.templateName,
          isTrue,
          reason: 'canvas 비율이 매핑·loss 에 영향을 줘야 함',
        );
      });

      test('weightOf hook — 모두 1.0 이면 weightOf null 과 동일 결과', () {
        final rNullWeight = suggest(
          media: photos2Mixed,
          canvas: const CanvasRatio.square(),
        );
        final rOneWeight = suggest(
          media: photos2Mixed,
          canvas: const CanvasRatio.square(),
          weightOf: (_) => 1.0,
        );
        expect(
          rNullWeight.suggestions.map((s) => s.loss).toList(),
          rOneWeight.suggestions.map((s) => s.loss).toList(),
        );
      });
    });

    group('suggest() — 입력 검증', () {
      test('N=1 → ArgumentError', () {
        const media = [MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0)];
        expect(
          () => suggest(media: media, canvas: const CanvasRatio.square()),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  }
  ```

- [ ] **Step 11-9: 전체 테스트 실행 — 모두 통과 확인**

  Run:
  ```bash
  flutter test test/cores/grid_suggestor/
  ```
  Expected: 전체 테스트 PASS (모든 task 의 테스트 합산).

- [ ] **Step 11-10: 분석기 통과**

  Run:
  ```bash
  flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/
  ```
  Expected: `No issues found!`.

- [ ] **Step 11-11: 커버리지 측정**

  Run:
  ```bash
  flutter test --coverage test/cores/grid_suggestor/
  # lcov 가 설치돼있으면:
  # genhtml coverage/lcov.info -o coverage/html
  ```
  Expected: `coverage/lcov.info` 생성. 알고리즘 모듈만 grep 하면 ≥ 90% 예상.

  > 정확한 percentile 측정은 Phase E 에서. 여기서는 lcov.info 생성 자체만 확인.

- [ ] **Step 11-12: Commit**

  ```bash
  git add lib/cores/grid_suggestor/templates/ \
          lib/cores/grid_suggestor/suggester.dart \
          lib/cores/grid_suggestor/grid_suggestor.dart \
          test/cores/grid_suggestor/templates_n2_test.dart \
          test/cores/grid_suggestor/fixtures/photos.dart \
          test/cores/grid_suggestor/suggester_test.dart
  git commit -m "feat : suggester() 통합 + N=2 stub 템플릿 3개 + 통합 테스트 (#1)"
  ```

---

## Phase A 완료 체크리스트 (DoD)

- [ ] `flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/` → `No issues found!`
- [ ] `flutter test test/cores/grid_suggestor/` → 전체 PASS
- [ ] `lib/cores/grid_suggestor/grid_suggestor.dart` 배럴에서 모든 공개 API export 확인:
  - `MediaItem`, `MediaType`
  - `CanvasRatio`
  - `GridNode`, `Split`, `Leaf`, `SplitAxis`, `cellIdsOf`
  - `NamedTemplate`
  - `GridSuggestion`, `SuggestCursor`
  - `cellBBoxes`, `cellAspectRatios`, `CellRect`
  - `bestMapping`, `MappingResult`
  - `treeFingerprint`, `rankCandidates`
  - `validateSuggestInput`
  - `suggest`
- [ ] N=2 입력에 대해 `suggest()` 가 정상 동작 (3개 stub 후보 중 매핑된 결과 반환)
- [ ] `flutter test --coverage` 로 lcov.info 생성 (정확한 % 는 Phase E)
- [ ] 커밋 11개 (Task 1 chore + Task 2~11 feat)

---

## 다음 단계 안내 (Phase B-E 미리보기)

Phase A 머지 후 별도 plan 사이클로:

| Phase | 책임 | 주요 task |
| --- | --- | --- |
| **B** — 큐레이션 카탈로그 | N=3..9 templates 추가 (~28개) + 8 invariant 테스트 | N별 1 task × 7 + 통합 invariant 1 task = 8 task |
| **C** — `/dev` 갤러리 | `grid_template_preview` 위젯 + dev_gallery 섹션 + 비율 토글 | 3 task |
| **D** — 시각 iterate | /dev 갤러리에서 ugly 발견 → 교체 (수동) | 1 task (반복) |
| **E** — 마감 | golden 테스트 N=2..9 + perf < 300ms + 커버리지 95% 검증 | 4 task |

각 Phase 가 독립 PR 가능. Phase B 까지 끝나면 Suggestion 화면 spec 사이클 시작 가능.
