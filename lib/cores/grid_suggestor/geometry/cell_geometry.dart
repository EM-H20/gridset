import '../models/canvas_ratio.dart';
import '../models/grid_node.dart';

/// 알고리즘 모듈 전용 normalized rectangle (0..1 좌표계).
///
/// Flutter `Rect` 를 쓸 수 없는 이유: `lib/cores/grid_suggestor/` 는 `flutter/` import 금지 (spec §2-3).
/// 외부 호출자가 Flutter Rect 로 변환하고 싶으면 `Rect.fromLTWH(c.left, c.top, c.width, c.height)`.
class CellRect {
  final double left;
  final double top;
  final double width;
  final double height;
  const CellRect(this.left, this.top, this.width, this.height);

  @override
  bool operator ==(Object other) =>
      other is CellRect &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);
}

/// BSP 트리의 각 Leaf 에 대한 normalized bounding box.
///
/// 입력 트리가 정상이면 반환 Map 의 cellId set 은 cellIdsOf(node) 와 일치.
Map<int, CellRect> cellBBoxes(GridNode root) {
  final result = <int, CellRect>{};
  _visit(root, const CellRect(0, 0, 1, 1), result);
  return result;
}

/// 각 Leaf 의 셀 종횡비 = (정규화 너비 × canvas.value) / 정규화 높이.
///
/// 알고리즘이 미디어 종횡비와 비교할 값.
Map<int, double> cellAspectRatios(GridNode root, CanvasRatio canvas) {
  final bboxes = cellBBoxes(root);
  final canvasV = canvas.value;
  return bboxes.map(
    (id, r) => MapEntry(id, (r.width * canvasV) / r.height),
  );
}

void _visit(GridNode node, CellRect bounds, Map<int, CellRect> out) {
  switch (node) {
    case Leaf(:final cellId):
      out[cellId] = bounds;
    case Split(:final axis, :final positions, :final children):
      final segments = _segmentsAlong(positions);
      for (var i = 0; i < children.length; i++) {
        final (start, end) = segments[i];
        final childBounds = switch (axis) {
          SplitAxis.vertical => CellRect(
              bounds.left + bounds.width * start,
              bounds.top,
              bounds.width * (end - start),
              bounds.height,
            ),
          SplitAxis.horizontal => CellRect(
              bounds.left,
              bounds.top + bounds.height * start,
              bounds.width,
              bounds.height * (end - start),
            ),
        };
        _visit(children[i], childBounds, out);
      }
  }
}

/// positions [0.3, 0.7] → [(0, 0.3), (0.3, 0.7), (0.7, 1)]
List<(double, double)> _segmentsAlong(List<double> positions) {
  final result = <(double, double)>[];
  var prev = 0.0;
  for (final p in positions) {
    result.add((prev, p));
    prev = p;
  }
  result.add((prev, 1.0));
  return result;
}
