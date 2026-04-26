import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('treeFingerprint', () {
    test('동일 트리 → 동일 fingerprint', () {
      final a = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      final b = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      expect(treeFingerprint(a), treeFingerprint(b));
    });

    test('positions ±10% 이내 → 동일 fingerprint (rounding)', () {
      final a = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      final b = Split(
        axis: SplitAxis.vertical,
        positions: const [0.55], // 5% 차이 — 같은 0.1 buckets
        children: const [Leaf(0), Leaf(1)],
      );
      expect(treeFingerprint(a), treeFingerprint(b));
    });

    test('axis 다르면 fingerprint 다름', () {
      final a = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      final b = Split(
        axis: SplitAxis.horizontal,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      expect(treeFingerprint(a), isNot(treeFingerprint(b)));
    });

    test('positions 0.2 차이 → 다른 fingerprint', () {
      final a = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      final b = Split(
        axis: SplitAxis.vertical,
        positions: const [0.7],
        children: const [Leaf(0), Leaf(1)],
      );
      expect(treeFingerprint(a), isNot(treeFingerprint(b)));
    });

    test('cellId 가 달라도 구조 동일하면 같은 fingerprint (구조 기반 dedup)', () {
      final a = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      final b = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(2), Leaf(3)],
      );
      expect(treeFingerprint(a), treeFingerprint(b));
    });
  });

  group('rankCandidates', () {
    test('loss 오름차순 정렬', () {
      final candidates = [
        GridSuggestion(
          tree: Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(0), Leaf(1)],
          ),
          mediaByCellId: const {0: 'm1', 1: 'm2'},
          loss: 2.0,
          templateName: 'b',
        ),
        GridSuggestion(
          tree: const Leaf(0),
          mediaByCellId: const {0: 'm1'},
          loss: 1.0,
          templateName: 'a',
        ),
        GridSuggestion(
          tree: Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(2), Leaf(3)],
          ),
          mediaByCellId: const {2: 'm3', 3: 'm4'},
          loss: 3.0,
          templateName: 'c',
        ),
      ];
      final ranked = rankCandidates(candidates);
      expect(ranked.map((c) => c.templateName).toList(), ['a', 'b', 'c']);
    });

    test('loss 동률 시 templateName 알파벳 순', () {
      final candidates = [
        GridSuggestion(
          tree: const Leaf(0),
          mediaByCellId: const {0: 'm1'},
          loss: 1.0,
          templateName: 'banana',
        ),
        GridSuggestion(
          tree: Split(
            axis: SplitAxis.horizontal,
            positions: const [0.5],
            children: const [Leaf(1), Leaf(2)],
          ),
          mediaByCellId: const {1: 'm2', 2: 'm3'},
          loss: 1.0,
          templateName: 'apple',
        ),
        GridSuggestion(
          tree: Split(
            axis: SplitAxis.vertical,
            positions: const [0.5],
            children: const [Leaf(3), Leaf(4)],
          ),
          mediaByCellId: const {3: 'm4', 4: 'm5'},
          loss: 1.0,
          templateName: 'cherry',
        ),
      ];
      final ranked = rankCandidates(candidates);
      expect(
        ranked.map((c) => c.templateName).toList(),
        ['apple', 'banana', 'cherry'],
      );
    });

    test('fingerprint 동일 후보 중 더 낮은 loss 만 살아남음', () {
      final sameTree = Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      );
      final candidates = [
        GridSuggestion(
          tree: sameTree,
          mediaByCellId: const {0: 'm1', 1: 'm2'},
          loss: 2.0,
          templateName: 'high_loss',
        ),
        GridSuggestion(
          tree: sameTree,
          mediaByCellId: const {0: 'm1', 1: 'm2'},
          loss: 1.0,
          templateName: 'low_loss',
        ),
      ];
      final ranked = rankCandidates(candidates);
      expect(ranked.length, 1);
      expect(ranked.first.templateName, 'low_loss');
    });
  });
}

GridSuggestion _candidate({required String name, required double loss}) {
  return GridSuggestion(
    tree: const Leaf(0),
    mediaByCellId: const {0: 'm1'},
    loss: loss,
    templateName: name,
  );
}
