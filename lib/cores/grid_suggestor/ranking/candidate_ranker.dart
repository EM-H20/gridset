import '../models/grid_node.dart';
import '../models/grid_suggestion.dart';

/// 트리 구조 fingerprint — fingerprint 동일하면 "구조적으로 비슷한 후보".
///
/// PRD §9-2-1 step 4: "분할 방향 동일 + 선 위치 ±10% 이내면 중복".
/// positions 를 floor 기반 0.1 단위 버킷 `[k×0.1, (k+1)×0.1)` 으로 매핑 — 같은
/// 버킷 안에 떨어지는 위치는 동일 fingerprint 로 dedup.
/// (예: 0.50·0.54·0.55 → 모두 0.5 버킷, 0.45 → 0.4 버킷, 0.60 → 0.6 버킷.)
String treeFingerprint(GridNode node) {
  final buf = StringBuffer();
  void visit(GridNode n) {
    switch (n) {
      case Leaf():
        buf.write('L');
      case Split(:final axis, :final positions, :final children):
        buf.write(axis == SplitAxis.vertical ? 'V' : 'H');
        buf.write('@');
        for (var i = 0; i < positions.length; i++) {
          if (i > 0) buf.write(',');
          // 0.1 단위 floor 버킷팅 — `[k×0.1, (k+1)×0.1)` 안의 위치를 동일 버킷으로 묶음.
          // (예: [0.4, 0.5) → 0.4, [0.5, 0.6) → 0.5 (0.55 포함), [0.6, 0.7) → 0.6.)
          final bucket = (positions[i] * 10).floor() / 10;
          buf.write(bucket.toStringAsFixed(1));
        }
        buf.write('(');
        for (var i = 0; i < children.length; i++) {
          if (i > 0) buf.write(',');
          visit(children[i]);
        }
        buf.write(')');
    }
  }
  visit(node);
  return buf.toString();
}

/// 후보 정렬 + fingerprint dedup.
///
/// 1) fingerprint 동일 후보 중 loss 가장 낮은 것만 살림.
/// 2) loss 오름차순 정렬 (동률 시 templateName 알파벳 오름차순).
List<GridSuggestion> rankCandidates(List<GridSuggestion> candidates) {
  // Step 1: fingerprint dedup
  final byFp = <String, GridSuggestion>{};
  for (final c in candidates) {
    final fp = treeFingerprint(c.tree);
    final existing = byFp[fp];
    if (existing == null || c.loss < existing.loss) {
      byFp[fp] = c;
    } else if (c.loss == existing.loss && c.templateName.compareTo(existing.templateName) < 0) {
      // tie 시 alphabetical 우선 — 결정성 보장
      byFp[fp] = c;
    }
  }

  // Step 2: loss + name 정렬
  final list = byFp.values.toList()
    ..sort((a, b) {
      final cmp = a.loss.compareTo(b.loss);
      if (cmp != 0) return cmp;
      return a.templateName.compareTo(b.templateName);
    });

  return list;
}
