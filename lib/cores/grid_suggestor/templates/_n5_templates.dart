import '../models/grid_node.dart';
import '../models/named_template.dart';

/// N=5 큐레이션 — 4개. 5분할 균등은 화이트리스트 외라 v1 제외.
final n5Templates = <NamedTemplate>[
  NamedTemplate(
    name: 'n5_left1_right4_2x2',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [0.5],
      children: [
        const Leaf(0),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [0.5],
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
          ],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4],
  ),
  NamedTemplate(
    name: 'n5_top1_bottom4_2x2',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [0.5],
      children: [
        const Leaf(0),
        Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
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
          ],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4],
  ),
  NamedTemplate(
    name: 'n5_left2_right3',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [0.5],
      children: [
        Split(
          axis: SplitAxis.horizontal,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [1 / 3, 2 / 3],
          children: const [Leaf(2), Leaf(3), Leaf(4)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4],
  ),
  NamedTemplate(
    name: 'n5_top2_bottom3',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [0.5],
      children: [
        Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        Split(
          axis: SplitAxis.vertical,
          positions: const [1 / 3, 2 / 3],
          children: const [Leaf(2), Leaf(3), Leaf(4)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4],
  ),
];
