import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('NamedTemplate', () {
    test('cellIds 가 트리 traversal 결과와 일치하면 OK', () {
      final t = NamedTemplate(
        name: 'n2_v_half',
        tree: Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        cellIds: const [0, 1],
      );
      expect(t.name, 'n2_v_half');
      expect(t.cellIds, [0, 1]);
    });

    test('cellIds 와 cellIdsOf(tree) 비교 헬퍼로 mismatch 감지', () {
      final broken = NamedTemplate(
        name: 'broken',
        tree: Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        cellIds: const [0, 2],
      );
      expect(broken.cellIds, isNot(equals(cellIdsOf(broken.tree))));
    });

    test('동일 값으로 만든 두 NamedTemplate 은 ==', () {
      final a = NamedTemplate(
        name: 'n2_v_half',
        tree: Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        cellIds: const [0, 1],
      );
      final b = NamedTemplate(
        name: 'n2_v_half',
        tree: Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        cellIds: const [0, 1],
      );
      expect(a, equals(b));
    });
  });
}
