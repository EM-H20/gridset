import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/share/models/cell_source.dart';
import 'package:gridset/features/share/services/grid_to_ffmpeg_filter.dart';

void main() {
  test('출력 사이즈 — 1:1 정사각, shortEdge=1080', () {
    // ar=1.0: w=1080, h=1080 (둘 다 같으므로 모두 1080)
    final size = computeOutputSize(const CanvasRatio.square(), 1080);
    expect(size.width, 1080);
    expect(size.height, 1080);
  });

  test('출력 사이즈 — 9:16 세로, shortEdge(width)=1080', () {
    // ar=9/16=0.5625 (<1): width=shortEdge=1080, height=1080/0.5625=1920
    // 짧은 변(width)은 입력값 그대로, 긴 변(height)만 16배수 정렬
    final size = computeOutputSize(const CanvasRatio.portrait916(), 1080);
    expect(size.width, 1080);
    expect(size.height, 1920);
    expect(size.height % 16, 0); // 계산된 긴 변만 16배수
  });

  test('출력 사이즈 — 4:5 세로, 16배수 정렬', () {
    // ar=4/5=0.8 (<1): width=1080, height=1080/0.8=1350 → 16배수=1360
    // 짧은 변(width)은 입력값 그대로, 긴 변(height)만 16배수 정렬
    final size = computeOutputSize(const CanvasRatio.portrait45(), 1080);
    expect(size.width, 1080);
    expect(size.height, 1360);
    expect(size.height % 16, 0); // 계산된 긴 변만 16배수
  });

  test('출력 사이즈 — 16:9 가로, shortEdge(height)=1080', () {
    // ar=16/9≈1.778 (>=1): height=shortEdge=1080, width=1080*(16/9)=1920
    // 짧은 변(height)은 입력값 그대로, 긴 변(width)만 16배수 정렬
    final size = computeOutputSize(const CanvasRatio.landscape169(), 1080);
    expect(size.width, 1920);
    expect(size.height, 1080);
    expect(size.width % 16, 0); // 계산된 긴 변만 16배수
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
    expect(filter, contains('color=c=0xF7F4ED:size=1080x1080:r=30:duration=5'));
    expect(filter, contains('trim=duration=5'));
    expect(filter, contains('overlay=x=0:y=0'));
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
