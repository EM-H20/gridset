# Grid Suggestor v1 — Phase C Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phase B 까지 완성된 큐레이션 카탈로그(N=2..9 합계 31개)를 `/dev` 갤러리에 시각 sweep 으로 노출 — Phase D 시각 iterate(ugly 발견 → 큐레이션 교체)의 prerequisite WYSIWYG 도구 확보.

**Architecture:** `GridTemplatePreview` 가 `NamedTemplate` + `CanvasRatio` 를 받아 알고리즘 모듈의 `cellBBoxes` 를 재사용해 `Stack` + `Positioned.fromRect` 로 BSP 시각화. `dev_gallery_page` 안의 새 private `_GridTemplatesSection` 이 N별로 sweep 하며 섹션 단위 캔버스 비율 토글을 갖는 StatefulWidget. 다른 섹션들과 동일한 `_*Section` 패턴 유지.

**Tech Stack:** Flutter (`StatefulWidget`, `AspectRatio`, `Stack`, `Positioned.fromRect`, `Wrap`, `LayoutBuilder`), `flutter_screenutil` (`.w/.h/.sp`), 알고리즘 모듈 (`cellBBoxes`, `CellRect`, `kGridTemplates`, `CanvasRatio`, `NamedTemplate` — 배럴 `package:gridset/cores/grid_suggestor/grid_suggestor.dart`), `flutter_test` (`testWidgets`, `find.byType`, `find.text`, `tester.tap`, `pumpAndSettle`).

**Spec:** `docs/superpowers/specs/2026-04-26-grid-suggestor-design.md` §5-5 (`/dev` 갤러리 — "Grid Templates" 섹션). 의존 spec `docs/superpowers/specs/2026-04-25-home-and-dev-gallery-design.md` §5 (Dev 컴포넌트 갤러리) 의 `_*Section` 패턴 유지.

**Phase Scope:** **Phase C 만**. Phase D (시각 iterate — ugly 발견 시 templates 교체) 와 Phase E (golden + perf + 통합) 는 별도 후속 plan 사이클.

**Phase C Deliverable Definition (DoD):**
- `flutter analyze lib/features/dev/ test/features/dev/` → `No issues found!`
- `flutter test test/features/dev/` 전체 통과 (기존 4 + 신규 ~6 ≈ 10+ tests)
- `flutter test` 전체 회귀 통과 (Phase B 의 72/72 + 신규 tests)
- `/dev` 갤러리 진입 시 새 "Grid Templates" 섹션 노출 — N=2..9 sweep, 합계 31 카드 렌더
- 4 preset 캔버스 비율 토글 (9:16 / 1:1 / 4:5 / 16:9) — 탭 시 모든 카드 동시 리렌더
- 섹션 카드 색상/텍스트/간격 모두 `AppColors`/`AppTextStyles`/`AppSpacing` 사용 (raw 값 0)
- 커밋 3개 (Task 1~3)

---

## File Structure

### Create

| 경로 | 책임 |
| --- | --- |
| `lib/features/dev/widgets/grid_template_preview.dart` | `GridTemplatePreview` widget — `NamedTemplate` + `CanvasRatio` → AspectRatio 컨테이너 + Stack/Positioned 로 BSP 시각화 + 셀별 cellId 번호 + 템플릿 이름 라벨 |
| `test/features/dev/widgets/grid_template_preview_test.dart` | widget unit test (이름 표시 / 셀 개수 / cellId 번호 / 캔버스 비율 변경 시 AspectRatio 갱신) |

### Modify

| 경로 | 변경 |
| --- | --- |
| `lib/features/dev/dev_gallery_page.dart` | `_GridTemplatesSection` private `StatefulWidget` 추가 (Task 2 에서 stateless 로 시작 → Task 3 에서 stateful 화), `SingleChildScrollView` 의 `Column` 에 등장 위치 추가 |
| `test/features/dev/dev_gallery_page_test.dart` | "Grid Templates" 섹션 sweep test + 캔버스 비율 토글 interaction test 보강 |

> **Note**: `_GridTemplatesSection` 은 다른 섹션들과 일관성 위해 `dev_gallery_page.dart` 내부 private class. 단, 카드를 그리는 `GridTemplatePreview` 는 다른 섹션의 `AppColorSwatch` 처럼 `widgets/` 하위에 별도 파일.

---

## Pre-flight: 빌드 환경 확인

- [ ] **Step 0-1: Phase B 안정 확인**

  Run (저장소 루트에서):
  ```bash
  flutter analyze lib/cores/grid_suggestor/ test/cores/grid_suggestor/
  flutter test test/cores/grid_suggestor/
  ```
  Expected: analyze clean + 72/72 PASS.

- [ ] **Step 0-2: 기존 dev 갤러리 회귀 baseline 확인**

  Run:
  ```bash
  flutter test test/features/dev/dev_gallery_page_test.dart
  ```
  Expected: 4 tests PASS (Components 타이틀 / 4 섹션 제목 sweep / AppButton 다수 인스턴스 / back 라우팅).

- [ ] **Step 0-3: build_runner 불필요 확인**

  Phase C 는 Freezed/JSON codegen 추가하지 않음 (UI 위젯만 추가). watch 가 살아있으면 그대로, 죽었으면 시작 안 해도 OK.

---

## Task 1: `GridTemplatePreview` 위젯 + widget test

**Files:**
- Create: `lib/features/dev/widgets/grid_template_preview.dart`
- Create: `test/features/dev/widgets/grid_template_preview_test.dart`

> 이 위젯은 dev 갤러리 외부에서도 재사용 가능 (Phase C-E 후 Suggestion 화면에서 후보 카드 미리보기로 활용 잠재). 그러나 v1 에서는 `/dev` 한 곳만 호출 — YAGNI 따라 features/dev/ 하위에 둠. 이전될 시 cores/widgets/ 로 승격.

### Step 1-1: 실패 widget test 작성

Create `test/features/dev/widgets/grid_template_preview_test.dart`:
```dart
// test/features/dev/widgets/grid_template_preview_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/dev/widgets/grid_template_preview.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  group('GridTemplatePreview', () {
    // 테스트 fixture — N=4 의 1+3 비대칭 패턴 (의미 있는 다중 셀)
    final fixtureTemplate = NamedTemplate(
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
    );

    testWidgets('템플릿 이름 라벨이 표시된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        GridTemplatePreview(
          template: fixtureTemplate,
          canvas: const CanvasRatio.portrait916(),
        ),
      );

      expect(find.text('n4_left1_right3'), findsOneWidget);
    });

    testWidgets('각 cellId 번호가 정확히 한 번씩 표시된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        GridTemplatePreview(
          template: fixtureTemplate,
          canvas: const CanvasRatio.square(),
        ),
      );

      // cellId 4개 (0, 1, 2, 3) 모두 정확히 한 번씩 렌더
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('AspectRatio 가 canvas.value 와 일치한다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        GridTemplatePreview(
          template: fixtureTemplate,
          canvas: const CanvasRatio.portrait916(),
        ),
      );

      // 위젯 트리에서 GridTemplatePreview 가 직접 만든 AspectRatio 를 찾음
      // (테스트 헬퍼의 Center/Scaffold 등 외부 AspectRatio 는 없음)
      final aspectRatio = tester.widget<AspectRatio>(
        find.descendant(
          of: find.byType(GridTemplatePreview),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(aspectRatio.aspectRatio, closeTo(9 / 16, 1e-9));
    });

    testWidgets('canvas 변경 시 AspectRatio 갱신된다', (tester) async {
      // 첫 빌드: 9:16
      await pumpWithScreenUtil(
        tester,
        GridTemplatePreview(
          template: fixtureTemplate,
          canvas: const CanvasRatio.portrait916(),
        ),
      );
      var aspect = tester.widget<AspectRatio>(
        find.descendant(
          of: find.byType(GridTemplatePreview),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(aspect.aspectRatio, closeTo(9 / 16, 1e-9));

      // 다시 빌드: 16:9
      await pumpWithScreenUtil(
        tester,
        GridTemplatePreview(
          template: fixtureTemplate,
          canvas: const CanvasRatio.landscape169(),
        ),
      );
      aspect = tester.widget<AspectRatio>(
        find.descendant(
          of: find.byType(GridTemplatePreview),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(aspect.aspectRatio, closeTo(16 / 9, 1e-9));
    });

    testWidgets('단일 Leaf 트리도 안전 (N=1 edge — 미사용이지만 위젯 robust 검증)', (tester) async {
      final singleLeaf = NamedTemplate(
        name: 'n1_solo',
        tree: const Leaf(0),
        cellIds: const [0],
      );
      await pumpWithScreenUtil(
        tester,
        GridTemplatePreview(
          template: singleLeaf,
          canvas: const CanvasRatio.square(),
        ),
      );

      expect(find.text('n1_solo'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });
}
```

### Step 1-2: 실패 확인

Run: `flutter test test/features/dev/widgets/grid_template_preview_test.dart`
Expected: 컴파일 실패 (`GridTemplatePreview` not defined).

### Step 1-3: `GridTemplatePreview` 구현

Create `lib/features/dev/widgets/grid_template_preview.dart`:
```dart
// lib/features/dev/widgets/grid_template_preview.dart
import 'package:flutter/material.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';
import '../../../cores/grid_suggestor/grid_suggestor.dart';

/// 큐레이션 템플릿 시각 미리보기 카드 (`/dev` 갤러리용).
///
/// 알고리즘 모듈의 [cellBBoxes] 를 재사용해 BSP 트리를 정규화 좌표(0..1)로 풀고,
/// [AspectRatio] 컨테이너 안의 [Stack] + [Positioned.fromRect] 로 셀들을 그린다.
/// 캔버스 비율 변경 시 AspectRatio 가 갱신되어 셀 종횡비가 즉시 반영.
///
/// 디자인: `AppColors.lightCream` 셀 테두리 + 옅은 셀 배경(`AppColors.charcoal04`),
/// cellId 번호는 `AppTextStyles.caption_16` 로 셀 좌상단 작게.
class GridTemplatePreview extends StatelessWidget {
  const GridTemplatePreview({
    super.key,
    required this.template,
    required this.canvas,
  });

  final NamedTemplate template;
  final CanvasRatio canvas;

  @override
  Widget build(BuildContext context) {
    final bboxes = cellBBoxes(template.tree);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 템플릿 이름 라벨
        Text(
          template.name,
          style: AppTextStyles.caption_16.copyWith(color: AppColors.charcoal82),
        ),
        SizedBox(height: AppSpacing.xs),
        // BSP 시각화 — 정규화 좌표를 LayoutBuilder constraints 로 픽셀 변환
        AspectRatio(
          aspectRatio: canvas.value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.charcoal40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    children: [
                      for (final entry in bboxes.entries)
                        Positioned.fromRect(
                          rect: Rect.fromLTWH(
                            entry.value.left * w,
                            entry.value.top * h,
                            entry.value.width * w,
                            entry.value.height * h,
                          ),
                          child: _CellTile(cellId: entry.key),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 단일 셀 시각화 — 옅은 배경 + 테두리 + cellId 좌상단.
class _CellTile extends StatelessWidget {
  const _CellTile({required this.cellId});
  final int cellId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal04,
        border: Border.all(color: AppColors.lightCream),
      ),
      padding: EdgeInsets.all(AppSpacing.xs),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          '$cellId',
          style: AppTextStyles.caption_16.copyWith(color: AppColors.charcoal),
        ),
      ),
    );
  }
}
```

### Step 1-4: 테스트 통과 확인

Run: `flutter test test/features/dev/widgets/grid_template_preview_test.dart`
Expected: 5 tests PASS.

### Step 1-5: 분석기 통과

Run: `flutter analyze lib/features/dev/ test/features/dev/`
Expected: `No issues found!`.

### Step 1-6: Commit

```bash
git add lib/features/dev/widgets/grid_template_preview.dart \
        test/features/dev/widgets/grid_template_preview_test.dart
git commit -m "feat : GridTemplatePreview 위젯 — BSP→Stack/Positioned 시각화 (#1)"
```

---

## Task 2: `_GridTemplatesSection` 추가 + dev_gallery_page 통합

**Files:**
- Modify: `lib/features/dev/dev_gallery_page.dart` (private `_GridTemplatesSection` 추가, scroll Column 에 위치)
- Modify: `test/features/dev/dev_gallery_page_test.dart` (섹션 sweep test 보강)

> Task 2 는 캔버스 비율을 `CanvasRatio.portrait916()` 으로 hardcode 한 `StatelessWidget` 으로 시작 — Task 3 에서 토글 가능한 `StatefulWidget` 으로 교체. incremental TDD 흐름 유지 (먼저 sweep 동작, 다음 토글 동작).

### Step 2-1: 회귀 + 신규 sweep test 작성 (실패)

Modify `test/features/dev/dev_gallery_page_test.dart` — 기존 `4개 GallerySection` 테스트를 `5개 GallerySection` 으로 업데이트하고 Grid Templates 전용 검증 test 추가:

기존 테스트 (lines 20-34):
```dart
testWidgets('4개 GallerySection 의 제목이 모두 렌더링된다', (tester) async {
  await pumpPage(tester, const DevGalleryPage());

  expect(find.text('AppButton'), findsOneWidget);
  await tester.scrollUntilVisible(
    find.text('Typography (AppTextStyles)'),
    300,
  );

  expect(find.text('AppIconButton'), findsOneWidget);
  expect(find.text('Colors (AppColors)'), findsOneWidget);
  expect(find.text('Typography (AppTextStyles)'), findsOneWidget);
});
```

위 테스트의 `4개` → `5개` 로 변경 + Grid Templates 추가:
```dart
testWidgets('5개 GallerySection 의 제목이 모두 렌더링된다', (tester) async {
  await pumpPage(tester, const DevGalleryPage());

  expect(find.text('AppButton'), findsOneWidget);
  // 마지막 섹션까지 스크롤하여 lazy build 강제
  await tester.scrollUntilVisible(
    find.text('Grid Templates'),
    300,
  );

  expect(find.text('AppIconButton'), findsOneWidget);
  expect(find.text('Colors (AppColors)'), findsOneWidget);
  expect(find.text('Typography (AppTextStyles)'), findsOneWidget);
  expect(find.text('Grid Templates'), findsOneWidget);
});
```

기존 테스트 file 의 import 들 그대로 두고, 추가로 Grid Templates 전용 widget test 를 새 group 으로 append:

```dart
// (위의 기존 group('DevGalleryPage', ...) 닫힘 뒤에 추가)

group('Grid Templates 섹션', () {
  testWidgets('N=2..9 의 모든 템플릿(31개)이 카드로 렌더된다', (tester) async {
    await pumpPage(tester, const DevGalleryPage());

    // 마지막 섹션까지 스크롤하여 lazy build 강제
    await tester.scrollUntilVisible(
      find.text('Grid Templates'),
      300,
    );

    // GridTemplatePreview 인스턴스가 31개 (kGridTemplates 합계) — 합계 검증으로 sweep 보장
    expect(find.byType(GridTemplatePreview), findsNWidgets(31));
  });

  testWidgets('각 N 의 첫 템플릿 이름이 화면에 노출된다 (sweep sanity)', (tester) async {
    await pumpPage(tester, const DevGalleryPage());

    await tester.scrollUntilVisible(
      find.text('Grid Templates'),
      300,
    );

    // N=2..9 의 대표 템플릿 이름들 (Phase B 큐레이션 첫 entry) — 모두 트리에 존재
    // 화면 밖이어도 widget tree 에는 build 됨 (SingleChildScrollView 라 lazy 아님).
    expect(find.text('n2_v_half'), findsOneWidget);
    expect(find.text('n3_v_thirds'), findsOneWidget);
    expect(find.text('n4_grid2x2'), findsOneWidget);
    expect(find.text('n5_left1_right4_2x2'), findsOneWidget);
    expect(find.text('n6_grid2x3'), findsOneWidget);
    expect(find.text('n7_left1_right6_2x3'), findsOneWidget);
    expect(find.text('n8_grid4x2'), findsOneWidget);
    expect(find.text('n9_grid3x3'), findsOneWidget);
  });
});
```

> **note (Task 1 fixture 와의 차이)**: Task 1 widget test 는 자체 fixture `n4_left1_right3` 를 만들어 격리 검증. Task 2 sweep test 는 실제 `kGridTemplates` 카탈로그를 사용 — 카탈로그 누락 회귀까지 잡힘.

> 검증 가능한 첫 entry 이름이 변경될 위험: `n2_v_half` 등 — `_n2_templates.dart` 의 `n2Templates[0].name` 과 일치해야 한다. 기존 Phase A 큐레이션 (`_n2_templates.dart`) 의 첫 항목 이름을 확인 후 수정.

추가 import 가 필요하면 (e.g., `GridTemplatePreview`):
```dart
import 'package:gridset/features/dev/widgets/grid_template_preview.dart';
```

### Step 2-2: 실패 확인

Run: `flutter test test/features/dev/dev_gallery_page_test.dart`
Expected: 새 group 의 모든 test 실패 (`Grid Templates` 텍스트 없음, `GridTemplatePreview` 인스턴스 0개), `5개 GallerySection` test 도 실패.

### Step 2-3: `_GridTemplatesSection` 구현 (StatelessWidget, canvas hardcoded)

Modify `lib/features/dev/dev_gallery_page.dart`:

먼저 import 영역에 추가:
```dart
import '../../cores/grid_suggestor/grid_suggestor.dart';
import 'widgets/grid_template_preview.dart';
```

`SingleChildScrollView` → `Column` 의 children 에 마지막 섹션으로 추가 (`_TypographySection` 뒤):
```dart
// (기존 _TypographySection 뒤)
SizedBox(height: AppSpacing.xl),
const _GridTemplatesSection(),
```

파일 하단 `_ItemLabel` 정의 위에 새 private class 추가 (Task 2 단계: stateless, canvas hardcoded):
```dart
// ---------------------------------------------------------------------------
// Grid Templates 섹션 (Phase C)
// ---------------------------------------------------------------------------

/// `kGridTemplates` 의 N=2..9 모든 큐레이션을 카드 sweep 으로 노출.
///
/// Task 2 단계: 캔버스 비율 hardcoded `portrait916`.
/// Task 3 에서 StatefulWidget 화 + 4 preset 토글 추가.
class _GridTemplatesSection extends StatelessWidget {
  const _GridTemplatesSection();

  // dev/dev_gallery 표시 비율 — Task 3 에서 setState 로 변경 가능.
  static const _canvas = CanvasRatio.portrait916();

  @override
  Widget build(BuildContext context) {
    final ns = kGridTemplates.keys.toList()..sort();
    return GallerySection(
      title: 'Grid Templates',
      children: [
        for (final n in ns) ...[
          _ItemLabel('N = $n (${kGridTemplates[n]!.length}개)'),
          // 한 줄에 카드들을 Wrap — 좁은 화면도 자동 줄바꿈
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final t in kGridTemplates[n]!)
                SizedBox(
                  // 한 카드당 폭 — 화면 폭의 약 1/3 가정
                  width: 120.w,
                  child: GridTemplatePreview(
                    template: t,
                    canvas: _canvas,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
```

> **Note**: `_ItemLabel` 은 이미 동일 파일에 존재 (line 248), 그대로 재사용. 새 import 추가 없음 (`AppColors` 등 page 가 이미 import 중).
>
> `120.w` 는 `flutter_screenutil` 의 design viewport(393×852) 기준. 1 행 카드 약 3개 + spacing → 393w 안에 자연 수렴.

### Step 2-4: 테스트 통과 확인

Run: `flutter test test/features/dev/dev_gallery_page_test.dart`
Expected: 모든 test PASS — `5개 GallerySection`, `Grid Templates 섹션 N=2..9 sweep (31)`, 각 N 의 첫 템플릿 이름 노출.

### Step 2-5: 회귀 — 전체 dev 영역 + grid_suggestor 영역

Run:
```bash
flutter test test/features/dev/ test/cores/grid_suggestor/
flutter analyze lib/features/dev/ test/features/dev/
```
Expected: 전부 PASS + analyze clean.

### Step 2-6: Commit

```bash
git add lib/features/dev/dev_gallery_page.dart \
        test/features/dev/dev_gallery_page_test.dart
git commit -m "feat : /dev 갤러리에 Grid Templates 섹션 추가 — N=2..9 sweep (#1)"
```

---

## Task 3: 캔버스 비율 토글 (StatefulWidget 화, 4 preset)

**Files:**
- Modify: `lib/features/dev/dev_gallery_page.dart` (`_GridTemplatesSection` → StatefulWidget, 4 preset chip + setState)
- Modify: `test/features/dev/dev_gallery_page_test.dart` (토글 interaction test 추가)

> 4 preset 만: `9:16` / `1:1` / `4:5` / `16:9`. `custom` 은 v1 갤러리 제외 (사용자 입력 받기 어렵고, 큐레이션 검토 본질이 아님). 디자이너가 custom 비율도 보고 싶으면 별도 hot-reload 로 코드 수정.

### Step 3-1: 토글 interaction test 작성 (실패)

`test/features/dev/dev_gallery_page_test.dart` 의 `Grid Templates 섹션` group 내 새 test 추가:
```dart
testWidgets('비율 토글: 9:16 → 1:1 → 4:5 → 16:9 탭 시 모든 카드의 AspectRatio 가 갱신된다', (tester) async {
  await pumpPage(tester, const DevGalleryPage());
  await tester.scrollUntilVisible(find.text('Grid Templates'), 300);

  // 초기 상태: 9:16 (Task 2 hardcoded 였던 디폴트)
  // GridTemplatePreview 안의 첫 AspectRatio 는 9/16 ≈ 0.5625
  AspectRatio firstAspect() => tester.firstWidget<AspectRatio>(
    find.descendant(
      of: find.byType(GridTemplatePreview).first,
      matching: find.byType(AspectRatio),
    ),
  );
  expect(firstAspect().aspectRatio, closeTo(9 / 16, 1e-9));

  // 1:1 chip 탭
  await tester.tap(find.text('1:1'));
  await tester.pumpAndSettle();
  expect(firstAspect().aspectRatio, closeTo(1.0, 1e-9));

  // 4:5 chip 탭
  await tester.tap(find.text('4:5'));
  await tester.pumpAndSettle();
  expect(firstAspect().aspectRatio, closeTo(4 / 5, 1e-9));

  // 16:9 chip 탭
  await tester.tap(find.text('16:9'));
  await tester.pumpAndSettle();
  expect(firstAspect().aspectRatio, closeTo(16 / 9, 1e-9));
});

testWidgets('비율 chip 4개 모두 노출된다 (9:16 / 1:1 / 4:5 / 16:9)', (tester) async {
  await pumpPage(tester, const DevGalleryPage());
  await tester.scrollUntilVisible(find.text('Grid Templates'), 300);

  expect(find.text('9:16'), findsOneWidget);
  expect(find.text('1:1'), findsOneWidget);
  expect(find.text('4:5'), findsOneWidget);
  expect(find.text('16:9'), findsOneWidget);
});
```

### Step 3-2: 실패 확인

Run: `flutter test test/features/dev/dev_gallery_page_test.dart`
Expected: 신규 2 test 실패 (chip text 없음, `firstAspect()` 변경 안됨).

### Step 3-3: `_GridTemplatesSection` 을 StatefulWidget 으로 변경

Modify `lib/features/dev/dev_gallery_page.dart` — Task 2 에서 만든 `_GridTemplatesSection` 전체를 아래로 교체:

```dart
// ---------------------------------------------------------------------------
// Grid Templates 섹션 (Phase C)
// ---------------------------------------------------------------------------

/// `kGridTemplates` 의 N=2..9 모든 큐레이션을 카드 sweep 으로 노출.
///
/// 캔버스 비율 토글 (4 preset) — 탭 시 setState 로 모든 카드 동시 리렌더.
/// `custom` 은 v1 갤러리 제외 (사용자 입력 부담 + 큐레이션 검토 본질 아님).
class _GridTemplatesSection extends StatefulWidget {
  const _GridTemplatesSection();

  @override
  State<_GridTemplatesSection> createState() => _GridTemplatesSectionState();
}

class _GridTemplatesSectionState extends State<_GridTemplatesSection> {
  // 토글 옵션 — 라벨 + CanvasRatio 인스턴스
  static const _options = <(String, CanvasRatio)>[
    ('9:16', CanvasRatio.portrait916()),
    ('1:1', CanvasRatio.square()),
    ('4:5', CanvasRatio.portrait45()),
    ('16:9', CanvasRatio.landscape169()),
  ];

  CanvasRatio _canvas = const CanvasRatio.portrait916();

  @override
  Widget build(BuildContext context) {
    final ns = kGridTemplates.keys.toList()..sort();
    return GallerySection(
      title: 'Grid Templates',
      children: [
        // 비율 토글 chip Wrap — 한 줄에 4개 (좁은 화면 자동 줄바꿈)
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in _options)
              _RatioChip(
                label: option.$1,
                selected: _canvas == option.$2,
                onTap: () => setState(() => _canvas = option.$2),
              ),
          ],
        ),
        for (final n in ns) ...[
          _ItemLabel('N = $n (${kGridTemplates[n]!.length}개)'),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final t in kGridTemplates[n]!)
                SizedBox(
                  width: 120.w,
                  child: GridTemplatePreview(
                    template: t,
                    canvas: _canvas,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 비율 선택 chip — selected 면 charcoal 배경 + offWhite 텍스트, 아니면 outline.
///
/// 디자인 시스템 (Lovable cream/charcoal) 의 inset 그림자 패턴 단순화 — chip 사이즈
/// 라 6px radius + 1px border 만으로 충분.
class _RatioChip extends StatelessWidget {
  const _RatioChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.charcoal : AppColors.cream,
          border: Border.all(color: AppColors.charcoal40),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.button_16.copyWith(
            color: selected ? AppColors.offWhite : AppColors.charcoal,
          ),
        ),
      ),
    );
  }
}
```

### Step 3-4: 테스트 통과 확인

Run: `flutter test test/features/dev/dev_gallery_page_test.dart`
Expected: 모든 test PASS (5 섹션 / 31 카드 sweep / 첫 템플릿 이름 / 4 chip 노출 / 토글 interaction).

### Step 3-5: 전체 회귀 + analyze

Run:
```bash
flutter test
flutter analyze lib/ test/
```
Expected: 전체 PASS, analyze clean.

> 만약 다른 features 의 widget test 가 viewport/render 차이로 흔들리면 STOP — 레이아웃 회귀일 수 있음. `_GridTemplatesSection` 의 `Wrap` / `120.w` 가 dev 갤러리 외부에 영향 줄 가능성 거의 없지만 검증 후 진행.

### Step 3-6: Commit

```bash
git add lib/features/dev/dev_gallery_page.dart \
        test/features/dev/dev_gallery_page_test.dart
git commit -m "feat : Grid Templates 섹션 캔버스 비율 토글 (4 preset) (#1)"
```

---

## Phase C 완료 체크리스트 (DoD)

- [ ] `flutter analyze lib/features/dev/ test/features/dev/` → `No issues found!`
- [ ] `flutter test test/features/dev/` 전체 PASS (기존 4 + 신규 ~6 ≈ 10+ tests)
- [ ] `flutter test` 전체 회귀 PASS (Phase B 의 72 + Phase C 신규)
- [ ] `/dev` 갤러리 5개 섹션 — 마지막 "Grid Templates" 섹션 노출 확인
- [ ] 31 `GridTemplatePreview` 카드 sweep (kGridTemplates 합계 일치)
- [ ] 4 preset 토글 (`9:16` / `1:1` / `4:5` / `16:9`) — 탭 시 모든 카드 즉시 리렌더
- [ ] 색상/텍스트/간격 raw 값 0건 (`AppColors`/`AppTextStyles`/`AppSpacing` 만)
- [ ] 커밋 3개 (Task 1~3, 모두 `(#1)` 태그, Co-Authored-By 부재)

---

## 다음 단계 안내 (Phase D-E 미리보기)

| Phase | 책임 | 주요 task |
| --- | --- | --- |
| **D** — 시각 iterate | `/dev` 갤러리에서 ugly 발견 → 해당 N 의 templates 교체 (Phase C 끝나야 가능, 1 task 반복) | 핫리로드 시각 검토 → templates 코드 수정 → fingerprint dedup 안전망 통과 확인 |
| **E** — 마감 | golden 테스트 N=2..9 + perf < 300ms (N=9 매핑) + 커버리지 95% 검증 | golden 생성 / perf benchmark / coverage report / 통합 시나리오 |

Phase E 머지 후 Suggestion 화면 spec 사이클 시작 (PRD §F00, §9-2-1~3 호출부).
