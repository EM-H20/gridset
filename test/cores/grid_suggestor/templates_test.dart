import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

// Private 모듈 직접 import — 화이트리스트 invariant 검증에 필요.
// 외부 features/ 에서는 이 import 가 의도적으로 막혀있다 (배럴만 사용).
import 'package:gridset/cores/grid_suggestor/templates/_allowed_positions.dart';

void main() {
  group('kGridTemplates 통합 invariant (8 항목)', () {
    // Invariant #1: kGridTemplates.keys == {2..9}
    test('1. N 키는 정확히 {2, 3, 4, 5, 6, 7, 8, 9}', () {
      expect(kGridTemplates.keys.toSet(), {2, 3, 4, 5, 6, 7, 8, 9});
    });

    // Invariant #2: 각 N 별 ≥ 3 templates (spec §5-2 lower bound)
    test('2. 각 N 의 템플릿 개수 ≥ 3', () {
      for (final entry in kGridTemplates.entries) {
        expect(
          entry.value.length,
          greaterThanOrEqualTo(3),
          reason: 'N=${entry.key} 의 템플릿이 3개 미만',
        );
      }
    });

    // Invariant #3: 각 템플릿의 leaf 개수 == N
    test('3. 각 템플릿의 leaf 개수 == N', () {
      for (final entry in kGridTemplates.entries) {
        final n = entry.key;
        for (final t in entry.value) {
          expect(
            cellIdsOf(t.tree),
            hasLength(n),
            reason: '${t.name} 의 leaf 개수가 $n 이 아님',
          );
        }
      }
    });

    // Invariant #4: 각 템플릿의 cellIds == [0..N-1] 정확히 (캐시와 traversal 일치)
    test('4. 각 템플릿의 cellIds == [0..N-1] + traversal 결과와 일치', () {
      for (final entry in kGridTemplates.entries) {
        final n = entry.key;
        final expected = List<int>.generate(n, (i) => i);
        for (final t in entry.value) {
          expect(t.cellIds, expected, reason: '${t.name} cellIds 가 [0..N-1] 아님');
          expect(
            cellIdsOf(t.tree),
            t.cellIds,
            reason: '${t.name} traversal 결과 != cellIds 캐시',
          );
        }
      }
    });

    // Invariant #5: 각 Split.positions 의 모든 값 ∈ kAllowedPositions (1e-9 tolerance)
    test('5. 모든 Split.positions ∈ kAllowedPositions (화이트리스트)', () {
      for (final entry in kGridTemplates.entries) {
        for (final t in entry.value) {
          _walkSplits(t.tree, (split) {
            for (final p in split.positions) {
              expect(
                isAllowedPosition(p),
                isTrue,
                reason: '${t.name} 의 position $p 가 화이트리스트 외',
              );
            }
          });
        }
      }
    });

    // Invariant #6: 각 Split.positions 가 strictly ascending
    test('6. 모든 Split.positions strictly ascending', () {
      for (final entry in kGridTemplates.entries) {
        for (final t in entry.value) {
          _walkSplits(t.tree, (split) {
            for (var i = 1; i < split.positions.length; i++) {
              expect(
                split.positions[i],
                greaterThan(split.positions[i - 1]),
                reason: '${t.name} positions 가 오름차순 아님',
              );
            }
          });
        }
      }
    });

    // Invariant #7: 같은 N 안에서 fingerprint 충돌 없음
    test('7. 같은 N 안에서 fingerprint 충돌 없음', () {
      for (final entry in kGridTemplates.entries) {
        final fps = entry.value.map((t) => treeFingerprint(t.tree)).toList();
        expect(
          fps.toSet().length,
          fps.length,
          reason:
              'N=${entry.key} 에서 중복 fingerprint 발견: '
              '${fps.where((fp) => fps.where((x) => x == fp).length > 1).toSet()}',
        );
      }
    });

    // Invariant #8: name 이 'n{N}_' 로 시작
    test('8. 모든 name 이 n{N}_ 로 시작', () {
      for (final entry in kGridTemplates.entries) {
        final n = entry.key;
        for (final t in entry.value) {
          expect(
            t.name,
            startsWith('n${n}_'),
            reason: '${t.name} 가 n${n}_ prefix 아님',
          );
        }
      }
    });

    // Bonus: 합계 ≥ 28 (spec §5-2 목표)
    test('합계 ≥ 28 templates (spec §5-2 목표)', () {
      final total =
          kGridTemplates.values.fold<int>(0, (sum, list) => sum + list.length);
      expect(total, greaterThanOrEqualTo(28));
    });
  });
}

/// 트리의 모든 Split 노드를 순회하며 visitor 호출.
///
/// Dart 3 sealed class 패턴 매칭에서 `case final Split split:` 는
/// `node` 가 Split 일 때 typed 변수 `split` 으로 binding (object pattern + variable pattern).
void _walkSplits(GridNode node, void Function(Split) visit) {
  switch (node) {
    case Leaf():
      return;
    case final Split split:
      visit(split);
      for (final c in split.children) {
        _walkSplits(c, visit);
      }
  }
}
