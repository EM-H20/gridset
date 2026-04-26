import '../models/grid_node.dart';
import '../models/grid_suggestion.dart';

/// 트리 구조 fingerprint — fingerprint 동일하면 "구조적으로 비슷한 후보".
///
/// PRD §9-2-1 step 4: "분할 방향 동일 + 선 위치 ±10% 이내면 중복".
/// positions 를 0.1 buckets 으로 라운딩해 ±5% 가 동일 bucket 으로 매핑.
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
          // 0.1 단위 버킷팅 — floor 기반으로 ±5% 범위 동일 버킷에 할당
          // (0.45~0.55) → 버킷 5 → 0.5, (0.55~0.65) → 버킷 6 → 0.6
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
