import 'grid_node.dart';

/// 큐레이션 템플릿 래퍼 — 이름 + BSP 트리 + cellIds traversal 캐시.
///
/// `name` 은 `n{N}_{descriptiveName}` 컨벤션 (snake_case).
/// `cellIds` 는 트리 traversal 결과의 const 캐시 — templates_test 가 일치 검증.
///
/// const 생성자라 traversal 강제 assert 는 못 박음. 대신 templates_test 의 invariant
/// (`cellIds == cellIdsOf(tree)`) 가 검증.
class NamedTemplate {
  final String name;
  final GridNode tree;
  final List<int> cellIds;

  const NamedTemplate({
    required this.name,
    required this.tree,
    required this.cellIds,
  });

  @override
  bool operator ==(Object other) =>
      other is NamedTemplate &&
      other.name == name &&
      other.tree == tree &&
      _listEq(other.cellIds, cellIds);

  @override
  int get hashCode => Object.hash(name, tree, Object.hashAll(cellIds));
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
