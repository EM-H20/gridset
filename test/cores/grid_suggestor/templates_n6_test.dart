import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('n6Templates 무결성', () {
    test('정확히 5개', () {
      expect(kGridTemplates[6], hasLength(5));
    });

    test('각 템플릿의 leaf 개수 == 6', () {
      for (final t in kGridTemplates[6]!) {
        expect(cellIdsOf(t.tree), hasLength(6), reason: '${t.name} leaf count');
      }
    });

    test('각 템플릿의 cellIds == [0, 1, 2, 3, 4, 5]', () {
      for (final t in kGridTemplates[6]!) {
        expect(t.cellIds, [0, 1, 2, 3, 4, 5], reason: '${t.name} cellIds');
        expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
      }
    });

    test('이름이 n6_ 로 시작', () {
      for (final t in kGridTemplates[6]!) {
        expect(t.name, startsWith('n6_'));
      }
    });

    test('fingerprint 충돌 없음', () {
      final fps = kGridTemplates[6]!.map((t) => treeFingerprint(t.tree)).toList();
      expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
    });
  });
}
