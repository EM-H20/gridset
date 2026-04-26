import '../models/grid_node.dart';
import '../models/named_template.dart';

/// N=3 큐레이션 — 4개.
///
/// `n{N}_{descriptiveName}` 컨벤션 (spec §5-3).
/// Phase D 에서 /dev 갤러리 시각 iterate 로 교체될 수 있음.
final n3Templates = <NamedTemplate>[
  NamedTemplate(
    name: 'n3_v_thirds',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [1 / 3, 2 / 3],
      children: const [Leaf(0), Leaf(1), Leaf(2)],
    ),
    cellIds: const [0, 1, 2],
  ),
  NamedTemplate(
    name: 'n3_h_thirds',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [1 / 3, 2 / 3],
      children: const [Leaf(0), Leaf(1), Leaf(2)],
    ),
    cellIds: const [0, 1, 2],
  ),
  NamedTemplate(
    name: 'n3_left1_right2',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [0.5],
      children: [
        const Leaf(0),
        Split(
          axis: SplitAxis.horizontal,
          positions: const [0.5],
          children: const [Leaf(1), Leaf(2)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2],
  ),
  NamedTemplate(
    name: 'n3_top1_bottom2',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [0.5],
      children: [
        const Leaf(0),
        Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(1), Leaf(2)],
        ),
      ],
    ),
    cellIds: const [0, 1, 2],
  ),
];
