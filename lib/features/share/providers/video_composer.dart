import 'dart:async';
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
/// `enableStatisticsCallback` 는 global singleton 라 한 번에 한 합성만 가정
/// (Suggestion onPick 흐름 단일 진입점). 매 합성마다 callback 을 등록·해제해
/// 이전 호출의 stale closure 가 progress 누적되지 않게 한다.
///
/// `executeWithArgumentsAsync` 사용 — 동기 `executeWithArguments` 는 완료까지
/// await 하므로 cancel() 시점에 이미 종료된 세션을 가리킨다. async 변형은
/// session 즉시 반환 + 완료 콜백 분리라 진행 중 cancel 가능.
///
/// stateful (`_activeSession` 필드) 라 `keepAlive: true` 로 인스턴스 유지.
class FfmpegVideoComposer implements VideoComposer {
  FfmpegVideoComposer();

  FFmpegSession? _activeSession;
  String? _activeOutPath;

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

    // 이전 호출의 stale callback 해제 (global singleton).
    FFmpegKitConfig.enableStatisticsCallback(null);
    FFmpegKitConfig.enableStatisticsCallback((stats) {
      final timeMs = stats.getTime();
      onProgress((timeMs / tMinMs).clamp(0.0, 1.0));
    });

    final completer = Completer<ReturnCode?>();
    final session = await FFmpegKit.executeWithArgumentsAsync(args, (s) async {
      final code = await s.getReturnCode();
      if (!completer.isCompleted) completer.complete(code);
    });
    _activeSession = session;
    _activeOutPath = outPath;

    try {
      final returnCode = await completer.future;
      if (!ReturnCode.isSuccess(returnCode)) {
        await _cleanupTempFile(outPath);
        throw StateError('ffmpeg 실패 — returnCode=$returnCode');
      }
      return outPath;
    } finally {
      // global callback 해제 + state 초기화.
      FFmpegKitConfig.enableStatisticsCallback(null);
      _activeSession = null;
      _activeOutPath = null;
    }
  }

  @override
  Future<void> cancel() async {
    final s = _activeSession;
    final path = _activeOutPath;
    if (s != null) {
      final id = s.getSessionId();
      if (id != null) {
        await FFmpegKit.cancel(id);
      }
    }
    if (path != null) {
      await _cleanupTempFile(path);
    }
    // _activeSession / _activeOutPath null 화는 composeMp4 의 finally 에서.
  }

  Future<void> _cleanupTempFile(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }
}

@Riverpod(keepAlive: true)
VideoComposer videoComposer(Ref ref) => FfmpegVideoComposer();
