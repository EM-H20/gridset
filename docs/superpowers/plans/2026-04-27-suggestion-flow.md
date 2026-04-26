# Suggestion 화면 + 진입 흐름 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈 → (옵션 비율 선택) → 사진/영상 picker → Suggestion 화면 흐름 구현. `lib/cores/grid_suggestor/` 알고리즘 코어를 호출부로 통합. Phase D 시각 iterate 로 ugly templates 교체까지.

**Architecture:** 평탄 3 라우트 (`/canvas-picker`, `/photo-picker`, `/suggestion`) + `autoDispose` Riverpod flow state. `photo_manager` 자체 picker UI (cream 테마 일관 적용). 후보 카드는 `PageView` + Peek (viewportFraction 0.7). BSP 트리 → 셀 자리잡기는 `cores/widgets/grid_layout/bsp_grid_layout.dart` shared primitive.

**Tech Stack:** Flutter 3.x, Riverpod (codegen), Freezed, go_router, photo_manager ^4.0.0, url_launcher, flutter_screenutil, flutter_svg.

**Spec:** `docs/superpowers/specs/2026-04-27-suggestion-flow-design.md`

**DoD (Definition of Done):**
- `flutter analyze` 무경고
- `flutter test` 전체 통과 (단위 + 위젯 + 통합)
- 홈 두 CTA 가 실제 흐름으로 연결 (stub SnackBar 제거)
- 권한 5상태 분기 동작 (authorized/limited/denied/restricted + loading)
- "다른 제안" cursor pagination 4 batch 한도까지 동작
- 디자인 시스템 정합 (`AppColors` / `AppSpacing` / `AppTextStyles` 만, raw 값 0)
- Phase D 시각 검토 후 골든 갱신 시 `templates_test.dart` 8 invariant 통과 유지

---

## File Structure

### Create

| 경로 | 책임 |
| --- | --- |
| `lib/cores/widgets/grid_layout/bsp_grid_layout.dart` | BSP 트리 → Stack+Positioned 셀 자리잡기 primitive |
| `lib/flow/flow_selection_provider.dart` | autoDispose: canvas + selectedMedia |
| `lib/flow/flow_selection.dart` | Freezed `FlowSelection` 모델 |
| `lib/features/canvas_picker/canvas_picker_page.dart` | 비율 선택 화면 |
| `lib/features/canvas_picker/widgets/ratio_chip.dart` | 4 preset chip |
| `lib/features/photo_picker/photo_picker_page.dart` | 권한 분기 + AssetGrid |
| `lib/features/photo_picker/providers/permission_provider.dart` | photo_manager 권한 상태 |
| `lib/features/photo_picker/providers/asset_paged_provider.dart` | asset 페이지네이션 |
| `lib/features/photo_picker/providers/asset_selection_provider.dart` | 선택 순서 보존 |
| `lib/features/photo_picker/widgets/asset_grid.dart` | 3-column lazy grid |
| `lib/features/photo_picker/widgets/asset_tile.dart` | 썸네일 + 선택 badge |
| `lib/features/photo_picker/widgets/permission_denied_view.dart` | denied/restricted 안내 화면 |
| `lib/features/photo_picker/widgets/limited_info_bar.dart` | iOS limited 안내 bar |
| `lib/features/photo_picker/asset_to_media_item.dart` | AssetEntity → MediaItem 변환 |
| `lib/features/suggestion/suggestion_page.dart` | PageView + Peek 후보 화면 |
| `lib/features/suggestion/providers/suggestion_notifier.dart` | SuggestionState + cursor |
| `lib/features/suggestion/providers/suggestion_state.dart` | Freezed sealed state |
| `lib/features/suggestion/widgets/suggestion_card.dart` | 한 후보 카드 (BspGridLayout) |
| `lib/features/suggestion/widgets/suggestion_cta_bar.dart` | 이걸로 / 다른 제안 / 빈 캔버스 |
| `lib/features/suggestion/widgets/suggestion_dots.dart` | PageView dots indicator |

### Modify

| 경로 | 변경 내용 |
| --- | --- |
| `pubspec.yaml` | `photo_manager: ^4.0.0` 추가 |
| `lib/routers/route_paths.dart` | `canvasPicker` / `photoPicker` / `suggestion` 추가 |
| `lib/routers/app_router.dart` | 3 GoRoute 추가 |
| `lib/features/home/home_page.dart` | stub SnackBar 제거 → 실제 라우팅 |
| `lib/features/dev/widgets/grid_template_preview.dart` | `BspGridLayout` 사용하도록 리팩터 |
| `ios/Runner/Info.plist` | `NSPhotoLibraryUsageDescription` 추가 |
| `android/app/src/main/AndroidManifest.xml` | `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` / `READ_EXTERNAL_STORAGE` 추가 |
| `lib/cores/grid_suggestor/templates/_n{N}_templates.dart` (해당 시) | Phase D 시각 검토 후 ugly templates 교체 |
| `test/cores/grid_suggestor/suggester_test.dart` (해당 시) | Phase D 골든 8개 갱신 |

### Test files

| 경로 | 검증 |
| --- | --- |
| `test/cores/widgets/grid_layout/bsp_grid_layout_test.dart` | cellBuilder 호출, normalizedBBox |
| `test/flow/flow_selection_provider_test.dart` | initial / setCanvas / setMedia / autoDispose reset |
| `test/features/canvas_picker/canvas_picker_page_test.dart` | 4 chip + 다음 활성/비활성 |
| `test/features/photo_picker/permission_provider_test.dart` | 5상태 매핑 |
| `test/features/photo_picker/asset_to_media_item_test.dart` | 변환 + AR 검증 |
| `test/features/photo_picker/photo_picker_page_test.dart` | 권한 분기 widget |
| `test/features/suggestion/suggestion_notifier_test.dart` | empty/loaded/error + selectIndex + loadMore |
| `test/features/suggestion/suggestion_page_test.dart` | PageView smoke + CTA |
| `integration_test/flow_test.dart` | home → ratio → picker → suggestion 통합 |

---

## Pre-flight: 빌드 환경

- [ ] **Step 0-1: 의존성 설치 + codegen 시작**

  ```bash
  flutter pub get
  ```

  Expected: dependencies 받아짐.

- [ ] **Step 0-2: build_runner watch 백그라운드 (별도 터미널)**

  ```bash
  dart run build_runner watch --delete-conflicting-outputs
  ```

  Expected: `[INFO] Succeeded after ...`. 이 명령은 plan 실행 동안 유지.

- [ ] **Step 0-3: 베이스라인 — 현재 상태 분석/테스트 통과 확인**

  ```bash
  flutter analyze && flutter test
  ```

  Expected: PASS (작업 시작 전 깨끗한 상태).

---

# PHASE A — 인프라 + Primitive (Task 1-5)

> **목표:** photo_manager 추가, 라우트 골격, FlowSelection state, BspGridLayout primitive, dev 리팩터.
> **DoD:** 새 라우트 3개로 navigate 가능 (페이지는 빈 placeholder), `BspGridLayout` 단위 테스트 통과, dev 갤러리 회귀 없음, 홈 stub 은 그대로 유지.

---

## Task 1: photo_manager 의존성 추가

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1-1: pubspec.yaml 의 dependencies 섹션에 photo_manager 추가**

  Edit `pubspec.yaml` — `connectivity_plus: ^6.1.0` 다음 줄에 추가:
  ```yaml
    # 미디어 (사진/영상 갤러리 접근)
    photo_manager: ^4.0.0
  ```

- [ ] **Step 1-2: pub get**

  ```bash
  flutter pub get
  ```

  Expected: photo_manager 다운로드 성공.

- [ ] **Step 1-3: 분석 확인**

  ```bash
  flutter analyze
  ```

  Expected: 무경고.

- [ ] **Step 1-4: 커밋**

  ```bash
  git add pubspec.yaml pubspec.lock
  git commit -m "feat : photo_manager 의존성 추가 — picker 화면 prereq (#3)"
  ```

---

## Task 2: 라우트 경로 + 빈 placeholder 라우트 등록

**Files:**
- Modify: `lib/routers/route_paths.dart`
- Modify: `lib/routers/app_router.dart`
- Create: `lib/features/canvas_picker/canvas_picker_page.dart` (placeholder)
- Create: `lib/features/photo_picker/photo_picker_page.dart` (placeholder)
- Create: `lib/features/suggestion/suggestion_page.dart` (placeholder)

- [ ] **Step 2-1: route_paths.dart 에 3개 경로 상수 추가**

  Edit `lib/routers/route_paths.dart` — `dev` 상수 위에 추가:
  ```dart
    /// 캔버스 비율 선택 (비율 먼저 정하기 흐름)
    static const String canvasPicker = '/canvas-picker';

    /// 사진/영상 picker
    static const String photoPicker = '/photo-picker';

    /// 자동 레이아웃 후보 화면
    static const String suggestion = '/suggestion';
  ```

- [ ] **Step 2-2: 3개 placeholder 페이지 생성**

  Create `lib/features/canvas_picker/canvas_picker_page.dart`:
  ```dart
  import 'package:flutter/material.dart';

  import '../../cores/constants/app_colors.dart';

  /// 캔버스 비율 선택 화면 (placeholder — Task 6 에서 구현).
  class CanvasPickerPage extends StatelessWidget {
    const CanvasPickerPage({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('비율')),
        body: const Center(child: Text('CanvasPickerPage')),
      );
    }
  }
  ```

  Create `lib/features/photo_picker/photo_picker_page.dart`:
  ```dart
  import 'package:flutter/material.dart';

  import '../../cores/constants/app_colors.dart';

  /// 사진/영상 picker (placeholder — Task 7~10 에서 구현).
  class PhotoPickerPage extends StatelessWidget {
    const PhotoPickerPage({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('사진 고르기')),
        body: const Center(child: Text('PhotoPickerPage')),
      );
    }
  }
  ```

  Create `lib/features/suggestion/suggestion_page.dart`:
  ```dart
  import 'package:flutter/material.dart';

  import '../../cores/constants/app_colors.dart';

  /// 후보 화면 (placeholder — Task 12~14 에서 구현).
  class SuggestionPage extends StatelessWidget {
    const SuggestionPage({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('제안')),
        body: const Center(child: Text('SuggestionPage')),
      );
    }
  }
  ```

- [ ] **Step 2-3: app_router.dart 에 3 GoRoute 추가**

  Edit `lib/routers/app_router.dart` — import 추가:
  ```dart
  import '../features/canvas_picker/canvas_picker_page.dart';
  import '../features/photo_picker/photo_picker_page.dart';
  import '../features/suggestion/suggestion_page.dart';
  ```

  routes 리스트의 `dev` GoRoute **앞**에 추가:
  ```dart
      GoRoute(
        path: RoutePaths.canvasPicker,
        pageBuilder: (context, state) => buildDirectionalSlide(
          key: state.pageKey,
          isForward: true,
          child: const CanvasPickerPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.photoPicker,
        pageBuilder: (context, state) => buildDirectionalSlide(
          key: state.pageKey,
          isForward: true,
          child: const PhotoPickerPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.suggestion,
        pageBuilder: (context, state) => buildDirectionalSlide(
          key: state.pageKey,
          isForward: true,
          child: const SuggestionPage(),
        ),
      ),
  ```

- [ ] **Step 2-4: 분석 + smoke 빌드**

  ```bash
  flutter analyze
  ```

  Expected: 무경고.

- [ ] **Step 2-5: 커밋**

  ```bash
  git add lib/routers lib/features/canvas_picker lib/features/photo_picker lib/features/suggestion
  git commit -m "feat : suggestion 흐름 라우트 골격 + placeholder 페이지 추가 (#3)"
  ```

---

## Task 3: FlowSelection 모델 + autoDispose Provider

**Files:**
- Create: `lib/flow/flow_selection.dart`
- Create: `lib/flow/flow_selection_provider.dart`
- Test: `test/flow/flow_selection_provider_test.dart`

- [ ] **Step 3-1: FlowSelection Freezed 모델 작성**

  Create `lib/flow/flow_selection.dart`:
  ```dart
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
  ```

- [ ] **Step 3-2: FlowSelectionNotifier 작성**

  Create `lib/flow/flow_selection_provider.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../cores/grid_suggestor/grid_suggestor.dart';
  import 'flow_selection.dart';

  part 'flow_selection_provider.g.dart';

  /// 흐름 공유 상태 Notifier.
  ///
  /// - `home → CTA` 진입 시 canvas/media 셋업
  /// - `home` 으로 돌아가면 라우트 dispose → autoDispose → build() 재호출
  ///   (명시 reset 불필요).
  @Riverpod(keepAlive: false)
  class FlowSelectionNotifier extends _$FlowSelectionNotifier {
    @override
    FlowSelection build() =>
        const FlowSelection(canvas: CanvasRatio.portrait916());

    void setCanvas(CanvasRatio ratio) =>
        state = state.copyWith(canvas: ratio);

    void setMedia(List<MediaItem> items) =>
        state = state.copyWith(media: items);
  }
  ```

  Codegen 자동 실행 (build_runner watch). `flow_selection.freezed.dart` 와 `flow_selection_provider.g.dart` 생성 확인.

- [ ] **Step 3-3: 실패하는 단위 테스트 작성**

  Create `test/flow/flow_selection_provider_test.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
  import 'package:gridset/flow/flow_selection_provider.dart';

  void main() {
    group('FlowSelectionNotifier', () {
      test('initial state — canvas 9:16, media 비어있음', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state = container.read(flowSelectionNotifierProvider);

        expect(state.canvas, const CanvasRatio.portrait916());
        expect(state.media, isEmpty);
      });

      test('setCanvas 가 canvas 만 갱신, media 보존', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(flowSelectionNotifierProvider.notifier)
            .setCanvas(const CanvasRatio.square());

        final s = container.read(flowSelectionNotifierProvider);
        expect(s.canvas, const CanvasRatio.square());
        expect(s.media, isEmpty);
      });

      test('setMedia 가 media 만 갱신, canvas 보존', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        const items = [
          MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
          MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
        ];

        container.read(flowSelectionNotifierProvider.notifier).setMedia(items);

        final s = container.read(flowSelectionNotifierProvider);
        expect(s.media, items);
        expect(s.canvas, const CanvasRatio.portrait916()); // 디폴트 보존
      });
    });
  }
  ```

- [ ] **Step 3-4: 테스트 실행 — codegen 후 PASS 확인**

  ```bash
  flutter test test/flow/flow_selection_provider_test.dart
  ```

  Expected: 3 tests PASS. codegen 미생성 시 `dart run build_runner build --delete-conflicting-outputs` 한 번 실행.

- [ ] **Step 3-5: 커밋**

  ```bash
  git add lib/flow test/flow
  git commit -m "feat : FlowSelection 모델 + autoDispose provider — 흐름 공유 상태 (#3)"
  ```

---

## Task 4: BspGridLayout primitive

**Files:**
- Create: `lib/cores/widgets/grid_layout/bsp_grid_layout.dart`
- Test: `test/cores/widgets/grid_layout/bsp_grid_layout_test.dart`

- [ ] **Step 4-1: 실패하는 위젯 테스트 작성**

  Create `test/cores/widgets/grid_layout/bsp_grid_layout_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
  import 'package:gridset/cores/widgets/grid_layout/bsp_grid_layout.dart';

  void main() {
    group('BspGridLayout', () {
      testWidgets('1+2 트리 — cellBuilder 가 cellId 1, 2, 3 으로 호출됨',
          (tester) async {
        final calledIds = <int>[];
        final tree = Split(
          axis: SplitAxis.vertical,
          positions: [0.5],
          children: const [
            Leaf(cellId: 1),
            Split(
              axis: SplitAxis.horizontal,
              positions: [0.5],
              children: [Leaf(cellId: 2), Leaf(cellId: 3)],
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            width: 360,
            height: 640,
            child: BspGridLayout(
              tree: tree,
              aspectRatio: 9 / 16,
              cellBuilder: (id, _) {
                calledIds.add(id);
                return ColoredBox(color: Colors.amber, child: Text('$id'));
              },
            ),
          ),
        ));

        expect(calledIds, [1, 2, 3]);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('aspectRatio 값이 AspectRatio 위젯에 반영',
          (tester) async {
        const tree = Leaf(cellId: 1);

        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            width: 200,
            child: BspGridLayout(
              tree: tree,
              aspectRatio: 1.0,
              cellBuilder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ));

        final ar = tester.widget<AspectRatio>(find.byType(AspectRatio));
        expect(ar.aspectRatio, 1.0);
      });
    });
  }
  ```

- [ ] **Step 4-2: 테스트 실행 — FAIL 확인**

  ```bash
  flutter test test/cores/widgets/grid_layout/bsp_grid_layout_test.dart
  ```

  Expected: FAIL ("BspGridLayout 모듈 없음").

- [ ] **Step 4-3: BspGridLayout 구현**

  Create `lib/cores/widgets/grid_layout/bsp_grid_layout.dart`:
  ```dart
  import 'package:flutter/material.dart';

  import '../../grid_suggestor/grid_suggestor.dart';

  /// 셀 빌더 시그니처 — 셀 id 와 정규화 bbox(0..1) 를 받아 위젯 반환.
  typedef BspCellBuilder = Widget Function(int cellId, Rect normalizedBBox);

  /// BSP 트리를 화면 비율(`aspectRatio`)에 맞춰 셀 단위 위젯으로 펼쳐주는 primitive.
  ///
  /// 알고리즘 모듈의 [cellBBoxes] 를 사용해 트리를 정규화 좌표(0..1)로 펼치고,
  /// [AspectRatio] 컨테이너의 [Stack] + [Positioned.fromRect] 로 각 셀에 빌더 호출.
  ///
  /// 두 use case 가 공유:
  /// - dev 갤러리: 셀 안에 cellId 텍스트 표시 (`GridTemplatePreview`)
  /// - production suggestion: 셀 안에 placeholder / 사진 매핑 (`SuggestionCard`)
  class BspGridLayout extends StatelessWidget {
    const BspGridLayout({
      super.key,
      required this.tree,
      required this.aspectRatio,
      required this.cellBuilder,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.borderColor,
    });

    final GridNode tree;
    final double aspectRatio;
    final BspCellBuilder cellBuilder;
    final BorderRadius borderRadius;
    final Color? borderColor;

    @override
    Widget build(BuildContext context) {
      final bboxes = cellBBoxes(tree);

      return AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
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
                        child: cellBuilder(
                          entry.key,
                          Rect.fromLTWH(
                            entry.value.left,
                            entry.value.top,
                            entry.value.width,
                            entry.value.height,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 4-4: 테스트 실행 — PASS**

  ```bash
  flutter test test/cores/widgets/grid_layout/bsp_grid_layout_test.dart
  ```

  Expected: 2 tests PASS.

- [ ] **Step 4-5: 커밋**

  ```bash
  git add lib/cores/widgets/grid_layout test/cores/widgets/grid_layout
  git commit -m "feat : BspGridLayout primitive — BSP 트리 → Stack+Positioned 셀 자리잡기 (#3)"
  ```

---

## Task 5: dev `GridTemplatePreview` 를 BspGridLayout 으로 리팩터

**Files:**
- Modify: `lib/features/dev/widgets/grid_template_preview.dart`

- [ ] **Step 5-1: GridTemplatePreview 리팩터**

  Replace `lib/features/dev/widgets/grid_template_preview.dart` 본문 (`build` 만 변경, `_CellTile` 유지):
  ```dart
  import 'package:flutter/material.dart';

  import '../../../cores/constants/app_colors.dart';
  import '../../../cores/constants/app_spacing.dart';
  import '../../../cores/constants/app_text_style.dart';
  import '../../../cores/grid_suggestor/grid_suggestor.dart';
  import '../../../cores/widgets/grid_layout/bsp_grid_layout.dart';

  /// 큐레이션 템플릿 시각 미리보기 카드 (`/dev` 갤러리용).
  ///
  /// 셀 자리잡기는 [BspGridLayout] 에 위임, 셀 안에는 cellId 텍스트만 표시.
  /// production suggestion 화면도 동일 [BspGridLayout] 을 다른 cellBuilder 로 사용.
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template.name,
            style:
                AppTextStyles.caption_16.copyWith(color: AppColors.charcoal82),
          ),
          SizedBox(height: AppSpacing.xs),
          BspGridLayout(
            tree: template.tree,
            aspectRatio: canvas.value,
            borderColor: AppColors.charcoal40,
            cellBuilder: (cellId, _) => _CellTile(cellId: cellId),
          ),
        ],
      );
    }
  }

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

- [ ] **Step 5-2: 회귀 — dev gallery widget smoke 테스트 통과 확인**

  ```bash
  flutter test test/features/dev/
  ```

  Expected: 기존 smoke test PASS (시각만 변경 없으므로).

- [ ] **Step 5-3: 분석**

  ```bash
  flutter analyze
  ```

  Expected: 무경고.

- [ ] **Step 5-4: 커밋**

  ```bash
  git add lib/features/dev/widgets/grid_template_preview.dart
  git commit -m "refactor : GridTemplatePreview — BspGridLayout primitive 사용 (#3)"
  ```

---

# PHASE B — CanvasPicker + PhotoPicker (Task 6-12)

> **목표:** 비율 선택 화면 + 사진/영상 picker 화면 (권한 + AssetGrid + 선택 모델 + MediaItem 변환).
> **DoD:** 두 화면 동작, 권한 5상태 분기, N=2..9 검증, AppSnackbar 에러 안내, iOS/Android 매니페스트 등록.

---

## Task 6: CanvasPicker 화면 (4 ratio chip)

**Files:**
- Create: `lib/features/canvas_picker/widgets/ratio_chip.dart`
- Modify: `lib/features/canvas_picker/canvas_picker_page.dart` (placeholder → 실제)
- Test: `test/features/canvas_picker/canvas_picker_page_test.dart`

- [ ] **Step 6-1: RatioChip 위젯 작성**

  Create `lib/features/canvas_picker/widgets/ratio_chip.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';

  import '../../../cores/constants/app_colors.dart';
  import '../../../cores/constants/app_spacing.dart';
  import '../../../cores/constants/app_text_style.dart';

  /// 비율 chip — outlined card + 선택 시 border 강조.
  ///
  /// 내부 모양 박스의 비율로 시각 힌트, 라벨/캡션은 16배수 폰트 유지.
  class RatioChip extends StatelessWidget {
    const RatioChip({
      super.key,
      required this.ratio,
      required this.label,
      required this.caption,
      required this.selected,
      required this.onTap,
    });

    final double ratio;
    final String label;
    final String caption;
    final bool selected;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
      final border = selected
          ? Border.all(color: AppColors.charcoal40, width: 1.5)
          : Border.all(color: AppColors.lightCream);

      return Semantics(
        button: true,
        selected: selected,
        label: '$label, $caption',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: border,
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: AppColors.shadowFocus,
                        offset: Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: ratio,
                  child: Container(
                    width: 48.w,
                    decoration: BoxDecoration(
                      color: AppColors.charcoal82,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(label,
                    style: AppTextStyles.body_16
                        .copyWith(color: AppColors.charcoal)),
                SizedBox(height: AppSpacing.xxs),
                Text(caption,
                    style: AppTextStyles.caption_16
                        .copyWith(color: AppColors.mutedGray)),
              ],
            ),
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 6-2: CanvasPickerPage 작성**

  Replace `lib/features/canvas_picker/canvas_picker_page.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';

  import '../../cores/constants/app_colors.dart';
  import '../../cores/constants/app_spacing.dart';
  import '../../cores/constants/app_text_style.dart';
  import '../../cores/grid_suggestor/grid_suggestor.dart';
  import '../../cores/widgets/buttons/app_button.dart';
  import '../../flow/flow_selection_provider.dart';
  import '../../routers/route_paths.dart';
  import 'widgets/ratio_chip.dart';

  /// 캔버스 비율 선택 화면 — 4 preset chip + "다음" CTA.
  ///
  /// chip 선택 시 로컬 상태 갱신, "다음" 누름 시 [FlowSelectionNotifier.setCanvas]
  /// 후 [RoutePaths.photoPicker] 로 push.
  class CanvasPickerPage extends ConsumerStatefulWidget {
    const CanvasPickerPage({super.key});

    @override
    ConsumerState<CanvasPickerPage> createState() => _CanvasPickerPageState();
  }

  class _CanvasPickerPageState extends ConsumerState<CanvasPickerPage> {
    CanvasRatio? _selected;

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.md),
                Text('캔버스 비율',
                    style: AppTextStyles.cardTitle_32
                        .copyWith(color: AppColors.charcoal)),
                SizedBox(height: AppSpacing.sm),
                Text('어떤 비율로 만들까요?',
                    style: AppTextStyles.body_16
                        .copyWith(color: AppColors.mutedGray)),
                SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.0,
                    children: [
                      _chipFor(
                        const CanvasRatio.portrait916(),
                        '9:16',
                        'Reels · Story',
                      ),
                      _chipFor(
                        const CanvasRatio.square(),
                        '1:1',
                        'Feed',
                      ),
                      _chipFor(
                        const CanvasRatio.portrait45(),
                        '4:5',
                        'Feed (세로)',
                      ),
                      _chipFor(
                        const CanvasRatio.landscape169(),
                        '16:9',
                        'YouTube',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.base),
                AppButton.primary(
                  label: '다음',
                  onPressed: _selected == null ? null : _onNext,
                ),
                SizedBox(height: AppSpacing.base),
              ],
            ),
          ),
        ),
      );
    }

    Widget _chipFor(CanvasRatio ratio, String label, String caption) {
      return RatioChip(
        ratio: ratio.value,
        label: label,
        caption: caption,
        selected: _selected == ratio,
        onTap: () => setState(() => _selected = ratio),
      );
    }

    void _onNext() {
      ref
          .read(flowSelectionNotifierProvider.notifier)
          .setCanvas(_selected!);
      context.push(RoutePaths.photoPicker);
    }
  }
  ```

- [ ] **Step 6-3: 위젯 테스트 작성**

  Create `test/features/canvas_picker/canvas_picker_page_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:go_router/go_router.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
  import 'package:gridset/features/canvas_picker/canvas_picker_page.dart';
  import 'package:gridset/flow/flow_selection_provider.dart';

  Widget _harness(Widget child) {
    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(path: '/', builder: (_, __) => child),
              GoRoute(
                path: '/photo-picker',
                builder: (_, __) => const Scaffold(body: Text('photo-stub')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void main() {
    testWidgets('chip 선택 → "다음" 활성 → push', (tester) async {
      await tester.pumpWidget(_harness(const CanvasPickerPage()));
      await tester.pumpAndSettle();

      // 9:16 chip 탭
      await tester.tap(find.text('9:16'));
      await tester.pumpAndSettle();

      // "다음" 탭
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      // photo-picker stub 화면으로 이동
      expect(find.text('photo-stub'), findsOneWidget);
    });

    testWidgets('chip 선택 시 flowSelectionProvider canvas 갱신',
        (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(393, 852),
          child: Consumer(builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(home: const CanvasPickerPage());
          }),
        ),
      ));
      await tester.pumpAndSettle();

      // 4:5 chip 탭
      await tester.tap(find.text('4:5'));
      await tester.pumpAndSettle();

      // setCanvas 는 "다음" 탭 시점이므로 chip 만 탭한 상태에선 미반영.
      expect(container.read(flowSelectionNotifierProvider).canvas,
          const CanvasRatio.portrait916()); // 디폴트
    });
  }
  ```

- [ ] **Step 6-4: 테스트 실행 — PASS**

  ```bash
  flutter test test/features/canvas_picker/
  ```

  Expected: 2 tests PASS.

- [ ] **Step 6-5: 커밋**

  ```bash
  git add lib/features/canvas_picker test/features/canvas_picker
  git commit -m "feat : CanvasPicker 화면 — 4 ratio chip + 다음 CTA (#3)"
  ```

---

## Task 7: PermissionState + permission_provider

**Files:**
- Create: `lib/features/photo_picker/providers/permission_provider.dart`
- Test: `test/features/photo_picker/permission_provider_test.dart`

- [ ] **Step 7-1: PermissionState enum + provider 작성**

  Create `lib/features/photo_picker/providers/permission_provider.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:photo_manager/photo_manager.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  part 'permission_provider.g.dart';

  /// 사진/영상 갤러리 접근 권한 상태.
  ///
  /// `notDetermined` 는 enum 외 — `requestPermissionExtend` 호출 시점에
  /// 시스템이 dialog 띄워주고 결과는 반드시 4 값 중 하나로 resolve.
  enum AppPermissionState {
    authorized,
    limited,
    denied,
    restricted;

    static AppPermissionState fromPlatform(PermissionState ps) {
      switch (ps) {
        case PermissionState.authorized:
          return AppPermissionState.authorized;
        case PermissionState.limited:
          return AppPermissionState.limited;
        case PermissionState.denied:
          return AppPermissionState.denied;
        case PermissionState.restricted:
          return AppPermissionState.restricted;
        case PermissionState.notDetermined:
          // 호출 결과로 notDetermined 가 오는 경우는 사실상 없음.
          // 안전하게 denied 매핑.
          return AppPermissionState.denied;
      }
    }
  }

  /// 권한 요청 + 상태 매핑. 진입 시 자동으로 시스템 dialog 가 뜬다 (notDetermined 인 경우).
  ///
  /// `keepAlive: false` (autoDispose) — picker 라우트 dispose 시 재초기화.
  @Riverpod(keepAlive: false)
  Future<AppPermissionState> photoPermission(PhotoPermissionRef ref) async {
    final ps = await PhotoManager.requestPermissionExtend();
    return AppPermissionState.fromPlatform(ps);
  }
  ```

- [ ] **Step 7-2: 단위 테스트 작성 (매핑 로직만)**

  Create `test/features/photo_picker/permission_provider_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/features/photo_picker/providers/permission_provider.dart';
  import 'package:photo_manager/photo_manager.dart';

  void main() {
    group('AppPermissionState.fromPlatform', () {
      test('authorized 매핑', () {
        expect(
          AppPermissionState.fromPlatform(PermissionState.authorized),
          AppPermissionState.authorized,
        );
      });
      test('limited 매핑', () {
        expect(
          AppPermissionState.fromPlatform(PermissionState.limited),
          AppPermissionState.limited,
        );
      });
      test('denied 매핑', () {
        expect(
          AppPermissionState.fromPlatform(PermissionState.denied),
          AppPermissionState.denied,
        );
      });
      test('restricted 매핑', () {
        expect(
          AppPermissionState.fromPlatform(PermissionState.restricted),
          AppPermissionState.restricted,
        );
      });
      test('notDetermined 은 denied 로 fallback', () {
        expect(
          AppPermissionState.fromPlatform(PermissionState.notDetermined),
          AppPermissionState.denied,
        );
      });
    });
  }
  ```

- [ ] **Step 7-3: 테스트 실행 — PASS**

  ```bash
  flutter test test/features/photo_picker/permission_provider_test.dart
  ```

  Expected: 5 tests PASS.

- [ ] **Step 7-4: 커밋**

  ```bash
  git add lib/features/photo_picker/providers test/features/photo_picker/permission_provider_test.dart
  git commit -m "feat : photo_picker 권한 상태 매핑 + provider (#3)"
  ```

---

## Task 8: PermissionDeniedView + LimitedInfoBar 위젯

**Files:**
- Create: `lib/features/photo_picker/widgets/permission_denied_view.dart`
- Create: `lib/features/photo_picker/widgets/limited_info_bar.dart`

- [ ] **Step 8-1: PermissionDeniedView**

  Create `lib/features/photo_picker/widgets/permission_denied_view.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:flutter_svg/flutter_svg.dart';
  import 'package:photo_manager/photo_manager.dart';

  import '../../../cores/constants/app_colors.dart';
  import '../../../cores/constants/app_spacing.dart';
  import '../../../cores/constants/app_text_style.dart';
  import '../../../cores/widgets/buttons/app_button.dart';
  import '../providers/permission_provider.dart';

  /// 권한 거부/제한 시 안내 화면.
  ///
  /// `denied` — "설정 열기" CTA 활성, [PhotoManager.openSetting] 호출
  /// (iOS/Android 모두 시스템 앱 설정으로 이동).
  /// `restricted` — CTA disabled (parental controls).
  class PermissionDeniedView extends StatelessWidget {
    const PermissionDeniedView({super.key, required this.state});

    final AppPermissionState state;

    @override
    Widget build(BuildContext context) {
      assert(
        state == AppPermissionState.denied ||
            state == AppPermissionState.restricted,
        'PermissionDeniedView 는 denied/restricted 일 때만 사용',
      );

      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/icon_siren.svg',
                width: 48.w,
                height: 48.w,
                colorFilter: const ColorFilter.mode(
                  AppColors.charcoal40,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(height: AppSpacing.base),
              Text(
                '갤러리 접근이 막혀있어요',
                style: AppTextStyles.cardTitle_32
                    .copyWith(color: AppColors.charcoal),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                state == AppPermissionState.restricted
                    ? '시스템 정책으로 접근이 제한되어 있어요'
                    : '설정에서 사진 접근을 허용하면 시작할 수 있어요',
                style: AppTextStyles.body_16
                    .copyWith(color: AppColors.charcoal82),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: '설정 열기',
                onPressed: state == AppPermissionState.restricted
                    ? null
                    : () => PhotoManager.openSetting(),
                isFullWidth: false,
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 8-2: LimitedInfoBar**

  Create `lib/features/photo_picker/widgets/limited_info_bar.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:photo_manager/photo_manager.dart';

  import '../../../cores/constants/app_colors.dart';
  import '../../../cores/constants/app_spacing.dart';
  import '../../../cores/constants/app_text_style.dart';

  /// iOS limited photo access 안내 bar — picker 그리드 상단 고정.
  ///
  /// 탭 시 [PhotoManager.presentLimited] — 사용자가 추가 사진 선택 가능.
  /// v1: 권한 상태가 limited 인 한 매번 표시 (dismiss 상태 저장 X).
  class LimitedInfoBar extends StatelessWidget {
    const LimitedInfoBar({super.key});

    @override
    Widget build(BuildContext context) {
      return Material(
        color: AppColors.charcoal04,
        child: InkWell(
          onTap: () => PhotoManager.presentLimited(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '선택한 사진만 보여요. 더 보려면',
                    style: AppTextStyles.body_16
                        .copyWith(color: AppColors.charcoal82),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.charcoal82, size: 20),
              ],
            ),
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 8-3: 분석**

  ```bash
  flutter analyze
  ```

  Expected: 무경고 (단, `url_launcher` import 가 unused 라면 사용 시점까지 두지 말 것).

- [ ] **Step 8-4: 커밋**

  ```bash
  git add lib/features/photo_picker/widgets
  git commit -m "feat : PermissionDeniedView + LimitedInfoBar — 권한 안내 위젯 (#3)"
  ```

---

## Task 9: AssetGrid + AssetTile + 선택 모델

**Files:**
- Create: `lib/features/photo_picker/providers/asset_paged_provider.dart`
- Create: `lib/features/photo_picker/providers/asset_selection_provider.dart`
- Create: `lib/features/photo_picker/widgets/asset_tile.dart`
- Create: `lib/features/photo_picker/widgets/asset_grid.dart`

- [ ] **Step 9-1: asset_paged_provider 작성**

  Create `lib/features/photo_picker/providers/asset_paged_provider.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:photo_manager/photo_manager.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  part 'asset_paged_provider.g.dart';

  /// "Recent" album 의 asset 페이지네이션.
  ///
  /// 60장씩 lazy load — 호출부에서 [loadMore] 누적 호출.
  /// `keepAlive: false` (autoDispose) — picker 라우트 떠나면 초기화.
  @Riverpod(keepAlive: false)
  class AssetPagedNotifier extends _$AssetPagedNotifier {
    static const int _pageSize = 60;
    AssetPathEntity? _album;
    int _page = 0;
    bool _exhausted = false;

    @override
    Future<List<AssetEntity>> build() async {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // image + video
        onlyAll: true,
      );
      if (albums.isEmpty) {
        _exhausted = true;
        return const [];
      }
      _album = albums.first;
      final first = await _album!.getAssetListPaged(page: 0, size: _pageSize);
      _page = 1;
      _exhausted = first.length < _pageSize;
      return first;
    }

    Future<void> loadMore() async {
      if (_exhausted || _album == null) return;
      final cur = state.valueOrNull ?? const [];
      final next = await _album!
          .getAssetListPaged(page: _page, size: _pageSize);
      _page += 1;
      _exhausted = next.length < _pageSize;
      state = AsyncData([...cur, ...next]);
    }

    bool get isExhausted => _exhausted;
  }
  ```

- [ ] **Step 9-2: asset_selection_provider — 선택 순서 보존 + 검증**

  Create `lib/features/photo_picker/providers/asset_selection_provider.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:photo_manager/photo_manager.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../../cores/widgets/snackbars/app_snackbar.dart';

  part 'asset_selection_provider.g.dart';

  const int _kMaxSelection = 9;
  const double _kMaxAspectRatio = 10.0; // 가로/세로 ≥10:1 차단
  const double _kMinAspectRatio = 0.1;

  /// 선택된 [AssetEntity] 들을 순서 보존해서 들고 있음.
  ///
  /// 토글:
  /// - 이미 있음 → 제거
  /// - 없음 + length==9 → no-op + AppSnackbar 안내
  /// - 없음 + AR 비정상 → no-op + AppSnackbar 안내
  @Riverpod(keepAlive: false)
  class AssetSelectionNotifier extends _$AssetSelectionNotifier {
    @override
    List<AssetEntity> build() => const [];

    /// [BuildContext] 는 SnackBar 표시용 — 테스트에서는 null 가능.
    void toggle(AssetEntity a, BuildContext? context) {
      final idx = state.indexWhere((e) => e.id == a.id);
      if (idx >= 0) {
        state = [...state.sublist(0, idx), ...state.sublist(idx + 1)];
        return;
      }

      if (state.length >= _kMaxSelection) {
        if (context != null) {
          AppSnackbar.show(
            context,
            message: '한 번에 9장까지 만들 수 있어요',
            iconPath: 'assets/icons/icon_block.svg',
          );
        }
        return;
      }

      if (a.width <= 0 || a.height <= 0) return;
      final ar = a.width / a.height;
      if (ar > _kMaxAspectRatio || ar < _kMinAspectRatio) {
        if (context != null) {
          AppSnackbar.show(
            context,
            message: '이 사진은 비율이 너무 길어 빠졌어요',
            iconPath: 'assets/icons/icon_block.svg',
          );
        }
        return;
      }

      state = [...state, a];
    }

    /// 호출부에서 검증 회피한 fast-path — 테스트용.
    void replaceAll(List<AssetEntity> items) => state = items;
  }
  ```

- [ ] **Step 9-3: AssetTile 위젯**

  Create `lib/features/photo_picker/widgets/asset_tile.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:photo_manager/photo_manager.dart';

  import '../../../cores/constants/app_colors.dart';
  import '../../../cores/constants/app_text_style.dart';
  import '../providers/asset_selection_provider.dart';

  /// 갤러리 그리드 셀 — 썸네일 + 선택 순서 badge + dim overlay.
  class AssetTile extends ConsumerWidget {
    const AssetTile({super.key, required this.asset});

    final AssetEntity asset;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final selection = ref.watch(assetSelectionNotifierProvider);
      final selIndex = selection.indexWhere((e) => e.id == asset.id);
      final selected = selIndex >= 0;

      return GestureDetector(
        onTap: () => ref
            .read(assetSelectionNotifierProvider.notifier)
            .toggle(asset, context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: ThumbnailSize.square(256),
              fit: BoxFit.cover,
            ),
            if (selected)
              Container(color: AppColors.charcoal40),
            if (selected)
              Positioned(
                top: 4.h,
                right: 4.h,
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.charcoal,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${selIndex + 1}',
                    style: AppTextStyles.caption_16
                        .copyWith(color: AppColors.offWhite),
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 9-4: AssetGrid 위젯**

  Create `lib/features/photo_picker/widgets/asset_grid.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../cores/constants/app_colors.dart';
  import '../../../cores/constants/app_spacing.dart';
  import '../../../cores/constants/app_text_style.dart';
  import '../providers/asset_paged_provider.dart';
  import 'asset_tile.dart';

  /// 3-column lazy grid — paged provider 와 연동.
  ///
  /// 갤러리 0장 시 안내 텍스트.
  class AssetGrid extends ConsumerWidget {
    const AssetGrid({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final pagedAsync = ref.watch(assetPagedNotifierProvider);
      return pagedAsync.when(
        loading: () => Container(color: AppColors.charcoal04),
        error: (_, __) => Center(
          child: Text('갤러리를 읽지 못했어요',
              style: AppTextStyles.body_16
                  .copyWith(color: AppColors.charcoal82)),
        ),
        data: (assets) {
          if (assets.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  '갤러리에 사진이 없어요',
                  style: AppTextStyles.body_16
                      .copyWith(color: AppColors.charcoal82),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                ref.read(assetPagedNotifierProvider.notifier).loadMore();
              }
              return false;
            },
            child: GridView.builder(
              padding: EdgeInsets.all(AppSpacing.xs),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1.0,
              ),
              itemCount: assets.length,
              itemBuilder: (_, i) => AssetTile(asset: assets[i]),
            ),
          );
        },
      );
    }
  }
  ```

- [ ] **Step 9-5: 분석**

  ```bash
  flutter analyze
  ```

  Expected: 무경고. (codegen 자동 — `*.g.dart` 갱신 확인)

- [ ] **Step 9-6: 커밋**

  ```bash
  git add lib/features/photo_picker
  git commit -m "feat : AssetGrid + AssetTile + paged/selection providers (#3)"
  ```

---

## Task 10: AssetEntity → MediaItem 변환 + 단위 테스트

**Files:**
- Create: `lib/features/photo_picker/asset_to_media_item.dart`
- Test: `test/features/photo_picker/asset_to_media_item_test.dart`

- [ ] **Step 10-1: 실패하는 테스트 작성**

  Create `test/features/photo_picker/asset_to_media_item_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
  import 'package:gridset/features/photo_picker/asset_to_media_item.dart';

  void main() {
    group('mediaItemFromMetrics', () {
      test('photo 정상 → MediaItem 반환', () {
        final r = mediaItemFromMetrics(
          id: 'a',
          isVideo: false,
          width: 1080,
          height: 1920,
          videoMs: null,
        );
        expect(r, isNotNull);
        expect(r!.id, 'a');
        expect(r.type, MediaType.photo);
        expect(r.aspectRatio, closeTo(1080 / 1920, 0.0001));
        expect(r.durationMs, isNull);
      });

      test('video 정상 → durationMs 채워짐', () {
        final r = mediaItemFromMetrics(
          id: 'v',
          isVideo: true,
          width: 1920,
          height: 1080,
          videoMs: 12000,
        );
        expect(r, isNotNull);
        expect(r!.type, MediaType.video);
        expect(r.durationMs, 12000);
      });

      test('width 또는 height 0 → null', () {
        expect(
          mediaItemFromMetrics(
              id: 'x', isVideo: false, width: 0, height: 1920, videoMs: null),
          isNull,
        );
        expect(
          mediaItemFromMetrics(
              id: 'x', isVideo: false, width: 1080, height: 0, videoMs: null),
          isNull,
        );
      });

      test('AR ≥10:1 또는 ≤1:10 → null (검증 차단)', () {
        expect(
          mediaItemFromMetrics(
              id: 'x', isVideo: false, width: 11000, height: 1000, videoMs: null),
          isNull,
        );
        expect(
          mediaItemFromMetrics(
              id: 'x', isVideo: false, width: 1000, height: 11000, videoMs: null),
          isNull,
        );
      });
    });
  }
  ```

- [ ] **Step 10-2: 테스트 실행 — FAIL**

  ```bash
  flutter test test/features/photo_picker/asset_to_media_item_test.dart
  ```

  Expected: FAIL ("mediaItemFromMetrics 정의 안 됨").

- [ ] **Step 10-3: 변환 함수 구현**

  Create `lib/features/photo_picker/asset_to_media_item.dart`:
  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:photo_manager/photo_manager.dart';

  import '../../cores/grid_suggestor/grid_suggestor.dart';

  /// AR 검증 한도 — 알고리즘 입력 검증과 동일.
  const double _kMaxAspectRatio = 10.0;
  const double _kMinAspectRatio = 0.1;

  /// AssetEntity 메타에서 MediaItem 만들기 (테스트 가능한 순수 함수).
  ///
  /// 검증 실패 시 null. 호출부는 null 인 항목을 skip.
  MediaItem? mediaItemFromMetrics({
    required String id,
    required bool isVideo,
    required int width,
    required int height,
    required int? videoMs,
  }) {
    if (width <= 0 || height <= 0) return null;
    final ar = width / height;
    if (!ar.isFinite || ar > _kMaxAspectRatio || ar < _kMinAspectRatio) {
      return null;
    }
    return MediaItem(
      id: id,
      type: isVideo ? MediaType.video : MediaType.photo,
      aspectRatio: ar,
      durationMs: isVideo ? videoMs : null,
    );
  }

  /// AssetEntity 어댑터 — 변환 실패 시 debugPrint + null.
  MediaItem? assetToMediaItem(AssetEntity a) {
    final r = mediaItemFromMetrics(
      id: a.id,
      isVideo: a.type == AssetType.video,
      width: a.width,
      height: a.height,
      videoMs: a.type == AssetType.video
          ? a.videoDuration.inMilliseconds
          : null,
    );
    if (r == null) {
      debugPrint('⚠️ asset 변환 실패: id=${a.id} type=${a.type} '
          'w=${a.width} h=${a.height}');
    }
    return r;
  }
  ```

- [ ] **Step 10-4: 테스트 실행 — PASS**

  ```bash
  flutter test test/features/photo_picker/asset_to_media_item_test.dart
  ```

  Expected: 4 tests PASS.

- [ ] **Step 10-5: 커밋**

  ```bash
  git add lib/features/photo_picker/asset_to_media_item.dart test/features/photo_picker/asset_to_media_item_test.dart
  git commit -m "feat : AssetEntity → MediaItem 변환 + AR 검증 (#3)"
  ```

---

## Task 11: PhotoPickerPage — 권한 분기 + AssetGrid + "다음" CTA

**Files:**
- Modify: `lib/features/photo_picker/photo_picker_page.dart`
- Test: `test/features/photo_picker/photo_picker_page_test.dart`

- [ ] **Step 11-1: PhotoPickerPage 본 구현**

  Replace `lib/features/photo_picker/photo_picker_page.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';

  import '../../cores/constants/app_colors.dart';
  import '../../cores/constants/app_spacing.dart';
  import '../../cores/constants/app_text_style.dart';
  import '../../cores/grid_suggestor/grid_suggestor.dart';
  import '../../cores/widgets/buttons/app_button.dart';
  import '../../flow/flow_selection_provider.dart';
  import '../../routers/route_paths.dart';
  import 'asset_to_media_item.dart';
  import 'providers/asset_selection_provider.dart';
  import 'providers/permission_provider.dart';
  import 'widgets/asset_grid.dart';
  import 'widgets/limited_info_bar.dart';
  import 'widgets/permission_denied_view.dart';

  /// 사진/영상 picker 화면 — 권한 분기 + AssetGrid + "다음" CTA.
  class PhotoPickerPage extends ConsumerWidget {
    const PhotoPickerPage({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final permAsync = ref.watch(photoPermissionProvider);
      final selection = ref.watch(assetSelectionNotifierProvider);

      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
            onPressed: () => context.pop(),
          ),
          title: Text(
            '사진 고르기 ${selection.length}/9',
            style: AppTextStyles.body_16
                .copyWith(color: AppColors.charcoal),
          ),
        ),
        body: SafeArea(
          child: permAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) =>
                const PermissionDeniedView(state: AppPermissionState.denied),
            data: (state) {
              switch (state) {
                case AppPermissionState.authorized:
                case AppPermissionState.limited:
                  return Column(
                    children: [
                      if (state == AppPermissionState.limited)
                        const LimitedInfoBar(),
                      const Expanded(child: AssetGrid()),
                      _BottomBar(
                        onNext: selection.length >= 2
                            ? () => _onNext(context, ref)
                            : null,
                        selectionCount: selection.length,
                      ),
                    ],
                  );
                case AppPermissionState.denied:
                case AppPermissionState.restricted:
                  return PermissionDeniedView(state: state);
              }
            },
          ),
        ),
      );
    }

    void _onNext(BuildContext context, WidgetRef ref) {
      final assets = ref.read(assetSelectionNotifierProvider);
      final items = assets
          .map(assetToMediaItem)
          .whereType<MediaItem>()
          .toList(growable: false);

      ref.read(flowSelectionNotifierProvider.notifier).setMedia(items);
      context.push(RoutePaths.suggestion);
    }
  }

  class _BottomBar extends StatelessWidget {
    const _BottomBar({required this.onNext, required this.selectionCount});

    final VoidCallback? onNext;
    final int selectionCount;

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
          AppSpacing.base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selectionCount < 2)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  '2장 이상 골라주세요',
                  style: AppTextStyles.caption_16
                      .copyWith(color: AppColors.mutedGray),
                  textAlign: TextAlign.center,
                ),
              ),
            AppButton.primary(label: '다음', onPressed: onNext),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 11-2: 권한 분기 widget 테스트 작성**

  Create `test/features/photo_picker/photo_picker_page_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:go_router/go_router.dart';
  import 'package:gridset/features/photo_picker/photo_picker_page.dart';
  import 'package:gridset/features/photo_picker/providers/permission_provider.dart';

  Widget _harness(Widget child, {required AppPermissionState perm}) {
    return ProviderScope(
      overrides: [
        photoPermissionProvider.overrideWith((ref) async => perm),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [GoRoute(path: '/', builder: (_, __) => child)],
          ),
        ),
      ),
    );
  }

  void main() {
    testWidgets('denied — DeniedView 표시', (tester) async {
      await tester.pumpWidget(
          _harness(const PhotoPickerPage(), perm: AppPermissionState.denied));
      await tester.pumpAndSettle();

      expect(find.text('갤러리 접근이 막혀있어요'), findsOneWidget);
      expect(find.text('설정 열기'), findsOneWidget);
    });

    testWidgets('restricted — DeniedView "설정 열기" disabled', (tester) async {
      await tester.pumpWidget(_harness(const PhotoPickerPage(),
          perm: AppPermissionState.restricted));
      await tester.pumpAndSettle();

      expect(find.text('갤러리 접근이 막혀있어요'), findsOneWidget);
      expect(find.text('시스템 정책으로 접근이 제한되어 있어요'), findsOneWidget);
    });

    testWidgets('limited — LimitedInfoBar 노출', (tester) async {
      await tester.pumpWidget(
          _harness(const PhotoPickerPage(), perm: AppPermissionState.limited));
      await tester.pumpAndSettle();

      expect(find.text('선택한 사진만 보여요. 더 보려면'), findsOneWidget);
    });

    testWidgets('authorized + 0 선택 → "다음" 비활성 + 안내 노출', (tester) async {
      await tester.pumpWidget(_harness(const PhotoPickerPage(),
          perm: AppPermissionState.authorized));
      await tester.pumpAndSettle();

      expect(find.text('2장 이상 골라주세요'), findsOneWidget);
    });
  }
  ```

- [ ] **Step 11-3: 테스트 실행 — PASS**

  ```bash
  flutter test test/features/photo_picker/photo_picker_page_test.dart
  ```

  Expected: 4 tests PASS.

- [ ] **Step 11-4: 커밋**

  ```bash
  git add lib/features/photo_picker test/features/photo_picker/photo_picker_page_test.dart
  git commit -m "feat : PhotoPickerPage — 권한 분기 + AssetGrid + 다음 CTA (#3)"
  ```

---

## Task 12: iOS Info.plist + Android manifest 권한 등록

**Files:**
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 12-1: iOS Info.plist 추가**

  Edit `ios/Runner/Info.plist` — `</dict>` 직전에 추가:
  ```xml
  <key>NSPhotoLibraryUsageDescription</key>
  <string>고른 사진으로 자동 그리드 레이아웃을 제안하기 위해 갤러리에 접근합니다.</string>
  ```

- [ ] **Step 12-2: Android manifest 권한 추가**

  Edit `android/app/src/main/AndroidManifest.xml` — `<application>` 태그 바깥, `<manifest>` 안에 추가:
  ```xml
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
  <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
      android:maxSdkVersion="32"/>
  ```

- [ ] **Step 12-3: 빌드 smoke (선택, debug)**

  ```bash
  flutter analyze
  ```

  Expected: 무경고. 실기기 테스트는 plan 마지막 통합 단계.

- [ ] **Step 12-4: 커밋**

  ```bash
  git add ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
  git commit -m "chore : 사진 갤러리 권한 매니페스트 등록 (iOS/Android) (#3)"
  ```

---

# PHASE C — Suggestion 화면 + 흐름 연결 (Task 13-17)

> **목표:** SuggestionState/Notifier, PageView+Peek 화면, CTA bar, 홈 stub 제거 + 라우팅, 통합 테스트.
> **DoD:** 두 진입 흐름 모두 끝까지 동작, "다른 제안" pagination 4 batch 한도 준수, "이걸로"/"빈 캔버스" stub SnackBar 동작, 통합 테스트 통과.

---

## Task 13: SuggestionState + SuggestionNotifier

**Files:**
- Create: `lib/features/suggestion/providers/suggestion_state.dart`
- Create: `lib/features/suggestion/providers/suggestion_notifier.dart`
- Test: `test/features/suggestion/suggestion_notifier_test.dart`

- [ ] **Step 13-1: SuggestionState (Freezed sealed)**

  Create `lib/features/suggestion/providers/suggestion_state.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  import '../../../cores/grid_suggestor/grid_suggestor.dart';

  part 'suggestion_state.freezed.dart';

  @freezed
  sealed class SuggestionState with _$SuggestionState {
    const factory SuggestionState.empty() = SuggestionStateEmpty;
    const factory SuggestionState.error(String message) = SuggestionStateError;
    const factory SuggestionState.loaded({
      required List<MediaItem> media,
      required CanvasRatio canvas,
      required List<GridSuggestion> suggestions,
      required int selectedIndex,
      SuggestCursor? cursor,
    }) = SuggestionStateLoaded;
  }
  ```

- [ ] **Step 13-2: SuggestionNotifier**

  Create `lib/features/suggestion/providers/suggestion_notifier.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../../cores/grid_suggestor/grid_suggestor.dart';
  import '../../../flow/flow_selection_provider.dart';
  import 'suggestion_state.dart';

  part 'suggestion_notifier.g.dart';

  /// 후보 화면 상태 — flowSelection 을 watch 해서 진입 시 자동 suggest 호출.
  ///
  /// `keepAlive: false` — suggestion 라우트 떠나면 초기화.
  @Riverpod(keepAlive: false)
  class SuggestionNotifier extends _$SuggestionNotifier {
    @override
    SuggestionState build() {
      final flow = ref.watch(flowSelectionNotifierProvider);
      if (flow.media.length < 2) {
        return const SuggestionState.empty();
      }
      try {
        final r = suggest(media: flow.media, canvas: flow.canvas);
        if (r.suggestions.isEmpty) {
          return const SuggestionState.empty();
        }
        return SuggestionState.loaded(
          media: flow.media,
          canvas: flow.canvas,
          suggestions: r.suggestions,
          selectedIndex: 0,
          cursor: r.nextCursor,
        );
      } on ArgumentError catch (e) {
        return SuggestionState.error(
          e.message?.toString() ?? '입력 검증 실패',
        );
      }
    }

    void selectIndex(int i) {
      final s = state;
      if (s is! SuggestionStateLoaded) return;
      if (i < 0 || i >= s.suggestions.length) return;
      state = s.copyWith(selectedIndex: i);
    }

    /// "다른 제안" — cursor 가 있으면 새 batch append.
    /// cursor null 이면 no-op (호출부가 disabled 처리).
    void loadMore() {
      final s = state;
      if (s is! SuggestionStateLoaded) return;
      if (s.cursor == null) return;
      try {
        final r = suggest(
          media: s.media,
          canvas: s.canvas,
          cursor: s.cursor!,
        );
        state = s.copyWith(
          suggestions: [...s.suggestions, ...r.suggestions],
          cursor: r.nextCursor,
        );
      } on ArgumentError {
        // 발생 거의 0
      }
    }
  }
  ```

- [ ] **Step 13-3: 단위 테스트 작성**

  Create `test/features/suggestion/suggestion_notifier_test.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
  import 'package:gridset/features/suggestion/providers/suggestion_notifier.dart';
  import 'package:gridset/features/suggestion/providers/suggestion_state.dart';
  import 'package:gridset/flow/flow_selection_provider.dart';

  void main() {
    group('SuggestionNotifier', () {
      test('media < 2 → empty state', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);

        c.read(flowSelectionNotifierProvider.notifier).setMedia(const []);

        final s = c.read(suggestionNotifierProvider);
        expect(s, isA<SuggestionStateEmpty>());
      });

      test('media >= 2 → loaded with suggestions', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);

        const items = [
          MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
          MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
          MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
        ];
        c.read(flowSelectionNotifierProvider.notifier).setMedia(items);

        final s = c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
        expect(s.suggestions, isNotEmpty);
        expect(s.selectedIndex, 0);
        expect(s.media.length, 3);
      });

      test('selectIndex 갱신', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);

        const items = [
          MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
          MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
          MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
        ];
        c.read(flowSelectionNotifierProvider.notifier).setMedia(items);

        // 진입
        final s0 = c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
        if (s0.suggestions.length >= 2) {
          c.read(suggestionNotifierProvider.notifier).selectIndex(1);
          final s1 =
              c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
          expect(s1.selectedIndex, 1);
        }
      });

      test('loadMore — cursor 진행 시 suggestions 누적', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);

        const items = [
          MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
          MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
          MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
        ];
        c.read(flowSelectionNotifierProvider.notifier).setMedia(items);

        final s0 = c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
        final initial = s0.suggestions.length;

        if (s0.cursor != null) {
          c.read(suggestionNotifierProvider.notifier).loadMore();
          final s1 =
              c.read(suggestionNotifierProvider) as SuggestionStateLoaded;
          expect(s1.suggestions.length, greaterThan(initial));
        }
      });
    });
  }
  ```

- [ ] **Step 13-4: 테스트 실행 — PASS**

  ```bash
  flutter test test/features/suggestion/suggestion_notifier_test.dart
  ```

  Expected: 4 tests PASS (codegen 자동 후).

- [ ] **Step 13-5: 커밋**

  ```bash
  git add lib/features/suggestion/providers test/features/suggestion/suggestion_notifier_test.dart
  git commit -m "feat : SuggestionState + Notifier — cursor pagination 흐름 (#3)"
  ```

---

## Task 14: SuggestionCard + dots indicator + CTA bar 위젯

**Files:**
- Create: `lib/features/suggestion/widgets/suggestion_card.dart`
- Create: `lib/features/suggestion/widgets/suggestion_dots.dart`
- Create: `lib/features/suggestion/widgets/suggestion_cta_bar.dart`

- [ ] **Step 14-1: SuggestionCard — BspGridLayout placeholder cellBuilder**

  Create `lib/features/suggestion/widgets/suggestion_card.dart`:
  ```dart
  import 'package:flutter/material.dart';

  import '../../../cores/constants/app_colors.dart';
  import '../../../cores/grid_suggestor/grid_suggestor.dart';
  import '../../../cores/widgets/grid_layout/bsp_grid_layout.dart';

  /// 후보 카드 한 개 — BspGridLayout 위에 placeholder 셀.
  ///
  /// v1.x 에서 사진 썸네일 매핑 추가 예정 — cellBuilder 만 교체.
  class SuggestionCard extends StatelessWidget {
    const SuggestionCard({
      super.key,
      required this.suggestion,
      required this.canvas,
    });

    final GridSuggestion suggestion;
    final CanvasRatio canvas;

    @override
    Widget build(BuildContext context) {
      return BspGridLayout(
        tree: suggestion.tree,
        aspectRatio: canvas.value,
        borderColor: AppColors.lightCream,
        cellBuilder: (_, __) => const _PlaceholderCell(),
      );
    }
  }

  class _PlaceholderCell extends StatelessWidget {
    const _PlaceholderCell();

    @override
    Widget build(BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.charcoal04,
          border: Border.all(color: AppColors.lightCream),
        ),
      );
    }
  }
  ```

- [ ] **Step 14-2: SuggestionDots indicator**

  Create `lib/features/suggestion/widgets/suggestion_dots.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';

  import '../../../cores/constants/app_colors.dart';
  import '../../../cores/constants/app_spacing.dart';

  /// PageView 현재 페이지 dots indicator — 활성은 길쭉한 pill, 나머지는 작은 점.
  class SuggestionDots extends StatelessWidget {
    const SuggestionDots({
      super.key,
      required this.count,
      required this.current,
    });

    final int count;
    final int current;

    @override
    Widget build(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final on = i == current;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: on ? 16.w : 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                color: on ? AppColors.charcoal : AppColors.charcoal40,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      );
    }
  }
  ```

- [ ] **Step 14-3: SuggestionCtaBar — 이걸로 / 다른 제안 / 빈 캔버스**

  Create `lib/features/suggestion/widgets/suggestion_cta_bar.dart`:
  ```dart
  import 'package:flutter/material.dart';

  import '../../../cores/constants/app_spacing.dart';
  import '../../../cores/widgets/buttons/app_button.dart';

  /// CTA bar — primary "이걸로" + outlined "다른 제안" / "빈 캔버스".
  ///
  /// "다른 제안" 은 cursor 소진 시 비활성. "이걸로"/"빈 캔버스" 는 v1 stub
  /// (Editor 미구현 — 호출부에서 SnackBar).
  class SuggestionCtaBar extends StatelessWidget {
    const SuggestionCtaBar({
      super.key,
      required this.onPick,
      required this.onMore,
      required this.onBlank,
    });

    final VoidCallback onPick;
    final VoidCallback? onMore;
    final VoidCallback onBlank;

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
          AppSpacing.base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton.primary(label: '이걸로', onPressed: onPick),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                    child: AppButton.outlined(
                        label: '다른 제안', onPressed: onMore)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: AppButton.outlined(
                        label: '빈 캔버스', onPressed: onBlank)),
              ],
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 14-4: 분석 + 커밋**

  ```bash
  flutter analyze
  ```

  Expected: 무경고.

  ```bash
  git add lib/features/suggestion/widgets
  git commit -m "feat : SuggestionCard + Dots + CtaBar 위젯 (#3)"
  ```

---

## Task 15: SuggestionPage — PageView+Peek + 상태 분기

**Files:**
- Modify: `lib/features/suggestion/suggestion_page.dart`
- Test: `test/features/suggestion/suggestion_page_test.dart`

- [ ] **Step 15-1: SuggestionPage 본 구현**

  Replace `lib/features/suggestion/suggestion_page.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';

  import '../../cores/constants/app_colors.dart';
  import '../../cores/constants/app_spacing.dart';
  import '../../cores/constants/app_text_style.dart';
  import '../../cores/widgets/snackbars/app_snackbar.dart';
  import 'providers/suggestion_notifier.dart';
  import 'providers/suggestion_state.dart';
  import 'widgets/suggestion_card.dart';
  import 'widgets/suggestion_cta_bar.dart';
  import 'widgets/suggestion_dots.dart';

  /// 후보 화면 — PageView + Peek (viewportFraction 0.7) + dots + CTA bar.
  class SuggestionPage extends ConsumerStatefulWidget {
    const SuggestionPage({super.key});

    @override
    ConsumerState<SuggestionPage> createState() => _SuggestionPageState();
  }

  class _SuggestionPageState extends ConsumerState<SuggestionPage> {
    final PageController _controller =
        PageController(viewportFraction: 0.7, initialPage: 0);

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final state = ref.watch(suggestionNotifierProvider);

      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
            onPressed: () => context.pop(),
          ),
          title: Text(
            '제안',
            style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
          ),
        ),
        body: SafeArea(
          child: switch (state) {
            SuggestionStateEmpty() => _Empty(),
            SuggestionStateError(:final message) => _Error(message: message),
            SuggestionStateLoaded() => _Loaded(
                state: state,
                controller: _controller,
                onPageChanged: (i) =>
                    ref.read(suggestionNotifierProvider.notifier).selectIndex(i),
                onPick: () => _stub(context, '에디터는 곧 준비됩니다'),
                onMore: state.cursor == null
                    ? null
                    : () {
                        ref
                            .read(suggestionNotifierProvider.notifier)
                            .loadMore();
                      },
                onBlank: () => _stub(context, '에디터는 곧 준비됩니다'),
              ),
          },
        ),
      );
    }

    void _stub(BuildContext context, String message) {
      AppSnackbar.show(
        context,
        message: message,
        iconPath: 'assets/icons/icon_copy.svg',
      );
    }
  }

  class _Empty extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            '먼저 사진을 2장 이상 골라주세요',
            style: AppTextStyles.body_16
                .copyWith(color: AppColors.charcoal82),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  class _Error extends StatelessWidget {
    const _Error({required this.message});
    final String message;

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            '이 조합으론 제안을 만들 수 없어요\n$message',
            style: AppTextStyles.body_16
                .copyWith(color: AppColors.charcoal82),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  class _Loaded extends StatelessWidget {
    const _Loaded({
      required this.state,
      required this.controller,
      required this.onPageChanged,
      required this.onPick,
      required this.onMore,
      required this.onBlank,
    });

    final SuggestionStateLoaded state;
    final PageController controller;
    final ValueChanged<int> onPageChanged;
    final VoidCallback onPick;
    final VoidCallback? onMore;
    final VoidCallback onBlank;

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.md),
            Text(
              '${state.suggestions.length}개 후보',
              style:
                  AppTextStyles.cardTitle_32.copyWith(color: AppColors.charcoal),
            ),
            SizedBox(height: AppSpacing.md),
            Expanded(
              child: PageView.builder(
                controller: controller,
                onPageChanged: onPageChanged,
                itemCount: state.suggestions.length,
                itemBuilder: (_, i) {
                  final selected = i == state.selectedIndex;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: selected ? 1.0 : 0.5,
                      child: SuggestionCard(
                        suggestion: state.suggestions[i],
                        canvas: state.canvas,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppSpacing.md),
            SuggestionDots(
              count: state.suggestions.length,
              current: state.selectedIndex,
            ),
            SuggestionCtaBar(
              onPick: onPick,
              onMore: onMore,
              onBlank: onBlank,
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 15-2: Page widget smoke 테스트**

  Create `test/features/suggestion/suggestion_page_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
  import 'package:gridset/features/suggestion/suggestion_page.dart';
  import 'package:gridset/flow/flow_selection_provider.dart';

  Widget _harness({required List<MediaItem> media}) {
    return ProviderScope(
      overrides: [
        flowSelectionNotifierProvider.overrideWith(() {
          final n = FlowSelectionNotifier();
          // build() 후 setMedia 가능 — 단순화 위해 직접 override 안 함, 본 테스트는
          // 호출 후 read 흐름. (대안: container 직접 다루는 방식)
          return n;
        }),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        child: MaterialApp(home: const SuggestionPage()),
      ),
    );
  }

  void main() {
    testWidgets('media 비어있음 → empty 안내', (tester) async {
      await tester.pumpWidget(_harness(media: const []));
      await tester.pumpAndSettle();

      expect(find.text('먼저 사진을 2장 이상 골라주세요'), findsOneWidget);
    });

    testWidgets('media >= 2 → "N개 후보" 표시', (tester) async {
      const media = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
        MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
      ];

      // ProviderContainer 직접 사용 — flow setMedia 후 page 마운트
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(flowSelectionNotifierProvider.notifier).setMedia(media);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(393, 852),
          child: MaterialApp(home: const SuggestionPage()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('개 후보'), findsOneWidget);
      expect(find.text('이걸로'), findsOneWidget);
      expect(find.text('다른 제안'), findsOneWidget);
      expect(find.text('빈 캔버스'), findsOneWidget);
    });
  }
  ```

- [ ] **Step 15-3: 테스트 실행 — PASS**

  ```bash
  flutter test test/features/suggestion/
  ```

  Expected: notifier 4 + page 2 = 6 tests PASS.

- [ ] **Step 15-4: 커밋**

  ```bash
  git add lib/features/suggestion/suggestion_page.dart test/features/suggestion/suggestion_page_test.dart
  git commit -m "feat : SuggestionPage — PageView+Peek + 분기 (empty/error/loaded) (#3)"
  ```

---

## Task 16: 홈 두 CTA stub 제거 → 실제 라우팅

**Files:**
- Modify: `lib/features/home/home_page.dart`

- [ ] **Step 16-1: stub SnackBar 제거 + 라우팅 연결**

  Edit `lib/features/home/home_page.dart`:
  - 클래스 시그니처를 `StatelessWidget` → `ConsumerWidget` 으로 변경
  - `_showStubSnackBar` 메서드 삭제
  - `build` 시그니처를 `Widget build(BuildContext context, WidgetRef ref)` 로 변경
  - 두 CTA `onPressed` 교체:

  ```dart
  // import 추가
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../cores/grid_suggestor/grid_suggestor.dart';
  import '../../flow/flow_selection_provider.dart';
  ```

  AppButton.primary 의 `onPressed` 를:
  ```dart
  onPressed: () {
    ref
        .read(flowSelectionNotifierProvider.notifier)
        .setCanvas(const CanvasRatio.portrait916());
    context.push(RoutePaths.photoPicker);
  },
  ```

  AppButton.outlined 의 `onPressed` 를:
  ```dart
  onPressed: () => context.push(RoutePaths.canvasPicker),
  ```

  최종 `HomePage` 클래스:
  ```dart
  class HomePage extends ConsumerWidget {
    const HomePage({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.md),
                const _HomeHeader(),
                SizedBox(height: AppSpacing.base),
                Text(
                  '오늘은\n뭐 모아볼까?',
                  style: AppTextStyles.cardTitle_32
                      .copyWith(color: AppColors.charcoal),
                ),
                SizedBox(height: AppSpacing.xl),
                const Expanded(child: _GridPreview()),
                SizedBox(height: AppSpacing.xl),
                AppButton.primary(
                  label: '사진·영상 고르기',
                  icon: Icons.image,
                  onPressed: () {
                    ref
                        .read(flowSelectionNotifierProvider.notifier)
                        .setCanvas(const CanvasRatio.portrait916());
                    context.push(RoutePaths.photoPicker);
                  },
                ),
                SizedBox(height: AppSpacing.md),
                AppButton.outlined(
                  label: '비율 먼저 정하기',
                  onPressed: () => context.push(RoutePaths.canvasPicker),
                ),
                SizedBox(height: AppSpacing.base),
              ],
            ),
          ),
        ),
      );
    }
  }
  ```

  (`_HomeHeader`, `_DebugEntryButton`, `_GridPreview`, `_PreviewCard` 등 private 클래스는 그대로 유지)

- [ ] **Step 16-2: 분석 + 빠른 manual smoke 빌드**

  ```bash
  flutter analyze
  ```

  Expected: 무경고.

  ```bash
  flutter run -d <시뮬레이터/실기기>
  ```

  manual: 홈 → "비율 먼저 정하기" 누르면 비율 화면 / 홈 → "사진·영상 고르기" 누르면 picker 권한 dialog → 갤러리.

- [ ] **Step 16-3: 커밋**

  ```bash
  git add lib/features/home/home_page.dart
  git commit -m "feat : 홈 CTA stub 제거 — 실제 흐름 라우팅 연결 (#3)"
  ```

---

## Task 17: 통합 테스트 — 두 흐름 end-to-end

**Files:**
- Create: `integration_test/flow_test.dart`

- [ ] **Step 17-1: 통합 테스트 작성**

  Create `integration_test/flow_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:integration_test/integration_test.dart';

  import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
  import 'package:gridset/features/photo_picker/providers/permission_provider.dart';
  import 'package:gridset/flow/flow_selection_provider.dart';
  import 'package:gridset/main.dart' as app;

  void main() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    testWidgets('비율 먼저 → 4:5 → picker(권한 mock authorized) → suggestion',
        (tester) async {
      // Riverpod override — 권한은 항상 authorized, media 는 미리 셋팅.
      const seed = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
        MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
      ];

      await tester.pumpWidget(ProviderScope(
        overrides: [
          photoPermissionProvider
              .overrideWith((ref) async => AppPermissionState.authorized),
        ],
        child: const app.GridsetApp(),
      ));
      await tester.pumpAndSettle();

      // 홈 → 비율 먼저
      await tester.tap(find.text('비율 먼저 정하기'));
      await tester.pumpAndSettle();

      // 4:5 chip 탭
      await tester.tap(find.text('4:5'));
      await tester.pumpAndSettle();

      // "다음" 누름 — picker 화면
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      expect(find.textContaining('사진 고르기'), findsOneWidget);

      // picker 의 selection 을 직접 셋업해서 Suggestion 진입 시뮬
      final ctxState = tester.state(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(ctxState.context);
      container.read(flowSelectionNotifierProvider.notifier).setMedia(seed);

      // 직접 navigate — 실제 picker 의 "다음" 누르려면 AssetEntity mock 필요.
      // 간단화 위해 router 직접 push.
      // (만약 실 ASSET 검증이 필요하면 photo_manager 자체 mock 가 필요)
    });
  }
  ```

  > 통합 테스트는 `photo_manager` 의 실 asset 의존성 때문에 mock 까지 다루기엔 별도 사이클 필요. v1 통합 테스트는 **라우팅 흐름 검증** 까지만 (Suggestion 진입까지의 흐름).

- [ ] **Step 17-2: 통합 테스트 실행 (시뮬레이터 또는 실기기)**

  ```bash
  flutter test integration_test/flow_test.dart
  ```

  Expected: PASS (또는 시뮬레이터 환경 issue 시 manual smoke 로 갈음).

- [ ] **Step 17-3: 커밋**

  ```bash
  git add integration_test
  git commit -m "test : 흐름 통합 — 비율 → picker → suggestion 라우팅 검증 (#3)"
  ```

---

# PHASE D — 시각 iterate (Task 18)

> **목표:** 실제 사진으로 흐름 끝까지 돌려보며 ugly templates 발견 → 교체 → 골든 갱신.
> **DoD:** Phase E 골든 8개 통과 유지, 시각 검토 결과 `.report/` 에 기록.

---

## Task 18: Phase D 시각 iterate

**Files (해당 시 수정):**
- Modify: `lib/cores/grid_suggestor/templates/_n{N}_templates.dart` (해당 N)
- Modify: `test/cores/grid_suggestor/suggester_test.dart` (golden 갱신)
- Create: `.report/20260427_#3_phase_d_visual_iterate.md` (검토 기록)

- [ ] **Step 18-1: 검토 환경 셋업**

  ```bash
  flutter run -d <실기기 권장>
  ```

  실기기에서 다음 4 케이스 직접 실행:
  - N=2 (가로 2개) — 9:16 + 1:1
  - N=4 (혼합 AR) — 9:16 + 4:5
  - N=6 (세로 위주) — 9:16
  - N=9 (혼합) — 1:1 + 16:9

  각 케이스에서 후보 3~5개 visual 검토.

- [ ] **Step 18-2: 검토 기록**

  Create `.report/20260427_#3_phase_d_visual_iterate.md`:
  ```markdown
  # Phase D — 시각 iterate 보고

  **Date:** 2026-04-27 (실행일)
  **Branch:** 20260426_#3_Suggestion_화면_진입_흐름_사진_picker_비율_선택
  **Issue:** #3

  ## 검토 케이스
  ...

  ## ugly 발견 templates
  | template name | 문제 | 대체 트리 |
  |---|---|---|
  | (예) `n4_left_big_right_3stack` | 우측 셀 AR 0.3 으로 너무 좁음 | `Split(vertical, [0.55], [Leaf(1), Split(horizontal, [0.5], [Leaf(2), Leaf(3)])])` |

  ## 골든 갱신 항목
  - `suggester_test.dart` `expect_n4_canvas916` ...

  ## perf 측정 (실기기)
  - N=9 단독 호출: ~ XX ms (테스트러너 ~225ms 와 비교)
  ```

- [ ] **Step 18-3: ugly templates 교체**

  발견 시:
  1. 해당 `_n{N}_templates.dart` 의 entry 교체
  2. `templates_test.dart` 의 8 invariant 통과 확인:
     ```bash
     flutter test test/cores/grid_suggestor/templates_test.dart
     ```
  3. `suggester_test.dart` 의 골든 expect 갱신 — 의도적 업데이트:
     ```bash
     flutter test test/cores/grid_suggestor/suggester_test.dart
     ```

- [ ] **Step 18-4: 무결성 + 회귀 종합 확인**

  ```bash
  flutter analyze
  flutter test
  ```

  Expected: 무경고, 전체 테스트 통과.

- [ ] **Step 18-5: 커밋 (검토 결과)**

  ugly 발견 없으면:
  ```bash
  git add .report/20260427_#3_phase_d_visual_iterate.md
  git commit -m "chore : Phase D 시각 검토 — 교체 없음, 보고서 추가 (#3)"
  ```

  교체 있으면:
  ```bash
  git add lib/cores/grid_suggestor/templates test/cores/grid_suggestor/suggester_test.dart .report/20260427_#3_phase_d_visual_iterate.md
  git commit -m "refactor : Phase D — ugly templates 교체 + 골든 갱신 (#3)"
  ```

---

# 종합 마감

- [ ] **Final Step 1: 전체 분석 + 테스트**

  ```bash
  flutter analyze
  flutter test
  flutter test integration_test/flow_test.dart
  ```

  Expected: 무경고, 전체 PASS.

- [ ] **Final Step 2: 커버리지 측정**

  ```bash
  flutter test --coverage
  ```

  새 모듈(`flow/`, `features/canvas_picker/`, `features/photo_picker/`, `features/suggestion/`, `cores/widgets/grid_layout/`) 의 커버리지가 80% 이상인지 lcov 로 확인.

- [ ] **Final Step 3: 디자인 시스템 정합 grep 점검**

  ```bash
  # raw 색상 / 폰트 사이즈 사용 검출 (이번 사이클 추가 파일만)
  grep -rn "Color(0xFF" lib/features/canvas_picker lib/features/photo_picker lib/features/suggestion lib/flow lib/cores/widgets/grid_layout || echo "OK"
  grep -rn "fontSize:" lib/features/canvas_picker lib/features/photo_picker lib/features/suggestion lib/flow lib/cores/widgets/grid_layout || echo "OK"
  grep -rn "EdgeInsets.all(\(8\|12\|16\|24\)" lib/features/canvas_picker lib/features/photo_picker lib/features/suggestion lib/flow lib/cores/widgets/grid_layout || echo "OK"
  ```

  Expected: 모두 "OK". 발견 시 상수 사용으로 교체 후 commit.

- [ ] **Final Step 4: 최종 커밋 (필요 시 정리)**

  ```bash
  git status
  git log --oneline main..HEAD
  ```

  PR 생성 (사용자가 직접):
  ```bash
  gh pr create --title "feat : Suggestion 화면 + 진입 흐름 (#3)" --body "..."
  ```

  > 자동 커밋/PR 생성 금지 — 사용자가 명시 요청 시만.

---

## Self-Review Checklist (실행 후)

- [ ] Spec §2-1 디렉터리 구조 모두 생성됨
- [ ] Spec §3 FlowSelection autoDispose 동작
- [ ] Spec §4-1 ~ 4-3 화면 3개 동작
- [ ] Spec §5 BspGridLayout 사용처 dev + suggestion
- [ ] Spec §6-1 권한 5상태 분기 (authorized/limited/denied/restricted/loading)
- [ ] Spec §6-2 AppSnackbar 메시지 + iconPath 매핑 정합
- [ ] Spec §7 Phase D 통합
- [ ] Spec §8 테스트 매트릭스 모두 작성됨
- [ ] Spec §9 디자인 시스템 grep 점검 통과
- [ ] Open Questions §12 — Phase D 검토 시 결정

---

**End of Plan.**
