import 'dart:ui' show Size;

import '../../../cores/grid_suggestor/grid_suggestor.dart';
import '../models/cell_source.dart';

/// 출력 사이즈 계산 — shortEdge 기준, 계산된 긴 변만 16배수 정렬.
///
/// `shortEdgePx`: 짧은 변 픽셀 수 (spec §1: 세로 카드→width, 가로 카드→height).
/// - ar >= 1 (가로 또는 정사각): height = shortEdgePx, width = shortEdgePx * ar
/// - ar < 1 (세로): width = shortEdgePx, height = shortEdgePx / ar
///
/// 짧은 변은 입력값 그대로 유지. 비율 계산으로 나온 긴 변만 16배수 올림.
/// 이유: spec §1 에서 1080px 짧은 변이 명시 → 그대로 보존해야 의도한 해상도.
Size computeOutputSize(CanvasRatio canvas, int shortEdgePx) {
  final ar = canvas.value;
  late int w, h;
  if (ar == 1) {
    // 정사각형: 양 변 모두 입력값 그대로 (계산 불필요)
    w = shortEdgePx;
    h = shortEdgePx;
  } else if (ar > 1) {
    // 가로가 더 넓음 → height 가 짧은 변, width 는 비율 계산 후 16배수 정렬
    h = shortEdgePx;
    w = _align16((shortEdgePx * ar).round());
  } else {
    // 세로가 더 넓음 → width 가 짧은 변, height 는 비율 계산 후 16배수 정렬
    w = shortEdgePx;
    h = _align16((shortEdgePx / ar).round());
  }
  return Size(w.toDouble(), h.toDouble());
}

// libx264: 가로/세로 모두 16배수 필요 (4:2:0 chroma subsampling)
int _align16(int v) => ((v + 15) ~/ 16) * 16;

/// ffmpeg input flags — photo 는 `-loop 1 -t {sec}` 추가, video 는 `-i` 만.
///
/// photo 에 `-loop 1 -t` 를 붙이는 이유: 정지 이미지를 T_min 동안 스트림으로
/// 공급하지 않으면 overlay 연결 시 duration 불일치가 발생한다.
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

/// filter_complex 문자열 생성 — bg color → 각 셀 trim/scale → overlay 누적.
///
/// 배경색 0xF7F4ED: 디자인 시스템 Cream 색상 (AppColors.cream 동일 값).
/// 각 셀 좌표를 16배수 정렬 후 overlay 하는 이유:
/// scale 결과와 overlay 좌표가 일치하지 않으면 픽셀 경계 오류가 발생한다.
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

  final cellPositions = <(int x, int y, int w, int h)>[];
  for (var i = 0; i < cells.length; i++) {
    final c = cells[i];
    final x = _align16((c.bbox.left * outputWidth).round());
    final y = _align16((c.bbox.top * outputHeight).round());
    final w = _align16((c.bbox.width * outputWidth).round());
    final h = _align16((c.bbox.height * outputHeight).round());
    cellPositions.add((x, y, w, h));

    // video: setpts 로 PTS 초기화 필요 (trim 후 타임스탬프가 남으면 overlay 싱크 오류)
    final isVideo = c is VideoSource;
    final setpts = isVideo ? ',setpts=PTS-STARTPTS' : '';
    buf.write('[$i:v]trim=duration=$tSec$setpts'
        ',scale=$w:$h,setsar=1[c$i];');
  }

  // overlay 누적: [bg][c0]→[s0]; [s0][c1]→[s1]; … → [out]
  buf.write('[bg]');
  for (var i = 0; i < cells.length; i++) {
    final (x, y, _, _) = cellPositions[i];
    final outLabel = i == cells.length - 1 ? 'out' : 's$i';
    if (i > 0) buf.write('[s${i - 1}]');
    buf.write('[c$i]overlay=x=$x:y=$y[$outLabel]');
    if (i < cells.length - 1) buf.write(';');
  }
  return buf.toString();
}
