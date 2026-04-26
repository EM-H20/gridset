import '../models/grid_node.dart';
import '../models/named_template.dart';

/// N=4 큐레이션 — 5개.
final n4Templates = <NamedTemplate>[
  NamedTemplate(
    name: 'n4_grid2x2',
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
          positions: const [0.5],
          children: const [Leaf(2), Leaf(3)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3],
  ),
  NamedTemplate(
    name: 'n4_left1_right3',
    tree: Split(
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
    ),
    cellIds: const [0, 1, 2, 3],
  ),
  NamedTemplate(
    name: 'n4_top1_bottom3',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [0.5],
      children: [
        const Leaf(0),
        Split(
          axis: SplitAxis.vertical,
          positions: const [1 / 3, 2 / 3],
          children: const [Leaf(1), Leaf(2), Leaf(3)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2, 3],
  ),
  NamedTemplate(
    name: 'n4_v_quarters',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [1 / 4, 1 / 2, 3 / 4],
      children: const [Leaf(0), Leaf(1), Leaf(2), Leaf(3)],
    ),
    cellIds: const [0, 1, 2, 3],
  ),
  NamedTemplate(
    name: 'n4_h_quarters',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [1 / 4, 1 / 2, 3 / 4],
      children: const [Leaf(0), Leaf(1), Leaf(2), Leaf(3)],
    ),
    cellIds: const [0, 1, 2, 3],
  ),
];
