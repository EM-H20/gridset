import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('n7Templates 무결성', () {
    test('정확히 4개', () {
      expect(kGridTemplates[7], hasLength(4));
    });

    test('각 템플릿의 leaf 개수 == 7', () {
      for (final t in kGridTemplates[7]!) {
        expect(cellIdsOf(t.tree), hasLength(7), reason: '${t.name} leaf count');
      }
    });

    test('각 템플릿의 cellIds == [0..6]', () {
      for (final t in kGridTemplates[7]!) {
        expect(t.cellIds, [0, 1, 2, 3, 4, 5, 6], reason: '${t.name} cellIds');
        expect(cellIdsOf(t.tree), t.cellIds, reason: '${t.name} traversal == cellIds');
      }
    });

    test('이름이 n7_ 로 시작', () {
      for (final t in kGridTemplates[7]!) {
        expect(t.name, startsWith('n7_'));
      }
    });

    test('fingerprint 충돌 없음', () {
      final fps = kGridTemplates[7]!.map((t) => treeFingerprint(t.tree)).toList();
      expect(fps.toSet().length, fps.length, reason: '중복 fingerprint 발견');
    });
  });
}
