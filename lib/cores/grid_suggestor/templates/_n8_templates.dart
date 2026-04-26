import '../models/grid_node.dart';
import '../models/named_template.dart';

/// N=8 큐레이션 — 3개.
final n8Templates = <NamedTemplate>[
  NamedTemplate(
    name: 'n8_grid4x2',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [1 / 4, 1 / 2, 3 / 4],
      children: [
        Split(
          axis: SplitAxis.horizontal,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [0.5],
          children: const [Leaf(2), Leaf(3)],
        ),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [0.5],
          children: const [Leaf(4), Leaf(5)],
        ),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [0.5],
          children: const [Leaf(6), Leaf(7)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6, 7],
  ),
  NamedTemplate(
    name: 'n8_grid2x4',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [1 / 4, 1 / 2, 3 / 4],
      children: [
        Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(2), Leaf(3)],
        ),
        Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(4), Leaf(5)],
        ),
        Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(6), Leaf(7)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6, 7],
  ),
  NamedTemplate(
    name: 'n8_top4_bottom4',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [0.5],
      children: [
        Split(
          axis: SplitAxis.vertical,
          positions: const [1 / 4, 1 / 2, 3 / 4],
          children: const [Leaf(0), Leaf(1), Leaf(2), Leaf(3)],
        ),
        Split(
          axis: SplitAxis.vertical,
          positions: const [1 / 4, 1 / 2, 3 / 4],
          children: const [Leaf(4), Leaf(5), Leaf(6), Leaf(7)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5, 6, 7],
  ),
];
