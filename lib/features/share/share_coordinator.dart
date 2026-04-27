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
    if (!hasVideoCell(suggestion, assetsById)) {
      await _runPhotoBranch(cardKey);
      return;
    }
    await _runVideoBranch(suggestion, canvas, assetsById, onProgress);
  }

  /// 영상 셀 포함 여부 판단 — run() 호출 전 분기 UI(ComposingModal 노출 등)에도 활용 가능.
  ///
  /// `@visibleForTesting` 로 노출 — 단위 테스트에서 분기 결정 검증.
  @visibleForTesting
  bool hasVideoCell(
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
    await File(path).writeAsBytes(bytes);

    await dispatcher.share(filePaths: [path], subject: 'Gridset');
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
  /// `asset.file` 은 native 호출 — 테스트 환경에서 null 반환 가능.
  /// null file 셀은 skip (실제 디바이스에서는 발생하지 않아야 함).
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
