# Suggestion 화면 + 진입 흐름 — Design Spec

**Date:** 2026-04-27
**Scope:** 홈 → 사진/영상 picker → (옵션: 비율 선택) → Suggestion 화면 의 진입 흐름. 화면 3개(`/canvas-picker`, `/picker`, `/suggestion`) + 라우팅 + Riverpod Notifier + 권한 처리 + Phase D 시각 iterate 흡수.
**Constraint:** 온디바이스. 외부 호출 없음. `lib/cores/grid_suggestor/` 알고리즘 모듈을 호출부로 통합.
**Source:** `docs/PRD.md` §F00, §9-2-1~3. `.issues/20260426_기능추가_Suggestion_화면_및_진입_흐름.md`.
**Depends on:** `docs/superpowers/specs/2026-04-26-grid-suggestor-design.md` (`lib/cores/grid_suggestor/` 코어 모듈 — main 머지 완료).
**Consumed by (post-spec):** Editor 화면 (F02-F06), F11 되돌리기/다시하기, F16 "내 템플릿".

---

## 1. 결정 요약

| 항목 | 결정 | 근거 |
| --- | --- | --- |
| Picker 패키지 | `photo_manager` | AssetEntity 메타(AR/duration) 직접 추출, iOS limited 콜백, 자체 picker UI 로 cream 톤 일관 적용 |
| 라우팅 구조 | 평탄 3 라우트 + `autoDispose` Riverpod flow state | 기존 라우터 컨벤션과 동일, 흐름 종료 시 자동 초기화, 화면 단위 테스트 용이 |
| 후보 카드 layout | A2′ — `PageView` 가로 풀브리드 + 인스타 캐러셀 식 peek (viewportFraction 0.92) | 메인 카드를 화면 너비 거의 전체로 확장해 분할 패턴이 또렷이 보이게 하면서, 양 옆 4% peek 으로 carousel 임을 인지하도록 단서 유지. (초기 0.7 → Phase D 시각 검토 시 너무 좁다는 피드백으로 0.92 로 상향) |
| 캔버스 비율 선택 UX | Full-screen route (`/canvas-picker`) | "비율 먼저 정하기" 는 흐름의 한 단계 — 라우트로 명시 |
| 권한·에러 정책 | 5상태 분기 + `AppSnackbar` (icon SVG 톤 매핑) | iOS limited 차별화, 디자인 시스템 통일 |
| `GridTemplatePreview` 승격 | C — shared BSP layout primitive (`cores/widgets/grid_layout/bsp_grid_layout.dart`) | 두 use case 공통은 셀 자리잡기뿐, cell 내용은 각자 |
| Phase D 시각 iterate | 이번 사이클 통합 | 화면이 살아있어야 검토 가능 → 이슈 #3 한 PR 로 마무리 |
| Editor 진입 (`이걸로` / `빈 캔버스`) | v1 stub SnackBar | Editor 화면(F02-F06) 다음 사이클 |

---

## 2. 아키텍처

### 2-1. 디렉터리 구조

```
lib/
├── cores/
│   └── widgets/
│       └── grid_layout/
│           └── bsp_grid_layout.dart        # 신규 — BSP 트리 → Stack+Positioned 셀 자리잡기 primitive
├── features/
│   ├── canvas_picker/                      # 신규 — 비율 선택 화면
│   │   ├── canvas_picker_page.dart
│   │   └── widgets/
│   │       └── ratio_chip.dart
│   ├── photo_picker/                       # 신규 — 사진/영상 picker 화면
│   │   ├── photo_picker_page.dart
│   │   ├── providers/
│   │   │   ├── permission_provider.dart    # photo_manager 권한 상태
│   │   │   └── asset_paged_provider.dart   # asset 페이지네이션
│   │   └── widgets/
│   │       ├── asset_grid.dart
│   │       ├── asset_tile.dart             # 선택 순서 badge 포함
│   │       ├── permission_denied_view.dart
│   │       └── limited_info_bar.dart
│   ├── suggestion/                         # 신규 — 후보 PageView 화면
│   │   ├── suggestion_page.dart
│   │   ├── providers/
│   │   │   └── suggestion_notifier.dart    # SuggestionState + cursor pagination
│   │   └── widgets/
│   │       ├── suggestion_card.dart        # PageView 한 페이지 — BspGridLayout 사용
│   │       └── suggestion_cta_bar.dart     # 이걸로 / 다른 제안 / 빈 캔버스
│   └── home/
│       └── home_page.dart                  # 기존 — stub CTA 두 개를 실제 라우팅으로
├── routers/
│   ├── app_router.dart                     # 기존 — 3 라우트 추가
│   └── route_paths.dart                    # 기존 — canvasPicker / photoPicker / suggestion 추가
├── flow/                                   # 신규 — 흐름 공유 상태
│   └── flow_selection_provider.dart        # autoDispose: canvas + selectedMedia
└── features/dev/widgets/
    └── grid_template_preview.dart          # 기존 → BspGridLayout 사용하도록 리팩터

test/
├── cores/widgets/grid_layout/
│   └── bsp_grid_layout_test.dart
├── features/photo_picker/
│   ├── permission_provider_test.dart
│   └── photo_picker_page_test.dart         # 권한 분기 widget test
├── features/suggestion/
│   ├── suggestion_notifier_test.dart       # cursor pagination, error
│   └── suggestion_page_test.dart           # PageView smoke
└── flow/
    └── flow_selection_provider_test.dart
```

### 2-2. 의존성 추가

`pubspec.yaml`:
```yaml
dependencies:
  photo_manager: ^4.0.0      # AssetEntity, requestPermissionExtend, presentLimited
  url_launcher: ^6.3.2       # 이미 존재 — openAppSettings 용도 추가
```

### 2-3. 라우팅

`lib/routers/route_paths.dart` 추가:
```dart
static const String canvasPicker = '/canvas-picker';
static const String photoPicker  = '/photo-picker';
static const String suggestion   = '/suggestion';
```

`lib/routers/app_router.dart` 에 3 GoRoute 추가. 모두 `buildDirectionalSlide(isForward: true)` transition.

진입 흐름:
- `home → "사진·영상 고르기"` :
  1. `flowSelectionProvider` 의 canvas 를 `CanvasRatio.portrait916()` 으로 셋팅
  2. `context.push(RoutePaths.photoPicker)`
- `home → "비율 먼저 정하기"` :
  1. `context.push(RoutePaths.canvasPicker)`
  2. canvas-picker 에서 chip 선택 → `flowSelectionProvider.canvas` 셋팅 → "다음" 누르면 `context.push(RoutePaths.photoPicker)`
- `photoPicker → "다음"` (N>=2) :
  1. `flowSelectionProvider.media` 에 선택 미디어 셋팅
  2. `context.push(RoutePaths.suggestion)`

뒤로가기:
- 시스템 뒤로가기는 라우트 pop. flow state 는 라우트 ref 가 alive 한 동안 유지 → home 으로 돌아가면 모든 라우트 dispose → autoDispose 동작.

---

## 3. 흐름 상태 — `flowSelectionProvider`

```dart
@freezed
class FlowSelection with _$FlowSelection {
  const factory FlowSelection({
    required CanvasRatio canvas,
    @Default(<MediaItem>[]) List<MediaItem> media,
  }) = _FlowSelection;
}

@riverpod
class FlowSelectionNotifier extends _$FlowSelectionNotifier {
  @override
  FlowSelection build() => const FlowSelection(canvas: CanvasRatio.portrait916());

  void setCanvas(CanvasRatio ratio) =>
      state = state.copyWith(canvas: ratio);

  void setMedia(List<MediaItem> items) =>
      state = state.copyWith(media: items);

  void reset() => state = const FlowSelection(canvas: CanvasRatio.portrait916());
}
```

`autoDispose` 효과: `home` 에 돌아오면 `/canvas-picker`/`/photo-picker`/`/suggestion` 모두 dispose → notifier ref 0 → `build()` 재호출 시 초기 상태. 명시 reset 호출 불필요.

---

## 4. 화면별 설계

### 4-1. CanvasPicker 화면

```
┌─ AppBar (back arrow, "비율" 타이틀) ──┐
│ Padding 16                            │
│   "캔버스 비율"        Card Title 32 │
│   "어떤 비율로 만들까요?"  Body 16   │
│   xl 간격                             │
│   2x2 grid:                           │
│   ┌────────┐ ┌────────┐               │
│   │ shape  │ │ shape  │               │
│   │ 9:16   │ │ 1:1    │               │
│   │ Reels  │ │ Feed   │               │
│   └────────┘ └────────┘               │
│   ┌────────┐ ┌────────┐               │
│   │ 4:5    │ │ 16:9   │               │
│   └────────┘ └────────┘               │
│   xl 간격                             │
│ AppButton.primary("다음") ──────────  │
└──────────────────────────────────────┘
```

**위젯:** `_RatioChip(canvas, label, caption, selected)` — outlined card, 선택 시 border `charcoal40` + `shadowFocus`.
**상태:** 로컬 `_selected: CanvasRatio?`. "다음" 은 `_selected != null` 일 때만 활성. 누르면 `flowSelectionProvider.setCanvas(_selected!)` → push photoPicker.
**Custom 비율:** v1 제외. 안내문 없음 (UX 단순).

### 4-2. PhotoPicker 화면

```
┌─ AppBar (back arrow, "사진 고르기" + "선택 N/9") ─┐
│ [LimitedInfoBar — limited 모드일 때만]              │
│ AssetGrid (3-column, photo_manager paged)           │
│   각 tile: AspectRatio square + 선택 순서 badge     │
│                                                      │
│ Bottom bar:                                          │
│   "2장 이상 골라주세요" (N<2 일 때)                  │
│   AppButton.primary("다음") (N>=2 활성)              │
└──────────────────────────────────────────────────────┘
```

#### 4-2-1. 권한 흐름 (`permissionProvider`)

```dart
@riverpod
Future<PermissionState> photoPermission(PhotoPermissionRef ref) async {
  final ps = await PhotoManager.requestPermissionExtend();
  return PermissionState.from(ps);
}

enum PermissionState { authorized, limited, denied, restricted }
```

`photoPickerPage` build:
```
ref.watch(photoPermissionProvider).when(
  loading:  () => SizedBox.shrink(),  // 짧음, 인디케이터 없음
  error:    (_, __) => PermissionDeniedView(reason: 'unknown'),
  data: (s) => switch (s) {
    authorized || limited => AssetGrid(showLimitedInfoBar: s == limited),
    denied || restricted  => PermissionDeniedView(reason: s.name),
  },
);
```

#### 4-2-2. AssetGrid + 선택 모델

`asset_paged_provider.dart`:
- `PhotoManager.getAssetPathList(type: RequestType.common)` 으로 "Recent" album 가져옴
- `albumPath.getAssetListPaged(page: page, size: 60)` 페이지네이션 (60장씩 lazy)
- `Notifier<List<AssetEntity>>` + loadMore 메서드

`assetSelectionProvider`:
- `Notifier<List<AssetEntity>>` — 선택된 asset 들을 순서 보존
- `toggle(AssetEntity)` :
  - 이미 있음 → 제거 (이후 순서 재계산)
  - 없음 + N==9 → no-op + `AppSnackbar` (`icon_block.svg`, `"한 번에 9장까지 만들 수 있어요"`)
  - 없음 + AR>=10 또는 AR<=0.1 → no-op + `AppSnackbar` (`icon_block.svg`, `"이 사진은 비율이 너무 길어 빠졌어요"`)
  - 그 외 → append

`AssetTile` 위젯:
- `AssetEntityImage` thumbnail (256x256 cache)
- 선택 시 dim overlay (`charcoal40`) + 우상단 동그라미 badge (선택 순서 1~9, `AppTextStyles.caption_16` `offWhite`, charcoal 배경)

#### 4-2-3. Limited info bar

```
┌──────────────────────────────────────┐
│ 🔓 선택한 사진만 보여요. 더 보려면 ›│  ← 탭 시 PhotoManager.presentLimited()
└──────────────────────────────────────┘
```

배경 `charcoal04`, 텍스트 `charcoal82` body_16, 우측 chevron icon (Material `Icons.chevron_right`, `charcoal82`).

**v1 노출 시점:** 권한 상태가 `limited` 인 한 매번 표시 (메모리 단순, dismiss 상태 저장 X). v1.x 에서 dismiss 후 N분 보존 등 검토.

#### 4-2-4. PermissionDeniedView

전체 화면 감싸는 `Center(Column)`:
- icon_siren SVG (48pt)
- `"갤러리 접근이 막혀있어요"` cardTitle_32
- `"설정에서 사진 접근을 허용하면 시작할 수 있어요"` body_16 (charcoal82)
- `AppButton.primary("설정 열기")` → `url_launcher.openAppSettings()`
  - `restricted` 상태면 disabled (parental controls)

#### 4-2-5. AssetEntity → MediaItem 변환

`asset_to_media_item.dart`:
```dart
Future<MediaItem?> assetToMediaItem(AssetEntity a) async {
  final ar = a.width > 0 && a.height > 0 ? a.width / a.height : null;
  if (ar == null || !ar.isFinite || ar <= 0) return null;
  return MediaItem(
    id: a.id,
    type: a.type == AssetType.video ? MediaType.video : MediaType.photo,
    aspectRatio: ar,
    durationMs: a.type == AssetType.video ? a.videoDuration.inMilliseconds : null,
  );
}
```

"다음" 누름 → 선택 asset 들을 변환 → null 제외 → `flowSelectionProvider.setMedia(...)` → push suggestion.
변환 중 null 발생 시 사용자 노출 X (debugPrint). 이미 선택 시 검증을 통과했으므로 발생 거의 0.

### 4-3. Suggestion 화면

```
┌─ AppBar (back arrow, "제안") ───────┐
│ Padding 16 (header)                 │
│   "N개 후보" cardTitle_32           │
│   md 간격                           │
│ ─ Carousel (가로 풀브리드, padding 0) ─│
│   PageView viewportFraction 0.92    │
│     (양 옆 4% peek)                 │
│   ─ 각 page: SuggestionCard ─       │
│       BspGridLayout (canvas AR 적용)│
│       각 cell: lightCream placeholder│
│         + charcoal04 분할선         │
│   md 간격                           │
│ ─ Padding 16 (footer) ───────────── │
│   Dots indicator (현재 page on)     │
│   xl 간격                           │
│ ─ CTA bar ──────────────────────── │
│   AppButton.primary("이걸로")       │
│   sm 간격                           │
│   Row [outlined "다른 제안", outlined│
│        "빈 캔버스"]                 │
└─────────────────────────────────────┘
```

#### 4-3-1. SuggestionNotifier

```dart
@freezed
class SuggestionState with _$SuggestionState {
  const factory SuggestionState.empty() = _Empty;
  const factory SuggestionState.error(String message) = _Error;
  const factory SuggestionState.loaded({
    required List<MediaItem> media,
    required CanvasRatio canvas,
    required List<GridSuggestion> suggestions,
    required int selectedIndex,
    SuggestCursor? cursor,
  }) = _Loaded;
}

@riverpod
class SuggestionNotifier extends _$SuggestionNotifier {
  @override
  SuggestionState build() {
    final flow = ref.watch(flowSelectionProvider);
    if (flow.media.length < 2) {
      return const SuggestionState.empty();
    }
    try {
      final r = suggest(media: flow.media, canvas: flow.canvas);
      return SuggestionState.loaded(
        media: flow.media,
        canvas: flow.canvas,
        suggestions: r.suggestions,
        selectedIndex: 0,
        cursor: r.nextCursor,
      );
    } on ArgumentError catch (e) {
      return SuggestionState.error(e.message?.toString() ?? '입력 검증 실패');
    }
  }

  void selectIndex(int i) {
    final s = state;
    if (s is! _Loaded) return;
    state = s.copyWith(selectedIndex: i);
  }

  void loadMore() {
    final s = state;
    if (s is! _Loaded) return;
    if (s.cursor == null) return; // 풀 소진
    try {
      final r = suggest(media: s.media, canvas: s.canvas, cursor: s.cursor!);
      state = s.copyWith(
        suggestions: [...s.suggestions, ...r.suggestions],
        cursor: r.nextCursor,
      );
    } on ArgumentError {
      // 발생 거의 0 — 호출부에서 SnackBar
      rethrow;
    }
  }
}
```

#### 4-3-2. PageView + Edge peek (인스타 캐러셀 식)

```dart
PageController(viewportFraction: 0.92, initialPage: 0)
```

PageView 자체는 화면 좌우 가장자리까지 풀브리드(외곽 horizontal padding 없음).
헤더 ("N개 후보") / dots / CTA bar 만 `EdgeInsets.symmetric(horizontal: AppSpacing.base)` 유지.

Page change 시 `notifier.selectIndex(newIndex)`. CTA "이걸로" 는 `s.suggestions[s.selectedIndex]` 를 stub SnackBar 로 표시 (Editor 미구현):
- `AppSnackbar.show(context, message: '에디터는 곧 준비됩니다', iconPath: 'assets/icons/icon_copy.svg')`

#### 4-3-3. CTA bar

| 버튼 | 동작 |
|---|---|
| **이걸로** | stub SnackBar (info copy icon) — Editor 다음 사이클 |
| **다른 제안** | `cursor==null` 이면 disabled. 활성 시 `loadMore()` → `PageController.animateToPage` 새 batch 첫 카드로 이동 |
| **빈 캔버스** | stub SnackBar (info copy icon) — Editor 미구현 |

cursor 소진(4 batch limit) 시 "다른 제안" disabled. PRD §9-2-1 step 5 의 "최대 4 batch" 한도가 알고리즘 모듈에서 이미 enforce 됨 (`_kMaxBatchCount`).

---

## 5. `BspGridLayout` primitive (`cores/widgets/grid_layout/`)

```dart
typedef BspCellBuilder = Widget Function(int cellId, Rect normalizedBBox);

class BspGridLayout extends StatelessWidget {
  const BspGridLayout({
    super.key,
    required this.tree,
    required this.aspectRatio,   // canvas value
    required this.cellBuilder,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.borderColor,            // null 이면 border 없음
  });

  final GridNode tree;
  final double aspectRatio;
  final BspCellBuilder cellBuilder;
  final BorderRadius borderRadius;
  final Color? borderColor;
}
```

내부:
1. `cellBBoxes(tree)` → `Map<int, CellRect>` (정규화 0..1)
2. `AspectRatio(aspectRatio, ...)` 컨테이너
3. `LayoutBuilder` → `Stack` + `Positioned.fromRect`
4. 각 cell 위치에 `cellBuilder(cellId, normalizedRect)` 호출

호출 예:
- Dev gallery: cellBuilder = `(id, _) => _CellTile(cellId: id)` (cellId 텍스트 + charcoal04 배경)
- Suggestion v1: cellBuilder = `(_, __) => _PlaceholderCell()` (lightCream 배경 + charcoal04 border)
- Suggestion v1.x (사진 매핑): cellBuilder = `(id, _) => _MappedThumb(asset: mapping[id])` (썸네일)

`GridTemplatePreview` (dev) 는 `BspGridLayout` 위 얇은 wrapper 로 리팩터.

---

## 6. 권한·에러·로딩 정책 (질문 5 결정 명세)

### 6-1. 권한 상태별 동작

picker 진입 → `PhotoManager.requestPermissionExtend()` 호출 (시스템 dialog 미결정 시 자동 표시).
콜백 결과를 `PermissionState` (4 값) 로 매핑:

| 상태 | 동작 |
|---|---|
| `authorized` | 정상 진행 |
| `limited` | 정상 진행 + LimitedInfoBar 표시 |
| `denied` | PermissionDeniedView ("설정 열기" CTA 활성) |
| `restricted` | PermissionDeniedView ("설정 열기" disabled) |

호출 미해결 동안은 `AsyncValue.loading` — 화면은 짧은 빈 영역 (인디케이터 없음, 보통 < 100ms).

### 6-2. 에러 — `AppSnackbar` 매핑

| 발생 | 메시지 | iconPath |
|---|---|---|
| picker N=10 시도 | "한 번에 9장까지 만들 수 있어요" | `icon_block.svg` |
| AR 비정상 asset 선택 | "이 사진은 비율이 너무 길어 빠졌어요" | `icon_block.svg` |
| `suggest()` `ArgumentError` (만에 하나) | `"이 조합으론 제안을 만들 수 없어요"` | `icon_siren.svg` |
| 메타 추출 실패 | 노출 X (debugPrint) | — |
| `이걸로` / `빈 캔버스` (Editor stub) | `"에디터는 곧 준비됩니다"` | `icon_copy.svg` |

### 6-3. 빈 상태

- 갤러리 사진 0장 → AssetGrid 자리에 안내 텍스트 + 취소 (back) 안내
- N=0 선택 상태 → "다음" disabled

### 6-4. 로딩

- picker 진입 (`getAssetListPaged` ~50ms) → 그리드 placeholder (회색 박스)
- suggestion 진입 (`suggest()` ~225ms 테스트러너 / 실기기 더 빠름) → 인디케이터 표시 X (200ms 이하 깜빡임 방지)
- "다른 제안" pagination → 즉시 append, 인디케이터 X

### 6-5. iOS Info.plist + Android manifest

iOS (`ios/Runner/Info.plist`):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>고른 사진으로 자동 그리드 레이아웃을 제안하기 위해 갤러리에 접근합니다.</string>
```

Android (`android/app/src/main/AndroidManifest.xml`) — `photo_manager` README 가이드:
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
```

---

## 7. Phase D 시각 iterate (이번 사이클 통합)

작업 순서 (구현 phase 마지막 단계):
1. picker/suggestion 흐름 동작 → 실제 사진 4~9장 골라 매핑 결과 시각 검토
2. ugly templates 발견 (예: cell aspect 가 어색해 사진이 잘림) → `templates/_n{N}_templates.dart` 의 해당 entry 교체
3. `templates_test.dart` 의 8 invariant 통과 확인
4. `suggester_test.dart` 의 골든 8개 갱신 (의도적 업데이트)
5. perf 측정 (실기기) — `suggest()` < 100ms 기대

판단 기준 (ugly):
- 셀 AR 이 1:3 이상 극단적
- 9분할 시 cell 높이 < 80pt 또는 너비 < 60pt 인 균등 그리드
- 좌큰우작은 패턴에서 좌측 비중 < 50%

iterate 횟수가 많아질 위험은 v1 수용 — 최대 4시간 cap, 그 이상이면 별도 이슈로 cut.

---

## 8. 테스트 전략

### 8-1. 단위 / Provider 테스트

| 파일 | 검증 |
|---|---|
| `bsp_grid_layout_test.dart` | 1+2 / 2x2 / 1+3 트리에 대해 `cellBuilder` 호출 횟수, normalizedBBox 정합 |
| `flow_selection_provider_test.dart` | initial state, setCanvas, setMedia, autoDispose 후 reset 확인 |
| `permission_provider_test.dart` | 5상태 매핑 (mock `PhotoManager.requestPermissionExtend`) |
| `suggestion_notifier_test.dart` | empty/loaded/error 분기, selectIndex, loadMore (cursor 진행), 4 batch 한도 |

### 8-2. Widget 테스트

| 파일 | 검증 |
|---|---|
| `canvas_picker_page_test.dart` | 4 chip 렌더, 선택 시 "다음" 활성, 누름 시 setCanvas 호출 |
| `photo_picker_page_test.dart` | 권한 분기 (authorized → grid, denied → DeniedView), N>=2 시 "다음" 활성 |
| `suggestion_page_test.dart` | empty 상태 → "다음" 화면 fallback / loaded → PageView 카드 N개, 다른 제안 누름 시 loadMore |

### 8-3. 통합 테스트

`integration_test/flow_test.dart`:
- home → "비율 먼저" → 9:16 선택 → picker mock asset 4개 선택 → suggestion 진입 → 후보 N개 표시 확인

photo_manager 의 시스템 권한 dialog 는 통합 테스트에서 mock — `PhotoManager.requestPermissionExtend` 를 wrap 하는 `permissionProvider` 를 override.

### 8-4. 커버리지

`~/.claude/rules/testing.md` 의 80% 기준. provider 와 변환 함수는 90%+ 자연 도달, 화면 widget 은 핵심 분기만 커버.

### 8-5. dev gallery 회귀

`GridTemplatePreview` 가 `BspGridLayout` 으로 리팩터되어도 `/dev` 갤러리 시각이 동일해야 함. 기존 widget smoke test 1개 유지 (`feedback_dev_gallery_purpose.md` 정책 — minimal smoke).

---

## 9. 디자인 시스템 정합 체크리스트

- [ ] 모든 색상은 `AppColors.*`
- [ ] 모든 간격/패딩은 `AppSpacing.*` (raw `EdgeInsets.all(16)` 금지)
- [ ] 모든 텍스트는 `AppTextStyles.*` (raw `TextStyle(fontSize:...)` 금지)
- [ ] `fontSize` 16 배수 유지 (.sp 자동 적용)
- [ ] 픽셀 폰트 weight w400 고정, letterSpacing 0
- [ ] `Color(0xFF...)` 직접 사용 금지
- [ ] `AppButton.primary` / `AppButton.outlined` / `AppIconButton` 만 사용 (raw `ElevatedButton` 금지)
- [ ] `AppSnackbar.show` 만 사용 (Material `SnackBar` 직접 호출 금지)
- [ ] dev gallery 위젯 테스트는 minimal smoke 만 (memory `feedback_dev_gallery_purpose.md`)

---

## 10. 작업 분량 추정

| Phase | 분량 | 비고 |
| --- | --- | --- |
| P1. 의존성 + 라우팅 + flow state | ~2h | photo_manager pub get, route_paths, app_router, flowSelectionProvider |
| P2. BspGridLayout primitive + dev 리팩터 | ~2h | 신규 + GridTemplatePreview 리팩터 + 회귀 smoke |
| P3. CanvasPicker 화면 | ~2h | 4 chip + "다음" + 위젯 test |
| P4. PhotoPicker — 권한 | ~3h | permissionProvider, DeniedView, LimitedInfoBar, iOS/Android 매니페스트 |
| P5. PhotoPicker — AssetGrid + 선택 | ~4h | paged provider, AssetTile, selection model, AR 검증, AppSnackbar |
| P6. Suggestion — Notifier | ~2h | SuggestionState, build, selectIndex, loadMore, 테스트 |
| P7. Suggestion — PageView + Peek + CTA | ~3h | viewportFraction, dots, "이걸로/다른 제안/빈 캔버스" |
| P8. 통합 — home CTA 연결 + 통합 테스트 | ~2h | home stub 교체, integration_test/flow_test |
| P9. Phase D 시각 iterate | ~3h (cap 4h) | 실제 사진 매핑 검토, ugly 교체, 골든 갱신 |
| **합계** | **~23h** | |

각 phase 가 독립 PR 가능하지만 이슈 #3 한 PR 권장 (3 화면 + 라우팅이 하나의 시각 단위).

plan 단계에서 phase 분리 권장:
- **Phase A** — P1, P2 (~4h) : 인프라 + primitive
- **Phase B** — P3, P4, P5 (~9h) : CanvasPicker + PhotoPicker
- **Phase C** — P6, P7, P8 (~7h) : Suggestion + 흐름 연결
- **Phase D** — P9 (~3h cap 4h) : 시각 iterate

A 머지 → B → C → D 순서. A/B/C 사이 main rebase 가능.

---

## 11. Forward-compatibility (다음 사이클 받침대)

| 미래 작업 | 이 spec 의 받침대 |
| --- | --- |
| Editor 화면 (F02-F06) | `flowSelectionProvider.media` + `suggestion.suggestions[selectedIndex]` 가 그대로 Editor 초기 상태로 흐름 |
| 사진 썸네일 매핑 (v1.x) ✓ | 구현 완료 — `BspGridLayout.cellBuilder` 를 `_MappedThumb` 로 swap, `selectedAssetsProvider` 도입, PageView preload. 자세한 설계: [`2026-04-27-mapped-thumb-design.md`](./2026-04-27-mapped-thumb-design.md) |
| F07 영상 자동 싱크 | `MediaItem.durationMs` 가 이미 변환에서 채워짐. `suggest(weightOf:...)` 인자만 채우면 알고리즘 재진입 |
| F11 되돌리기/다시하기 | flow state 가 Riverpod Notifier — history stack push/pop 자연 |
| F16 "내 템플릿" | dev gallery + suggestion 둘 다 `BspGridLayout` 사용 → 사용자 정의 NamedTemplate 시각화 즉시 |
| 비율 프리셋 추가 | `CanvasRatio` sealed class 에 factory 추가 + canvas-picker chip 1개 추가 |

---

## 12. Open Questions (구현 단계 결정)

- **AssetEntity → MediaItem 변환 시 EXIF orientation** — `photo_manager` 가 자동 보정해주는지 측정 필요. 안 하면 변환 함수에 orientation rotate 분기 추가.
- ~~**PageView + Peek viewportFraction 0.7 vs 0.75 vs 0.8** — 픽셀 수 시뮬 필요. 일단 0.7 로 시작, Phase D 검토 시 조정.~~ → **결정**: viewportFraction 0.92 + carousel 가로 풀브리드 (인스타 캐러셀 식). 0.7 은 시각 검토 결과 카드가 좁아 분할 패턴이 잘 안 보였음.
- **AssetTile thumbnail cache size** — 256x256 기본, 화면 dpr 에 따라 384/512 도 검토.
