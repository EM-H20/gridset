import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('GridNode', () {
    test('Leaf == Leaf 동일 cellId', () {
      expect(const Leaf(0), equals(const Leaf(0)));
      expect(const Leaf(0).hashCode, const Leaf(0).hashCode);
    });

    test('Leaf 다른 cellId 는 ≠', () {
      expect(const Leaf(0), isNot(equals(const Leaf(1))));
    });

    test('Split: positions 와 children 길이 mismatch 는 assert', () {
      expect(
        () => Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(0)],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Split: positions 비어있으면 assert', () {
      expect(
        () => Split(
          axis: SplitAxis.vertical,
          positions: const [],
          children: const [Leaf(0), Leaf(1)],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('cellIdsOf: 단일 Leaf', () {
      expect(cellIdsOf(const Leaf(0)), [0]);
    });

    test('cellIdsOf: 깊이 1 split 2-way', () {
      final tree = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      expect(cellIdsOf(tree), [0, 1]);
    });

    test('cellIdsOf: 중첩 트리', () {
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
      expect(cellIdsOf(tree), [0, 1, 2, 3]);
    });
  });
}
