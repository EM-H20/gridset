import '../models/grid_node.dart';
import '../models/named_template.dart';

/// N=7 큐레이션 — 4개. (큐레이션 가장 어려운 N — Phase D 시각 iterate 권장)
final n7Templates = <NamedTemplate>[
  NamedTemplate(
    name: 'n7_left1_right6_2x3',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [0.5],
      children: [
        const Leaf(0),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [1 / 3, 2 / 3],
          children: [
            Split(
              axis: SplitAxis.vertical,
              positions: const [0.5],
              children: const [Leaf(1), Leaf(2)],
            ),
            Split(
              axis: SplitAxis.vertical,
              positions: const [0.5],
              children: const [Leaf(3), Leaf(4)],
            ),
            Split(
              axis: SplitAxis.vertical,
              positions: const [0.5],
              children: const [Leaf(5), Leaf(6)],
            ),
          ],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6],
  ),
  NamedTemplate(
    name: 'n7_top1_bottom6_3x2',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [0.5],
      children: [
        const Leaf(0),
        Split(
          axis: SplitAxis.vertical,
          positions: const [1 / 3, 2 / 3],
          children: [
            Split(
              axis: SplitAxis.horizontal,
              positions: const [0.5],
              children: const [Leaf(1), Leaf(2)],
            ),
            Split(
              axis: SplitAxis.horizontal,
              positions: const [0.5],
              children: const [Leaf(3), Leaf(4)],
            ),
            Split(
              axis: SplitAxis.horizontal,
              positions: const [0.5],
              children: const [Leaf(5), Leaf(6)],
            ),
          ],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6],
  ),
  NamedTemplate(
    name: 'n7_left3_right4',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [0.5],
      children: [
        Split(
          axis: SplitAxis.horizontal,
          positions: const [1 / 3, 2 / 3],
          children: const [Leaf(0), Leaf(1), Leaf(2)],
        ),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [1 / 4, 1 / 2, 3 / 4],
          children: const [Leaf(3), Leaf(4), Leaf(5), Leaf(6)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6],
  ),
  NamedTemplate(
    name: 'n7_top3_bottom4',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [0.5],
      children: [
        Split(
          axis: SplitAxis.vertical,
          positions: const [1 / 3, 2 / 3],
          children: const [Leaf(0), Leaf(1), Leaf(2)],
        ),
        Split(
          axis: SplitAxis.vertical,
          positions: const [1 / 4, 1 / 2, 3 / 4],
          children: const [Leaf(3), Leaf(4), Leaf(5), Leaf(6)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6],
  ),
];
