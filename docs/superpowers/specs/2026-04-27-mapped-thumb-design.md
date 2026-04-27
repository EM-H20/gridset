# Suggestion 사진 썸네일 매핑 (`_MappedThumb`) — Design Spec

**Date:** 2026-04-27
**Scope:** Suggestion 화면 (`SuggestionCard`) 의 셀 빌더를 `_PlaceholderCell` 에서 `_MappedThumb` 로 교체. `GridSuggestion.mediaByCellId` (cellId → MediaItem.id) 매핑을 실제 사진/영상 첫 프레임 썸네일로 시각화. PRD §F00 자동 레이아웃 제안의 "후보 비교" 단계가 의미를 갖도록 만든다.
**Constraint:** 온디바이스. 외부 호출 없음. `photo_manager` / `photo_manager_image_provider` 만 사용. 코어 (`lib/cores/grid_suggestor/`) 의존성 변동 없음 — 본 작업은 `features/suggestion/` 한정.
**Source:** `docs/PRD.md` §F00, §9-2-4 (편집 0). `.issues/20260427_기능추가_Suggestion_사진_썸네일_매핑.md`.
**Depends on:** `docs/superpowers/specs/2026-04-27-suggestion-flow-design.md` (Suggestion 화면 골격 — main 머지 완료).
**Consumed by (post-spec):** Phase D 큐레이션 시각 iterate (별 PR), F08 PNG 저장 (Editor sprint), F06 셀 내 미디어 조작 (Editor sprint), F07 영상 자동 싱크 (별 sprint).

---

## 1. 결정 요약

| # | 항목 | 결정 | 근거 |
|---|---|---|---|
| 1 | AssetEntity 입수 경로 | 신규 `selectedAssetsProvider` (keepAlive: true). picker `_onNext` 가 `setMedia` 와 페어로 `setAssets` 호출 | flow 의 도메인은 "알고리즘 입력 (MediaItem)", assets 는 "렌더링 자원" — 분리. cores/flow 가 photo_manager 에 직접 의존하지 않음 |
| 2 | fit 모드 | `BoxFit.cover` 고정 | "편집 0" 철학과 인스타 그리드 인상. cell ↔ media AR 차이는 알고리즘이 최소화하므로 잘림은 통상 작음. F06 진입 시 사용자가 변경 |
| 3 | 썸네일 사이즈 | `ThumbnailSize.square(512)` 고정 | N=2 split 셀(화면 절반 ≈ 585px) 도 또렷. 9셀 × 3카드 ≈ 27MB cap. 본 화면은 미리보기라 저장 화질과 무관 — F08 의 RepaintBoundary pixelRatio 정책은 별 spec |
| 4 | 영상 셀 표시 | 첫 프레임 still + 우상단 16px ▶ 인디케이터 | `AssetEntityImage` / `thumbnailDataWithSize` 가 video 에 대해 native first-frame 반환. 인디케이터는 인스타·갤러리 표준 패턴 |
| 5 | preload 범위 | `PageView.allowImplicitScrolling: true` (인접 1장) | swipe 직후 빈 셀 깜빡임 제거. 메모리 영향 미미 (9셀 × 1장 추가) |
| 6 | 매핑 실패 fallback | `_PlaceholderCell` 톤 그대로 + `debugPrint` 한 줄 | 권한 limited 자동 변경처럼 사용자 책임 외 케이스가 다수 — 위협 톤 부적절. picker 미선택 셀 톤과 일관 |
| 7 | Phase D 큐레이션 시각 iterate | **본 PR 비포함**, 후속 PR 로 분리 | UI 코드 변경과 큐레이션(template entry + 골든) 변경의 의도 분리. 시각 판단 round-trip 으로 본 PR 머지 지연 방지 |
| 8 | 단위 테스트 모킹 | `ThumbnailLoader` 추상 어댑터 + `FakeThumbnailLoader` 주입 | `assetToMediaItem` 어댑터 패턴과 일관. photo_manager 네이티브 의존을 1점에 격리 |
| 9 | spec 위치 | 본 파일 (`2026-04-27-mapped-thumb-design.md`). 기존 `suggestion-flow-design.md` §"GridTemplatePreview 승격" 표 v1.x 행은 구현 PR 시점에 cross-link 갱신 | brainstorming skill 의 `YYYY-MM-DD-<topic>-design.md` 패턴. 후속 (Phase D / F06 / F08) 도 토픽별 spec 으로 독립 |

---

## 2. 아키텍처

### 2-1. 컴포넌트 트리

```
photo_picker route (기존)
└─ _onNext()
   ├─ flowSelectionProvider.setMedia(items: List<MediaItem>)   (기존)
   └─ selectedAssetsProvider.setAssets(items: List<AssetEntity>)  ← 신규

suggestion route
└─ SuggestionPage
   ├─ ref.watch(suggestionNotifierProvider)         (기존)
   ├─ ref.watch(selectedAssetsProvider)             (신규)
   └─ PageView.builder(allowImplicitScrolling: true, ...)
      └─ SuggestionCard(suggestion, canvas, assetsById)
         └─ BspGridLayout(
              cellBuilder: (cellId, _) => _MappedThumb(
                cellId: cellId,
                mediaByCellId: suggestion.mediaByCellId,
                assetsById: assetsById,
              ))
```

### 2-2. 책임 분리

| 레이어 | 책임 | 비책임 |
|---|---|---|
| `selectedAssetsProvider` | id → AssetEntity Map 보존 (picker 라우트 떠난 후에도) | 알고리즘 입력 변환 (= flow 의 책임) |
| `SuggestionCard` | suggestion + assetsById prop 받아 BspGridLayout 에 cellBuilder 위임 | 비동기 로드 / 실패 분기 (`_MappedThumb` 안쪽) |
| `_MappedThumb` | cellId 에서 asset 해석 + 비동기 로드 + 3분기 (성공/실패/대기) | 셀 위치/크기 (= `BspGridLayout` 책임) |
| `ThumbnailLoader` | photo_manager API 1점 격리 | 캐싱 정책 (현재는 photo_manager 자체 캐시 의존) |

### 2-3. 의존성 흐름

```
features/suggestion ──depends──▶ cores/grid_suggestor (배럴, 기존)
features/suggestion ──depends──▶ photo_manager (신규 / suggestion 영역 한정)
features/photo_picker ──depends──▶ flow + suggestion.providers.selected_assets  (신규)
flow/, cores/grid_suggestor/ ──┃ photo_manager 의존성 0 유지 (기존 정책 보존)
```

---

## 3. 데이터 흐름

```
[picker] AssetSelectionNotifier (List<AssetEntity>, keepAlive: false)
              │ _onNext()
              ▼
        +─── 분기 (페어 호출) ───+
        ▼                       ▼
flowSelectionProvider     selectedAssetsProvider          ← 신규
  setMedia(items)            setAssets(items)
  (List<MediaItem>)          (Map<String, AssetEntity>)
        │                       │
        ▼                       ▼
[suggestion route 로 push]
              │
              ▼
suggestionNotifier (suggest 호출)
  → suggestions[i].mediaByCellId  (cellId → assetId)
              │
              ▼
SuggestionPage build
  ─ assetsById = ref.watch(selectedAssetsProvider)
  ─ each card → cellBuilder(cellId)
    └─ _MappedThumb 가
       1) assetId = mediaByCellId[cellId]                      (sync)
       2) asset   = assetsById[assetId]                        (sync)
       3) loader.load(asset, ThumbnailSize.square(512))        (async)
       4) Image.memory(bytes, fit: cover) + ▶ if video         (sync)
```

### 3-1. 페어 호출 보장

`setMedia` 와 `setAssets` 둘 중 하나만 호출되는 경우 (예: 미래 코드 변경) 본 화면이 silent 실패 (모든 셀 placeholder). 이를 막기 위해:

- picker `_onNext` 에서 두 호출을 **순서 고정** 으로 묶음 (`setMedia` → `setAssets`).
- 단위 테스트로 페어 호출 contract 검증 (`photo_picker_page_test.dart` 확장).
- 향후 `setMedia` 만 호출하는 경로가 추가될 가능성을 차단하기 위해 spec §6 비범위에 "MediaItem ↔ AssetEntity 페어 깨지는 변경 금지" 명시.

### 3-2. `selectedAssetsProvider` 시그니처

```dart
@Riverpod(keepAlive: true)
class SelectedAssetsNotifier extends _$SelectedAssetsNotifier {
  @override
  Map<String, AssetEntity> build() => const {};

  /// id → AssetEntity 맵으로 변환해 보존. List 의 순서는 알고리즘 입력 (flow.media)
  /// 에서만 의미 있고 본 provider 는 lookup 용이므로 Map 으로 정규화.
  void setAssets(List<AssetEntity> items) =>
      state = Map.unmodifiable({for (final a in items) a.id: a});
}
```

`keepAlive: true` 근거: `flowSelectionProvider` 와 동일한 라이프사이클. picker → suggestion 라우트 전환 사이의 microtask 동안 state 가 살아있어야 함 (`flow_selection_provider.dart` 가 같은 이유로 keepAlive 적용).

---

## 4. `_MappedThumb` 명세

### 4-1. 인터페이스

`_MappedThumb` 는 **`ConsumerStatefulWidget`** 으로 만든다. 이유: `FutureBuilder` 가 매 rebuild 시 새 Future 를 받으면 한 프레임 `waiting` 으로 떨어져 깜빡임 발생 (PageView preload + `gaplessPlayback` 으로도 차단 안 됨). State 안에서 future 를 1회만 시작하고 의존 입력이 바뀔 때만 재생성한다.

```dart
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
  late Future<Uint8List?>? _future;
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
    if (prevId != nextId || old.assetsById[prevId] != widget.assetsById[nextId]) {
      _resolveAndLoad();
    }
  }

  void _resolveAndLoad() {
    final assetId = widget.mediaByCellId[widget.cellId];
    final asset = assetId == null ? null : widget.assetsById[assetId];
    _asset = asset;
    _future = asset == null
        ? null
        : ref
            .read(thumbnailLoaderProvider)
            .load(asset, size: const ThumbnailSize.square(512));
  }
}
```

### 4-2. 빌드 분기

| 분기 | 조건 | 결과 |
|---|---|---|
| ① 계약 위반 | `mediaByCellId[cellId] == null` | `_PlaceholderCell` + `assert` (debug) + `debugPrint` |
| ② asset 사라짐 | `assetsById[assetId] == null` | `_PlaceholderCell` + `debugPrint('⚠️ asset 누락 cellId=$cellId id=$assetId')` |
| ③ 로딩 중 | `FutureBuilder` `ConnectionState.waiting` | `_PlaceholderCell` (인디케이터 0 — 깜빡임 방지) |
| ④ 로드 실패 | `snapshot.hasError` 또는 `snapshot.data == null` | `_PlaceholderCell` + `debugPrint('⚠️ thumb load 실패 cellId=$cellId asset=$assetId err=$err')` |
| ⑤ 성공 사진 | data 있음 + `asset.type == AssetType.image` | `Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)` |
| ⑥ 성공 영상 | data 있음 + `asset.type == AssetType.video` | ⑤ + 우상단 ▶ overlay |

`gaplessPlayback: true` — 같은 위젯이 다른 byte 로 rebuild 될 때 한 프레임 빈 화면 방지 (PageView preload 와 시너지).

### 4-3. Future 라이프사이클

`_MappedThumb` 는 stateful (§4-1) 로 future 를 **State 가 보유**. 호출 시점:

| 시점 | 동작 |
|---|---|
| `initState` | `_resolveAndLoad()` 1회 호출 → `_future` 채움 |
| `didUpdateWidget` | `(cellId, mediaByCellId, assetsById)` 가 결정하는 asset 동일성 비교. 다르면 재로드, 같으면 보존 |
| `build` | 보유한 `_future` 를 `FutureBuilder.future` 로 그대로 전달. rebuild 가 일어나도 future 객체가 유지되어 `FutureBuilder` 가 waiting 으로 떨어지지 않음 |

PageView preload (인접 카드 build) → `_MappedThumb.initState` → loader 호출 → 사용자가 swipe 도달 시점에는 photo_manager 캐시에 byte 적재 완료. 검증: `FakeThumbnailLoader.callCount` 가 동일 (cellId, asset) 조합에 대해 위젯 lifecycle 동안 정확히 1회 (asset 변경 없는 경우).

---

## 5. `ThumbnailLoader` 어댑터

### 5-1. 인터페이스

```dart
abstract class ThumbnailLoader {
  Future<Uint8List?> load(AssetEntity asset, {required ThumbnailSize size});
}
```

### 5-2. 프로덕션 구현

```dart
class PhotoManagerThumbnailLoader implements ThumbnailLoader {
  const PhotoManagerThumbnailLoader();
  @override
  Future<Uint8List?> load(AssetEntity asset, {required ThumbnailSize size}) =>
      asset.thumbnailDataWithSize(size);
}

@Riverpod(keepAlive: true)
ThumbnailLoader thumbnailLoader(Ref ref) =>
    const PhotoManagerThumbnailLoader();
```

### 5-3. 테스트 fake

```dart
class FakeThumbnailLoader implements ThumbnailLoader {
  FakeThumbnailLoader({this.bytesById = const {}, this.failIds = const {}});
  final Map<String, Uint8List> bytesById;  // asset.id → bytes
  final Set<String> failIds;
  int callCount = 0;

  @override
  Future<Uint8List?> load(AssetEntity asset, {required ThumbnailSize size}) async {
    callCount += 1;
    if (failIds.contains(asset.id)) return null;
    return bytesById[asset.id];
  }
}
```

테스트는 `thumbnailLoaderProvider.overrideWith((_) => fake)` 로 주입.

---

## 6. 영상 ▶ 인디케이터

| 항목 | 값 |
|---|---|
| 위치 | 셀 우상단 |
| 인셋 | 8px (모든 방향) |
| 아이콘 사이즈 | 16px (앱 16배수 그리드 준수) |
| 아이콘 자산 | `assets/icons/icon_play.svg` (없으면 신규 추가) |
| 아이콘 색 | `AppColors.offWhite` |
| 배경 | `AppColors.charcoal40` 24px 원형 (Container shape: circle) |
| 분기 | `asset.type == AssetType.video` 만 표시 |
| 텍스트 | 없음 (duration 텍스트는 F07 sprint 에서 결정) |

---

## 7. PageView preload + fit (`suggestion_page.dart` 변경)

기존:
```dart
PageView.builder(
  controller: controller,
  onPageChanged: onPageChanged,
  itemCount: state.suggestions.length,
  itemBuilder: ...,
)
```

변경:
```dart
PageView.builder(
  controller: controller,
  allowImplicitScrolling: true,   // ← 신규: 인접 1장 preload
  onPageChanged: onPageChanged,
  itemCount: state.suggestions.length,
  itemBuilder: ...,
)
```

`allowImplicitScrolling: true` 는 PageView 의 `cacheExtent` 를 viewport 1장만큼 확장 → `_MappedThumb` 의 `FutureBuilder` 가 인접 카드에서도 미리 시작 → photo_manager 캐시에 byte 적재 → swipe 시 ⑤/⑥ 분기로 즉시 진입.

---

## 8. 에러 / fallback 매트릭스

| 케이스 | 발생 빈도 | 시각 | 로그 |
|---|---|---|---|
| `mediaByCellId[cellId] == null` | 거의 0 (알고리즘 계약) | placeholder | `assert` (debug) + `debugPrint` |
| `assetsById[id] == null` | 권한 limited 변경 / asset 삭제 | placeholder | `debugPrint` |
| `thumbnailDataWithSize == null` | 코덱 / IO 실패 | placeholder | `debugPrint` |
| 로딩 중 (`waiting`) | 정상 | placeholder (인디케이터 0) | 0 |

PRD §F00 "편집 0" 컨셉상 어떤 실패도 사용자에게 위협 톤 노출 X. placeholder 톤은 picker 미선택 셀 / 카드 로딩 직후 톤과 동일.

---

## 9. 테스트 단위

| Layer | 대상 | 검증 |
|---|---|---|
| **Unit** | `SelectedAssetsNotifier` | (a) `setAssets` 후 unmodifiable map (b) id key 정합성 (c) 빈 리스트 → 빈 map (d) 중복 id → 후입력 우선 |
| **Widget** | `_MappedThumb` (Fake 주입) | (a) 정상 매핑 → `Image` 노드 1개, fit cover (b) `assetsById` 누락 → placeholder 톤 (c) loader 가 null → placeholder + debugPrint (d) 영상 자산 → ▶ icon finder 발견 (e) 위젯 lifecycle 중 임의 횟수 rebuild 후에도 동일 (cellId, asset) 에 대한 `FakeThumbnailLoader.callCount == 1` (f) `mediaByCellId` 가 다른 asset 으로 바뀌면 callCount 가 1 → 2 로 증가 |
| **Widget** | `SuggestionCard` | mediaByCellId 매핑 셀 개수 = `_MappedThumb` 또는 fallback 렌더 개수 |
| **Provider** | `photo_picker._onNext` 페어 호출 | `setMedia` 후 `selectedAssetsProvider` 도 채워졌는지 (`photo_picker_page_test.dart` 확장) |

골든 테스트는 본 PR 범위 밖 — Phase D 후속 PR 에서 갱신.

---

## 10. 변경 영향 파일

### 신규
- `lib/features/suggestion/widgets/mapped_thumb.dart` (private 위젯) 또는 `suggestion_card.dart` 내 `_MappedThumb` 로 inline. (한 화면 한정 위젯이라 inline 권장)
- `lib/features/suggestion/providers/selected_assets_provider.dart` + `.g.dart` (codegen)
- `lib/features/suggestion/providers/thumbnail_loader.dart` + `.g.dart` (인터페이스 + photo_manager 구현 + Riverpod provider)
- `assets/icons/icon_play.svg` (없을 경우)
- `test/features/suggestion/widgets/mapped_thumb_test.dart`
- `test/features/suggestion/providers/selected_assets_provider_test.dart`

### 수정
- `lib/features/suggestion/widgets/suggestion_card.dart` — `cellBuilder` 를 `_MappedThumb` 로 교체. `_PlaceholderCell` 은 fallback 용 private 유지. 인자에 `assetsById` 추가.
- `lib/features/suggestion/suggestion_page.dart` — `PageView.builder(allowImplicitScrolling: true, ...)` + `selectedAssetsProvider` watch + `SuggestionCard` 에 `assetsById` prop 전달.
- `lib/features/photo_picker/photo_picker_page.dart` — `_onNext` 에 `selectedAssetsProvider.setAssets(assets)` 페어 호출 추가.
- `pubspec.yaml` — `assets/icons/icon_play.svg` 등록 (디렉터리 등록만 돼있으면 불필요).
- `test/features/suggestion/suggestion_card_test.dart` — `_MappedThumb` 분기 검증으로 일부 기존 케이스 갱신 (placeholder 가정 → mapped 가정).
- `test/features/photo_picker/photo_picker_page_test.dart` — `_onNext` 후 selectedAssetsProvider 채워졌는지 검증.

### Spec
- `docs/superpowers/specs/2026-04-27-suggestion-flow-design.md` §"GridTemplatePreview 승격" 표 v1.x 행 = 완료 ✓ + 본 spec 으로 cross-link. (구현 PR 시점에 함께 갱신)

---

## 11. 비범위 (Out of Scope)

- ❌ Phase D 큐레이션 시각 iterate — 별 PR (이슈 본문 §검토 변수 §"Phase D 결정 프로세스" = "별도 후속 PR")
- ❌ 셀 내 미디어 조작 / pinch-zoom / long-press — F06, Editor sprint
- ❌ 영상 재생 / 자동 싱크 / 길이 조정 — F07, 별 sprint (PRD §9-2-4 "편집 0")
- ❌ PNG 저장 — F08, Editor sprint (저장 화질은 Editor 셀 ImageProvider 해상도 ↔ `RepaintBoundary.pixelRatio` 매칭으로 결정 — 본 spec 의 썸네일 사이즈와 무관)
- ❌ "다른 제안 보기" loadMore 시 신규 카드의 별도 preload 정책 — 동일 정책 자연 적용
- ❌ photo_manager 자체 캐시 외 추가 LRU 캐시 — 필요 시 후속 spec
- ❌ MediaItem ↔ AssetEntity 페어 깨지는 setMedia/setAssets 단독 호출 경로 추가 — 명시 금지

---

## 12. 후속 hooks

| 후속 작업 | 본 spec 의 어떤 부분이 영향받나 |
|---|---|
| Phase D 큐레이션 시각 iterate | template entry 교체로 `mediaByCellId` 분포가 달라짐. `_MappedThumb` 자체는 무관. 영향 받는 골든은 후속 PR 에서 의도적 갱신 |
| F06 셀 내 미디어 조작 (Editor) | `_MappedThumb` 시그니처에 `CellTransform?` 추가 가능성. Suggestion 화면은 transform 0 (기본 cover). Editor 의 셀 위젯은 `_MappedThumb` 와 별 위젯이 될 가능성 큼 (long-press / GestureDetector 책임) |
| F07 영상 자동 싱크 | ▶ 인디케이터 옆에 duration 텍스트 추가 가능성 (PRD §9-2-4 의 T_min cap 노출). 본 spec §6 의 "텍스트 없음" 결정을 그때 재검토 |
| F08 PNG 저장 | Editor 셀 ImageProvider 해상도 ↔ `RepaintBoundary.pixelRatio` 매칭이 별 spec 으로 결정. 본 spec 의 썸네일 사이즈(512) 와 무관 |
