import '../models/grid_node.dart';
import '../models/named_template.dart';

/// N=2 큐레이션 — V½, H½, V60-40 3개.
///
/// Phase A 의 stub 큐레이션. Phase B 에서 패턴 다양화·시각 iterate.
/// Dart 제약상 (Split non-const) 모든 템플릿은 final 로 초기화.
final n2Templates = <NamedTemplate>[
  NamedTemplate(
    name: 'n2_v_half',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [0.5],
      children: const [Leaf(0), Leaf(1)],
    ),
    cellIds: const [0, 1],
  ),
  NamedTemplate(
    name: 'n2_h_half',
    tree: Split(
      axis: SplitAxis.horizontal,
      positions: const [0.5],
      children: const [Leaf(0), Leaf(1)],
    ),
    cellIds: const [0, 1],
  ),
  NamedTemplate(
    name: 'n2_v_60_40',
    tree: Split(
      axis: SplitAxis.vertical,
      positions: const [0.6],
      children: const [Leaf(0), Leaf(1)],
    ),
    cellIds: const [0, 1],
  ),
];
