# 자동 제안 결과 share-first 출력 (PNG / MP4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Suggestion "이걸로" CTA 가 사진만 카드는 1080 long edge PNG / 영상 셀 1+ 카드는 1080 30fps MP4 로 합성한 뒤 OS share 시트로 노출하도록 SnackBar stub 을 종결한다.

**Architecture:** ShareCoordinator 가 미디어 분기 → ImageCapturer (RepaintBoundary) 또는 VideoComposer (ffmpeg_kit) 어댑터로 위임 → ShareDispatcher (share_plus) 로 OS 시트 노출. 네이티브 의존은 3개 어댑터로 1점 격리해 단위 테스트 fake 주입.

**Tech Stack:** Flutter 3.9.2, Riverpod (`riverpod_annotation`), photo_manager, **share_plus** (이미 있음), **ffmpeg_kit_flutter_new** (신규), **path_provider** (신규), flutter_screenutil.

**Spec:** `docs/superpowers/specs/2026-04-27-share-output-design.md`
**Issue:** GitHub #7
**Branch:** `20260427_#7_자동_제안_결과_share_PNG_MP4` (이미 체크아웃)

---

## File Map

### 신규

| 파일 | 책임 |
|---|---|
| `lib/features/share/models/cell_source.dart` | `sealed class CellSource` (PhotoSource / VideoSource) — ffmpeg 합성 입력 |
| `lib/features/share/services/t_min_calculator.dart` | `computeTMinMs(videos)` 순수 함수 (1초 floor / 15초 cap) |
| `lib/features/share/services/grid_to_ffmpeg_filter.dart` | BSP tree + cellBBoxes → filter_complex 문자열, 16배수 정렬 |
| `lib/features/share/providers/share_dispatcher.dart` (+ `.g.dart`) | `ShareDispatcher` 인터페이스 + `SharePlusDispatcher` + Riverpod provider |
| `lib/features/share/providers/image_capturer.dart` (+ `.g.dart`) | `ImageCapturer` 인터페이스 + `RepaintBoundaryImageCapturer` + provider |
| `lib/features/share/providers/video_composer.dart` (+ `.g.dart`) | `VideoComposer` 인터페이스 + `FfmpegVideoComposer` + provider |
| `lib/features/share/widgets/composing_modal.dart` | full-screen 진행 modal + Cancel |
| `lib/features/share/share_coordinator.dart` | 분기 + 흐름 orchestration |
| `test/features/share/...` | 단위 5+ / 위젯 3+ |

### 수정

| 파일 | 변경 |
|---|---|
| `pubspec.yaml` | `ffmpeg_kit_flutter_new`, `path_provider` 추가 (share_plus 이미 있음) |
| `lib/features/suggestion/suggestion_page.dart` | `_Loaded` 카드 `RepaintBoundary` wrapping + `onPick` 콜백을 ShareCoordinator 호출로 교체 |
| `docs/superpowers/specs/2026-04-27-mapped-thumb-design.md` | §11/12 의 F08/F09 후속 hooks 행을 본 spec cross-link |

### Implementation 결정 — RepaintBoundary 캡처 방식

spec §4-2 의 두 가지 대안 중 **본 plan 은 "현재 화면 카드를 RepaintBoundary 로 wrapping + pixelRatio 동적 조정"** 을 채택:

```dart
final box = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
final pixelRatio = 1080 / math.max(box.size.width, box.size.height);
final image = await box.toImage(pixelRatio: pixelRatio);
```

근거:
- off-screen `BuildOwner` 직접 wiring 은 복잡하고 Flutter 내부 구조 변동 위험
- 카드는 이미 사용자 화면에 떠있음 — `RepaintBoundary(key: ...)` wrapping + `pixelRatio` 로 1080 long edge 보장
- 화질 trade-off: `_MappedThumb` 의 512 썸네일이 1080 캔버스에서 약간 흐림. 후속 spec 에서 1080 reload 옵션 추가
- Flutter 표준 패턴 (e.g. `screenshot` 패키지) 와 일관

### build_runner 가정

`dart run build_runner watch --delete-conflicting-outputs` 가 background 에서 안 돌고 있다고 가정. 각 codegen 필요 task 끝에 `dart run build_runner build --delete-conflicting-outputs` 한 번 명시.

---

## Task 1: pubspec 의존성 추가

**Files:** `pubspec.yaml`

- [ ] **Step 1.1: 의존성 추가**

`pubspec.yaml` 의 `dependencies:` 아래 `share_plus: ^12.0.1` 가 이미 있는 위치 부근에 추가:

```yaml
  ffmpeg_kit_flutter_new: ^1.0.0
  path_provider: ^2.1.5
```

(정확한 latest 버전은 `flutter pub add` 로 자동 결정 가능 — 다음 step.)

- [ ] **Step 1.2: 의존성 설치**

Run:
```bash
flutter pub add ffmpeg_kit_flutter_new path_provider
flutter pub get
```
Expected: `Resolving dependencies...` 후 `Got dependencies!` 또는 `+ ffmpeg_kit_flutter_new`, `+ path_provider` 로그.

- [ ] **Step 1.3: analyze**

Run: `flutter analyze`
Expected: `No issues found!` (기존 deprecated 1건 제외 — 본 PR 무관).

- [ ] **Step 1.4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore : ffmpeg_kit_flutter_new + path_provider 의존성 추가 (#7)"
```

---

## Task 2: `CellSource` sealed model + 단위 테스트

**Files:**
- Create: `lib/features/share/models/cell_source.dart`
- Create: `test/features/share/models/cell_source_test.dart`

- [ ] **Step 2.1: 실패하는 테스트 작성**

`test/features/share/models/cell_source_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/share/models/cell_source.dart';

void main() {
  test('PhotoSource — cellId / bbox / filePath 보존', () {
    const bbox = CellRect(0, 0, 0.5, 1);
    final src = PhotoSource(cellId: 0, bbox: bbox, filePath: '/tmp/a.jpg');
    expect(src.cellId, 0);
    expect(src.bbox, bbox);
    expect(src.filePath, '/tmp/a.jpg');
  });

  test('VideoSource — durationMs 추가 보존', () {
    const bbox = CellRect(0.5, 0, 0.5, 1);
    final src = VideoSource(
      cellId: 1,
      bbox: bbox,
      filePath: '/tmp/b.mp4',
      durationMs: 5000,
    );
    expect(src.cellId, 1);
    expect(src.filePath, '/tmp/b.mp4');
    expect(src.durationMs, 5000);
  });

  test('CellSource — sealed 분기 (switch 패턴 컴파일)', () {
    final CellSource src = PhotoSource(
      cellId: 0,
      bbox: const CellRect(0, 0, 1, 1),
      filePath: '/tmp/a.jpg',
    );
    final result = switch (src) {
      PhotoSource() => 'photo',
      VideoSource() => 'video',
    };
    expect(result, 'photo');
  });
}
```

- [ ] **Step 2.2: 테스트 실행 (실패)**

Run: `flutter test test/features/share/models/cell_source_test.dart`
Expected: FAIL — `CellSource`, `PhotoSource`, `VideoSource` 정의되지 않음.

- [ ] **Step 2.3: 모델 작성**

`lib/features/share/models/cell_source.dart`:

```dart
import '../../../cores/grid_suggestor/grid_suggestor.dart';

/// ffmpeg 합성 입력 — 셀 단위로 photo / video 분기.
///
/// `bbox` 는 정규화 좌표 (0..1). `GridToFfmpegFilter` 가 출력 캔버스 픽셀
/// 좌표로 변환 + 16배수 정렬 후 ffmpeg `overlay` 에 전달.
sealed class CellSource {
  final int cellId;
  final CellRect bbox;
  const CellSource({required this.cellId, required this.bbox});
}

final class PhotoSource extends CellSource {
  final String filePath;
  const PhotoSource({
    required super.cellId,
    required super.bbox,
    required this.filePath,
  });
}

final class VideoSource extends CellSource {
  final String filePath;
  final int durationMs;
  const VideoSource({
    required super.cellId,
    required super.bbox,
    required this.filePath,
    required this.durationMs,
  });
}
```

- [ ] **Step 2.4: 테스트 실행 (PASS)**

Run: `flutter test test/features/share/models/cell_source_test.dart`
Expected: 3 PASS.

- [ ] **Step 2.5: Commit**

```bash
git add lib/features/share/models/cell_source.dart \
  test/features/share/models/cell_source_test.dart
git commit -m "feat : CellSource sealed 모델 추가 (#7)"
```

---

## Task 3: `computeTMinMs` 순수 함수 + 단위 테스트

**Files:**
- Create: `lib/features/share/services/t_min_calculator.dart`
- Create: `test/features/share/services/t_min_calculator_test.dart`

- [ ] **Step 3.1: 실패하는 테스트 작성**

`test/features/share/services/t_min_calculator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/features/share/services/t_min_calculator.dart';

void main() {
  test('빈 입력 → 0', () {
    expect(computeTMinMs(const []), 0);
  });

  test('1개 → 그 값 (cap/floor 안)', () {
    expect(computeTMinMs(const [5000]), 5000);
  });

  test('여러 개 → 최소값', () {
    expect(computeTMinMs(const [8000, 3000, 12000]), 3000);
  });

  test('1초 floor — 0.5초는 1초로 올림', () {
    expect(computeTMinMs(const [500]), 1000);
  });

  test('15초 cap — 16초는 15초로 자름', () {
    expect(computeTMinMs(const [16000, 20000]), 15000);
  });

  test('floor + cap 동시 적용', () {
    expect(computeTMinMs(const [200, 30000]), 1000); // min=200 → floor 1000
  });
}
```

- [ ] **Step 3.2: 테스트 실행 (실패)**

Run: `flutter test test/features/share/services/t_min_calculator_test.dart`
Expected: FAIL — `computeTMinMs` 정의되지 않음.

- [ ] **Step 3.3: 함수 작성**

`lib/features/share/services/t_min_calculator.dart`:

```dart
/// 영상 셀 duration 들 중 최솟값으로 T_min 계산.
///
/// 1초 floor: 0.x초 영상은 사용자 인지 불가 → 1초로 올림.
/// 15초 cap: PRD §9-2-4 MVP 한도.
/// 빈 입력: 사진만 카드 → 호출자가 PNG 분기로 우회 (반환 0).
int computeTMinMs(Iterable<int> videoDurationsMs) {
  if (videoDurationsMs.isEmpty) return 0;
  final minMs = videoDurationsMs.reduce((a, b) => a < b ? a : b);
  return minMs.clamp(1000, 15000);
}
```

- [ ] **Step 3.4: 테스트 실행 (PASS)**

Run: `flutter test test/features/share/services/t_min_calculator_test.dart`
Expected: 6 PASS.

- [ ] **Step 3.5: Commit**

```bash
git add lib/features/share/services/t_min_calculator.dart \
  test/features/share/services/t_min_calculator_test.dart
git commit -m "feat : T_min 계산 순수 함수 (1초 floor / 15초 cap) (#7)"
```

---

## Task 4: `GridToFfmpegFilter` + 단위 테스트

**Files:**
- Create: `lib/features/share/services/grid_to_ffmpeg_filter.dart`
- Create: `test/features/share/services/grid_to_ffmpeg_filter_test.dart`

- [ ] **Step 4.1: 실패하는 테스트 작성**

`test/features/share/services/grid_to_ffmpeg_filter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/share/models/cell_source.dart';
import 'package:gridset/features/share/services/grid_to_ffmpeg_filter.dart';

void main() {
  test('출력 사이즈 — 1:1 정사각, 1080 long edge', () {
    final size = computeOutputSize(const CanvasRatio.square(), 1080);
    expect(size.width, 1080);
    expect(size.height, 1080);
  });

  test('출력 사이즈 — 9:16 세로, 16배수 정렬', () {
    final size = computeOutputSize(const CanvasRatio.portrait916(), 1080);
    // height=1080, width=1080 * 9/16 = 607.5 → 16배수 정렬 → 608
    expect(size.height, 1080);
    expect(size.width, 608);
    expect(size.width % 16, 0);
  });

  test('출력 사이즈 — 16:9 가로, long edge=1920', () {
    final size = computeOutputSize(const CanvasRatio.landscape169(), 1080);
    // width=1080, height=1080 * 9/16 = 607.5 → 608. long edge cap.
    // landscape: width=1080×16/9 = 1920, height=1080
    expect(size.width, 1920);
    expect(size.height, 1080);
  });

  test('filter_complex — 2 셀 vertical split, 영상 1 + 사진 1', () {
    final cells = [
      VideoSource(
        cellId: 0,
        bbox: const CellRect(0, 0, 0.5, 1),
        filePath: '/tmp/v.mp4',
        durationMs: 5000,
      ),
      PhotoSource(
        cellId: 1,
        bbox: const CellRect(0.5, 0, 0.5, 1),
        filePath: '/tmp/p.jpg',
      ),
    ];
    final filter = buildFilterComplex(
      cells: cells,
      outputWidth: 1080,
      outputHeight: 1080,
      tMinMs: 5000,
      fps: 30,
    );
    // bg color
    expect(filter, contains('color=c=0xF7F4ED:size=1080x1080:r=30:duration=5'));
    // 셀별 trim/scale (cell w=540, h=1080)
    expect(filter, contains('trim=duration=5'));
    expect(filter, contains('scale=544:1088'));   // 540→544, 1080→1088 (16배수)
    // overlay 누적
    expect(filter, contains('overlay=x=0:y=0'));
    expect(filter, contains('overlay=x=544:y=0'));
  });

  test('input flags — photo 는 -loop 1 -t Tmin/1000 -i', () {
    final cells = [
      PhotoSource(
        cellId: 0,
        bbox: const CellRect(0, 0, 1, 1),
        filePath: '/tmp/p.jpg',
      ),
    ];
    final flags = buildInputFlags(cells: cells, tMinMs: 5000);
    expect(flags, ['-loop', '1', '-t', '5', '-i', '/tmp/p.jpg']);
  });

  test('input flags — video 는 -i 만', () {
    final cells = [
      VideoSource(
        cellId: 0,
        bbox: const CellRect(0, 0, 1, 1),
        filePath: '/tmp/v.mp4',
        durationMs: 5000,
      ),
    ];
    final flags = buildInputFlags(cells: cells, tMinMs: 5000);
    expect(flags, ['-i', '/tmp/v.mp4']);
  });
}
```

- [ ] **Step 4.2: 테스트 실행 (실패)**

Run: `flutter test test/features/share/services/grid_to_ffmpeg_filter_test.dart`
Expected: FAIL — 함수 정의되지 않음.

- [ ] **Step 4.3: 구현 작성**

`lib/features/share/services/grid_to_ffmpeg_filter.dart`:

```dart
import 'dart:ui' show Size;

import '../../../cores/grid_suggestor/grid_suggestor.dart';
import '../models/cell_source.dart';

/// 출력 long edge 기준 사이즈. 16배수 정렬 (libx264 요구).
Size computeOutputSize(CanvasRatio canvas, int longEdgePx) {
  final ar = canvas.value;       // width / height
  late int w, h;
  if (ar >= 1) {
    w = longEdgePx;
    h = (longEdgePx / ar).round();
  } else {
    h = longEdgePx;
    w = (longEdgePx * ar).round();
  }
  return Size(_align16(w).toDouble(), _align16(h).toDouble());
}

int _align16(int v) => ((v + 15) ~/ 16) * 16;

/// ffmpeg input flags — photo 는 `-loop 1 -t {sec}` 추가, video 는 `-i` 만.
List<String> buildInputFlags({
  required List<CellSource> cells,
  required int tMinMs,
}) {
  final flags = <String>[];
  final tSec = (tMinMs / 1000).toStringAsFixed(0);
  for (final c in cells) {
    switch (c) {
      case PhotoSource(filePath: final p):
        flags.addAll(['-loop', '1', '-t', tSec, '-i', p]);
      case VideoSource(filePath: final p):
        flags.addAll(['-i', p]);
    }
  }
  return flags;
}

/// filter_complex 문자열. bg + 각 셀 trim/scale + overlay 누적.
String buildFilterComplex({
  required List<CellSource> cells,
  required int outputWidth,
  required int outputHeight,
  required int tMinMs,
  required int fps,
}) {
  final tSec = (tMinMs / 1000).toStringAsFixed(0);
  final buf = StringBuffer()
    ..write('color=c=0xF7F4ED:size=${outputWidth}x$outputHeight'
        ':r=$fps:duration=$tSec[bg];');

  // 셀별 scale + 16배수 정렬한 픽셀 좌표
  final cellPositions = <(int x, int y, int w, int h)>[];
  for (var i = 0; i < cells.length; i++) {
    final c = cells[i];
    final x = _align16((c.bbox.left * outputWidth).round());
    final y = _align16((c.bbox.top * outputHeight).round());
    final w = _align16((c.bbox.width * outputWidth).round());
    final h = _align16((c.bbox.height * outputHeight).round());
    cellPositions.add((x, y, w, h));

    final isVideo = c is VideoSource;
    final setpts = isVideo ? ',setpts=PTS-STARTPTS' : '';
    buf.write('[$i:v]trim=duration=$tSec$setpts'
        ',scale=$w:$h,setsar=1[c$i];');
  }

  // overlay 누적
  buf.write('[bg]');
  for (var i = 0; i < cells.length; i++) {
    final (x, y, _, _) = cellPositions[i];
    final outLabel = i == cells.length - 1 ? 'out' : 's$i';
    final inLabel = i == 0 ? '' : '[s${i - 1}]';
    if (i > 0) buf.write(inLabel);
    buf.write('[c$i]overlay=x=$x:y=$y[$outLabel]');
    if (i < cells.length - 1) buf.write(';');
  }
  return buf.toString();
}
```

- [ ] **Step 4.4: 테스트 실행 (PASS)**

Run: `flutter test test/features/share/services/grid_to_ffmpeg_filter_test.dart`
Expected: 6 PASS.

- [ ] **Step 4.5: Commit**

```bash
git add lib/features/share/services/grid_to_ffmpeg_filter.dart \
  test/features/share/services/grid_to_ffmpeg_filter_test.dart
git commit -m "feat : GridToFfmpegFilter (BSP → filter_complex 변환) (#7)"
```

---

## Task 5: `ShareDispatcher` 어댑터

**Files:**
- Create: `lib/features/share/providers/share_dispatcher.dart`
- Create: `test/features/share/providers/share_dispatcher_test.dart`

- [ ] **Step 5.1: 실패하는 테스트 작성**

`test/features/share/providers/share_dispatcher_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/features/share/providers/share_dispatcher.dart';

class _RecordingDispatcher implements ShareDispatcher {
  List<String>? lastFilePaths;
  String? lastSubject;

  @override
  Future<void> share({required List<String> filePaths, String? subject}) async {
    lastFilePaths = filePaths;
    lastSubject = subject;
  }
}

void main() {
  test('인터페이스 구현 가능 — 호출 인자 보존', () async {
    final fake = _RecordingDispatcher();
    await fake.share(filePaths: ['/tmp/a.png'], subject: 'Gridset');
    expect(fake.lastFilePaths, ['/tmp/a.png']);
    expect(fake.lastSubject, 'Gridset');
  });

  test('shareDispatcherProvider — 기본 구현 SharePlusDispatcher', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dispatcher = container.read(shareDispatcherProvider);
    expect(dispatcher, isA<ShareDispatcher>());
  });
}
```

- [ ] **Step 5.2: 테스트 실행 (실패)**

Run: `flutter test test/features/share/providers/share_dispatcher_test.dart`
Expected: FAIL — `ShareDispatcher`, `shareDispatcherProvider` 정의 없음.

- [ ] **Step 5.3: 어댑터 구현**

`lib/features/share/providers/share_dispatcher.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'share_dispatcher.g.dart';

/// share_plus 호출을 1점 격리하는 어댑터.
///
/// 테스트는 `shareDispatcherProvider.overrideWith((_) => FakeDispatcher())`
/// 로 주입.
abstract interface class ShareDispatcher {
  Future<void> share({required List<String> filePaths, String? subject});
}

/// 프로덕션 구현 — share_plus.shareXFiles 위임.
class SharePlusDispatcher implements ShareDispatcher {
  const SharePlusDispatcher();

  @override
  Future<void> share({
    required List<String> filePaths,
    String? subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: filePaths.map(XFile.new).toList(),
        subject: subject,
      ),
    );
  }
}

@Riverpod(keepAlive: true)
ShareDispatcher shareDispatcher(Ref ref) => const SharePlusDispatcher();
```

- [ ] **Step 5.4: codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `share_dispatcher.g.dart` 생성.

- [ ] **Step 5.5: 테스트 실행 (PASS)**

Run: `flutter test test/features/share/providers/share_dispatcher_test.dart`
Expected: 2 PASS.

- [ ] **Step 5.6: Commit**

```bash
git add lib/features/share/providers/share_dispatcher.dart \
  lib/features/share/providers/share_dispatcher.g.dart \
  test/features/share/providers/share_dispatcher_test.dart
git commit -m "feat : ShareDispatcher 어댑터 (share_plus 1점 격리) (#7)"
```

---

## Task 6: `ImageCapturer` 어댑터 (인터페이스 + Fake + provider)

**Files:**
- Create: `lib/features/share/providers/image_capturer.dart`
- Create: `test/features/share/providers/image_capturer_test.dart`

- [ ] **Step 6.1: 실패하는 테스트 작성**

`test/features/share/providers/image_capturer_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/features/share/providers/image_capturer.dart';

void main() {
  test('인터페이스 — 비동기 Uint8List 반환', () async {
    final fake = _FakeCapturer(Uint8List.fromList([1, 2, 3]));
    final bytes = await fake.capturePng(
      key: GlobalKey(),
      longEdgePx: 1080,
    );
    expect(bytes, [1, 2, 3]);
  });

  test('imageCapturerProvider — 기본 구현 RepaintBoundaryImageCapturer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final capturer = container.read(imageCapturerProvider);
    expect(capturer, isA<ImageCapturer>());
  });
}

class _FakeCapturer implements ImageCapturer {
  _FakeCapturer(this.bytes);
  final Uint8List bytes;
  @override
  Future<Uint8List> capturePng({
    required GlobalKey key,
    required int longEdgePx,
  }) async => bytes;
}
```

- [ ] **Step 6.2: 테스트 실행 (실패)**

Run: `flutter test test/features/share/providers/image_capturer_test.dart`
Expected: FAIL — `ImageCapturer`, `imageCapturerProvider` 정의 없음.

- [ ] **Step 6.3: 인터페이스 + 구현 작성**

`lib/features/share/providers/image_capturer.dart`:

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_capturer.g.dart';

/// 화면에 떠있는 위젯의 RepaintBoundary 를 캡처해 PNG bytes 반환.
///
/// `key` 는 RepaintBoundary 를 wrapping 한 위젯의 GlobalKey.
/// 호출자가 widget tree 의 RepaintBoundary(key: ...) 로 카드를 감싸야 함.
abstract interface class ImageCapturer {
  Future<Uint8List> capturePng({
    required GlobalKey key,
    required int longEdgePx,
  });
}

/// 프로덕션 구현 — RenderRepaintBoundary.toImage(pixelRatio) 위임.
///
/// pixelRatio 는 카드 dp 사이즈 기준으로 1080 long edge 가 나오게 동적 계산.
/// (iPhone 14 360dp 카드 → pixelRatio 3 → 1080px.)
class RepaintBoundaryImageCapturer implements ImageCapturer {
  const RepaintBoundaryImageCapturer();

  @override
  Future<Uint8List> capturePng({
    required GlobalKey key,
    required int longEdgePx,
  }) async {
    final ctx = key.currentContext;
    if (ctx == null) {
      throw StateError('ImageCapturer: GlobalKey.currentContext == null. '
          'RepaintBoundary 가 mount 되어있는지 확인.');
    }
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
    final size = boundary.size;
    final longEdgeDp = math.max(size.width, size.height);
    final pixelRatio = longEdgePx / longEdgeDp;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('ImageCapturer: PNG byteData == null');
    }
    return byteData.buffer.asUint8List();
  }
}

@Riverpod(keepAlive: true)
ImageCapturer imageCapturer(Ref ref) => const RepaintBoundaryImageCapturer();
```

- [ ] **Step 6.4: codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `image_capturer.g.dart` 생성.

- [ ] **Step 6.5: 테스트 실행 (PASS)**

Run: `flutter test test/features/share/providers/image_capturer_test.dart`
Expected: 2 PASS.

- [ ] **Step 6.6: Commit**

```bash
git add lib/features/share/providers/image_capturer.dart \
  lib/features/share/providers/image_capturer.g.dart \
  test/features/share/providers/image_capturer_test.dart
git commit -m "feat : ImageCapturer 어댑터 (RepaintBoundary 1080 PNG) (#7)"
```

---

## Task 7: `VideoComposer` 어댑터 (인터페이스 + Fake + provider)

본 task 는 인터페이스 + Riverpod provider 만. `FfmpegVideoComposer` 실 구현은 Task 8.

**Files:**
- Create: `lib/features/share/providers/video_composer.dart`
- Create: `test/features/share/providers/video_composer_test.dart`

- [ ] **Step 7.1: 실패하는 테스트 작성**

`test/features/share/providers/video_composer_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/share/models/cell_source.dart';
import 'package:gridset/features/share/providers/video_composer.dart';

class _FakeComposer implements VideoComposer {
  bool cancelled = false;
  double? lastProgress;

  @override
  Future<String> composeMp4({
    required List<CellSource> cells,
    required CanvasRatio canvas,
    required int longEdgePx,
    required int fps,
    required int tMinMs,
    required void Function(double) onProgress,
  }) async {
    onProgress(0.5);
    lastProgress = 0.5;
    return '/tmp/fake.mp4';
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
  }
}

void main() {
  test('인터페이스 — composeMp4 + cancel', () async {
    final fake = _FakeComposer();
    final path = await fake.composeMp4(
      cells: const [],
      canvas: const CanvasRatio.square(),
      longEdgePx: 1080,
      fps: 30,
      tMinMs: 5000,
      onProgress: (_) {},
    );
    expect(path, '/tmp/fake.mp4');
    expect(fake.lastProgress, 0.5);
    await fake.cancel();
    expect(fake.cancelled, isTrue);
  });

  test('videoComposerProvider — 기본 구현 VideoComposer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final composer = container.read(videoComposerProvider);
    expect(composer, isA<VideoComposer>());
  });
}
```

- [ ] **Step 7.2: 테스트 실행 (실패)**

Run: `flutter test test/features/share/providers/video_composer_test.dart`
Expected: FAIL — `VideoComposer` 정의 없음.

- [ ] **Step 7.3: 인터페이스 + provider 작성 (구현 stub)**

`lib/features/share/providers/video_composer.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../cores/grid_suggestor/grid_suggestor.dart';
import '../models/cell_source.dart';

part 'video_composer.g.dart';

/// ffmpeg_kit 호출을 1점 격리하는 어댑터.
///
/// 테스트는 `videoComposerProvider.overrideWith((_) => FakeComposer())`.
abstract interface class VideoComposer {
  /// MP4 출력 path 반환. progress 0..1 콜백 (인코딩 진척).
  Future<String> composeMp4({
    required List<CellSource> cells,
    required CanvasRatio canvas,
    required int longEdgePx,
    required int fps,
    required int tMinMs,
    required void Function(double progress) onProgress,
  });

  /// 진행 중 ffmpeg session cancel.
  Future<void> cancel();
}

/// stub — 실 구현은 Task 8 (FfmpegVideoComposer).
class _StubComposer implements VideoComposer {
  const _StubComposer();
  @override
  Future<String> composeMp4({
    required List<CellSource> cells,
    required CanvasRatio canvas,
    required int longEdgePx,
    required int fps,
    required int tMinMs,
    required void Function(double progress) onProgress,
  }) async {
    throw UnimplementedError('VideoComposer 실 구현은 Task 8');
  }

  @override
  Future<void> cancel() async {}
}

@Riverpod(keepAlive: true)
VideoComposer videoComposer(Ref ref) => const _StubComposer();
```

- [ ] **Step 7.4: codegen + 테스트 (PASS)**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/share/providers/video_composer_test.dart
```
Expected: 2 PASS.

- [ ] **Step 7.5: Commit**

```bash
git add lib/features/share/providers/video_composer.dart \
  lib/features/share/providers/video_composer.g.dart \
  test/features/share/providers/video_composer_test.dart
git commit -m "feat : VideoComposer 인터페이스 + provider stub (#7)"
```

---

## Task 8: `FfmpegVideoComposer` 실 구현

ffmpeg_kit_flutter_new 통합. 단위 테스트는 native 의존이라 직접 호출 어려움 → Fake 로 ShareCoordinator 단계에서 검증. 본 task 는 implementation + analyze + 매뉴얼 sanity check.

**Files:**
- Modify: `lib/features/share/providers/video_composer.dart` (`_StubComposer` → `FfmpegVideoComposer` 교체)

- [ ] **Step 8.1: `_StubComposer` 를 `FfmpegVideoComposer` 로 교체**

`lib/features/share/providers/video_composer.dart` 의 `_StubComposer` 부분 교체:

```dart
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../services/grid_to_ffmpeg_filter.dart';

class FfmpegVideoComposer implements VideoComposer {
  FfmpegVideoComposer();

  FFmpegSession? _activeSession;

  @override
  Future<String> composeMp4({
    required List<CellSource> cells,
    required CanvasRatio canvas,
    required int longEdgePx,
    required int fps,
    required int tMinMs,
    required void Function(double progress) onProgress,
  }) async {
    final size = computeOutputSize(canvas, longEdgePx);
    final outW = size.width.toInt();
    final outH = size.height.toInt();

    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '${tempDir.path}/gridset_$ts.mp4';

    // ffmpeg 명령 구성: input flags + filter_complex + output flags
    final inputFlags = buildInputFlags(cells: cells, tMinMs: tMinMs);
    final filter = buildFilterComplex(
      cells: cells,
      outputWidth: outW,
      outputHeight: outH,
      tMinMs: tMinMs,
      fps: fps,
    );
    final tSec = (tMinMs / 1000).toStringAsFixed(0);
    final args = [
      ...inputFlags,
      '-filter_complex', filter,
      '-map', '[out]',
      '-c:v', 'libx264',
      '-preset', 'veryfast',
      '-pix_fmt', 'yuv420p',
      '-r', '$fps',
      '-t', tSec,
      '-y',
      outPath,
    ];

    // progress 콜백: Statistics.getTime (ms) / tMinMs.
    FFmpegKitConfig.enableStatisticsCallback((stats) {
      final timeMs = stats.getTime();
      onProgress((timeMs / tMinMs).clamp(0.0, 1.0));
    });

    final session = await FFmpegKit.executeWithArguments(args);
    _activeSession = session;
    final returnCode = await session.getReturnCode();
    _activeSession = null;
    if (!ReturnCode.isSuccess(returnCode)) {
      // cleanup
      final f = File(outPath);
      if (await f.exists()) await f.delete();
      throw StateError('ffmpeg 실패 — returnCode=$returnCode');
    }
    return outPath;
  }

  @override
  Future<void> cancel() async {
    final s = _activeSession;
    if (s != null) {
      await FFmpegKit.cancel(s.getSessionId() ?? 0);
      _activeSession = null;
    }
  }
}
```

provider 함수도 `_StubComposer()` → `FfmpegVideoComposer()` 로 교체:

```dart
@Riverpod(keepAlive: true)
VideoComposer videoComposer(Ref ref) => FfmpegVideoComposer();
```

기존 stub class `_StubComposer` 제거.

- [ ] **Step 8.2: codegen 재실행**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `video_composer.g.dart` 갱신 — `keepAlive` provider 의 hash 가 바뀜.

- [ ] **Step 8.3: 단위 테스트 (PASS)**

Run: `flutter test test/features/share/providers/video_composer_test.dart`
Expected: 2 PASS (이전에 작성한 인터페이스 검증 + provider 존재).

- [ ] **Step 8.4: analyze**

Run: `flutter analyze lib/features/share/`
Expected: `No issues found!`.

- [ ] **Step 8.5: Commit**

```bash
git add lib/features/share/providers/video_composer.dart \
  lib/features/share/providers/video_composer.g.dart
git commit -m "feat : FfmpegVideoComposer 실 구현 (filter_complex + Statistics progress) (#7)"
```

---

## Task 9: `ComposingModal` 위젯

**Files:**
- Create: `lib/features/share/widgets/composing_modal.dart`
- Create: `test/features/share/widgets/composing_modal_test.dart`

- [ ] **Step 9.1: 실패하는 테스트 작성**

`test/features/share/widgets/composing_modal_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/constants/app_colors.dart';
import 'package:gridset/features/share/widgets/composing_modal.dart';

void main() {
  testWidgets('ComposingModal — 진행 progress 표시 + cancel 콜백', (tester) async {
    var cancelled = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        child: MaterialApp(
          home: Scaffold(
            body: ComposingModal(
              progress: 0.5,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('영상 만드는 중...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);

    final progressBar =
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progressBar.value, 0.5);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
  });

  testWidgets('ComposingModal — 배경 charcoal82', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        child: MaterialApp(
          home: Scaffold(
            body: ComposingModal(progress: 0.0, onCancel: () {}),
          ),
        ),
      ),
    );

    final coloredBox = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(ComposingModal),
        matching: find.byType(ColoredBox),
      ).first,
    );
    expect(coloredBox.color, AppColors.charcoal82);
  });
}
```

- [ ] **Step 9.2: 테스트 실행 (실패)**

Run: `flutter test test/features/share/widgets/composing_modal_test.dart`
Expected: FAIL — `ComposingModal` 정의 없음.

- [ ] **Step 9.3: 위젯 작성**

`lib/features/share/widgets/composing_modal.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';

/// 영상 합성 진행 modal — full-screen charcoal82 dim + 진행 bar + 취소 버튼.
///
/// 호출자가 200ms 이후만 노출하도록 timing 제어. 본 위젯은 stateless presentation.
class ComposingModal extends StatelessWidget {
  const ComposingModal({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  final double progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.charcoal82,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '영상 만드는 중...',
                style: AppTextStyles.body_16
                    .copyWith(color: AppColors.offWhite),
              ),
              SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 360.w,
                child: LinearProgressIndicator(
                  value: progress,
                  color: AppColors.offWhite,
                  backgroundColor: AppColors.charcoal40,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.offWhite),
                ),
                child: Text(
                  '취소',
                  style: AppTextStyles.body_16
                      .copyWith(color: AppColors.offWhite),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 9.4: 테스트 실행 (PASS)**

Run: `flutter test test/features/share/widgets/composing_modal_test.dart`
Expected: 2 PASS.

- [ ] **Step 9.5: Commit**

```bash
git add lib/features/share/widgets/composing_modal.dart \
  test/features/share/widgets/composing_modal_test.dart
git commit -m "feat : ComposingModal — 영상 합성 진행 + 취소 (#7)"
```

---

## Task 10: `ShareCoordinator` orchestration

**Files:**
- Create: `lib/features/share/share_coordinator.dart`
- Create: `test/features/share/share_coordinator_test.dart`

- [ ] **Step 10.1: 실패하는 테스트 작성 (Fake 어댑터 3개)**

`test/features/share/share_coordinator_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/share/models/cell_source.dart';
import 'package:gridset/features/share/providers/image_capturer.dart';
import 'package:gridset/features/share/providers/share_dispatcher.dart';
import 'package:gridset/features/share/providers/video_composer.dart';
import 'package:gridset/features/share/share_coordinator.dart';
import 'package:photo_manager/photo_manager.dart';

class _FakeImageCapturer implements ImageCapturer {
  Uint8List bytes = Uint8List.fromList([1]);
  int callCount = 0;
  @override
  Future<Uint8List> capturePng({
    required GlobalKey key,
    required int longEdgePx,
  }) async {
    callCount++;
    return bytes;
  }
}

class _FakeVideoComposer implements VideoComposer {
  String outPath = '/tmp/fake.mp4';
  int callCount = 0;
  bool cancelled = false;
  @override
  Future<String> composeMp4({
    required List<CellSource> cells,
    required CanvasRatio canvas,
    required int longEdgePx,
    required int fps,
    required int tMinMs,
    required void Function(double) onProgress,
  }) async {
    callCount++;
    onProgress(1.0);
    return outPath;
  }
  @override
  Future<void> cancel() async => cancelled = true;
}

class _FakeDispatcher implements ShareDispatcher {
  List<String>? lastFilePaths;
  int callCount = 0;
  @override
  Future<void> share({required List<String> filePaths, String? subject}) async {
    callCount++;
    lastFilePaths = filePaths;
  }
}

AssetEntity _photo(String id) =>
    AssetEntity(id: id, typeInt: 1, width: 100, height: 100);
AssetEntity _video(String id) => AssetEntity(
      id: id, typeInt: 2, width: 100, height: 100,
      duration: 5,
    );

GridSuggestion _suggestion(Map<int, String> mediaByCellId) => GridSuggestion(
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      ),
      mediaByCellId: mediaByCellId,
      loss: 0.0,
      templateName: 'test_2',
    );

void main() {
  testWidgets('사진만 — ImageCapturer 호출 + share PNG', (tester) async {
    final cap = _FakeImageCapturer();
    final composer = _FakeVideoComposer();
    final dispatcher = _FakeDispatcher();

    final cardKey = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        imageCapturerProvider.overrideWith((_) => cap),
        videoComposerProvider.overrideWith((_) => composer),
        shareDispatcherProvider.overrideWith((_) => dispatcher),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        child: MaterialApp(
          home: Scaffold(body: RepaintBoundary(key: cardKey)),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );
    final coordinator = ShareCoordinator(container);
    await coordinator.run(
      cardKey: cardKey,
      suggestion: _suggestion({0: 'a', 1: 'b'}),
      canvas: const CanvasRatio.square(),
      assetsById: {'a': _photo('a'), 'b': _photo('b')},
    );

    expect(cap.callCount, 1);
    expect(composer.callCount, 0);
    expect(dispatcher.callCount, 1);
    expect(dispatcher.lastFilePaths, hasLength(1));
    expect(dispatcher.lastFilePaths!.first, endsWith('.png'));
  });

  testWidgets('영상 1+ — VideoComposer 호출 + share MP4', (tester) async {
    final cap = _FakeImageCapturer();
    final composer = _FakeVideoComposer();
    final dispatcher = _FakeDispatcher();

    final cardKey = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        imageCapturerProvider.overrideWith((_) => cap),
        videoComposerProvider.overrideWith((_) => composer),
        shareDispatcherProvider.overrideWith((_) => dispatcher),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        child: MaterialApp(
          home: Scaffold(body: RepaintBoundary(key: cardKey)),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );
    final coordinator = ShareCoordinator(container);
    await coordinator.run(
      cardKey: cardKey,
      suggestion: _suggestion({0: 'a', 1: 'b'}),
      canvas: const CanvasRatio.square(),
      assetsById: {'a': _video('a'), 'b': _photo('b')},
    );

    expect(cap.callCount, 0);
    expect(composer.callCount, 1);
    expect(dispatcher.callCount, 1);
    expect(dispatcher.lastFilePaths!.first, endsWith('.mp4'));
  });
}
```

- [ ] **Step 10.2: 테스트 실행 (실패)**

Run: `flutter test test/features/share/share_coordinator_test.dart`
Expected: FAIL — `ShareCoordinator` 정의 없음.

- [ ] **Step 10.3: ShareCoordinator 구현**

`lib/features/share/share_coordinator.dart`:

```dart
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../cores/grid_suggestor/grid_suggestor.dart';
import 'models/cell_source.dart';
import 'providers/image_capturer.dart';
import 'providers/share_dispatcher.dart';
import 'providers/video_composer.dart';
import 'services/t_min_calculator.dart';

/// "이걸로" 흐름 orchestration — 사진/영상 분기 + 캡처/합성 + share.
///
/// 컴포넌트 트리: SuggestionPage 의 onPick callback 이 호출.
/// `cardKey` 는 RepaintBoundary 로 wrapping 된 카드의 GlobalKey.
class ShareCoordinator {
  ShareCoordinator(this._ref);
  final ProviderContainer _ref;

  /// 분기 + 흐름 실행. progress 콜백은 ComposingModal 갱신용 (영상 분기만).
  Future<void> run({
    required GlobalKey cardKey,
    required GridSuggestion suggestion,
    required CanvasRatio canvas,
    required Map<String, AssetEntity> assetsById,
    void Function(double progress)? onProgress,
  }) async {
    final hasVideo = _hasVideoCell(suggestion, assetsById);
    if (!hasVideo) {
      await _runPhotoBranch(cardKey, suggestion, canvas, assetsById);
      return;
    }
    await _runVideoBranch(suggestion, canvas, assetsById, onProgress);
  }

  bool _hasVideoCell(
    GridSuggestion suggestion,
    Map<String, AssetEntity> assetsById,
  ) {
    for (final assetId in suggestion.mediaByCellId.values) {
      final asset = assetsById[assetId];
      if (asset != null && asset.type == AssetType.video) return true;
    }
    return false;
  }

  Future<void> _runPhotoBranch(
    GlobalKey cardKey,
    GridSuggestion suggestion,
    CanvasRatio canvas,
    Map<String, AssetEntity> assetsById,
  ) async {
    final capturer = _ref.read(imageCapturerProvider);
    final dispatcher = _ref.read(shareDispatcherProvider);

    final bytes = await capturer.capturePng(key: cardKey, longEdgePx: 1080);

    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${tempDir.path}/gridset_$ts.png';
    await File(path).writeAsBytes(bytes);

    await dispatcher.share(filePaths: [path], subject: 'Gridset');
  }

  Future<void> _runVideoBranch(
    GridSuggestion suggestion,
    CanvasRatio canvas,
    Map<String, AssetEntity> assetsById,
    void Function(double progress)? onProgress,
  ) async {
    final composer = _ref.read(videoComposerProvider);
    final dispatcher = _ref.read(shareDispatcherProvider);

    final cells = await _buildCellSources(suggestion, assetsById);
    final tMin = computeTMinMs(
      cells.whereType<VideoSource>().map((v) => v.durationMs),
    );

    final outPath = await composer.composeMp4(
      cells: cells,
      canvas: canvas,
      longEdgePx: 1080,
      fps: 30,
      tMinMs: tMin,
      onProgress: onProgress ?? (_) {},
    );

    await dispatcher.share(filePaths: [outPath], subject: 'Gridset');
  }

  Future<List<CellSource>> _buildCellSources(
    GridSuggestion suggestion,
    Map<String, AssetEntity> assetsById,
  ) async {
    final bboxes = cellBBoxes(suggestion.tree);
    final result = <CellSource>[];
    for (final entry in suggestion.mediaByCellId.entries) {
      final cellId = entry.key;
      final assetId = entry.value;
      final asset = assetsById[assetId];
      final bbox = bboxes[cellId];
      if (asset == null || bbox == null) continue;
      final file = await asset.file;
      if (file == null) continue;
      if (asset.type == AssetType.video) {
        result.add(VideoSource(
          cellId: cellId,
          bbox: bbox,
          filePath: file.path,
          durationMs: asset.videoDuration.inMilliseconds,
        ));
      } else {
        result.add(PhotoSource(
          cellId: cellId,
          bbox: bbox,
          filePath: file.path,
        ));
      }
    }
    return result;
  }
}
```

- [ ] **Step 10.4: 테스트 실행 (PASS)**

Run: `flutter test test/features/share/share_coordinator_test.dart`
Expected: 2 PASS.

(주의: `_runPhotoBranch` 에서 `path_provider.getTemporaryDirectory` 가 native 호출이라 단위 테스트 환경에서 fail 가능. mock 필요시 `path_provider_platform_interface` mock 추가. 본 테스트가 fail 한다면 Step 10.5 로 보강.)

- [ ] **Step 10.5: path_provider mock 추가 (Step 10.4 fail 시)**

Run: `flutter pub add --dev plugin_platform_interface`

테스트 main 시작 부분에 추가:

```dart
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

void main() {
  setUp(() {
    PathProviderPlatform.instance = _FakePathProvider();
  });
  // ... 기존 테스트들
}
```

- [ ] **Step 10.6: Commit**

```bash
git add lib/features/share/share_coordinator.dart \
  test/features/share/share_coordinator_test.dart
git commit -m "feat : ShareCoordinator — 사진/영상 분기 + share 흐름 (#7)"
```

---

## Task 11: SuggestionPage 연결 (`onPick` → ShareCoordinator)

**Files:**
- Modify: `lib/features/suggestion/suggestion_page.dart`

- [ ] **Step 11.1: SuggestionPage 변경**

`lib/features/suggestion/suggestion_page.dart` 의 변경 두 곳:

(1) `_Loaded.itemBuilder` 안 `SuggestionCard` 를 `RepaintBoundary` 로 wrapping. 단 selected card 만 캡처 대상이라 GlobalKey 는 한 개만:

먼저 `_SuggestionPageState` 에 GlobalKey 추가:

```dart
final GlobalKey _shareCardKey = GlobalKey();
```

`itemBuilder` 안 `SuggestionCard` 를 wrapping. selected 카드일 때만 GlobalKey 부여:

```dart
itemBuilder: (_, i) {
  final selected = i == state.selectedIndex;
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: selected ? 1.0 : 0.5,
      child: Center(
        child: RepaintBoundary(
          key: selected ? _shareCardKey : null,
          child: SuggestionCard(
            suggestion: state.suggestions[i],
            canvas: state.canvas,
            assetsById: assetsById,
          ),
        ),
      ),
    ),
  );
},
```

(2) `onPick` callback 변경 — SnackBar stub 제거:

```dart
onPick: () => _onPick(context, ref, state),
```

`_onPick` 메서드 추가 (`_SuggestionPageState` 안):

```dart
import '../share/share_coordinator.dart';
// ...

Future<void> _onPick(
  BuildContext context,
  WidgetRef ref,
  SuggestionStateLoaded state,
) async {
  final container = ProviderScope.containerOf(context);
  final coordinator = ShareCoordinator(container);
  final suggestion = state.suggestions[state.selectedIndex];
  final assetsById = ref.read(selectedAssetsNotifierProvider);

  // 200ms 이후만 ComposingModal 노출. 사진만 분기는 보통 그 안에 끝남.
  bool modalShown = false;
  double progress = 0;
  void showModalIfNotYet() {
    if (modalShown) return;
    modalShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (_, setStateDialog) {
          // progress 갱신 — composer 의 onProgress 가 갱신 후 closeIfDone.
          return ComposingModal(
            progress: progress,
            onCancel: () async {
              await ref.read(videoComposerProvider).cancel();
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  Future.delayed(const Duration(milliseconds: 200), showModalIfNotYet);

  try {
    await coordinator.run(
      cardKey: _shareCardKey,
      suggestion: suggestion,
      canvas: state.canvas,
      assetsById: assetsById,
      onProgress: (p) {
        progress = p;
        // dialog 안 setStateDialog 호출은 builder 캡처라 직접 호출 불가.
        // 가장 단순한 방법: 짧은 latency 로 지속적 dialog rebuild.
      },
    );
  } catch (e) {
    if (modalShown && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      message: e.toString().contains('cancel')
          ? '취소되었어요'
          : '영상 만들기에 실패했어요',
      iconPath: 'assets/icons/icon_siren.svg',
    );
    return;
  }

  if (modalShown && context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}
```

기존 `_stub(context, '에디터는 곧 준비됩니다')` 의 onPick stub 호출은 제거.

import 추가:
```dart
import '../share/share_coordinator.dart';
import '../share/widgets/composing_modal.dart';
import '../share/providers/video_composer.dart';
import 'providers/selected_assets_provider.dart';   // 이미 있음
```

- [ ] **Step 11.2: 기존 suggestion_page test 회귀 (PASS)**

Run: `flutter test test/features/suggestion/suggestion_page_test.dart`
Expected: 모든 케이스 PASS (RepaintBoundary 추가는 widget tree 변화 — 기존 검증 영향 없음).

만약 fail: `find.byType(SuggestionCard)` 가 RepaintBoundary 안에 있어 descendant 로 해결.

- [ ] **Step 11.3: analyze**

Run: `flutter analyze lib/features/suggestion/`
Expected: `No issues found!`.

- [ ] **Step 11.4: Commit**

```bash
git add lib/features/suggestion/suggestion_page.dart
git commit -m "feat : SuggestionPage onPick → ShareCoordinator + RepaintBoundary wrapping (#7)"
```

---

## Task 12: spec cross-link 갱신

**Files:**
- Modify: `docs/superpowers/specs/2026-04-27-mapped-thumb-design.md`

- [ ] **Step 12.1: F08/F09 후속 hooks 행 갱신**

Run: `grep -n "F08\|F09\|PNG 저장\|share" docs/superpowers/specs/2026-04-27-mapped-thumb-design.md`

해당 행을 찾아 본 spec cross-link 추가:

```markdown
| F08 PNG 저장 / F09 MP4 저장 ✓ (별 PR #7 진행 중) | 본 spec 의 후속. 자세한 spec: [`2026-04-27-share-output-design.md`](./2026-04-27-share-output-design.md) |
```

- [ ] **Step 12.2: Commit**

```bash
git add docs/superpowers/specs/2026-04-27-mapped-thumb-design.md
git commit -m "docs : mapped-thumb spec F08/F09 후속 hooks cross-link (#7)"
```

---

## Task 13: 최종 회귀 + analyze

**Files:** 없음 (실행만)

- [ ] **Step 13.1: 전체 테스트**

Run: `flutter test`
Expected: 전체 PASS. 본 PR 추가 테스트 (Task 2~10) 약 20+ 케이스 + 기존 168 = 188+ PASS.

- [ ] **Step 13.2: analyze**

Run: `flutter analyze`
Expected: `No issues found!` (기존 deprecated 1건 제외 — 본 PR 무관).

- [ ] **Step 13.3: 매뉴얼 시각 검증**

iOS 시뮬레이터 또는 실 기기 (사진 권한 필수):

1. home → 비율 먼저 정하기 → 1:1 → 사진만 4장 선택 → 다음
2. suggestion 화면에서 카드 선택 → "이걸로" tap
3. iOS share 시트 노출 확인 (사진/카톡/AirDrop 등 옵션)
4. 사진 앱에 저장 → 1080×1080 PNG 확인
5. 뒤로 → 영상 1+ 사진 mix → 새 흐름 → "이걸로" tap
6. ComposingModal 노출 (영상 분기) + 진행 % bar 갱신 확인
7. 합성 완료 후 share 시트 노출 → MP4 확인
8. 도중 "취소" tap 동작 확인

만약 시각 / 동작 이상 발견 시 별 task 로 후속 작업.

---

## Task 14: PR 생성 (사용자 액션)

**Files:** 없음 (사용자 직접)

- [ ] **Step 14.1: push (사용자)**

CLAUDE.md 가 `git push 절대 금지` 라 사용자 명시 요청 시에만:

```bash
git push -u origin 20260427_#7_자동_제안_결과_share_PNG_MP4
```

- [ ] **Step 14.2: PR 생성 (사용자)**

```bash
gh pr create --title "20260427 #7 자동 제안 결과 share PNG MP4" \
  --body-file .issues/20260427_기능추가_share_first_출력_PNG_MP4.md
```

---

## Out of Scope (본 PR 비포함)

| 작업 | 후속 PR |
|---|---|
| 셀별 "루프 vs 트림" 사용자 토글 | F06 (셀 내 미디어 조작) |
| 셀 내 pinch-zoom / 위치 조정 | F06 |
| 워터마크 / 로고 | 후속 spec |
| 720p / 4K 출력 옵션 | 후속 spec (`longEdgePx` 인자만 변경) |
| Phase D 큐레이션 풀 보강 | 별 PR |
| 1080 thumbnail off-screen reload (화질 개선) | 후속 spec — 본 PR 은 화면 카드 캡처 |
| 음성 트랙 처리 | F07 영상 자동 싱크 sprint |

---

## Self-Review Notes (작성자 확인용)

**Spec coverage** (spec §1 결정 9개):
- 1. share 흐름 → Task 10, 11
- 2. 사진/영상 분기 → Task 10
- 3. 한 sprint 통합 → 본 plan 자체
- 4. 출력 1080 → Task 4 (computeOutputSize), Task 6 (ImageCapturer pixelRatio), Task 8 (FfmpegVideoComposer)
- 5. 30fps / 15s cap / H.264+AAC → Task 8 ffmpeg args
- 6. 영상 default 트림 → Task 4 buildFilterComplex (trim 항상 적용)
- 7. ComposingModal → Task 9, Task 11 노출
- 8. 어댑터 3개 → Task 5, 6, 7+8
- 9. spec 위치 → 신규 spec 이미 commit (`1136b14`)

**Spec §3-3 T_min**: Task 3.
**Spec §4 ImageCapturer**: Task 6 (interface) + Task 11 (cardKey wiring).
**Spec §5 VideoComposer**: Task 7 (interface) + Task 8 (ffmpeg).
**Spec §6 ComposingModal**: Task 9 + Task 11 노출 timing.
**Spec §7 에러 매트릭스**: Task 10 (`run` catch) + Task 11 (`_onPick` try/catch) + SnackBar.
**Spec §8 테스트 단위**: Task 2~10 각 단위 + 통합 검증.
**Spec §9 변경 영향 파일**: 모든 Task.
**Spec §10/11 비범위 / 후속 hooks**: 본 plan §"Out of Scope" + Task 12 cross-link.

**Placeholder scan**: `<issue-num>` 같은 미치환 placeholder 없음. 모든 commit 메시지 `(#7)` 명시.

**Type consistency**:
- `ImageCapturer.capturePng({key, longEdgePx})` — Task 6 정의, Task 10 호출 일관
- `VideoComposer.composeMp4({cells, canvas, longEdgePx, fps, tMinMs, onProgress})` — Task 7 정의, Task 10 호출 일관
- `ShareDispatcher.share({filePaths, subject})` — Task 5 정의, Task 10 호출 일관
- `CellSource` sealed → `PhotoSource` / `VideoSource` 분기 — Task 2 정의, Task 4/8/10 사용 일관
- `computeTMinMs(Iterable<int>)` — Task 3, Task 10 사용 일관 (cells 의 VideoSource.durationMs 추출)
- `computeOutputSize(canvas, longEdgePx) → Size` — Task 4, Task 8 사용 일관

**Implementation reality check**:
- Task 6 RepaintBoundary 캡처: 화면 카드 GlobalKey wiring 으로 단순화. spec §4-2 의 off-screen 권장 vs implementation 단순화 trade-off 명시.
- Task 8 FFmpegKit progress callback: enableStatisticsCallback 이 global 라 한 번에 한 합성만 가능 (본 sprint 가정 — 사용자가 동시 합성 호출 X).
- Task 10 path_provider: 단위 테스트 환경에서 native 의존 fail 가능 — Step 10.5 fallback 명시.
