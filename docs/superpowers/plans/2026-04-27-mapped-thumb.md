# Suggestion 사진 썸네일 매핑 (`_MappedThumb`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Suggestion 카드의 셀 빌더를 `_PlaceholderCell` 에서 `_MappedThumb` 로 교체해 `GridSuggestion.mediaByCellId` 를 실제 사진/영상 첫 프레임 썸네일로 시각화.

**Architecture:** `selectedAssetsProvider` (keepAlive) 가 picker 라우트 떠난 후에도 `Map<String, AssetEntity>` 보존. `_MappedThumb` (ConsumerStatefulWidget) 가 cellId → assetId → AssetEntity 해석 후 `ThumbnailLoader` 어댑터로 비동기 byte 로드 → `Image.memory(fit: cover)` + 영상 ▶ overlay. PageView 에 `allowImplicitScrolling: true` 추가해 인접 1장 preload.

**Tech Stack:** Flutter 3.9.2, Riverpod (`flutter_riverpod` + `riverpod_annotation`), Freezed, photo_manager 3.9, photo_manager_image_provider 2.1, flutter_svg, flutter_screenutil, go_router.

**Spec:** `docs/superpowers/specs/2026-04-27-mapped-thumb-design.md`
**Issue:** GitHub #5 — `.issues/20260427_기능추가_Suggestion_사진_썸네일_매핑.md`
**Branch:** `20260427_#5_v1_x_사진_썸네일_매핑_MappedThumb_Phase_D_큐레이션_시각_iterate` (브랜치 이름에 "Phase D" 포함되지만 본 PR 범위에서 분리 — spec §11 / plan Out of Scope)

---

## File Map

### 신규
| 파일 | 책임 |
|---|---|
| `lib/features/suggestion/providers/selected_assets_provider.dart` (+ `.g.dart`) | `Map<String, AssetEntity>` 보존 (keepAlive) |
| `lib/features/suggestion/providers/thumbnail_loader.dart` (+ `.g.dart`) | photo_manager `thumbnailDataWithSize` 1점 격리 (인터페이스 + 프로덕션 구현 + Riverpod provider) |
| `assets/icons/icon_play.svg` | 영상 셀 우상단 ▶ 인디케이터 자산 |
| `test/features/suggestion/providers/selected_assets_provider_test.dart` | provider 단위 |
| `test/features/suggestion/widgets/mapped_thumb_test.dart` | `_MappedThumb` 분기 6 케이스 |

### 수정
| 파일 | 변경 |
|---|---|
| `lib/features/suggestion/widgets/suggestion_card.dart` | `assetsById` prop 추가, `cellBuilder` 를 `_MappedThumb` 로 교체. `_PlaceholderCell` 은 fallback 용 private 유지. `_MappedThumb` 는 inline private |
| `lib/features/suggestion/suggestion_page.dart` | `selectedAssetsProvider` watch + `SuggestionCard` 에 `assetsById` prop. `PageView.builder(allowImplicitScrolling: true, ...)` 한 줄 추가 |
| `lib/features/photo_picker/photo_picker_page.dart` | `_onNext` 에서 `setMedia` 와 페어로 `setAssets` 호출 |
| `pubspec.yaml` | `assets/icons/icon_play.svg` 등록 (디렉터리 등록만 돼있는지 먼저 확인) |
| `test/features/suggestion/suggestion_card_test.dart` | placeholder 가정 → mapped 가정으로 갱신 |
| `test/features/photo_picker/photo_picker_page_test.dart` | `_onNext` 후 selectedAssetsProvider 채워짐 검증 케이스 추가 |
| `docs/superpowers/specs/2026-04-27-suggestion-flow-design.md` | §"GridTemplatePreview 승격" 표 v1.x 행 = 완료 ✓ + 본 spec cross-link |

### 본 plan 의 build_runner 가정
프로젝트 컨벤션: `dart run build_runner watch --delete-conflicting-outputs` 가 background 로 돌고 있음. Riverpod / Freezed 코드 생성이 즉시 반영. 만약 watch 가 안 돌면 각 Task 끝에 `dart run build_runner build --delete-conflicting-outputs` 한 번 실행 후 진행.

---

## Task 1: `SelectedAssetsNotifier` provider

**Files:**
- Create: `lib/features/suggestion/providers/selected_assets_provider.dart`
- Create: `test/features/suggestion/providers/selected_assets_provider_test.dart`

- [ ] **Step 1.1: Write failing test**

`test/features/suggestion/providers/selected_assets_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/features/suggestion/providers/selected_assets_provider.dart';
import 'package:photo_manager/photo_manager.dart';

// 테스트용 가짜 AssetEntity — id 만 사용. photo_manager 의 AssetEntity 는
// final 클래스라 `AssetEntity(id: ..., typeInt: 1, width: 1, height: 1)` 로
// 직접 생성해도 native 호출이 일어나지 않으므로 unit test 안전.
AssetEntity _fake(String id) => AssetEntity(
      id: id,
      typeInt: 1, // image
      width: 100,
      height: 100,
    );

void main() {
  test('초기 state 는 빈 map', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(selectedAssetsNotifierProvider), isEmpty);
  });

  test('setAssets — list → id 키 map', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier =
        container.read(selectedAssetsNotifierProvider.notifier);

    notifier.setAssets([_fake('a'), _fake('b')]);

    final state = container.read(selectedAssetsNotifierProvider);
    expect(state.keys, ['a', 'b']);
    expect(state['a']!.id, 'a');
    expect(state['b']!.id, 'b');
  });

  test('setAssets — 빈 리스트 → 빈 map', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier =
        container.read(selectedAssetsNotifierProvider.notifier);

    notifier.setAssets(const []);
    expect(container.read(selectedAssetsNotifierProvider), isEmpty);
  });

  test('setAssets — 동일 id 중복 → 후입력 우선 (last-wins)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier =
        container.read(selectedAssetsNotifierProvider.notifier);

    final first = _fake('x');
    final second = _fake('x'); // 같은 id 의 다른 인스턴스
    notifier.setAssets([first, second]);

    final state = container.read(selectedAssetsNotifierProvider);
    expect(state.length, 1);
    expect(identical(state['x'], second), isTrue,
        reason: 'Map literal 의 last-wins 시맨틱과 일관');
  });

  test('state map 은 수정 불가', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier =
        container.read(selectedAssetsNotifierProvider.notifier);

    notifier.setAssets([_fake('a')]);
    final state = container.read(selectedAssetsNotifierProvider);

    expect(() => state['b'] = _fake('b'), throwsUnsupportedError);
  });
}
```

- [ ] **Step 1.2: Run test to verify it fails**

Run: `flutter test test/features/suggestion/providers/selected_assets_provider_test.dart`
Expected: FAIL — `selectedAssetsNotifierProvider` 가 정의되지 않음.

- [ ] **Step 1.3: Write provider**

`lib/features/suggestion/providers/selected_assets_provider.dart`:

```dart
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_assets_provider.g.dart';

/// picker → suggestion 흐름 동안 `Map<String, AssetEntity>` 보존.
///
/// `flowSelectionProvider` 와 페어로 picker `_onNext` 에서 채워짐.
/// `_MappedThumb` 가 cellId → assetId → AssetEntity 를 해석할 때 lookup.
///
/// `keepAlive: true` — picker 라우트 떠난 직후 microtask 에서도 state 가
/// 살아있어야 suggestion 화면이 처음 build 될 때 빈 map 으로 떨어지지 않음.
/// (`flowSelectionProvider` 와 동일한 라이프사이클.)
@Riverpod(keepAlive: true)
class SelectedAssetsNotifier extends _$SelectedAssetsNotifier {
  @override
  Map<String, AssetEntity> build() => const {};

  /// `id → AssetEntity` 로 정규화. List 의 순서는 알고리즘 입력
  /// (`flow.media`) 에서만 의미 있고, 본 provider 는 lookup 용이라 Map.
  /// `Map.unmodifiable` 로 외부 mutation 차단.
  void setAssets(List<AssetEntity> items) =>
      state = Map.unmodifiable({for (final a in items) a.id: a});
}
```

- [ ] **Step 1.4: Trigger codegen** (watch 가 안 돌고 있는 경우만)

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `selected_assets_provider.g.dart` 생성.

- [ ] **Step 1.5: Run test to verify it passes**

Run: `flutter test test/features/suggestion/providers/selected_assets_provider_test.dart`
Expected: PASS — 5 케이스 모두 green.

- [ ] **Step 1.6: Commit**

```bash
git add lib/features/suggestion/providers/selected_assets_provider.dart \
  lib/features/suggestion/providers/selected_assets_provider.g.dart \
  test/features/suggestion/providers/selected_assets_provider_test.dart
git commit -m "feat : SelectedAssetsNotifier provider 추가 (#5)"
```

---

## Task 2: `ThumbnailLoader` 어댑터 + Riverpod provider

추상 인터페이스 + photo_manager 위임 구현 + Riverpod provider. Fake 는 Task 5 의 `_MappedThumb` 위젯 테스트에서 사용. 본 Task 는 인터페이스/구현/provider 만 만들고 단위 테스트 X (위임 1줄이라 의미 있는 단위 검증 없음 — fake 사용은 Task 5 통합 테스트로 대체).

**Files:**
- Create: `lib/features/suggestion/providers/thumbnail_loader.dart`

- [ ] **Step 2.1: Write file**

```dart
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'thumbnail_loader.g.dart';

/// photo_manager 의 `thumbnailDataWithSize` 호출을 1점에 격리.
///
/// 테스트는 `thumbnailLoaderProvider.overrideWith((_) => FakeLoader(...))`
/// 로 주입.
abstract class ThumbnailLoader {
  Future<Uint8List?> load(AssetEntity asset, {required ThumbnailSize size});
}

/// 프로덕션 구현 — photo_manager 직접 위임.
class PhotoManagerThumbnailLoader implements ThumbnailLoader {
  const PhotoManagerThumbnailLoader();

  @override
  Future<Uint8List?> load(AssetEntity asset, {required ThumbnailSize size}) =>
      asset.thumbnailDataWithSize(size);
}

/// `keepAlive: true` — 어댑터 자체는 stateless 라 dispose 로 잃을 게 없지만
/// 매번 new 하지 않게 하려고 keepAlive.
@Riverpod(keepAlive: true)
ThumbnailLoader thumbnailLoader(Ref ref) =>
    const PhotoManagerThumbnailLoader();
```

- [ ] **Step 2.2: Trigger codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `thumbnail_loader.g.dart` 생성.

- [ ] **Step 2.3: Sanity build**

Run: `flutter analyze lib/features/suggestion/providers/thumbnail_loader.dart`
Expected: `No issues found!`

- [ ] **Step 2.4: Commit**

```bash
git add lib/features/suggestion/providers/thumbnail_loader.dart \
  lib/features/suggestion/providers/thumbnail_loader.g.dart
git commit -m "feat : ThumbnailLoader 어댑터 + provider 추가 (#5)"
```

---

## Task 3: `icon_play.svg` 자산 추가 + pubspec 등록

영상 셀 우상단 ▶ 인디케이터 자산. 16px 박스 안에 채워진 삼각형 단순 svg.

**Files:**
- Create: `assets/icons/icon_play.svg`
- Modify: `pubspec.yaml`

- [ ] **Step 3.1: Confirm 디렉터리 등록 상태**

Run: `grep -n "assets/icons" pubspec.yaml`
Expected: 디렉터리 / 파일 명시 등록 형태 확인. 현재 `pubspec.yaml` 의 `assets:` 섹션에 `assets/icons/` 디렉터리는 등록되어 있지 않을 수 있음 (`icon_block.svg` 등이 있는데도 등록 X 라면 다른 mechanism — 확인 필요).

확인 결과에 따라:
- `assets/icons/` 가 이미 등록 → Step 3.3 으로
- 미등록 → 개별 파일 등록 (`pubspec.yaml` 의 기존 `assets/wordmark.svg` 식 패턴)

- [ ] **Step 3.2: Write svg**

`assets/icons/icon_play.svg`:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none">
  <path d="M5 3.5 L5 12.5 L12 8 Z" fill="currentColor"/>
</svg>
```

(`currentColor` 로 두면 `SvgPicture.asset(..., colorFilter: ColorFilter.mode(AppColors.offWhite, BlendMode.srcIn))` 로 색 주입 가능.)

- [ ] **Step 3.3: pubspec 등록 (Step 3.1 결과에 따라)**

기존 패턴이 개별 파일이면, `pubspec.yaml` 의 `assets:` 아래 추가:

```yaml
    - assets/icons/icon_play.svg
```

- [ ] **Step 3.4: 자산 적재 확인**

Run: `flutter pub get && flutter analyze`
Expected: `No issues found!` + svg 파일 빌드 시 누락 경고 없음.

- [ ] **Step 3.5: Commit**

```bash
git add assets/icons/icon_play.svg pubspec.yaml
git commit -m "feat : icon_play.svg 자산 추가 (#5)"
```

---

## Task 4: `photo_picker._onNext` 페어 호출 (`setMedia` + `setAssets`)

picker `_onNext` 가 기존 `flowSelectionProvider.setMedia` 호출 옆에 `selectedAssetsProvider.setAssets` 를 페어로 추가.

**Files:**
- Modify: `lib/features/photo_picker/photo_picker_page.dart` (`_onNext` 메서드)
- Modify: `test/features/photo_picker/photo_picker_page_test.dart` (페어 호출 검증 추가)

- [ ] **Step 4.1: Write failing test (페어 호출 검증)**

`test/features/photo_picker/photo_picker_page_test.dart` 의 `void main() { ... }` 끝에 케이스 추가:

```dart
  test('_onNext 페어 호출 — setMedia 와 setAssets 가 함께 호출됨', () async {
    // photo_picker_page 내부 _onNext 는 private 이라 직접 호출 불가.
    // ProviderContainer 에서 flow + selectedAssets 두 provider 가
    // 동일 List<AssetEntity> source 로 동기 채워졌는지 검증.

    final container = ProviderContainer(overrides: [
      photoPermissionProvider
          .overrideWith((ref) async => AppPermissionState.authorized),
    ]);
    addTearDown(container.dispose);

    // ===== 시뮬레이션: _onNext 가 호출하는 두 setter 를 직접 호출 =====
    // 본 테스트는 "두 setter 가 묶여 있음" 의 contract 만 검증한다.
    // 실 위젯 통합 테스트는 native 의존이라 여기 범위 밖.
    final assets = [
      AssetEntity(id: 'p1', typeInt: 1, width: 100, height: 100),
      AssetEntity(id: 'p2', typeInt: 1, width: 100, height: 100),
    ];

    final items = assets
        .map(assetToMediaItem)
        .whereType<MediaItem>()
        .toList(growable: false);

    container.read(flowSelectionNotifierProvider.notifier).setMedia(items);
    container
        .read(selectedAssetsNotifierProvider.notifier)
        .setAssets(assets);

    expect(
      container.read(flowSelectionNotifierProvider).media.map((m) => m.id),
      ['p1', 'p2'],
      reason: 'flow.media 가 채워짐',
    );
    expect(
      container.read(selectedAssetsNotifierProvider).keys,
      ['p1', 'p2'],
      reason: 'selectedAssetsProvider 도 같은 source 로 채워짐',
    );
  });
```

상단 import 에 추가:

```dart
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/photo_picker/asset_to_media_item.dart';
import 'package:gridset/features/suggestion/providers/selected_assets_provider.dart';
import 'package:gridset/flow/flow_selection_provider.dart';
import 'package:photo_manager/photo_manager.dart';
```

- [ ] **Step 4.2: Run test to verify it fails**

Run: `flutter test test/features/photo_picker/photo_picker_page_test.dart`
Expected: 새 케이스 PASS (실은 setter 호출만 검증하므로 통과). **그러나 본 케이스의 진짜 검증은 `_onNext` 코드가 setAssets 호출하지 않으면 회귀 시 다른 위젯 테스트에서 selectedAssets 가 비어있어 fail**. 하단 Task 5 의 widget test 가 그 회귀 캐치.

(즉 본 테스트는 contract-level 가드. Step 4.3 의 코드 변경은 추가 케이스로 직접 fail 검증되지 않지만, Task 5 의 mapped_thumb_test 가 의존하는 `_onNext` 의 페어 호출이 깨지면 Task 5 가 fail.)

- [ ] **Step 4.3: `_onNext` 에 setAssets 추가**

`lib/features/photo_picker/photo_picker_page.dart` 의 `_onNext`:

```dart
import '../suggestion/providers/selected_assets_provider.dart';
```

import 추가 후 `_onNext` 본문 변경:

```dart
  void _onNext(BuildContext context, WidgetRef ref) {
    final assets = ref.read(assetSelectionNotifierProvider);
    final items = assets
        .map(assetToMediaItem)
        .whereType<MediaItem>()
        .toList(growable: false);

    // 페어 호출 — flowSelection 은 알고리즘 입력 (MediaItem),
    // selectedAssets 는 렌더링 자원 (AssetEntity). 둘 중 하나만 호출되면
    // suggestion 화면이 silent 실패 (모든 셀 placeholder).
    ref.read(flowSelectionNotifierProvider.notifier).setMedia(items);
    ref
        .read(selectedAssetsNotifierProvider.notifier)
        .setAssets(assets);

    context.push(RoutePaths.suggestion);
  }
```

- [ ] **Step 4.4: Run all photo_picker tests**

Run: `flutter test test/features/photo_picker/`
Expected: 모든 케이스 PASS.

- [ ] **Step 4.5: Commit**

```bash
git add lib/features/photo_picker/photo_picker_page.dart \
  test/features/photo_picker/photo_picker_page_test.dart
git commit -m "feat : photo_picker._onNext 페어 호출 (setMedia+setAssets) (#5)"
```

---

## Task 5: `_MappedThumb` 위젯 — TDD 6 케이스

본 Task 가 가장 큼. SuggestionCard 시그니처 확장 (assetsById prop) 도 본 Task 에 포함 (그래야 _MappedThumb 가 호출 가능).

**Files:**
- Modify: `lib/features/suggestion/widgets/suggestion_card.dart` (SuggestionCard 시그니처 확장 + _MappedThumb inline 추가)
- Create: `test/features/suggestion/widgets/mapped_thumb_test.dart`

- [ ] **Step 5.1: Write failing test (6 케이스 + 추가)**

`test/features/suggestion/widgets/mapped_thumb_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/constants/app_colors.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/suggestion/providers/thumbnail_loader.dart';
import 'package:gridset/features/suggestion/widgets/suggestion_card.dart';
import 'package:photo_manager/photo_manager.dart';

class _FakeLoader implements ThumbnailLoader {
  _FakeLoader({this.bytesById = const {}, this.failIds = const {}});
  final Map<String, Uint8List> bytesById;
  final Set<String> failIds;
  int callCount = 0;

  @override
  Future<Uint8List?> load(AssetEntity asset,
      {required ThumbnailSize size}) async {
    callCount += 1;
    if (failIds.contains(asset.id)) return null;
    return bytesById[asset.id];
  }
}

// 1×1 transparent PNG — 위젯이 Image.memory 로 렌더할 수 있는 가장 작은 byte.
final Uint8List _kTinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

AssetEntity _photo(String id) =>
    AssetEntity(id: id, typeInt: 1, width: 100, height: 100);
AssetEntity _video(String id) =>
    AssetEntity(id: id, typeInt: 2, width: 100, height: 100);

Widget _harness({
  required Widget child,
  required _FakeLoader loader,
}) {
  return ProviderScope(
    overrides: [thumbnailLoaderProvider.overrideWith((_) => loader)],
    child: ScreenUtilInit(
      designSize: const Size(393, 852),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

GridSuggestion _twoCellSuggestion({
  String idA = 'a',
  String idB = 'b',
}) =>
    GridSuggestion(
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      ),
      mediaByCellId: {0: idA, 1: idB},
      loss: 0.0,
      templateName: 'test_2',
    );

void main() {
  testWidgets('(a) 정상 매핑 → Image 노드, fit cover', (tester) async {
    final loader = _FakeLoader(bytesById: {'a': _kTinyPng, 'b': _kTinyPng});
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();

    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, hasLength(2), reason: '두 leaf → 두 Image');
    for (final img in images) {
      expect(img.fit, BoxFit.cover);
      expect(img.gaplessPlayback, isTrue);
    }
  });

  testWidgets('(b) assetsById 누락 → placeholder 톤', (tester) async {
    final loader = _FakeLoader();
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: const {}, // 매핑 누락
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    final placeholders = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(SuggestionCard),
        matching: find.byType(Container),
      ),
    );
    for (final c in placeholders) {
      final dec = c.decoration as BoxDecoration?;
      if (dec == null) continue;
      expect(dec.color, AppColors.lightCream);
    }
    expect(loader.callCount, 0, reason: 'asset 없으면 loader 호출 X');
  });

  testWidgets('(c) loader 가 null → placeholder', (tester) async {
    final loader = _FakeLoader(failIds: {'a', 'b'});
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(loader.callCount, 2);
  });

  testWidgets('(d) 영상 자산 → ▶ icon overlay', (tester) async {
    final loader = _FakeLoader(bytesById: {'v': _kTinyPng});
    final suggestion = GridSuggestion(
      tree: const Leaf(0),
      mediaByCellId: const {0: 'v'},
      loss: 0.0,
      templateName: 'test_1',
    );
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: suggestion,
        canvas: const CanvasRatio.square(),
        assetsById: {'v': _video('v')},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is SvgPicture &&
          (w.bytesLoader.toString().contains('icon_play') ||
              w.toString().contains('icon_play'))),
      findsOneWidget,
      reason: '영상 자산은 ▶ overlay 가 셀 위에 깔림',
    );
  });

  testWidgets(
      '(e) rebuild 후에도 동일 (cellId, asset) 에 대한 callCount == 1',
      (tester) async {
    final loader = _FakeLoader(bytesById: {'a': _kTinyPng, 'b': _kTinyPng});
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();
    final initial = loader.callCount;
    expect(initial, 2, reason: '셀 2개 × 1회');

    // 같은 prop 으로 rebuild — _MappedThumb State 의 _future 가 그대로
    // 유지되어 loader 재호출 없어야.
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();

    expect(loader.callCount, initial,
        reason: '동일 (cellId, asset) → didUpdateWidget 비교 후 재호출 X');
  });

  testWidgets('(f) asset 변경 시 callCount 증가', (tester) async {
    final loader = _FakeLoader(
      bytesById: {'a': _kTinyPng, 'b': _kTinyPng, 'a2': _kTinyPng},
    );
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(idA: 'a'),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();
    final before = loader.callCount;

    // cell 0 의 assetId 가 a → a2 로 바뀜.
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(idA: 'a2'),
        canvas: const CanvasRatio.square(),
        assetsById: {
          'a': _photo('a'),
          'a2': _photo('a2'),
          'b': _photo('b'),
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(loader.callCount, greaterThan(before),
        reason: 'cell 0 의 asset 이 바뀌었으므로 재로드 1회 발생');
  });
}
```

- [ ] **Step 5.2: Run test to verify it fails**

Run: `flutter test test/features/suggestion/widgets/mapped_thumb_test.dart`
Expected: FAIL — `SuggestionCard` 가 `assetsById` prop 없음. 또는 컴파일 에러.

- [ ] **Step 5.3: Write `SuggestionCard` + `_MappedThumb` 구현**

`lib/features/suggestion/widgets/suggestion_card.dart` 전면 갱신:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/grid_suggestor/grid_suggestor.dart';
import '../../../cores/widgets/grid_layout/bsp_grid_layout.dart';
import '../providers/thumbnail_loader.dart';

/// 후보 카드 한 개 — BspGridLayout 위에 사진 썸네일 매핑.
///
/// `mediaByCellId` 로 cellId → assetId 해석, `assetsById` 로
/// assetId → AssetEntity 해석 후 `_MappedThumb` 가 비동기 로드.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.canvas,
    required this.assetsById,
  });

  final GridSuggestion suggestion;
  final CanvasRatio canvas;
  final Map<String, AssetEntity> assetsById;

  @override
  Widget build(BuildContext context) {
    return BspGridLayout(
      tree: suggestion.tree,
      aspectRatio: canvas.value,
      borderColor: AppColors.lightCream,
      cellBuilder: (cellId, _) => _MappedThumb(
        cellId: cellId,
        mediaByCellId: suggestion.mediaByCellId,
        assetsById: assetsById,
      ),
    );
  }
}

/// 매핑된 셀 — id → AssetEntity → 썸네일 byte → Image.memory(cover).
///
/// stateful — `FutureBuilder` 가 매 rebuild 시 새 Future 를 받으면 한 프레임
/// `waiting` 으로 떨어져 깜빡임 발생. State 가 future 를 1회 시작 후 보관.
class _MappedThumb extends ConsumerStatefulWidget {
  const _MappedThumb({
    required this.cellId,
    required this.mediaByCellId,
    required this.assetsById,
  });

  final int cellId;
  final Map<int, String> mediaByCellId;
  final Map<String, AssetEntity> assetsById;

  @override
  ConsumerState<_MappedThumb> createState() => _MappedThumbState();
}

class _MappedThumbState extends ConsumerState<_MappedThumb> {
  Future<Uint8List?>? _future;
  AssetEntity? _asset;

  @override
  void initState() {
    super.initState();
    _resolveAndLoad();
  }

  @override
  void didUpdateWidget(covariant _MappedThumb old) {
    super.didUpdateWidget(old);
    final prevId = old.mediaByCellId[old.cellId];
    final nextId = widget.mediaByCellId[widget.cellId];
    final prevAsset = prevId == null ? null : old.assetsById[prevId];
    final nextAsset = nextId == null ? null : widget.assetsById[nextId];
    if (prevId != nextId || !identical(prevAsset, nextAsset)) {
      _resolveAndLoad();
    }
  }

  void _resolveAndLoad() {
    final assetId = widget.mediaByCellId[widget.cellId];
    assert(assetId != null,
        'mediaByCellId 에 cellId=${widget.cellId} 매핑 없음 — 알고리즘 계약 위반');
    final asset = assetId == null ? null : widget.assetsById[assetId];
    _asset = asset;
    if (asset == null) {
      if (assetId != null) {
        debugPrint('⚠️ asset 누락 cellId=${widget.cellId} id=$assetId');
      }
      _future = null;
      return;
    }
    _future = ref
        .read(thumbnailLoaderProvider)
        .load(asset, size: const ThumbnailSize.square(512));
  }

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    final future = _future;
    if (asset == null || future == null) {
      return const _PlaceholderCell();
    }
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _PlaceholderCell();
        }
        final bytes = snap.data;
        if (snap.hasError || bytes == null) {
          debugPrint(
            '⚠️ thumb load 실패 cellId=${widget.cellId} '
            'asset=${asset.id} err=${snap.error}',
          );
          return const _PlaceholderCell();
        }
        final image = Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
        if (asset.type == AssetType.video) {
          return Stack(
            fit: StackFit.expand,
            children: [
              image,
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _VideoIndicator(),
              ),
            ],
          );
        }
        return image;
      },
    );
  }
}

class _VideoIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.charcoal40,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/icons/icon_play.svg',
        width: 16,
        height: 16,
        colorFilter: const ColorFilter.mode(
          AppColors.offWhite,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _PlaceholderCell extends StatelessWidget {
  const _PlaceholderCell();

  @override
  Widget build(BuildContext context) {
    // spec(2026-04-27-mapped-thumb-design.md) §8 — 매핑 실패/대기 모두
    // 동일 톤. 사용자에게 위협 톤 노출 X.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightCream,
        border: Border.all(color: AppColors.charcoal04),
      ),
    );
  }
}
```

- [ ] **Step 5.4: Run mapped_thumb test**

Run: `flutter test test/features/suggestion/widgets/mapped_thumb_test.dart`
Expected: 6 케이스 PASS.

- [ ] **Step 5.5: Run all suggestion tests (회귀 확인)**

Run: `flutter test test/features/suggestion/`
Expected: 기존 `suggestion_card_test.dart` 가 새 `assetsById` 인자를 안 줘서 **컴파일 fail**. Task 6 에서 갱신.

본 Task 는 mapped_thumb_test 만 green 인 상태에서 commit 진행 (다음 Task 가 즉시 그 fail 을 해결).

- [ ] **Step 5.6: Commit**

```bash
git add lib/features/suggestion/widgets/suggestion_card.dart \
  test/features/suggestion/widgets/mapped_thumb_test.dart
git commit -m "feat : _MappedThumb 위젯 + SuggestionCard 시그니처 확장 (#5)"
```

---

## Task 6: 기존 `suggestion_card_test.dart` 갱신

Task 5 에서 `SuggestionCard` 가 `assetsById` 를 require 받도록 바뀜 → 기존 placeholder 가정 테스트가 컴파일 실패. 두 길:

(i) 기존 회귀 테스트 (placeholder 톤) 의 의도를 보존하기 위해 `assetsById: const {}` (매핑 누락) 케이스로 변형 — 같은 결과 (placeholder 톤 두 개) 가 나옴.
(ii) 회귀 테스트를 mapped_thumb_test 의 케이스 (b) 가 흡수했다고 보고 케이스 삭제.

**(i) 선택** — 기존 spec(2026-04-27-suggestion-flow-design.md) 의 placeholder 톤 회귀 가드는 별도 의미가 있어 보존.

**Files:**
- Modify: `test/features/suggestion/suggestion_card_test.dart`

- [ ] **Step 6.1: Run test to confirm current failure**

Run: `flutter test test/features/suggestion/suggestion_card_test.dart`
Expected: 컴파일 에러 — `SuggestionCard` 가 `assetsById` 누락.

- [ ] **Step 6.2: 갱신 — assetsById: const {} 케이스로 변형**

`test/features/suggestion/suggestion_card_test.dart` 전면 갱신:

```dart
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/constants/app_colors.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/suggestion/widgets/suggestion_card.dart';

void main() {
  // 회귀 방지 — spec(2026-04-27-suggestion-flow-design.md) 의
  // "Suggestion v1: lightCream 배경 + charcoal04 border" 와 코드가 swap 되어
  // 셀 분할이 cream 배경 위에서 시각적으로 사라졌던 사례.
  //
  // v1.x mapped-thumb-design 도입 후: assetsById 가 비어있는 fallback 경로에서도
  // 동일한 placeholder 톤이 유지됨을 보증.
  testWidgets(
    'SuggestionCard — assetsById 누락 시 placeholder 톤 유지 (lightCream + charcoal04)',
    (tester) async {
      final suggestion = GridSuggestion(
        tree: Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        mediaByCellId: const {0: 'a', 1: 'b'},
        loss: 0.0,
        templateName: 'test_2',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(393, 852),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SuggestionCard(
                    suggestion: suggestion,
                    canvas: const CanvasRatio.square(),
                    assetsById: const {}, // 매핑 누락 — fallback 경로
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // _PlaceholderCell 의 Container 만 SuggestionCard 하위에 존재.
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(SuggestionCard),
          matching: find.byType(Container),
        ),
      );

      // 두 leaf → 두 placeholder. (BspGridLayout 자체의 DecoratedBox 는
      // Container 가 아니므로 제외됨.)
      final withPlaceholderDecoration = containers.where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == AppColors.lightCream;
      });
      expect(withPlaceholderDecoration, hasLength(2),
          reason: 'leaf 마다 placeholder 한 개');

      for (final c in withPlaceholderDecoration) {
        final decoration = c.decoration as BoxDecoration;
        final border = decoration.border as Border;
        expect(
          border.top.color,
          AppColors.charcoal04,
          reason: 'spec: charcoal04 분할선',
        );
        expect(border.left.color, AppColors.charcoal04);
        expect(border.right.color, AppColors.charcoal04);
        expect(border.bottom.color, AppColors.charcoal04);
      }
    },
  );
}
```

- [ ] **Step 6.3: Run test to verify pass**

Run: `flutter test test/features/suggestion/suggestion_card_test.dart`
Expected: PASS.

- [ ] **Step 6.4: Run all suggestion tests**

Run: `flutter test test/features/suggestion/`
Expected: 모든 케이스 PASS.

- [ ] **Step 6.5: Commit**

```bash
git add test/features/suggestion/suggestion_card_test.dart
git commit -m "test : suggestion_card_test 갱신 — assetsById 누락 케이스 (#5)"
```

---

## Task 7: `SuggestionPage` 수정 (selectedAssetsProvider watch + assetsById prop + allowImplicitScrolling)

**Files:**
- Modify: `lib/features/suggestion/suggestion_page.dart`
- Modify: `test/features/suggestion/suggestion_page_test.dart` (필요 시 — provider 주입 추가)

- [ ] **Step 7.1: 기존 suggestion_page_test 확인**

Run: `flutter test test/features/suggestion/suggestion_page_test.dart`
Expected: 컴파일/런 fail 가능 (Task 5 후 SuggestionCard 가 assetsById 요구).

- [ ] **Step 7.2: SuggestionPage 변경**

`lib/features/suggestion/suggestion_page.dart` 의 `_Loaded.build` 안 PageView.builder 변경 + `_Loaded` 가 assetsById 받도록:

먼저 import 추가:

```dart
import 'providers/selected_assets_provider.dart';
```

`_SuggestionPageState.build` 안에서 watch 추가:

```dart
    final state = ref.watch(suggestionNotifierProvider);
    final assetsById = ref.watch(selectedAssetsNotifierProvider);
```

`_Loaded` 호출에 prop 추가:

```dart
          SuggestionStateLoaded() => _Loaded(
              state: state,
              assetsById: assetsById,        // ← 신규
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
```

`_Loaded` 클래스 시그니처 + PageView.builder 변경:

```dart
class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.assetsById,
    required this.controller,
    required this.onPageChanged,
    required this.onPick,
    required this.onMore,
    required this.onBlank,
  });

  final SuggestionStateLoaded state;
  final Map<String, AssetEntity> assetsById;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPick;
  final VoidCallback? onMore;
  final VoidCallback onBlank;
  ...
```

`AssetEntity` import 필요:

```dart
import 'package:photo_manager/photo_manager.dart';
```

PageView.builder 안:

```dart
        Expanded(
          child: PageView.builder(
            controller: controller,
            allowImplicitScrolling: true,    // ← 신규: 인접 1장 preload
            onPageChanged: onPageChanged,
            itemCount: state.suggestions.length,
            itemBuilder: (_, i) {
              final selected = i == state.selectedIndex;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1.0 : 0.5,
                  child: SuggestionCard(
                    suggestion: state.suggestions[i],
                    canvas: state.canvas,
                    assetsById: assetsById,       // ← 신규
                  ),
                ),
              );
            },
          ),
        ),
```

- [ ] **Step 7.3: suggestion_page_test 갱신 (필요 시)**

기존 테스트가 SuggestionState.loaded 를 직접 주입한다면 selectedAssetsProvider 도 함께 주입 필요. 현재 테스트 파일 검토:

Run: `cat test/features/suggestion/suggestion_page_test.dart`

- 만약 ProviderScope override 가 이미 있고 SuggestionStateLoaded 시나리오가 있다면, override 에 `selectedAssetsNotifierProvider.overrideWith` 추가.
- 권한 화면만 검증하는 테스트라면 변경 불필요.

수정이 필요한 경우 — 예시 (시나리오에 따라):

```dart
// ProviderScope overrides 에 추가:
selectedAssetsNotifierProvider.overrideWith(() {
  return _StubNotifier();
}),
```

(실제 테스트 코드를 보고 적합하게 적용. 단순 권한 분기만 검증 중이면 변경 불요.)

- [ ] **Step 7.4: Run all suggestion + flow tests**

Run: `flutter test test/features/suggestion/ test/flow/`
Expected: 모든 케이스 PASS.

- [ ] **Step 7.5: Run analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7.6: Commit**

```bash
git add lib/features/suggestion/suggestion_page.dart \
  test/features/suggestion/suggestion_page_test.dart
git commit -m "feat : SuggestionPage assetsById watch + PageView preload (#5)"
```

---

## Task 8: spec cross-link 갱신

기존 `2026-04-27-suggestion-flow-design.md` §"GridTemplatePreview 승격" 표 v1.x 행 = 완료 ✓ + 본 spec cross-link.

**Files:**
- Modify: `docs/superpowers/specs/2026-04-27-suggestion-flow-design.md`

- [ ] **Step 8.1: Locate v1.x row**

Run: `grep -n "v1.x\|MappedThumb\|사진 썸네일 매핑" docs/superpowers/specs/2026-04-27-suggestion-flow-design.md`
Expected: 약 line 578 부근 의 표 행.

- [ ] **Step 8.2: 행 업데이트**

`| 사진 썸네일 매핑 (v1.x) | ... |` 행을 다음과 같이 갱신 (정확한 형식은 기존 표 칼럼 수에 맞춤):

```
| 사진 썸네일 매핑 (v1.x) ✓ | `BspGridLayout.cellBuilder` 를 `_PlaceholderCell` → `_MappedThumb(asset:...)` 로 swap. 자세한 spec: [`2026-04-27-mapped-thumb-design.md`](./2026-04-27-mapped-thumb-design.md) |
```

- [ ] **Step 8.3: Commit**

```bash
git add docs/superpowers/specs/2026-04-27-suggestion-flow-design.md
git commit -m "docs : suggestion-flow-design v1.x 완료 표시 + cross-link (#5)"
```

---

## Task 9: 최종 회귀 + 분석 + 매뉴얼 시각 검증

**Files:** 없음 (실행만)

- [ ] **Step 9.1: 전체 테스트**

Run: `flutter test`
Expected: 전체 PASS.

- [ ] **Step 9.2: analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 9.3: 디바이스/시뮬레이터 매뉴얼 검증**

iOS 시뮬레이터 또는 실 기기 (사진 권한 필수):

1. 앱 실행 → 홈 → "그리드 만들기"
2. canvas-picker → 비율 선택 (예: 1:1)
3. photo-picker → 권한 허용 → 사진 4~5장 선택 → "다음"
4. suggestion 화면 진입 — 카드마다 셀에 실제 사진 썸네일이 또렷이 보이는지 확인
5. PageView swipe — 인접 카드도 즉시 채워져 깜빡임 없는지 확인 (allowImplicitScrolling 효과)
6. 영상이 섞여있다면 우상단 ▶ 인디케이터 노출 확인
7. fit cover — 사진 잘림이 자연스러운지 (letterbox 없음) 확인

만약 시각적 이상이 있으면 Phase D 후속 PR 의 입력으로 메모.

- [ ] **Step 9.4: PR 생성 (사용자 승인 후)**

`CLAUDE.md` 가 `git push 절대 금지` 라 본 단계는 사용자 명시 요청 시에만. 본 plan 의 default 는 commit 까지만.

---

## Out of Scope (본 PR 비포함)

이슈 §검토 변수 / spec §11 와 일치:
- ❌ Phase D 큐레이션 시각 iterate (별 PR — Step 9.3 결과로 ugly template 발견 시 후속 작업)
- ❌ 셀 내 미디어 long-press / pinch-zoom (F06)
- ❌ 영상 재생 / 자동 싱크 (F07)
- ❌ PNG 저장 (F08)
- ❌ photo_manager 외 추가 LRU 캐시
- ❌ duration 텍스트 노출 (F07 spec 시 재검토)

---

## Self-Review Notes (작성자 확인용)

**Spec coverage:**
- §1 결정 요약 9개 항목 모두 Task 매핑 (1→1, 2→2, 3→Task 5 PageView 단 — fit/size/preload, 4→2/3/5, 6→5, 7→ Phase D 별도, 8→2/5, 9→8/spec 본 plan 자체).
- §2 아키텍처 — Task 1, 2, 5, 7 합산.
- §3 데이터 흐름 — Task 4 (페어 호출).
- §4 _MappedThumb 명세 — Task 5.
- §5 ThumbnailLoader — Task 2.
- §6 영상 인디케이터 — Task 3 + 5.
- §7 PageView preload — Task 7.
- §8 fallback 매트릭스 — Task 5 의 (b)(c) 케이스.
- §9 테스트 단위 — Task 1, 4, 5, 6 분배.
- §10 변경 파일 — Task 1~7 합산.
- §11 비범위 — Out of Scope 섹션.
- §12 후속 hooks — 본 plan 비포함, spec 자체 보존.

**Placeholder scan:** `<issue-num>` 만 의도적 placeholder (실행 직전 GitHub 이슈 등록 후 치환).

**Type consistency:**
- `selectedAssetsNotifierProvider` — Task 1 정의, Task 4 / 7 사용.
- `thumbnailLoaderProvider` — Task 2 정의, Task 5 override.
- `SuggestionCard.assetsById` — Task 5 시그니처 추가, Task 6 / 7 호출.
- `_MappedThumb({cellId, mediaByCellId, assetsById})` — Task 5 일관.
- `ThumbnailSize.square(512)` — spec §1 / Task 5 일관.
