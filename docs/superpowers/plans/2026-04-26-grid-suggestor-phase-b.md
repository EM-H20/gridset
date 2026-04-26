# Grid Suggestor v1 — Phase B Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phase A 의 N=2 stub 큐레이션을 N=3..9 큐레이션 ~29개로 확장 + 분할 위치 화이트리스트 모듈화 + 8 invariant 통합 무결성 테스트로 카탈로그 품질을 컴파일 + 테스트 단계에서 보증.

**Architecture:** 각 N 마다 `templates/_n{N}_templates.dart` 1 개 파일에 `final n{N}Templates = <NamedTemplate>[...]` 정적 list. 화이트리스트는 `templates/_allowed_positions.dart` 한 곳. `kGridTemplates` (UnmodifiableMapView) 에 N=3..9 키 단계적으로 추가. 기존 N별 spot-check 테스트(`templates_n{N}_test.dart`) 들은 Task 9 에서 통합 `templates_test.dart` 로 흡수하며 정리.

**Tech Stack:** Dart 3.x sealed class, Freezed (이미 존재, 추가 codegen 없음), `dart:collection` (UnmodifiableListView), flutter_test (host runner).

**Spec:** `docs/superpowers/specs/2026-04-26-grid-suggestor-design.md` §5-1 (화이트리스트), §5-2 (N별 개수), §5-3 (작명), §5-4 (kGridTemplates), §5-6 (8 invariant).

**Phase Scope:** **Phase B 만**. Phase C (`/dev` 갤러리), Phase D (시각 iterate), Phase E (golden·perf 마감) 은 별도 후속 plan 사이클.

**Phase B Deliverable Definition (DoD):**
- `flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/` → `No issues found!`
- `flutter test test/cores/grid_suggestor/` 전체 통과 (예상 ~110+ tests)
- `kGridTemplates.keys` == `{2, 3, 4, 5, 6, 7, 8, 9}`
- 합계 ≥28 templates 등록 (spec §5-2 목표)
- `templates_test.dart` 의 8 invariant 모두 통과
- `templates_n2_test.dart` ~ `templates_n9_test.dart` 들이 정리되어 단일 `templates_test.dart` 만 남음
- 커밋 9개 (Task 1~9)

---

## File Structure

### Create

| 경로 | 책임 |
| --- | --- |
| `lib/cores/grid_suggestor/templates/_allowed_positions.dart` | 화이트리스트 const Set + `isAllowedPosition(double, {tolerance})` 헬퍼 |
| `lib/cores/grid_suggestor/templates/_n3_templates.dart` | N=3 큐레이션 (4개) |
| `lib/cores/grid_suggestor/templates/_n4_templates.dart` | N=4 큐레이션 (5개) |
| `lib/cores/grid_suggestor/templates/_n5_templates.dart` | N=5 큐레이션 (4개) |
| `lib/cores/grid_suggestor/templates/_n6_templates.dart` | N=6 큐레이션 (5개) |
| `lib/cores/grid_suggestor/templates/_n7_templates.dart` | N=7 큐레이션 (4개) |
| `lib/cores/grid_suggestor/templates/_n8_templates.dart` | N=8 큐레이션 (3개) |
| `lib/cores/grid_suggestor/templates/_n9_templates.dart` | N=9 큐레이션 (3개) |
| `test/cores/grid_suggestor/allowed_positions_test.dart` | 화이트리스트 + isAllowedPosition 단위 테스트 |
| `test/cores/grid_suggestor/templates_n3_test.dart` ~ `templates_n9_test.dart` | 각 N 별 spot-check (Task 9 에서 정리됨) |
| `test/cores/grid_suggestor/templates_test.dart` | 8 invariant 통합 sweep |

### Modify

| 경로 | 변경 |
| --- | --- |
| `lib/cores/grid_suggestor/templates/grid_templates.dart` | `kGridTemplates` 에 N=3..9 키 추가 (Task 2~8 단계적) |
| `test/cores/grid_suggestor/templates_n2_test.dart` | Task 9 에서 삭제 |
| (Task 9 에서 정리되는) `templates_n3_test.dart` ~ `templates_n9_test.dart` | Task 9 에서 삭제 |

> **Note**: 각 N 의 패턴 코드는 plan 안에 stub 으로 박혀있다. Phase D (시각 iterate) 에서 `/dev` 갤러리로 미적 검토 후 교체될 수 있음. fingerprint dedup 안전망이 충돌 자동 차단.

---

## Pre-flight: 빌드 환경 확인

- [ ] **Step 0-1: Phase A 가 머지 가능 상태인지 확인**

  Run:
  ```bash
  cd /Users/luca/workspace/Flutter_Project/gridset
  flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/
  flutter test test/cores/grid_suggestor/
  ```
  Expected: analyze clean + 64/64 tests pass.

- [ ] **Step 0-2: build_runner watch 백그라운드 기동 (필요시)**

  Phase B 는 Freezed codegen 추가하지 않지만, 안전을 위해 watch 가 동작 중이면 그대로 두기. 멈춰있으면 다음 명령으로 재시작:
  ```bash
  dart run build_runner watch --delete-conflicting-outputs
  ```
  Expected: `Built with build_runner in ...; wrote 0 outputs.` (이미 생성된 코드 그대로).

---

## Task 1: 화이트리스트 모듈 + 검증 헬퍼

**Files:**
- Create: `lib/cores/grid_suggestor/templates/_allowed_positions.dart`
- Test: `test/cores/grid_suggestor/allowed_positions_test.dart`

> 이 모듈은 외부 export 하지 않는다. invariant 검증에만 사용 — Task 9 의 통합 테스트가 import. 화이트리스트는 큐레이션의 SSOT.

- [ ] **Step 1-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/allowed_positions_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';

  // private 모듈을 직접 import — 테스트가 그 외 파일에서 못 끌어와야 함을 의도.
  import 'package:gridset/cores/grid_suggestor/templates/_allowed_positions.dart';

  void main() {
    group('kAllowedPositions', () {
      test('정확히 7개 — {1/4, 1/3, 0.4, 0.5, 0.6, 2/3, 3/4}', () {
        expect(kAllowedPositions, hasLength(7));
        expect(kAllowedPositions, contains(closeTo(1 / 4, 1e-9)));
        expect(kAllowedPositions, contains(closeTo(1 / 3, 1e-9)));
        expect(kAllowedPositions, contains(closeTo(0.4, 1e-9)));
        expect(kAllowedPositions, contains(closeTo(0.5, 1e-9)));
        expect(kAllowedPositions, contains(closeTo(0.6, 1e-9)));
        expect(kAllowedPositions, contains(closeTo(2 / 3, 1e-9)));
        expect(kAllowedPositions, contains(closeTo(3 / 4, 1e-9)));
      });
    });

    group('isAllowedPosition', () {
      test('정확히 일치하는 값 — true', () {
        expect(isAllowedPosition(0.5), isTrue);
        expect(isAllowedPosition(1 / 3), isTrue);
        expect(isAllowedPosition(2 / 3), isTrue);
      });

      test('1e-9 이내 오차 — true (부동소수 오차 허용)', () {
        expect(isAllowedPosition(0.5 + 1e-10), isTrue);
        expect(isAllowedPosition(1 / 3 - 1e-10), isTrue);
      });

      test('화이트리스트 외 값 — false', () {
        expect(isAllowedPosition(0.45), isFalse);
        expect(isAllowedPosition(0.7), isFalse);
        expect(isAllowedPosition(0.0), isFalse);
        expect(isAllowedPosition(1.0), isFalse);
      });
    });
  }
  ```

- [ ] **Step 1-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/allowed_positions_test.dart`
  Expected: 컴파일 실패 (`kAllowedPositions` not defined).

- [ ] **Step 1-3: 구현**

  Create `lib/cores/grid_suggestor/templates/_allowed_positions.dart`:
  ```dart
  /// 큐레이션 분할 위치 화이트리스트 (spec §5-1).
  ///
  /// 모든 `Split.positions` 의 각 값은 이 set 에 속해야 한다.
  /// PRD §9-2-3 에디터 스냅 가이드(½, ⅓, ⅔)에 4분할 균등용 ¼·¾ 추가.
  /// v1.x 사용자 데이터 보고 set 확장 가능 (e.g., 황금비 0.382/0.618).
  ///
  /// 부동소수 비교 오차 허용은 [isAllowedPosition] 사용.
  const Set<double> kAllowedPositions = <double>{
    1 / 4, // 0.25 — 4-row/4-col 균등 분할용
    1 / 3, // 0.333...
    0.4,
    0.5,
    0.6,
    2 / 3, // 0.666...
    3 / 4, // 0.75 — 4-row/4-col 균등 분할용
  };

  /// 부동소수 오차 허용 비교 (절대 오차 ≤ [tolerance], 기본 1e-9).
  ///
  /// 1/3, 2/3 같은 무한소수 표현 차이 + 큐레이션 코드의 직접 입력 모두 허용.
  bool isAllowedPosition(double position, {double tolerance = 1e-9}) {
    for (final allowed in kAllowedPositions) {
      if ((position - allowed).abs() <= tolerance) return true;
    }
    return false;
  }
  ```

- [ ] **Step 1-4: 테스트 통과 확인**

  Run: `flutter test test/cores/grid_suggestor/allowed_positions_test.dart`
  Expected: 7 tests PASS (1 set + 3 isAllowedPosition + 3 sub-cases).

  Note: 위 테스트가 7 expect 인데 group 별로는 1 + 3 = 4 test. 정확히 4 tests PASS.

- [ ] **Step 1-5: 분석기 통과**

  Run: `flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/`
  Expected: `No issues found!`.

- [ ] **Step 1-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/templates/_allowed_positions.dart \
          test/cores/grid_suggestor/allowed_positions_test.dart
  git commit -m "feat : 분할 위치 화이트리스트 모듈 (kAllowedPositions + isAllowedPosition) (#1)"
  ```

---

## Task 2: N=3 큐레이션 (4개)

**Files:**
- Create: `lib/cores/grid_suggestor/templates/_n3_templates.dart`
- Test: `test/cores/grid_suggestor/templates_n3_test.dart`
- Modify: `lib/cores/grid_suggestor/templates/grid_templates.dart` (kGridTemplates 에 N=3 추가)

### N=3 큐레이션 패턴

| 이름 | 설명 |
| --- | --- |
| `n3_v_thirds` | V⅓-등분 (가로 3분할, 세로로 긴 셀 3개) |
| `n3_h_thirds` | H⅓-등분 (세로 3분할, 가로로 긴 셀 3개) |
| `n3_left1_right2` | V½ 좌1 + 우(H½ 2개) — L자 우측 |
| `n3_top1_bottom2` | H½ 상1 + 하(V½ 2개) — L자 상측 |

- [ ] **Step 2-1: 실패 테스트 작성 (N=3 spot-check)**

  Create `test/cores/grid_suggestor/templates_n3_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('n3Templates 무결성', () {
      test('정확히 4개', () {
        expect(kGridTemplates[3], hasLength(4));
      });

      test('각 템플릿의 leaf 개수 == 3', () {
        for (final t in kGridTemplates[3]!) {
          expect(cellIdsOf(t.tree), hasLength(3), reason: '${t.name} leaf count');
        }
      });

      test('각 템플릿의 cellIds == [0, 1, 2]', () {
        for (final t in kGridTemplates[3]!) {
          expect(t.cellIds, [0, 1, 2], reason: '${t.name} cellIds');
          expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
        }
      });

      test('이름이 n3_ 로 시작', () {
        for (final t in kGridTemplates[3]!) {
          expect(t.name, startsWith('n3_'));
        }
      });

      test('fingerprint 충돌 없음', () {
        final fps = kGridTemplates[3]!.map((t) => treeFingerprint(t.tree)).toList();
        expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
      });
    });
  }
  ```

- [ ] **Step 2-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/templates_n3_test.dart`
  Expected: 실패 (`kGridTemplates[3]` 가 null).

- [ ] **Step 2-3: N=3 templates 구현**

  Create `lib/cores/grid_suggestor/templates/_n3_templates.dart`:
  ```dart
  import '../models/grid_node.dart';
  import '../models/named_template.dart';

  /// N=3 큐레이션 — 4개.
  ///
  /// `n{N}_{descriptiveName}` 컨벤션 (spec §5-3).
  /// Phase D 에서 /dev 갤러리 시각 iterate 로 교체될 수 있음.
  final n3Templates = <NamedTemplate>[
    NamedTemplate(
      name: 'n3_v_thirds',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [1 / 3, 2 / 3],
        children: const [Leaf(0), Leaf(1), Leaf(2)],
      ),
      cellIds: const [0, 1, 2],
    ),
    NamedTemplate(
      name: 'n3_h_thirds',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [1 / 3, 2 / 3],
        children: const [Leaf(0), Leaf(1), Leaf(2)],
      ),
      cellIds: const [0, 1, 2],
    ),
    NamedTemplate(
      name: 'n3_left1_right2',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(1), Leaf(2)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2],
    ),
    NamedTemplate(
      name: 'n3_top1_bottom2',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(1), Leaf(2)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2],
    ),
  ];
  ```

- [ ] **Step 2-4: kGridTemplates 에 N=3 등록**

  Modify `lib/cores/grid_suggestor/templates/grid_templates.dart`:
  ```dart
  import 'dart:collection';

  import '../models/named_template.dart';
  import '_n2_templates.dart';
  import '_n3_templates.dart';

  /// N → 큐레이션된 템플릿 list.
  ///
  /// Phase B 진행 중 — N=2,3 등록 완료. Task 3~8 에서 N=4..9 추가.
  /// 외부에서 Map/List 변경을 막기 위해 [UnmodifiableMapView]·[UnmodifiableListView] 로 노출.
  /// 무결성 invariant 는 templates_test 에서 검증.
  final Map<int, List<NamedTemplate>> kGridTemplates =
      UnmodifiableMapView<int, List<NamedTemplate>>({
    2: UnmodifiableListView<NamedTemplate>(n2Templates),
    3: UnmodifiableListView<NamedTemplate>(n3Templates),
  });
  ```

- [ ] **Step 2-5: 테스트 통과 확인**

  Run: `flutter test test/cores/grid_suggestor/templates_n3_test.dart`
  Expected: 5 tests PASS.

- [ ] **Step 2-6: 모듈 전체 회귀 테스트**

  Run: `flutter test test/cores/grid_suggestor/`
  Expected: 전체 PASS (이전 + 새 5 tests).

- [ ] **Step 2-7: Commit**

  ```bash
  git add lib/cores/grid_suggestor/templates/_n3_templates.dart \
          lib/cores/grid_suggestor/templates/grid_templates.dart \
          test/cores/grid_suggestor/templates_n3_test.dart
  git commit -m "feat : N=3 큐레이션 4개 + kGridTemplates 등록 (#1)"
  ```

---

## Task 3: N=4 큐레이션 (5개)

**Files:**
- Create: `lib/cores/grid_suggestor/templates/_n4_templates.dart`
- Test: `test/cores/grid_suggestor/templates_n4_test.dart`
- Modify: `lib/cores/grid_suggestor/templates/grid_templates.dart`

### N=4 큐레이션 패턴

| 이름 | 설명 |
| --- | --- |
| `n4_grid2x2` | 2×2 균등 |
| `n4_left1_right3` | V½ 좌1 + 우(H⅓-등분 3개) |
| `n4_top1_bottom3` | H½ 상1 + 하(V⅓-등분 3개) |
| `n4_v_quarters` | V¼·½·¾ 4-col 균등 |
| `n4_h_quarters` | H¼·½·¾ 4-row 균등 |

- [ ] **Step 3-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/templates_n4_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('n4Templates 무결성', () {
      test('정확히 5개', () {
        expect(kGridTemplates[4], hasLength(5));
      });

      test('각 템플릿의 leaf 개수 == 4', () {
        for (final t in kGridTemplates[4]!) {
          expect(cellIdsOf(t.tree), hasLength(4), reason: '${t.name} leaf count');
        }
      });

      test('각 템플릿의 cellIds == [0, 1, 2, 3]', () {
        for (final t in kGridTemplates[4]!) {
          expect(t.cellIds, [0, 1, 2, 3], reason: '${t.name} cellIds');
          expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
        }
      });

      test('이름이 n4_ 로 시작', () {
        for (final t in kGridTemplates[4]!) {
          expect(t.name, startsWith('n4_'));
        }
      });

      test('fingerprint 충돌 없음', () {
        final fps = kGridTemplates[4]!.map((t) => treeFingerprint(t.tree)).toList();
        expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
      });
    });
  }
  ```

- [ ] **Step 3-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/templates_n4_test.dart`
  Expected: 실패 (`kGridTemplates[4]` null).

- [ ] **Step 3-3: N=4 templates 구현**

  Create `lib/cores/grid_suggestor/templates/_n4_templates.dart`:
  ```dart
  import '../models/grid_node.dart';
  import '../models/named_template.dart';

  /// N=4 큐레이션 — 5개.
  final n4Templates = <NamedTemplate>[
    NamedTemplate(
      name: 'n4_grid2x2',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(0), Leaf(1)],
          ),
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(2), Leaf(3)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3],
    ),
    NamedTemplate(
      name: 'n4_left1_right3',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(1), Leaf(2), Leaf(3)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3],
    ),
    NamedTemplate(
      name: 'n4_top1_bottom3',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(1), Leaf(2), Leaf(3)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3],
    ),
    NamedTemplate(
      name: 'n4_v_quarters',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [1 / 4, 1 / 2, 3 / 4],
        children: const [Leaf(0), Leaf(1), Leaf(2), Leaf(3)],
      ),
      cellIds: const [0, 1, 2, 3],
    ),
    NamedTemplate(
      name: 'n4_h_quarters',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [1 / 4, 1 / 2, 3 / 4],
        children: const [Leaf(0), Leaf(1), Leaf(2), Leaf(3)],
      ),
      cellIds: const [0, 1, 2, 3],
    ),
  ];
  ```

- [ ] **Step 3-4: kGridTemplates 에 N=4 등록**

  Modify `lib/cores/grid_suggestor/templates/grid_templates.dart` — import 추가 + Map 항목 추가:
  ```dart
  import 'dart:collection';

  import '../models/named_template.dart';
  import '_n2_templates.dart';
  import '_n3_templates.dart';
  import '_n4_templates.dart';

  /// (dartdoc 동일하게 유지)
  final Map<int, List<NamedTemplate>> kGridTemplates =
      UnmodifiableMapView<int, List<NamedTemplate>>({
    2: UnmodifiableListView<NamedTemplate>(n2Templates),
    3: UnmodifiableListView<NamedTemplate>(n3Templates),
    4: UnmodifiableListView<NamedTemplate>(n4Templates),
  });
  ```

- [ ] **Step 3-5: 테스트 통과 + 회귀**

  Run: `flutter test test/cores/grid_suggestor/`
  Expected: 전체 PASS.

- [ ] **Step 3-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/templates/_n4_templates.dart \
          lib/cores/grid_suggestor/templates/grid_templates.dart \
          test/cores/grid_suggestor/templates_n4_test.dart
  git commit -m "feat : N=4 큐레이션 5개 + 4분할 균등 (¼·¾ 화이트리스트 활용) (#1)"
  ```

---

## Task 4: N=5 큐레이션 (4개)

**Files:**
- Create: `lib/cores/grid_suggestor/templates/_n5_templates.dart`
- Test: `test/cores/grid_suggestor/templates_n5_test.dart`
- Modify: `lib/cores/grid_suggestor/templates/grid_templates.dart`

### N=5 큐레이션 패턴

| 이름 | 설명 |
| --- | --- |
| `n5_left1_right4_2x2` | V½ 좌1 + 우(2×2) |
| `n5_top1_bottom4_2x2` | H½ 상1 + 하(2×2) |
| `n5_left2_right3` | V½ 좌(H½ 2) + 우(H⅓ 3) |
| `n5_top2_bottom3` | H½ 상(V½ 2) + 하(V⅓ 3) |

> 5분할 균등은 화이트리스트 외(⅕,⅖,⅗,⅘)라 v1 제외 (spec §5-2).

- [ ] **Step 4-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/templates_n5_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('n5Templates 무결성', () {
      test('정확히 4개', () {
        expect(kGridTemplates[5], hasLength(4));
      });

      test('각 템플릿의 leaf 개수 == 5', () {
        for (final t in kGridTemplates[5]!) {
          expect(cellIdsOf(t.tree), hasLength(5), reason: '${t.name} leaf count');
        }
      });

      test('각 템플릿의 cellIds == [0, 1, 2, 3, 4]', () {
        for (final t in kGridTemplates[5]!) {
          expect(t.cellIds, [0, 1, 2, 3, 4], reason: '${t.name} cellIds');
          expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
        }
      });

      test('이름이 n5_ 로 시작', () {
        for (final t in kGridTemplates[5]!) {
          expect(t.name, startsWith('n5_'));
        }
      });

      test('fingerprint 충돌 없음', () {
        final fps = kGridTemplates[5]!.map((t) => treeFingerprint(t.tree)).toList();
        expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
      });
    });
  }
  ```

- [ ] **Step 4-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/templates_n5_test.dart`
  Expected: 실패 (`kGridTemplates[5]` null).

- [ ] **Step 4-3: N=5 templates 구현**

  Create `lib/cores/grid_suggestor/templates/_n5_templates.dart`:
  ```dart
  import '../models/grid_node.dart';
  import '../models/named_template.dart';

  /// N=5 큐레이션 — 4개. 5분할 균등은 화이트리스트 외라 v1 제외.
  final n5Templates = <NamedTemplate>[
    NamedTemplate(
      name: 'n5_left1_right4_2x2',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: [
              Split(
                axis: SplitAxis.vertical,
                positions: const [0.5],
                children: const [Leaf(1), Leaf(2)],
              ),
              Split(
                axis: SplitAxis.vertical,
                positions: const [0.5],
                children: const [Leaf(3), Leaf(4)],
              ),
            ],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4],
    ),
    NamedTemplate(
      name: 'n5_top1_bottom4_2x2',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: [
              Split(
                axis: SplitAxis.horizontal,
                positions: const [0.5],
                children: const [Leaf(1), Leaf(2)],
              ),
              Split(
                axis: SplitAxis.horizontal,
                positions: const [0.5],
                children: const [Leaf(3), Leaf(4)],
              ),
            ],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4],
    ),
    NamedTemplate(
      name: 'n5_left2_right3',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(0), Leaf(1)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(2), Leaf(3), Leaf(4)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4],
    ),
    NamedTemplate(
      name: 'n5_top2_bottom3',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(0), Leaf(1)],
          ),
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(2), Leaf(3), Leaf(4)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4],
    ),
  ];
  ```

- [ ] **Step 4-4: kGridTemplates 에 N=5 등록**

  Modify `lib/cores/grid_suggestor/templates/grid_templates.dart`:
  ```dart
  import 'dart:collection';

  import '../models/named_template.dart';
  import '_n2_templates.dart';
  import '_n3_templates.dart';
  import '_n4_templates.dart';
  import '_n5_templates.dart';

  /// (dartdoc 동일)
  final Map<int, List<NamedTemplate>> kGridTemplates =
      UnmodifiableMapView<int, List<NamedTemplate>>({
    2: UnmodifiableListView<NamedTemplate>(n2Templates),
    3: UnmodifiableListView<NamedTemplate>(n3Templates),
    4: UnmodifiableListView<NamedTemplate>(n4Templates),
    5: UnmodifiableListView<NamedTemplate>(n5Templates),
  });
  ```

- [ ] **Step 4-5: 테스트 통과 + 회귀**

  Run: `flutter test test/cores/grid_suggestor/`
  Expected: 전체 PASS.

- [ ] **Step 4-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/templates/_n5_templates.dart \
          lib/cores/grid_suggestor/templates/grid_templates.dart \
          test/cores/grid_suggestor/templates_n5_test.dart
  git commit -m "feat : N=5 큐레이션 4개 (1+4 / 2+3 변형) (#1)"
  ```

---

## Task 5: N=6 큐레이션 (5개)

**Files:**
- Create: `lib/cores/grid_suggestor/templates/_n6_templates.dart`
- Test: `test/cores/grid_suggestor/templates_n6_test.dart`
- Modify: `lib/cores/grid_suggestor/templates/grid_templates.dart`

### N=6 큐레이션 패턴

| 이름 | 설명 |
| --- | --- |
| `n6_grid2x3` | V½ + 각 H⅓ (2 col × 3 row) |
| `n6_grid3x2` | V⅓ + 각 H½ (3 col × 2 row) |
| `n6_top2_bottom4` | H½ 상(V½ 2) + 하(V¼·½·¾ 4) |
| `n6_top4_bottom2` | H½ 상(V¼·½·¾ 4) + 하(V½ 2) |
| `n6_left2_right4` | V½ 좌(H½ 2) + 우(H¼·½·¾ 4) |

- [ ] **Step 5-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/templates_n6_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('n6Templates 무결성', () {
      test('정확히 5개', () {
        expect(kGridTemplates[6], hasLength(5));
      });

      test('각 템플릿의 leaf 개수 == 6', () {
        for (final t in kGridTemplates[6]!) {
          expect(cellIdsOf(t.tree), hasLength(6), reason: '${t.name} leaf count');
        }
      });

      test('각 템플릿의 cellIds == [0, 1, 2, 3, 4, 5]', () {
        for (final t in kGridTemplates[6]!) {
          expect(t.cellIds, [0, 1, 2, 3, 4, 5], reason: '${t.name} cellIds');
          expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
        }
      });

      test('이름이 n6_ 로 시작', () {
        for (final t in kGridTemplates[6]!) {
          expect(t.name, startsWith('n6_'));
        }
      });

      test('fingerprint 충돌 없음', () {
        final fps = kGridTemplates[6]!.map((t) => treeFingerprint(t.tree)).toList();
        expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
      });
    });
  }
  ```

- [ ] **Step 5-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/templates_n6_test.dart`
  Expected: 실패.

- [ ] **Step 5-3: N=6 templates 구현**

  Create `lib/cores/grid_suggestor/templates/_n6_templates.dart`:
  ```dart
  import '../models/grid_node.dart';
  import '../models/named_template.dart';

  /// N=6 큐레이션 — 5개.
  final n6Templates = <NamedTemplate>[
    NamedTemplate(
      name: 'n6_grid2x3',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(0), Leaf(1), Leaf(2)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(3), Leaf(4), Leaf(5)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5],
    ),
    NamedTemplate(
      name: 'n6_grid3x2',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [1 / 3, 2 / 3],
        children: [
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(0), Leaf(1)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(2), Leaf(3)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(4), Leaf(5)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5],
    ),
    NamedTemplate(
      name: 'n6_top2_bottom4',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(0), Leaf(1)],
          ),
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 4, 1 / 2, 3 / 4],
            children: const [Leaf(2), Leaf(3), Leaf(4), Leaf(5)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5],
    ),
    NamedTemplate(
      name: 'n6_top4_bottom2',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 4, 1 / 2, 3 / 4],
            children: const [Leaf(0), Leaf(1), Leaf(2), Leaf(3)],
          ),
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(4), Leaf(5)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5],
    ),
    NamedTemplate(
      name: 'n6_left2_right4',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(0), Leaf(1)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 4, 1 / 2, 3 / 4],
            children: const [Leaf(2), Leaf(3), Leaf(4), Leaf(5)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5],
    ),
  ];
  ```

- [ ] **Step 5-4: kGridTemplates 에 N=6 등록**

  Modify `lib/cores/grid_suggestor/templates/grid_templates.dart` — import + Map 항목 추가:
  ```dart
  import '_n6_templates.dart';
  // ... 그리고 Map 에:
  6: UnmodifiableListView<NamedTemplate>(n6Templates),
  ```

- [ ] **Step 5-5: 테스트 통과 + 회귀**

  Run: `flutter test test/cores/grid_suggestor/`
  Expected: 전체 PASS.

- [ ] **Step 5-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/templates/_n6_templates.dart \
          lib/cores/grid_suggestor/templates/grid_templates.dart \
          test/cores/grid_suggestor/templates_n6_test.dart
  git commit -m "feat : N=6 큐레이션 5개 (2×3 / 3×2 / 2+4 / 4+2 변형) (#1)"
  ```

---

## Task 6: N=7 큐레이션 (4개)

**Files:**
- Create: `lib/cores/grid_suggestor/templates/_n7_templates.dart`
- Test: `test/cores/grid_suggestor/templates_n7_test.dart`
- Modify: `lib/cores/grid_suggestor/templates/grid_templates.dart`

### N=7 큐레이션 패턴

| 이름 | 설명 |
| --- | --- |
| `n7_left1_right6_2x3` | V½ 좌1 + 우(2×3 = 6) |
| `n7_top1_bottom6_3x2` | H½ 상1 + 하(3×2 = 6) |
| `n7_left3_right4` | V½ 좌(H⅓ 3) + 우(H¼·½·¾ 4) |
| `n7_top3_bottom4` | H½ 상(V⅓ 3) + 하(V¼·½·¾ 4) |

- [ ] **Step 6-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/templates_n7_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('n7Templates 무결성', () {
      test('정확히 4개', () {
        expect(kGridTemplates[7], hasLength(4));
      });

      test('각 템플릿의 leaf 개수 == 7', () {
        for (final t in kGridTemplates[7]!) {
          expect(cellIdsOf(t.tree), hasLength(7), reason: '${t.name} leaf count');
        }
      });

      test('각 템플릿의 cellIds == [0..6]', () {
        for (final t in kGridTemplates[7]!) {
          expect(t.cellIds, [0, 1, 2, 3, 4, 5, 6], reason: '${t.name} cellIds');
          expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
        }
      });

      test('이름이 n7_ 로 시작', () {
        for (final t in kGridTemplates[7]!) {
          expect(t.name, startsWith('n7_'));
        }
      });

      test('fingerprint 충돌 없음', () {
        final fps = kGridTemplates[7]!.map((t) => treeFingerprint(t.tree)).toList();
        expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
      });
    });
  }
  ```

- [ ] **Step 6-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/templates_n7_test.dart`
  Expected: 실패.

- [ ] **Step 6-3: N=7 templates 구현**

  Create `lib/cores/grid_suggestor/templates/_n7_templates.dart`:
  ```dart
  import '../models/grid_node.dart';
  import '../models/named_template.dart';

  /// N=7 큐레이션 — 4개. (큐레이션 가장 어려운 N — Phase D 시각 iterate 권장)
  final n7Templates = <NamedTemplate>[
    NamedTemplate(
      name: 'n7_left1_right6_2x3',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: [
              Split(
                axis: SplitAxis.vertical,
                positions: const [0.5],
                children: const [Leaf(1), Leaf(2)],
              ),
              Split(
                axis: SplitAxis.vertical,
                positions: const [0.5],
                children: const [Leaf(3), Leaf(4)],
              ),
              Split(
                axis: SplitAxis.vertical,
                positions: const [0.5],
                children: const [Leaf(5), Leaf(6)],
              ),
            ],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6],
    ),
    NamedTemplate(
      name: 'n7_top1_bottom6_3x2',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 3, 2 / 3],
            children: [
              Split(
                axis: SplitAxis.horizontal,
                positions: const [0.5],
                children: const [Leaf(1), Leaf(2)],
              ),
              Split(
                axis: SplitAxis.horizontal,
                positions: const [0.5],
                children: const [Leaf(3), Leaf(4)],
              ),
              Split(
                axis: SplitAxis.horizontal,
                positions: const [0.5],
                children: const [Leaf(5), Leaf(6)],
              ),
            ],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6],
    ),
    NamedTemplate(
      name: 'n7_left3_right4',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(0), Leaf(1), Leaf(2)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 4, 1 / 2, 3 / 4],
            children: const [Leaf(3), Leaf(4), Leaf(5), Leaf(6)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6],
    ),
    NamedTemplate(
      name: 'n7_top3_bottom4',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(0), Leaf(1), Leaf(2)],
          ),
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 4, 1 / 2, 3 / 4],
            children: const [Leaf(3), Leaf(4), Leaf(5), Leaf(6)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6],
    ),
  ];
  ```

- [ ] **Step 6-4: kGridTemplates 에 N=7 등록**

  Modify `lib/cores/grid_suggestor/templates/grid_templates.dart` — import + Map 항목:
  ```dart
  import '_n7_templates.dart';
  // ... Map 에:
  7: UnmodifiableListView<NamedTemplate>(n7Templates),
  ```

- [ ] **Step 6-5: 테스트 통과 + 회귀**

  Run: `flutter test test/cores/grid_suggestor/`
  Expected: 전체 PASS.

- [ ] **Step 6-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/templates/_n7_templates.dart \
          lib/cores/grid_suggestor/templates/grid_templates.dart \
          test/cores/grid_suggestor/templates_n7_test.dart
  git commit -m "feat : N=7 큐레이션 4개 (1+6 / 3+4 변형) (#1)"
  ```

---

## Task 7: N=8 큐레이션 (3개)

**Files:**
- Create: `lib/cores/grid_suggestor/templates/_n8_templates.dart`
- Test: `test/cores/grid_suggestor/templates_n8_test.dart`
- Modify: `lib/cores/grid_suggestor/templates/grid_templates.dart`

### N=8 큐레이션 패턴

| 이름 | 설명 |
| --- | --- |
| `n8_grid4x2` | V¼·½·¾ + 각 H½ (4 col × 2 row) |
| `n8_grid2x4` | H¼·½·¾ + 각 V½ (2 col × 4 row) |
| `n8_top4_bottom4` | H½ 상(V¼·½·¾ 4) + 하(V¼·½·¾ 4) |

- [ ] **Step 7-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/templates_n8_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('n8Templates 무결성', () {
      test('정확히 3개', () {
        expect(kGridTemplates[8], hasLength(3));
      });

      test('각 템플릿의 leaf 개수 == 8', () {
        for (final t in kGridTemplates[8]!) {
          expect(cellIdsOf(t.tree), hasLength(8), reason: '${t.name} leaf count');
        }
      });

      test('각 템플릿의 cellIds == [0..7]', () {
        for (final t in kGridTemplates[8]!) {
          expect(t.cellIds, [0, 1, 2, 3, 4, 5, 6, 7], reason: '${t.name} cellIds');
          expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
        }
      });

      test('이름이 n8_ 로 시작', () {
        for (final t in kGridTemplates[8]!) {
          expect(t.name, startsWith('n8_'));
        }
      });

      test('fingerprint 충돌 없음', () {
        final fps = kGridTemplates[8]!.map((t) => treeFingerprint(t.tree)).toList();
        expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
      });
    });
  }
  ```

- [ ] **Step 7-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/templates_n8_test.dart`
  Expected: 실패.

- [ ] **Step 7-3: N=8 templates 구현**

  Create `lib/cores/grid_suggestor/templates/_n8_templates.dart`:
  ```dart
  import '../models/grid_node.dart';
  import '../models/named_template.dart';

  /// N=8 큐레이션 — 3개.
  final n8Templates = <NamedTemplate>[
    NamedTemplate(
      name: 'n8_grid4x2',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [1 / 4, 1 / 2, 3 / 4],
        children: [
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(0), Leaf(1)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(2), Leaf(3)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(4), Leaf(5)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(6), Leaf(7)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6, 7],
    ),
    NamedTemplate(
      name: 'n8_grid2x4',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [1 / 4, 1 / 2, 3 / 4],
        children: [
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(0), Leaf(1)],
          ),
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(2), Leaf(3)],
          ),
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(4), Leaf(5)],
          ),
          Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(6), Leaf(7)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6, 7],
    ),
    NamedTemplate(
      name: 'n8_top4_bottom4',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 4, 1 / 2, 3 / 4],
            children: const [Leaf(0), Leaf(1), Leaf(2), Leaf(3)],
          ),
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 4, 1 / 2, 3 / 4],
            children: const [Leaf(4), Leaf(5), Leaf(6), Leaf(7)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6, 7],
    ),
  ];
  ```

- [ ] **Step 7-4: kGridTemplates 에 N=8 등록**

  Modify `lib/cores/grid_suggestor/templates/grid_templates.dart`:
  ```dart
  import '_n8_templates.dart';
  // ... Map 에:
  8: UnmodifiableListView<NamedTemplate>(n8Templates),
  ```

- [ ] **Step 7-5: 테스트 통과 + 회귀**

  Run: `flutter test test/cores/grid_suggestor/`
  Expected: 전체 PASS.

- [ ] **Step 7-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/templates/_n8_templates.dart \
          lib/cores/grid_suggestor/templates/grid_templates.dart \
          test/cores/grid_suggestor/templates_n8_test.dart
  git commit -m "feat : N=8 큐레이션 3개 (4×2 / 2×4 / 4+4) (#1)"
  ```

---

## Task 8: N=9 큐레이션 (3개)

**Files:**
- Create: `lib/cores/grid_suggestor/templates/_n9_templates.dart`
- Test: `test/cores/grid_suggestor/templates_n9_test.dart`
- Modify: `lib/cores/grid_suggestor/templates/grid_templates.dart`

### N=9 큐레이션 패턴

| 이름 | 설명 |
| --- | --- |
| `n9_grid3x3` | V⅓ + 각 H⅓ (3 col × 3 row) |
| `n9_left1_right8_4x2` | V½ 좌1 + 우(4×2 = 8) |
| `n9_top1_bottom8_2x4` | H½ 상1 + 하(2×4 = 8) |

- [ ] **Step 8-1: 실패 테스트 작성**

  Create `test/cores/grid_suggestor/templates_n9_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  void main() {
    group('n9Templates 무결성', () {
      test('정확히 3개', () {
        expect(kGridTemplates[9], hasLength(3));
      });

      test('각 템플릿의 leaf 개수 == 9', () {
        for (final t in kGridTemplates[9]!) {
          expect(cellIdsOf(t.tree), hasLength(9), reason: '${t.name} leaf count');
        }
      });

      test('각 템플릿의 cellIds == [0..8]', () {
        for (final t in kGridTemplates[9]!) {
          expect(t.cellIds, [0, 1, 2, 3, 4, 5, 6, 7, 8], reason: '${t.name} cellIds');
          expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
        }
      });

      test('이름이 n9_ 로 시작', () {
        for (final t in kGridTemplates[9]!) {
          expect(t.name, startsWith('n9_'));
        }
      });

      test('fingerprint 충돌 없음', () {
        final fps = kGridTemplates[9]!.map((t) => treeFingerprint(t.tree)).toList();
        expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
      });
    });
  }
  ```

- [ ] **Step 8-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/templates_n9_test.dart`
  Expected: 실패.

- [ ] **Step 8-3: N=9 templates 구현**

  Create `lib/cores/grid_suggestor/templates/_n9_templates.dart`:
  ```dart
  import '../models/grid_node.dart';
  import '../models/named_template.dart';

  /// N=9 큐레이션 — 3개.
  final n9Templates = <NamedTemplate>[
    NamedTemplate(
      name: 'n9_grid3x3',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [1 / 3, 2 / 3],
        children: [
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(0), Leaf(1), Leaf(2)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(3), Leaf(4), Leaf(5)],
          ),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(6), Leaf(7), Leaf(8)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6, 7, 8],
    ),
    NamedTemplate(
      name: 'n9_left1_right8_4x2',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 4, 1 / 2, 3 / 4],
            children: [
              Split(
                axis: SplitAxis.vertical,
                positions: const [0.5],
                children: const [Leaf(1), Leaf(2)],
              ),
              Split(
                axis: SplitAxis.vertical,
                positions: const [0.5],
                children: const [Leaf(3), Leaf(4)],
              ),
              Split(
                axis: SplitAxis.vertical,
                positions: const [0.5],
                children: const [Leaf(5), Leaf(6)],
              ),
              Split(
                axis: SplitAxis.vertical,
                positions: const [0.5],
                children: const [Leaf(7), Leaf(8)],
              ),
            ],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6, 7, 8],
    ),
    NamedTemplate(
      name: 'n9_top1_bottom8_2x4',
      tree: Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.vertical,
            positions: const [1 / 4, 1 / 2, 3 / 4],
            children: [
              Split(
                axis: SplitAxis.horizontal,
                positions: const [0.5],
                children: const [Leaf(1), Leaf(2)],
              ),
              Split(
                axis: SplitAxis.horizontal,
                positions: const [0.5],
                children: const [Leaf(3), Leaf(4)],
              ),
              Split(
                axis: SplitAxis.horizontal,
                positions: const [0.5],
                children: const [Leaf(5), Leaf(6)],
              ),
              Split(
                axis: SplitAxis.horizontal,
                positions: const [0.5],
                children: const [Leaf(7), Leaf(8)],
              ),
            ],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3, 4, 5, 6, 7, 8],
    ),
  ];
  ```

- [ ] **Step 8-4: kGridTemplates 에 N=9 등록 (최종)**

  Modify `lib/cores/grid_suggestor/templates/grid_templates.dart` — 최종 형태:
  ```dart
  import 'dart:collection';

  import '../models/named_template.dart';
  import '_n2_templates.dart';
  import '_n3_templates.dart';
  import '_n4_templates.dart';
  import '_n5_templates.dart';
  import '_n6_templates.dart';
  import '_n7_templates.dart';
  import '_n8_templates.dart';
  import '_n9_templates.dart';

  /// N → 큐레이션된 템플릿 list.
  ///
  /// Phase B 완료 — N=2..9 등록 완료. 합계 ≥28.
  /// 외부에서 Map/List 변경을 막기 위해 [UnmodifiableMapView]·[UnmodifiableListView] 로 노출.
  /// 무결성 invariant 는 templates_test 에서 검증.
  final Map<int, List<NamedTemplate>> kGridTemplates =
      UnmodifiableMapView<int, List<NamedTemplate>>({
    2: UnmodifiableListView<NamedTemplate>(n2Templates),
    3: UnmodifiableListView<NamedTemplate>(n3Templates),
    4: UnmodifiableListView<NamedTemplate>(n4Templates),
    5: UnmodifiableListView<NamedTemplate>(n5Templates),
    6: UnmodifiableListView<NamedTemplate>(n6Templates),
    7: UnmodifiableListView<NamedTemplate>(n7Templates),
    8: UnmodifiableListView<NamedTemplate>(n8Templates),
    9: UnmodifiableListView<NamedTemplate>(n9Templates),
  });
  ```

- [ ] **Step 8-5: 테스트 통과 + 회귀**

  Run: `flutter test test/cores/grid_suggestor/`
  Expected: 전체 PASS. 이 시점에 Phase B 카탈로그 코어 완성 — Task 9 는 정리/통합 단계.

- [ ] **Step 8-6: Commit**

  ```bash
  git add lib/cores/grid_suggestor/templates/_n9_templates.dart \
          lib/cores/grid_suggestor/templates/grid_templates.dart \
          test/cores/grid_suggestor/templates_n9_test.dart
  git commit -m "feat : N=9 큐레이션 3개 + kGridTemplates 모든 N 등록 완료 (#1)"
  ```

---

## Task 9: 8 invariant 통합 테스트 + N별 spot-check 정리

**Files:**
- Create: `test/cores/grid_suggestor/templates_test.dart` (8 invariant 통합 sweep)
- Delete: `test/cores/grid_suggestor/templates_n2_test.dart`
- Delete: `test/cores/grid_suggestor/templates_n3_test.dart`
- Delete: `test/cores/grid_suggestor/templates_n4_test.dart`
- Delete: `test/cores/grid_suggestor/templates_n5_test.dart`
- Delete: `test/cores/grid_suggestor/templates_n6_test.dart`
- Delete: `test/cores/grid_suggestor/templates_n7_test.dart`
- Delete: `test/cores/grid_suggestor/templates_n8_test.dart`
- Delete: `test/cores/grid_suggestor/templates_n9_test.dart`

> Task 9 는 Task 1~8 의 N별 spot-check 들 (각 5 invariant) 을 단일 통합 테스트(`templates_test.dart`) 로 흡수한다. 통합 테스트가 모든 N 을 sweep 하면서 8 invariant 전체를 검증하므로 N별 단위 테스트는 중복.

- [ ] **Step 9-1: 실패 테스트 작성 (통합 8 invariant)**

  Create `test/cores/grid_suggestor/templates_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

  // Private 모듈 직접 import — 화이트리스트 invariant 검증에 필요.
  // 외부 features/ 에서는 이 import 가 의도적으로 막혀있다 (배럴만 사용).
  import 'package:gridset/cores/grid_suggestor/templates/_allowed_positions.dart';

  void main() {
    group('kGridTemplates 통합 invariant (8 항목)', () {
      // Invariant #1: kGridTemplates.keys == {2..9}
      test('1. N 키는 정확히 {2, 3, 4, 5, 6, 7, 8, 9}', () {
        expect(kGridTemplates.keys.toSet(), {2, 3, 4, 5, 6, 7, 8, 9});
      });

      // Invariant #2: 각 N 별 ≥ 3 templates (spec §5-2 lower bound)
      test('2. 각 N 의 템플릿 개수 ≥ 3', () {
        for (final entry in kGridTemplates.entries) {
          expect(
            entry.value.length,
            greaterThanOrEqualTo(3),
            reason: 'N=${entry.key} 의 템플릿이 3개 미만',
          );
        }
      });

      // Invariant #3: 각 템플릿의 leaf 개수 == N
      test('3. 각 템플릿의 leaf 개수 == N', () {
        for (final entry in kGridTemplates.entries) {
          final n = entry.key;
          for (final t in entry.value) {
            expect(
              cellIdsOf(t.tree),
              hasLength(n),
              reason: '${t.name} 의 leaf 개수가 $n 이 아님',
            );
          }
        }
      });

      // Invariant #4: 각 템플릿의 cellIds == [0..N-1] 정확히 (캐시와 traversal 일치)
      test('4. 각 템플릿의 cellIds == [0..N-1] + traversal 결과와 일치', () {
        for (final entry in kGridTemplates.entries) {
          final n = entry.key;
          final expected = List<int>.generate(n, (i) => i);
          for (final t in entry.value) {
            expect(t.cellIds, expected, reason: '${t.name} cellIds 가 [0..N-1] 아님');
            expect(
              cellIdsOf(t.tree),
              t.cellIds,
              reason: '${t.name} traversal 결과 != cellIds 캐시',
            );
          }
        }
      });

      // Invariant #5: 각 Split.positions 의 모든 값 ∈ kAllowedPositions (1e-9 tolerance)
      test('5. 모든 Split.positions ∈ kAllowedPositions (화이트리스트)', () {
        for (final entry in kGridTemplates.entries) {
          for (final t in entry.value) {
            _walkSplits(t.tree, (split) {
              for (final p in split.positions) {
                expect(
                  isAllowedPosition(p),
                  isTrue,
                  reason: '${t.name} 의 position $p 가 화이트리스트 외',
                );
              }
            });
          }
        }
      });

      // Invariant #6: 각 Split.positions 가 strictly ascending
      test('6. 모든 Split.positions strictly ascending', () {
        for (final entry in kGridTemplates.entries) {
          for (final t in entry.value) {
            _walkSplits(t.tree, (split) {
              for (var i = 1; i < split.positions.length; i++) {
                expect(
                  split.positions[i],
                  greaterThan(split.positions[i - 1]),
                  reason: '${t.name} positions 가 오름차순 아님',
                );
              }
            });
          }
        }
      });

      // Invariant #7: 같은 N 안에서 fingerprint 충돌 없음
      test('7. 같은 N 안에서 fingerprint 충돌 없음', () {
        for (final entry in kGridTemplates.entries) {
          final fps = entry.value.map((t) => treeFingerprint(t.tree)).toList();
          expect(
            fps.toSet().length,
            fps.length,
            reason:
                'N=${entry.key} 에서 중복 fingerprint 발견: '
                '${fps.where((fp) => fps.where((x) => x == fp).length > 1).toSet()}',
          );
        }
      });

      // Invariant #8: name 이 'n{N}_' 로 시작
      test('8. 모든 name 이 n{N}_ 로 시작', () {
        for (final entry in kGridTemplates.entries) {
          final n = entry.key;
          for (final t in entry.value) {
            expect(
              t.name,
              startsWith('n${n}_'),
              reason: '${t.name} 가 n${n}_ prefix 아님',
            );
          }
        }
      });

      // Bonus: 합계 ≥ 28 (spec §5-2 목표)
      test('합계 ≥ 28 templates (spec §5-2 목표)', () {
        final total =
            kGridTemplates.values.fold<int>(0, (sum, list) => sum + list.length);
        expect(total, greaterThanOrEqualTo(28));
      });
    });
  }

  /// 트리의 모든 Split 노드를 순회하며 visitor 호출.
  ///
  /// Dart 3 sealed class 패턴 매칭에서 `case final Split split:` 는
  /// `node` 가 Split 일 때 typed 변수 `split` 으로 binding (object pattern + variable pattern).
  void _walkSplits(GridNode node, void Function(Split) visit) {
    switch (node) {
      case Leaf():
        return;
      case final Split split:
        visit(split);
        for (final c in split.children) {
          _walkSplits(c, visit);
        }
    }
  }
  ```

- [ ] **Step 9-2: 실패 확인**

  Run: `flutter test test/cores/grid_suggestor/templates_test.dart`
  Expected: PASS — 모든 N 카탈로그가 이미 Task 1~8 에서 검증된 상태로 들어있으므로 통합 테스트도 자연 통과.

  만약 실패하면: 어느 invariant 인지 확인 후 해당 N 의 templates 파일 수정. 수정 후 회귀 (`flutter test test/cores/grid_suggestor/`).

- [ ] **Step 9-3: N별 spot-check 테스트 파일 8개 삭제**

  N별 spot-check 가 통합 테스트로 흡수되었으므로 중복 제거:
  ```bash
  rm test/cores/grid_suggestor/templates_n2_test.dart \
     test/cores/grid_suggestor/templates_n3_test.dart \
     test/cores/grid_suggestor/templates_n4_test.dart \
     test/cores/grid_suggestor/templates_n5_test.dart \
     test/cores/grid_suggestor/templates_n6_test.dart \
     test/cores/grid_suggestor/templates_n7_test.dart \
     test/cores/grid_suggestor/templates_n8_test.dart \
     test/cores/grid_suggestor/templates_n9_test.dart
  ```

- [ ] **Step 9-4: 정리 후 회귀 테스트**

  Run: `flutter test test/cores/grid_suggestor/`
  Expected: 전체 PASS. 이 시점 모듈 테스트 카운트 ≈ 64 (Phase A) + ~9 (templates_test 9 tests including bonus) + 4 (allowed_positions) = ~77.

- [ ] **Step 9-5: 분석기 통과**

  Run: `flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/`
  Expected: `No issues found!`.

- [ ] **Step 9-6: Commit**

  ```bash
  git add test/cores/grid_suggestor/templates_test.dart
  git add -u test/cores/grid_suggestor/  # 삭제된 8 파일 스테이징
  git commit -m "test : 8 invariant 통합 sweep + N별 spot-check 정리 (#1)"
  ```

---

## Phase B 완료 체크리스트 (DoD)

- [ ] `flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/` → `No issues found!`
- [ ] `flutter test test/cores/grid_suggestor/` → 전체 PASS (~77 tests 예상)
- [ ] `kGridTemplates.keys` == `{2, 3, 4, 5, 6, 7, 8, 9}` — 통합 invariant #1 검증
- [ ] 합계 ≥ 28 templates — 통합 invariant bonus 검증
- [ ] 8 invariant 통합 테스트 모두 통과 — `templates_test.dart`
- [ ] N별 단위 테스트 파일들 정리 (`templates_n{2..9}_test.dart` 모두 삭제, `templates_test.dart` 단일 파일만 남음)
- [ ] 커밋 9개 (Task 1~9, 모두 `(#1)` 태그)

---

## 다음 단계 안내 (Phase C-E 미리보기)

Phase B 머지 후 별도 plan 사이클로:

| Phase | 책임 | 주요 task |
| --- | --- | --- |
| **C** — `/dev` 갤러리 | `grid_template_preview` 위젯 + dev_gallery 섹션 + 캔버스 비율 토글 | 3 task |
| **D** — 시각 iterate | /dev 갤러리에서 ugly 발견 → 해당 N 의 templates 교체 (Phase C 끝나야 가능) | 1 task (반복) |
| **E** — 마감 | golden 테스트 N=2..9 + perf < 300ms + 커버리지 95% 검증 | 4 task |

Phase B 까지 완료되면 Suggestion 화면 spec 사이클 시작 가능 (호출부가 N=2..9 의 정상 결과를 받을 수 있음).
