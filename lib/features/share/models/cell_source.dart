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
