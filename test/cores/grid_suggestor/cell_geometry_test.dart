import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('cellBBoxes', () {
    test('단일 Leaf — 전체 bbox', () {
      final bboxes = cellBBoxes(const Leaf(0));
      expect(bboxes[0]?.left, 0);
      expect(bboxes[0]?.top, 0);
      expect(bboxes[0]?.width, 1);
      expect(bboxes[0]?.height, 1);
    });

    test('V½ — 좌우 반반', () {
      final tree = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      final bboxes = cellBBoxes(tree);
      expect(bboxes[0]?.left, 0);
      expect(bboxes[0]?.width, 0.5);
      expect(bboxes[1]?.left, 0.5);
      expect(bboxes[1]?.width, 0.5);
    });

    test('H½ — 상하 반반', () {
      final tree = Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      final bboxes = cellBBoxes(tree);
      expect(bboxes[0]?.top, 0);
      expect(bboxes[0]?.height, 0.5);
      expect(bboxes[1]?.top, 0.5);
      expect(bboxes[1]?.height, 0.5);
    });

    test('중첩 — V½ 좌1 + 우 H⅓-등분 (n4_left1right3)', () {
      final tree = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(1), Leaf(2), Leaf(3)],
          ),
        ],
      );
      final bboxes = cellBBoxes(tree);
      // 좌측 큰 셀
      expect(bboxes[0]?.left, 0);
      expect(bboxes[0]?.width, 0.5);
      expect(bboxes[0]?.height, 1);
      // 우측 상단
      expect(bboxes[1]?.left, 0.5);
      expect(bboxes[1]?.top, 0);
      expect(bboxes[1]?.width, 0.5);
      expect(bboxes[1]?.height, closeTo(1 / 3, 1e-12));
      // 우측 하단
      expect(bboxes[3]?.top, closeTo(2 / 3, 1e-12));
      expect(bboxes[3]?.height, closeTo(1 / 3, 1e-12));
    });
  });

  group('cellAspectRatios', () {
    test('square 캔버스 — 셀 종횡비 = 정규화 비율', () {
      final tree = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      final ars = cellAspectRatios(tree, const CanvasRatio.square());
      expect(ars[0], closeTo(0.5, 1e-12)); // 0.5w / 1h * 1
      expect(ars[1], closeTo(0.5, 1e-12));
    });

    test('portrait916 캔버스 — 셀 종횡비 = w/h × canvas', () {
      const tree = Leaf(0);
      final ars = cellAspectRatios(tree, const CanvasRatio.portrait916());
      // 1w / 1h × 9/16 = 9/16
      expect(ars[0], closeTo(9 / 16, 1e-12));
    });
  });
}
