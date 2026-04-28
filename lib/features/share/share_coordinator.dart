import 'dart:developer' as developer;
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
/// SuggestionPage 의 onPick callback 에서 호출.
/// `ProviderContainer` 를 직접 주입받아 provider 참조
/// (위젯 트리 밖에서도 동작하도록 ref 대신 container 사용).
class ShareCoordinator {
  ShareCoordinator(this._container);

  final ProviderContainer _container;

  /// 분기 + 흐름 실행.
  ///
  /// `onProgress` 는 ComposingModal 갱신용 (영상 분기에서만 호출, 0..1).
  /// `cardKey` 는 RepaintBoundary 를 wrapping 한 카드의 GlobalKey.
  Future<void> run({
    required GlobalKey cardKey,
    required GridSuggestion suggestion,
    required CanvasRatio canvas,
    required Map<String, AssetEntity> assetsById,
    void Function(double progress)? onProgress,
  }) async {
    if (!_hasVideoCell(suggestion, assetsById)) {
      await _runPhotoBranch(cardKey);
      return;
    }
    await _runVideoBranch(suggestion, canvas, assetsById, onProgress);
  }

  /// 진행 중 영상 합성 cancel — UI 의 ComposingModal "취소" 버튼 → 호출.
  /// 사진 분기는 너무 짧아 cancel 의미 없음 (no-op).
  Future<void> cancel() async {
    await _container.read(videoComposerProvider).cancel();
  }

  /// 영상 셀 포함 여부 판단 — 사진/영상 분기 결정용.
  ///
  /// 단위 테스트에서는 `run()` 의 side-effect (ImageCapturer/VideoComposer
  /// callCount) 로 분기 결정을 검증하므로 private 으로 유지한다.
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

  Future<void> _runPhotoBranch(GlobalKey cardKey) async {
    final capturer = _container.read(imageCapturerProvider);
    final dispatcher = _container.read(shareDispatcherProvider);

    final bytes = await capturer.capturePng(key: cardKey, longEdgePx: 1080);

    // 임시 파일에 PNG 저장 — share_plus 가 파일 경로 기반으로 동작.
    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${tempDir.path}/gridset_$ts.png';

    try {
      await File(path).writeAsBytes(bytes);
      await dispatcher.share(filePaths: [path], subject: 'Gridset');
    } on FileSystemException catch (e, st) {
      developer.log(
        'PNG 저장 실패: $e',
        name: 'ShareCoordinator',
        error: e,
        stackTrace: st,
      );
      // 실패 케이스에선 호출자가 SnackBar 로 안내 — VideoComposer 와 동일 흐름.
      rethrow;
    }
    // share 성공 시점에 즉시 삭제하지 않는다 — share_plus 가 OS 핸드오프 한 뒤
    // 일부 share target (카톡 등) 이 비동기로 늦게 read 하면 race 로 실패. MP4
    // 분기와 동일하게 임시 파일 보존 → OS cache directory 가 자동 만료.
    // tempDir 이 grow 하지 않게 호출 진입 시 stale 파일 일괄 cleanup (헬퍼).
  }

  Future<void> _runVideoBranch(
    GridSuggestion suggestion,
    CanvasRatio canvas,
    Map<String, AssetEntity> assetsById,
    void Function(double progress)? onProgress,
  ) async {
    final composer = _container.read(videoComposerProvider);
    final dispatcher = _container.read(shareDispatcherProvider);

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

  /// suggestion + assetsById → CellSource 리스트 변환.
  ///
  /// 셀 누락은 silent skip 하지 않고 즉시 throw — 셀 1개라도 빠지면 결과
  /// MP4 가 사용자 의도와 다른 형태로 (영상 빠진 채) 출력되어 "성공" 으로
  /// share 되는 데이터 무결성 문제 발생. 권한 limited 변경 / asset 삭제 등
  /// edge case 도 호출자가 SnackBar 로 명시적 안내해야 한다.
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

      if (asset == null) {
        throw StateError(
          'asset 누락 — cellId=$cellId assetId=$assetId. '
          '권한 변경 또는 asset 삭제 가능성.',
        );
      }
      if (bbox == null) {
        throw StateError(
          'bbox 누락 — cellId=$cellId. 알고리즘 계약 위반.',
        );
      }

      final file = await asset.file;
      if (file == null) {
        throw StateError(
          'asset.file 누락 — cellId=$cellId id=$assetId. '
          '권한 limited 변경 가능성.',
        );
      }

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
