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
