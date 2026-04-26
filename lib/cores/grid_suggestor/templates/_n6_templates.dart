import '../models/grid_node.dart';
import '../models/named_template.dart';

/// N=6 큐레이션 — 5개.
final n6Templates = <NamedTemplate>[
  NamedTemplate(
    name: 'n6_grid2x3',
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
          positions: const [1 / 3, 2 / 3],
          children: const [Leaf(3), Leaf(4), Leaf(5)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5],
  ),
  NamedTemplate(
    name: 'n6_grid3x2',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [1 / 3, 2 / 3],
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
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5],
  ),
  NamedTemplate(
    name: 'n6_top2_bottom4',
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
          positions: const [1 / 4, 1 / 2, 3 / 4],
          children: const [Leaf(2), Leaf(3), Leaf(4), Leaf(5)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5],
  ),
  NamedTemplate(
    name: 'n6_top4_bottom2',
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
          positions: const [0.5],
          children: const [Leaf(4), Leaf(5)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5],
  ),
  NamedTemplate(
    name: 'n6_left2_right4',
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
          positions: const [1 / 4, 1 / 2, 3 / 4],
          children: const [Leaf(2), Leaf(3), Leaf(4), Leaf(5)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3, 4, 5],
  ),
];
