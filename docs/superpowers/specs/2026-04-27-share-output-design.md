# 자동 제안 결과 share-first 출력 (PNG / MP4) — Design Spec

**Date:** 2026-04-27
**Scope:** Suggestion 화면의 "이걸로" CTA 가 SnackBar stub 인 상태를 종결. 사용자가 선택한 후보 카드를 1080 long edge PNG (사진만) 또는 MP4 (영상 셀 1개 이상) 로 합성한 뒤 OS share 시트 (`share_plus`) 로 노출. 카톡 / 인스타 / 사진 저장 / AirDrop / 기타 share extension 으로 사용자가 직접 분기. PRD §F08 (PNG 저장) + §F09 (MP4 저장) + §F07 (영상 자동 싱크 default 트림) 을 한 sprint 에 통합.
**Constraint:** 온디바이스. 외부 호출 없음. ffmpeg_kit_flutter_new (네이티브) 의존 1점을 `VideoComposer` 어댑터로 격리. 임시 파일은 OS cache 디렉터리 — 자동 정리 의존.
**Source:** `docs/PRD.md` §F08 / §F09 / §9-2-4 (영상 자동 싱크) / §9-2-5 (미디어 렌더링 파이프라인). 본 brainstorming 세션 (이슈 #5 작업 종료 직후 결정).
**Depends on:** `docs/superpowers/specs/2026-04-27-mapped-thumb-design.md` (셀 매핑 — main 머지 예정 PR #6), `lib/cores/grid_suggestor/` 알고리즘 모듈 (BSP tree → 셀 좌표).
**Consumed by (post-spec):** F06 셀 내 미디어 조작 (CellTransform 적용 시 본 spec 의 `CellSource` 확장), F11 되돌리기 (share 자체는 read-only 라 무관), F16 내 템플릿 (ShareCoordinator 재사용).

---

## 1. 결정 요약

| # | 항목 | 결정 | 근거 |
|---|---|---|---|
| 1 | "이걸로" 흐름 | Suggestion 카드 → share_plus 시트 (편집 0, 에디터 우회) | 사용자가 자동 제안 결과 그대로 share 가능 → 사용자 가치 unlock 의 가장 빠른 길. PRD §9-2-4 "편집 0" 직결. 카톡/인스타/저장 모두 OS share extension 한 통로로 |
| 2 | 미디어 분기 | 영상 셀 1개라도 → MP4 / 사진만 → PNG | 영상 카드를 PNG 정지화면으로 저장하면 사용자 의도와 어긋남. 미디어 종류에 맞는 출력 형식 |
| 3 | 스코프 | 한 sprint 통합 (PNG + MP4 + 영상 자동 싱크) | AI 협업에서 분해는 컨텍스트 재적재 / 코드 결합도 깨짐 비용이 분해 이득보다 큼. ffmpeg_kit spike 와 share 흐름이 한 흐름 안에서 결정되어야 일관 |
| 4 | 출력 해상도 | 1080 long edge (1:1 → 1080×1080, 9:16 → 1080×1920, 4:5 → 1080×1350, 16:9 → 1920×1080) | 인스타 / 카톡 표준 baseline. 디바이스 dp 무관 일관 화질 |
| 5 | MP4 fps / cap / 코덱 | 30fps / T_min ≤ 15초 / H.264 + AAC | PRD §9-2-4 "MVP cap 15초" 그대로. 30fps 인스타 표준. H.264+AAC 호환성 최대 |
| 6 | 영상 default | 자동 트림 (T_min 까지). 루프 토글은 F06 후속 | PRD §9-2-4 "트림 default, 루프는 사용자 선택". 본 sprint 시점 사용자 토글 UI 없음 |
| 7 | 진행 UI | Full-screen modal + Cancel (ffmpeg session.cancel) | 영상 합성 5~30초 가능. 사용자에게 "지금 일어나고 있다" 명시 필요. Cancel 가능해야 사용자 통제권 보장 |
| 8 | 어댑터 | VideoComposer / ImageCapturer / ShareDispatcher 3개 — Riverpod 주입 | `ThumbnailLoader` 패턴과 일관. 네이티브 의존 (ffmpeg_kit / share_plus) 1점 격리, 단위 테스트 fake 주입 가능 |
| 9 | spec 위치 | 본 파일 (`2026-04-27-share-output-design.md`) | 토픽별 spec 패턴 일관 |

---

## 2. 아키텍처

### 2-1. 컴포넌트 트리

```text
SuggestionPage "이걸로" tap (현재 SnackBar stub)
  └─ ShareCoordinator.run(suggestion, canvas, assetsById)
      ├─ 분기: assetsById 의 어떤 셀이 video?
      │   ├─ NO  (사진만)
      │   │    ├─ ImageCapturer.capturePng(card, size: 1080×{비율})
      │   │    ├─ tempFile 저장 (path_provider)
      │   │    └─ ShareDispatcher.share([XFile png])
      │   └─ YES (영상 1개 이상)
      │        ├─ T_min 계산 (영상 셀 duration min, cap 15s, floor 1s)
      │        ├─ CellSource[] 추출 (cellId → photo path | video path)
      │        ├─ GridToFfmpegFilter.build(tree, canvas, cells, T_min, fps)
      │        ├─ VideoComposer.composeMp4(filter, inputs, outputSize, T_min, fps)
      │        │     → progress 콜백으로 ComposingModal 갱신
      │        └─ ShareDispatcher.share([XFile mp4])
      └─ ComposingModal (200ms 이후 노출, Cancel 버튼)
```

### 2-2. 어댑터 책임 분리

```text
ImageCapturer (abstract interface class)
  ├─ RepaintBoundaryImageCapturer (off-screen 1080 위젯 build → toImage → PNG)
  └─ FakeImageCapturer (테스트 — 1×1 PNG 반환)

VideoComposer (abstract interface class)
  ├─ FfmpegVideoComposer (ffmpeg_kit_flutter_new — filter_complex)
  └─ FakeVideoComposer (테스트 — fake .mp4 path 반환, progress 시뮬레이션)

ShareDispatcher (abstract interface class)
  ├─ SharePlusDispatcher (share_plus.shareXFiles)
  └─ FakeShareDispatcher (테스트 — 호출 인자 record)
```

이슈 #5 의 `ThumbnailLoader` 패턴과 일관. Riverpod `keepAlive: true` provider 로 주입.

### 2-3. 의존성 흐름

```text
features/share ──depends──▶ cores/grid_suggestor (배럴 — GridSuggestion / GridNode / cellBBoxes)
features/share ──depends──▶ features/suggestion/providers/selected_assets_provider (assetsById lookup)
features/share ──depends──▶ ffmpeg_kit_flutter_new + share_plus + path_provider (어댑터 1점 격리)
flow/, cores/grid_suggestor/ ──┃ ffmpeg_kit / share_plus 의존성 0 유지
```

---

## 3. 데이터 흐름

### 3-1. 사진만 (PNG 분기)

```text
1. assetsById 의 모든 AssetEntity.type 검사 → 모두 image
2. 출력 사이즈 계산:
   - canvas.value < 1 (세로) → height=1080, width=1080×canvas.value
   - canvas.value ≥ 1 (가로/정사각) → width=1080, height=1080/canvas.value
   * 결과는 16의 배수로 보정 (ffmpeg/PNG 인코더 호환)
3. off-screen 위젯 트리 build (BuildContext 별도):
   - SizedBox(width: outW, height: outH)
   - SuggestionCard(suggestion, canvas, assetsById_high_res)
   - 안쪽 _MappedThumb 의 ThumbnailLoader 가 ThumbnailSize.square(1080) 으로 재로드
   - 첫 frame paint 까지 대기 (FutureBuilder all done)
4. RepaintBoundary.toImage(pixelRatio: 1.0) → ui.Image
5. ui.Image.toByteData(format: ImageByteFormat.png) → Uint8List
6. path_provider.getTemporaryDirectory() / 'gridset_<unix_ts>.png'
7. ShareDispatcher.share(files: [XFile(path)], subject: 'Gridset')
```

### 3-2. 영상 포함 (MP4 분기)

```text
1. assetsById 에서 type == video 인 셀 ≥ 1 검출
2. T_min 계산:
   T_min = clamp(min(video durations), 1000ms, 15000ms)
3. CellSource[] 생성:
   for each cellId in suggestion.mediaByCellId:
     asset = assetsById[mediaByCellId[cellId]]
     CellSource(
       cellId,
       bbox = cellBBoxes(tree)[cellId],   // 정규화 좌표
       kind = asset.type == video ? VideoSource(file=asset.file)
                                  : PhotoSource(file=asset.file),
     )
4. 출력 사이즈 = §3-1 과 동일 (1080 long edge)
5. GridToFfmpegFilter.build(cells, outputSize, T_min, fps=30):
   - input flag 구성:
       video: -i path
       photo: -loop 1 -t Tmin/1000 -i path
   - filter_complex graph:
       color=c=#F7F4ED:size=WxH:r=30:duration=Tmin [bg];
       각 cell:
         [n:v]trim=duration=Tmin,setpts=PTS-STARTPTS,
              scale=cellW:cellH,setsar=1[c{n}];
       overlay 누적:
         [bg][c0]overlay=x=x0:y=y0[s0];
         [s0][c1]overlay=x=x1:y=y1[s1];
         ...
         [s{n-1}][c{n}]overlay=x=xn:y=yn[out]
   - output: -map [out] -c:v libx264 -preset veryfast
             -pix_fmt yuv420p -r 30 -t Tmin/1000
6. FFmpegVideoComposer.run(args)
   - FFmpegKit.executeAsync(...) — progress 콜백으로 ComposingModal 갱신
   - 실패 시 SnackBar
7. 출력 path → ShareDispatcher.share([XFile(mp4)])
```

### 3-3. T_min 계산 명세

```dart
int computeTMinMs(Iterable<AssetEntity> videos) {
  if (videos.isEmpty) return 0;       // 호출자가 사진만 분기로 처리
  final minMs = videos
      .map((a) => a.videoDuration.inMilliseconds)
      .reduce((a, b) => a < b ? a : b);
  return minMs.clamp(1000, 15000);    // 1초 floor, 15초 cap
}
```

- 1초 floor: 0.x초 영상이면 너무 짧아 사용자 인지 불가
- 15초 cap: PRD §9-2-4 MVP 한도

---

## 4. ImageCapturer 명세

### 4-1. 인터페이스

```dart
abstract interface class ImageCapturer {
  Future<Uint8List> capturePng({
    required GridSuggestion suggestion,
    required CanvasRatio canvas,
    required Map<String, AssetEntity> assetsById,
    required int longEdgePx,    // 1080
  });
}
```

### 4-2. 프로덕션 구현

`RepaintBoundaryImageCapturer` 가 off-screen widget tree 를 build 하기 위해 다음 절차:

1. `BuildOwner` 와 `RenderView` 직접 생성 (off-screen rendering)
2. `RepaintBoundary` 안에 1080×{비율} 사이즈의 SuggestionCard 위젯 트리
3. `WidgetsBinding.instance.scheduleFrame()` 으로 첫 frame 강제
4. 모든 셀의 `_MappedThumb._future` 가 완료될 때까지 대기 (timeout: 5s)
5. `RenderRepaintBoundary.toImage(pixelRatio: 1.0)` 호출
6. `ui.Image.toByteData(format: png)` → Uint8List

대안: 화면에 invisible Stack 으로 mount 후 캡처. 단순하나 화면 paint 한 frame 영향. 본 spec 은 off-screen 권장.

### 4-3. 1080 thumbnail 재로드

`_MappedThumb` 의 기존 ThumbnailSize.square(512) 는 1080 캔버스에서 흐림. capturer 가 build 하는 위젯 트리 안에서는 `thumbnailLoaderProvider.overrideWith` 로 size=1080 reloader 주입. 화면 표시용 (512) 캐시와 분리.

---

## 5. VideoComposer 명세

### 5-1. 인터페이스

```dart
abstract interface class VideoComposer {
  /// progress 0.0..1.0 콜백.
  Future<String> composeMp4({
    required List<CellSource> cells,
    required GridNode tree,
    required CanvasRatio canvas,
    required int longEdgePx,
    required int fps,
    required int tMinMs,
    required void Function(double progress) onProgress,
  });

  /// 진행 중 ffmpeg session cancel.
  Future<void> cancel();
}
```

### 5-2. CellSource 모델

```dart
sealed class CellSource {
  final int cellId;
  final CellRect bbox;        // 정규화 좌표 (cores/grid_suggestor)
  const CellSource(this.cellId, this.bbox);
}

final class PhotoSource extends CellSource {
  final String filePath;
  const PhotoSource(super.cellId, super.bbox, this.filePath);
}

final class VideoSource extends CellSource {
  final String filePath;
  final int durationMs;
  const VideoSource(super.cellId, super.bbox, this.filePath, this.durationMs);
}
```

후속 F06 (셀 내 미디어 조작) 에서 `CellTransform? transform` 추가 가능 — 본 spec 은 identity transform 가정.

### 5-3. ffmpeg filter_complex 예시 (N=4, 2×2 grid, 1:1 1080×1080, T_min=5000)

```text
입력:
  -i video1.mp4                           [#0]
  -loop 1 -t 5 -i photo1.jpg              [#1]
  -loop 1 -t 5 -i photo2.jpg              [#2]
  -i video2.mp4                           [#3]

filter_complex:
  color=c=0xF7F4ED:size=1080x1080:r=30:duration=5[bg];
  [0:v]trim=duration=5,setpts=PTS-STARTPTS,scale=540:540,setsar=1[c0];
  [1:v]trim=duration=5,scale=540:540,setsar=1[c1];
  [2:v]trim=duration=5,scale=540:540,setsar=1[c2];
  [3:v]trim=duration=5,setpts=PTS-STARTPTS,scale=540:540,setsar=1[c3];
  [bg][c0]overlay=x=0:y=0[s0];
  [s0][c1]overlay=x=540:y=0[s1];
  [s1][c2]overlay=x=0:y=540[s2];
  [s2][c3]overlay=x=540:y=540[out]

output:
  -map [out] -c:v libx264 -preset veryfast -pix_fmt yuv420p -r 30 -t 5 out.mp4
```

`GridToFfmpegFilter` 가 `cellBBoxes` 의 정규화 좌표를 1080 스케일로 변환 + 16배수 정렬 (libx264 요구).

### 5-4. progress 콜백

ffmpeg-kit 의 `Statistics.getTime()` (ms 단위 인코딩 진행) ÷ `tMinMs` = 0..1 progress.

---

## 6. ComposingModal

### 6-1. 노출 정책

- 호출 즉시 노출하면 사진만 분기 (수백 ms) 에서 깜빡거림
- **200ms 이후만** 노출 (`Future.delayed` 후 `composer.isRunning` 이면 modal push)
- 사진만 분기는 거의 노출 X, 영상 분기에서만 노출

### 6-2. 시각

| 영역 | 내용 |
|---|---|
| 배경 | full-screen `charcoal82` (반투명 dark) |
| 중앙 | "영상 만드는 중..." `body_16` `offWhite` |
| 진행 bar | LinearProgressIndicator(value: progress, color: offWhite) — 360.w |
| 버튼 | "취소" — outlined, offWhite border |

### 6-3. Cancel 동작

- "취소" tap → `composer.cancel()` (ffmpeg session.cancel) → modal pop
- 사용자에게 SnackBar 안 띄움 (사용자 의도 cancel 이므로 무음)

---

## 7. 에러 / fallback 매트릭스

| 케이스 | 처리 | 사용자 시각 |
|---|---|---|
| 영상 0.x초 → T_min < 1000 | T_min = 1000 (1초 floor) | 1초 영상 출력 |
| 영상 > 15초 → T_min > 15000 | T_min = 15000 (cap) | 15초 영상 출력 |
| ffmpeg 실패 (코덱/IO) | tempFile cleanup + modal pop + SnackBar "영상 만들기에 실패했어요" | SnackBar (siren 톤) |
| 사용자 cancel | 무음 + modal pop + tempFile cleanup | 화면 그대로 |
| share 시트 사용자 dismiss | 무음 (정상 흐름) — tempFile 은 OS cache 자동 정리 | 화면 그대로 |
| AssetEntity.file == null (권한 limited 변경) | 해당 셀 placeholder → 영상 분기 → 합성 fail → SnackBar | 위와 동일 |
| 디스크 풀 (PathAccessException) | SnackBar "저장 공간 부족" | SnackBar |
| 진행 시간 30초 초과 (timeout) | 자동 cancel + SnackBar "영상 만들기가 너무 오래 걸려요" | SnackBar |

---

## 8. 테스트 단위

| Layer | 대상 | 검증 |
|---|---|---|
| Unit | `T_min computeTMinMs` | 빈 / 1개 / 다수 / 0.x초 floor / 16초 cap |
| Unit | `GridToFfmpegFilter.build` | BSP tree → filter_complex 문자열 정확성. 좌표 16배수 정렬. cell 4 / 9 케이스 |
| Unit | `CellSource` factory | AssetEntity → PhotoSource / VideoSource 분기 |
| Widget | `ShareCoordinator` (Fake 어댑터 3개) | (a) 사진만 → ImageCapturer.capturePng 1회 + ShareDispatcher.share([png]) 1회 (b) 영상 1+ → VideoComposer.composeMp4 1회 + ShareDispatcher.share([mp4]) 1회 (c) ffmpeg fail → SnackBar (d) cancel → modal pop |
| Widget | `ComposingModal` | 진행 갱신 / cancel tap → composer.cancel 호출 |
| Integration (skip on CI) | `FfmpegVideoComposer` 실 호출 | sample 그리드 합성 후 출력 mp4 duration / size 검증 (선택) |

ffmpeg integration test 는 native 의존이라 CI tag 로 분리 (`flutter test --tags=ffmpeg`).

---

## 9. 변경 영향 파일

### 신규
- `lib/features/share/share_coordinator.dart` — 분기 + 흐름 orchestration
- `lib/features/share/models/cell_source.dart` — sealed class
- `lib/features/share/services/t_min_calculator.dart` — `computeTMinMs`
- `lib/features/share/services/grid_to_ffmpeg_filter.dart` — BSP → filter_complex
- `lib/features/share/providers/image_capturer.dart` (+ .g.dart) — 인터페이스 + RepaintBoundary 구현 + provider
- `lib/features/share/providers/video_composer.dart` (+ .g.dart) — 인터페이스 + ffmpeg_kit 구현 + provider
- `lib/features/share/providers/share_dispatcher.dart` (+ .g.dart) — 인터페이스 + share_plus 구현 + provider
- `lib/features/share/widgets/composing_modal.dart`
- `test/features/share/...` (단위 5+ / 위젯 3+)

### 수정
- `lib/features/suggestion/suggestion_page.dart` — `onPick` 콜백을 `ShareCoordinator.run` 호출로 교체. 기존 SnackBar stub 제거
- `pubspec.yaml` — `share_plus`, `ffmpeg_kit_flutter_new`, `path_provider` 추가
- `docs/superpowers/specs/2026-04-27-mapped-thumb-design.md` §11/12 — F08/F09 후속 hooks 행을 본 spec cross-link 로 갱신

---

## 10. 비범위 (Out of Scope)

- ❌ 셀별 "루프 vs 트림" 사용자 토글 → F06 셀 내 미디어 조작 sprint
- ❌ 셀 내 미디어 pinch-zoom / 위치 조정 → F06 (CellTransform 적용 시점)
- ❌ 에디터 화면 (F02-F06) — "이걸로" 가 share 종착점이라 우회. "빈 캔버스" 만 별 흐름
- ❌ 워터마크 / 로고 삽입 → 후속 spec
- ❌ 저장 history / 갤러리 (앱 내) — share 가 OS 사진 앱 저장으로 흡수
- ❌ Phase D 큐레이션 풀 보강 — 별 PR (template 풀 부족)
- ❌ FFmpeg 직접 의존 — `VideoComposer` 어댑터 외부에서 ffmpeg-kit 직접 호출 금지
- ❌ 720p / 4K 출력 — v1 은 1080 고정. 후속 spec 에서 사용자 선택

---

## 11. 후속 hooks

| 후속 작업 | 본 spec 의 어디가 영향 |
|---|---|
| F06 셀 내 미디어 조작 | `CellSource` 에 `transform: CellTransform?` 추가. `GridToFfmpegFilter` 의 cell scale/translate 단계에서 transform 적용 |
| F07 영상 자동 싱크 — 루프 토글 | `CellSource.VideoSource` 에 `loop: bool` 추가. ffmpeg `-stream_loop` 적용. spec §6-3 의 default 트림 결정 재검토 |
| F11 되돌리기 | 본 sprint 의 share 흐름은 read-only — 영향 없음 |
| F16 내 템플릿 | ShareCoordinator 가 trigger 받는 위치 추가 (Suggestion 외에 에디터 / 템플릿 미리보기) |
| 워터마크 | filter_complex 의 마지막 overlay 단계에 watermark image 추가 |
| 720p / 4K 옵션 | `longEdgePx` 가 이미 인자라 변경 0. UI 토글 + provider 만 |
