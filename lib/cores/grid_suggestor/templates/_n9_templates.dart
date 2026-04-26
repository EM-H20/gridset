import '../models/grid_node.dart';
import '../models/named_template.dart';

/// N=9 큐레이션 — 3개.
final n9Templates = <NamedTemplate>[
  NamedTemplate(
    name: 'n9_grid3x3',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [1 / 3, 2 / 3],
      children: [
        Split(
          axis: SplitAxis.horizontal,
          positions: const [1 / 3, 2 / 3],
          children: const [Leaf(0), Leaf(1), Leaf(2)],
        ),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [1 / 3, 2 / 3],
          children: const [Leaf(3), Leaf(4), Leaf(5)],
        ),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [1 / 3, 2 / 3],
          children: const [Leaf(6), Leaf(7), Leaf(8)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6, 7, 8],
  ),
  NamedTemplate(
    name: 'n9_left1_right8_4x2',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [0.5],
      children: [
        const Leaf(0),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [1 / 4, 1 / 2, 3 / 4],
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
            Split(
              axis: SplitAxis.vertical,
              positions: const [0.5],
              children: const [Leaf(7), Leaf(8)],
            ),
          ],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6, 7, 8],
  ),
  NamedTemplate(
    name: 'n9_top1_bottom8_2x4',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [0.5],
      children: [
        const Leaf(0),
        Split(
          axis: SplitAxis.vertical,
          positions: const [1 / 4, 1 / 2, 3 / 4],
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
            Split(
              axis: SplitAxis.horizontal,
              positions: const [0.5],
              children: const [Leaf(7), Leaf(8)],
            ),
          ],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6, 7, 8],
  ),
];
