/// BSP (Binary Space Partition) 트리 — 그리드 레이아웃의 자료구조.
///
/// `Split` 노드: 한 축으로 N-way 분할. positions 길이 + 1 == children 길이.
/// `Leaf` 노드: 미디어가 들어갈 셀. cellId 는 트리 내 0..N-1 유일.
///
/// PRD §9-2-2 의 평면 V/H 표현은 균형 BSP 트리의 특수 케이스.
/// 비대칭 패턴("좌1+우3" 등)은 BSP 만 표현 가능.
sealed class GridNode {
  const GridNode();
}

final class Split extends GridNode {
  final SplitAxis axis;
  final List<double> positions;
  final List<GridNode> children;

  Split({
    required this.axis,
    required this.positions,
    required this.children,
  })  : assert(positions.isNotEmpty, 'positions must not be empty'),
        assert(
          children.length == positions.length + 1,
          'children.length must equal positions.length + 1',
        );

  @override
  bool operator ==(Object other) =>
      other is Split &&
      other.axis == axis &&
      _listEquals(other.positions, positions) &&
      _listEquals(other.children, children);

  @override
  int get hashCode =>
      Object.hash(axis, Object.hashAll(positions), Object.hashAll(children));
}

final class Leaf extends GridNode {
  final int cellId;
  const Leaf(this.cellId);

  @override
  bool operator ==(Object other) => other is Leaf && other.cellId == cellId;

  @override
  int get hashCode => cellId.hashCode;
}

enum SplitAxis { vertical, horizontal }

/// 트리 내 모든 Leaf 의 cellId 를 in-order 로 수집.
///
/// 큐레이션 무결성 검증(invariant: cellIds == 0..N-1) 과 NamedTemplate.cellIds 캐시에 사용.
List<int> cellIdsOf(GridNode node) {
  final result = <int>[];
  void visit(GridNode n) {
    switch (n) {
      case Leaf(:final cellId):
        result.add(cellId);
      case Split(:final children):
        for (final c in children) {
          visit(c);
        }
    }
  }
  visit(node);
  return result;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
