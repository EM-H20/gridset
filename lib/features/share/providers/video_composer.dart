import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../cores/grid_suggestor/grid_suggestor.dart';
import '../models/cell_source.dart';
import '../services/grid_to_ffmpeg_filter.dart';

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

/// 프로덕션 구현 — ffmpeg_kit_flutter_new 의 filter_complex 합성.
///
/// `enableStatisticsCallback` 는 global 라 한 번에 한 합성만 가정.
/// 사용자가 동시 호출하지 않는다는 전제 (Suggestion onPick 흐름 단일 진입점).
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
      final id = s.getSessionId();
      if (id != null) {
        await FFmpegKit.cancel(id);
      }
      _activeSession = null;
    }
  }
}

@Riverpod(keepAlive: true)
VideoComposer videoComposer(Ref ref) => FfmpegVideoComposer();
