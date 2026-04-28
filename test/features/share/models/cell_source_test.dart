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
