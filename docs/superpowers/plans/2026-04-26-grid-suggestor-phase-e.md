# Grid Suggestor v1 — Phase E Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phase A-C 까지 완성된 알고리즘 + 큐레이션 + dev 갤러리 위에 spec §6-3 의 Layer 4(golden) + Layer 5(perf) 를 추가하고 커버리지 95% 도달을 측정해 issue #1 의 마감 검증을 완료한다. Layer 1-3(입력 검증 / 순수 함수 단위 / 8 invariant) 은 Phase A/B 에서 이미 충족.

**Architecture:** N=3..9 mixed-aspect fixture 를 `test/cores/grid_suggestor/fixtures/photos.dart` 에 보강한 뒤, suggester_test 에 "골든" group 을 추가해 N=2..9 각 대표 입력의 **첫 suggestion `templateName`** 을 고정. 신규 `suggester_perf_test.dart` 가 N=9 mixed-aspect 입력으로 10회 평균 < 300ms 검증. 마지막 task 에서 `flutter test --coverage` 실행 후 lcov 수치 보고.

**Tech Stack:** `flutter_test`, `dart:async` `Stopwatch`, `lcov` (Flutter 기본 포함). 추가 패키지 없음.

**Spec:** `docs/superpowers/specs/2026-04-26-grid-suggestor-design.md` §4-9 (성능 예산), §6-3 Layer 4 (`golden: N=4 portrait916 first suggestion is grid2x2`), Layer 5 (`perf: N=9 within 300ms`), §6-4 (커버리지 95%).

**Phase Scope:** **Phase E 만**. Phase D (시각 iterate) 는 사용자 핫리로드 검토로 별도 진행 — Phase E 의 골든은 현재 templates 의 첫 suggestion 을 capture 하므로 D 가 templates 를 교체하면 골든 갱신이 자연스럽게 필요.

**Phase E Deliverable Definition (DoD):**
- `flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/` → `No issues found!`
- `flutter test test/cores/grid_suggestor/` 전체 통과 (Phase B 의 72 + 신규 ~12 ≈ 84+)
- N=2..9 골든 8 케이스 모두 통과 (현재 큐레이션 기준 capture)
- `suggester_perf_test.dart` N=9 평균 < 300ms (테스트 러너 기준)
- `flutter test --coverage` 후 `lib/cores/grid_suggestor/` 커버리지 ≥ 95% (보고만, 강제 fail 없음)
- 커밋 4개 (Task 1~4)

---

## File Structure

### Create

| 경로 | 책임 |
| --- | --- |
| `test/cores/grid_suggestor/suggester_perf_test.dart` | N=9 mixed-aspect 입력으로 `suggest()` 10회 평균 측정 — < 300ms expect (Phase E Task 3) |

### Modify

| 경로 | 변경 |
| --- | --- |
| `test/cores/grid_suggestor/fixtures/photos.dart` | N=3..9 mixed-aspect fixture 7개 추가 (Task 1) |
| `test/cores/grid_suggestor/suggester_test.dart` | 새 group "골든 — 각 N 의 첫 suggestion 이름 고정" 추가, 8 케이스 (Task 2) |

> **Note**: 현재 fixtures 는 N=2 만 (`photos2Mixed`, `photos2Square`). N=3..9 fixture 가 없어서 골든 + perf 가 작동하려면 보강 필수. 보강은 Task 1 에서 한 번에.

---

## Pre-flight: 빌드 환경 확인

- [ ] **Step 0-1: Phase C 안정 확인**

  Run (저장소 루트에서):
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Expected: analyze clean + 108/108 PASS.

- [ ] **Step 0-2: 사용자 안내 — Phase D 미진행 영향**

  Phase D (시각 iterate) 가 미진행이라 Phase E 의 골든 8개는 **현재 templates 의 첫 suggestion 을 capture**. 추후 Phase D 에서 templates 를 교체하면 깨지는 골든은 정상 — 의도적 큐레이션 변경이 PR 리뷰 게이트에서 골든 갱신과 함께 통과해야 함 (spec §6-3 Layer 4 의 "큐레이션 의도 변경 시 골든도 의도적 업데이트").

---

## Task 1: N=3..9 mixed-aspect fixture 보강

**Files:**
- Modify: `test/cores/grid_suggestor/fixtures/photos.dart` (현재 14 lines → ~70 lines 예상)

> 모든 fixture 는 `const` `MediaItem` list. id 는 `p1`, `p2` ... 로 단순 (test 비교 용이). aspectRatio 는 mixed (가로 + 세로 + 정사각 섞어) 로 골든이 실제 매핑 다양성을 검증하도록.

### Step 1-1: fixture 보강

`test/cores/grid_suggestor/fixtures/photos.dart` 를 다음 전체로 교체:
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

/// 3장 — 가로 1, 세로 1, 정사각 1 (다양성 mix).
const photos3Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.0),
];

/// 4장 — 2 가로 + 2 세로.
const photos4Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
];

/// 5장 — 2 가로 + 2 세로 + 1 정사각.
const photos5Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 1.0),
];

/// 6장 — 3 가로 + 3 세로.
const photos6Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p6', type: MediaType.photo, aspectRatio: 0.667),
];

/// 7장 — 3 가로 + 3 세로 + 1 정사각.
const photos7Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p6', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p7', type: MediaType.photo, aspectRatio: 1.0),
];

/// 8장 — 4 가로 + 4 세로.
const photos8Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p6', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p7', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p8', type: MediaType.photo, aspectRatio: 0.667),
];

/// 9장 — 3 가로 + 3 세로 + 3 정사각 (perf 측정 + 골든 모두 사용).
const photos9Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p6', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p7', type: MediaType.photo, aspectRatio: 1.0),
  MediaItem(id: 'p8', type: MediaType.photo, aspectRatio: 1.0),
  MediaItem(id: 'p9', type: MediaType.photo, aspectRatio: 1.0),
];
```

### Step 1-2: 회귀 — 기존 테스트가 깨지지 않는지 확인

Run: `flutter test test/cores/grid_suggestor/`
Expected: 72/72 PASS (기존 N=2 fixture 사용 코드 그대로 동작 — 새 fixture 는 noop).

### Step 1-3: 분석기 통과

Run: `flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/`
Expected: `No issues found!` (사용 안되는 const 라도 lint 무관).

### Step 1-4: Commit

```bash
git add test/cores/grid_suggestor/fixtures/photos.dart
git commit -m "test : N=3..9 mixed-aspect fixture 보강 (golden/perf 준비) (#1)"
```

---

## Task 2: Golden test — N=2..9 첫 suggestion templateName 고정

**Files:**
- Modify: `test/cores/grid_suggestor/suggester_test.dart` — 새 `group('골든 — 첫 suggestion templateName 고정', ...)` 추가, 8 testWidgets

> spec §6-3 Layer 4 의 "Golden 은 N=2..9 각각 대표 fixture 1개 → 첫 suggestion 의 templateName 고정. 큐레이션 의도 변경 시 골든도 의도적 업데이트". canvas 는 가장 흔한 `portrait916()` 으로 통일.

### Step 2-1: 골든 capture (실패 테스트 우선 작성)

`test/cores/grid_suggestor/suggester_test.dart` 의 마지막 group 닫힘 `}` 뒤에 추가:
```dart
group('suggest() — 골든 (각 N 의 첫 suggestion templateName 고정)', () {
  // canvas 는 PRD 기본값 9:16 로 통일. 큐레이션 변경 시 골든도 의도적 갱신.

  test('N=2 — first suggestion is n2_v_60_40 (현재 큐레이션)', () {
    final r = suggest(
      media: photos2Mixed,
      canvas: const CanvasRatio.portrait916(),
    );
    expect(r.suggestions, isNotEmpty);
    expect(r.suggestions.first.templateName, 'GOLDEN_TBD_N2');
  });

  test('N=3 — first suggestion (현재 큐레이션)', () {
    final r = suggest(
      media: photos3Mixed,
      canvas: const CanvasRatio.portrait916(),
    );
    expect(r.suggestions, isNotEmpty);
    expect(r.suggestions.first.templateName, 'GOLDEN_TBD_N3');
  });

  test('N=4 — first suggestion (현재 큐레이션)', () {
    final r = suggest(
      media: photos4Mixed,
      canvas: const CanvasRatio.portrait916(),
    );
    expect(r.suggestions, isNotEmpty);
    expect(r.suggestions.first.templateName, 'GOLDEN_TBD_N4');
  });

  test('N=5 — first suggestion (현재 큐레이션)', () {
    final r = suggest(
      media: photos5Mixed,
      canvas: const CanvasRatio.portrait916(),
    );
    expect(r.suggestions, isNotEmpty);
    expect(r.suggestions.first.templateName, 'GOLDEN_TBD_N5');
  });

  test('N=6 — first suggestion (현재 큐레이션)', () {
    final r = suggest(
      media: photos6Mixed,
      canvas: const CanvasRatio.portrait916(),
    );
    expect(r.suggestions, isNotEmpty);
    expect(r.suggestions.first.templateName, 'GOLDEN_TBD_N6');
  });

  test('N=7 — first suggestion (현재 큐레이션)', () {
    final r = suggest(
      media: photos7Mixed,
      canvas: const CanvasRatio.portrait916(),
    );
    expect(r.suggestions, isNotEmpty);
    expect(r.suggestions.first.templateName, 'GOLDEN_TBD_N7');
  });

  test('N=8 — first suggestion (현재 큐레이션)', () {
    final r = suggest(
      media: photos8Mixed,
      canvas: const CanvasRatio.portrait916(),
    );
    expect(r.suggestions, isNotEmpty);
    expect(r.suggestions.first.templateName, 'GOLDEN_TBD_N8');
  });

  test('N=9 — first suggestion (현재 큐레이션)', () {
    final r = suggest(
      media: photos9Mixed,
      canvas: const CanvasRatio.portrait916(),
    );
    expect(r.suggestions, isNotEmpty);
    expect(r.suggestions.first.templateName, 'GOLDEN_TBD_N9');
  });
});
```

### Step 2-2: 실패 확인 — 실제 templateName 추출

Run: `flutter test test/cores/grid_suggestor/suggester_test.dart`
Expected: 8 골든 모두 실패 — 실패 메시지의 `Actual: 'n4_xxx'` 부분이 실제 첫 suggestion 의 templateName. 8개 모두 추출 후 다음 step 에서 `GOLDEN_TBD_N{n}` 자리 교체.

> 알고리즘 결정성 (Phase A determinism test 통과 확인됨) 덕분에 골든이 매 실행마다 동일하게 capture 된다.

### Step 2-3: 골든 값 교체

Step 2-2 의 실패 메시지에서 추출한 N=2..9 각 templateName 으로 8개 `GOLDEN_TBD_N{n}` 자리 교체. 예시:
- `'GOLDEN_TBD_N2'` → `'n2_v_60_40'` (실제 출력 따라)
- `'GOLDEN_TBD_N3'` → 실제 출력 (e.g., `'n3_top1_bottom2'`)
- ...

> implementer 에게 dispatch 시: 위 8 자리 모두 실제 출력으로 교체 후 다시 `flutter test` 통과 확인.

### Step 2-4: 통과 확인 + 회귀

Run: `flutter test test/cores/grid_suggestor/`
Expected: 전체 PASS (Phase B 72 + Task 1 fixture noop + Task 2 골든 8 = 80).

### Step 2-5: 분석기

Run: `flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/`
Expected: `No issues found!`.

### Step 2-6: Commit

```bash
git add test/cores/grid_suggestor/suggester_test.dart
git commit -m "test : 골든 — N=2..9 각 첫 suggestion templateName 고정 (#1)"
```

---

## Task 3: Perf benchmark — N=9 < 300ms

**Files:**
- Create: `test/cores/grid_suggestor/suggester_perf_test.dart`

> spec §6-3 Layer 5 코드 그대로. 단, 사용 fixture 는 Task 1 의 `photos9Mixed`. CI noise 가 큰 환경에서 흔들리면 expect 빼고 print 만 (회귀 감지용 baseline) — 일단 expect 유지 후 flaky 발견 시 사용자가 결정.

### Step 3-1: 신규 perf test 작성

Create `test/cores/grid_suggestor/suggester_perf_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

import 'fixtures/photos.dart';

void main() {
  group('suggester perf', () {
    test('N=9 suggest() 10회 평균 < 300ms (테스트 러너 기준)', () {
      // PRD §11 < 3000ms (모바일) 에 10x 마진. 테스트 러너(macOS host) 기준.
      // 9! = 362,880 permutations × 9 비교 ≈ 3.3M ops — N=9 가 최악.
      const iterations = 10;
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        suggest(
          media: photos9Mixed,
          canvas: const CanvasRatio.portrait916(),
        );
      }
      sw.stop();
      final avgMs = sw.elapsedMilliseconds / iterations;
      // 디버깅 시 평균 확인용 — CI 에서도 stdout 에 남음.
      // ignore: avoid_print
      print('avg N=9 suggest: ${avgMs.toStringAsFixed(1)}ms');
      expect(
        avgMs,
        lessThan(300),
        reason: 'N=9 평균 응답 < 300ms 위반 — 알고리즘 회귀 의심',
      );
    });
  });
}
```

### Step 3-2: 통과 확인

Run: `flutter test test/cores/grid_suggestor/suggester_perf_test.dart`
Expected: 1 test PASS, stdout 에 `avg N=9 suggest: <X>ms` 출력. X 는 일반적으로 < 50ms 예상 (브루트포스 N! 가 9! ≈ 362,880, dart vm 빠름).

만약 expect 실패 (X >= 300):
- 테스트 러너 환경 노이즈가 큰지 확인 (CPU 사용률, 다른 프로세스).
- 알고리즘 회귀 가능성 — `bestMapping`, `cellAspectRatios` 의 hot path 에 새 비용 추가됐는지 git diff 확인.
- DONE_WITH_CONCERNS 로 보고.

### Step 3-3: 회귀 + analyze

Run:
```bash
flutter test test/cores/grid_suggestor/
flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/
```
Expected: 전부 PASS + analyze clean.

### Step 3-4: Commit

```bash
git add test/cores/grid_suggestor/suggester_perf_test.dart
git commit -m "test : N=9 perf benchmark (10회 평균 < 300ms) (#1)"
```

---

## Task 4: Coverage 측정 + DoD 정리

**Files:**
- (수정 없음 — 측정/보고만)

> spec §6-4: 95% 자연 도달 예상. `flutter test --coverage` + lcov 로 측정. 강제 fail 게이트 없음 (보고만 — DoD 통과 검증).

### Step 4-1: coverage 측정

Run (저장소 루트에서):
```bash
flutter test --coverage
```
Expected: `coverage/lcov.info` 생성, 전체 test suite PASS.

### Step 4-2: lcov 수치 확인 (grid_suggestor 모듈만)

Run (lcov gem 설치 안 했을 수 있어 awk 로 직접 추출):
```bash
awk '
/^SF:lib\/cores\/grid_suggestor/ { include = 1; lines = 0; hit = 0 }
include && /^DA:/ {
  lines++
  split($0, a, ",")
  if (a[2] != "0") hit++
}
include && /^end_of_record/ {
  print FILENAME ": " hit "/" lines
  total_lines += lines
  total_hit += hit
  include = 0
}
END {
  if (total_lines > 0) {
    printf "TOTAL grid_suggestor: %d/%d (%.1f%%)\n", total_hit, total_lines, (total_hit / total_lines * 100)
  }
}
' coverage/lcov.info
```
Expected: `TOTAL grid_suggestor: <hit>/<lines> (≥95.0%)`.

만약 < 95%:
- 어느 파일이 낮은지 위 출력의 file별 라인에서 식별.
- 미커버 분기 — 합리적 (e.g., `bestMapping` 의 n=0 fallback 은 `validateSuggestInput` 가 막아줘 도달 불가) → 95% 미달이라도 받아들임.
- 알고리즘 의도와 다른 dead code → 별도 후속 작업으로 정리 (Phase E 범위 외).
- 측정 결과 자체는 보고. 95% 미달이면 DONE_WITH_CONCERNS 로 보고하고 사용자 결정 대기.

### Step 4-3: Phase E DoD 최종 점검

Run:
```bash
flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/
flutter test test/cores/grid_suggestor/ 2>&1 | tail -3
```
Expected:
- analyze clean
- All tests passed (Phase B 의 72 + Phase E Task 1 fixture noop + Task 2 골든 8 + Task 3 perf 1 = 81)

> Phase C 의 dev 갤러리 test 는 별도 (`test/features/dev/`) — Phase E 범위 외 회귀로 `flutter test` 전체 한 번 더 확인 권장.

Run: `flutter test 2>&1 | tail -3`
Expected: 전체 PASS (Phase C 까지 108 + Phase E 신규 9 = 117).

### Step 4-4: Commit (보고용 메시지 only — 코드 변경 없음)

> Task 4 는 측정만 하므로 commit 할 코드 변경 없음. 그러나 Phase 흐름 일관성 위해 plan 의 measurement summary 를 plan 문서에 append + commit 할 수도 있다. 기본은 commit 없음 — 측정 결과만 reporter 가 본문에 포함하고 사용자가 plan 갱신 결정.

만약 plan doc 에 결과 append 옵션 선택 시:
```bash
# Phase E plan 의 DoD 섹션에 measurement 결과 추가 후
git add docs/superpowers/plans/2026-04-26-grid-suggestor-phase-e.md
git commit -m "docs : Phase E coverage 측정 결과 plan 에 기록 (#1)"
```

---

## Phase E 완료 체크리스트 (DoD)

- [ ] `flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/` → `No issues found!`
- [ ] `flutter test test/cores/grid_suggestor/` 전체 PASS (~81 tests)
- [ ] `flutter test` 전체 회귀 PASS (~117 tests)
- [ ] N=2..9 골든 8 케이스 모두 통과
- [ ] N=9 perf 평균 < 300ms (stdout 에 측정값 출력)
- [ ] `lib/cores/grid_suggestor/` 라인 커버리지 ≥ 95% (또는 미달 사유 명시)
- [ ] 커밋 3~4개 (Task 1~3 + 옵션 4, 모두 `(#1)`, Co-Authored-By 부재)

---

## 다음 단계 안내 (Phase E 후)

Phase E 완료 시 issue #1 의 모든 작업 항목 충족 — issue close 가능. 후속 사이클:

| 다음 사이클 | 책임 | 비고 |
| --- | --- | --- |
| **Phase D 시각 iterate (사용자 핫리로드)** | 사용자가 `/dev` 갤러리에서 N=2..9 31 카드 검토 → ugly 발견 시 `_n{N}_templates.dart` 의 entry 교체 | Phase E 의 골든 8개 재캡처 필요 (templates 변경 시 자연 발생) |
| **Suggestion 화면 spec 사이클** | 호출부 (PRD §F00, §9-2-1~3) — `suggest()` 를 사용하는 UI Notifier + 화면 + 라우팅 | spec/plan/implement 신규 사이클. 의존: 본 issue #1 머지 |
| **future-risk 정리 (Phase A reviewer 식별)** | `AppRadius` 토큰 신설 + `BorderRadius.circular(N)` 일괄 교체 / `dev_gallery_page.dart` 분리 / N=8·N=9 templates 다양성 추가 | tech debt cycle, 우선순위 낮음 |
