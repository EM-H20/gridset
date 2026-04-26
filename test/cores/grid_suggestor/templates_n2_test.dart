import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('n2Templates 무결성', () {
    test('정확히 3개', () {
      expect(kGridTemplates[2], hasLength(3));
    });

    test('각 템플릿의 leaf 개수 == 2', () {
      for (final t in kGridTemplates[2]!) {
        expect(cellIdsOf(t.tree), hasLength(2), reason: '${t.name} leaf count');
      }
    });

    test('각 템플릿의 cellIds == [0, 1]', () {
      for (final t in kGridTemplates[2]!) {
        expect(t.cellIds, [0, 1], reason: '${t.name} cellIds');
        expect(
          cellIdsOf(t.tree),
          t.cellIds,
          reason: '${t.name} traversal == cellIds',
        );
      }
    });

    test('이름이 n2_ 로 시작', () {
      for (final t in kGridTemplates[2]!) {
        expect(t.name, startsWith('n2_'));
      }
    });

    test('fingerprint 충돌 없음', () {
      final fps =
          kGridTemplates[2]!.map((t) => treeFingerprint(t.tree)).toList();
      expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
    });
  });
}
