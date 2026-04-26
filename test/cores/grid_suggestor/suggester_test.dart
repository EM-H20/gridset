import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

import 'fixtures/photos.dart';

void main() {
  group('suggest() — N=2 통합', () {
    test('정상 입력 — suggestions 반환됨', () {
      final r = suggest(
        media: photos2Mixed,
        canvas: const CanvasRatio.square(),
      );
      expect(r.suggestions, isNotEmpty);
      expect(r.suggestions.length, lessThanOrEqualTo(3));
    });

    test('각 suggestion 의 mediaByCellId 가 모든 cellId 커버', () {
      final r = suggest(
        media: photos2Mixed,
        canvas: const CanvasRatio.square(),
      );
      for (final s in r.suggestions) {
        expect(s.mediaByCellId.keys.toSet(), {0, 1});
        expect(s.mediaByCellId.values.toSet(), {'p_wide', 'p_tall'});
      }
    });

    test('결정성 — 같은 입력 같은 출력', () {
      final r1 = suggest(
        media: photos2Mixed,
        canvas: const CanvasRatio.square(),
      );
      final r2 = suggest(
        media: photos2Mixed,
        canvas: const CanvasRatio.square(),
      );
      expect(
        r1.suggestions.map((s) => s.templateName).toList(),
        r2.suggestions.map((s) => s.templateName).toList(),
      );
      expect(
        r1.suggestions.map((s) => s.loss).toList(),
        r2.suggestions.map((s) => s.loss).toList(),
      );
    });

    test('cursor: 풀 소진까지 batch 진행하면 결국 nextCursor null', () {
      SuggestCursor? cursor;
      final allShown = <String>{};
      var batches = 0;
      while (batches < 4) {
        final r = suggest(
          media: photos2Mixed,
          canvas: const CanvasRatio.square(),
          cursor: cursor,
          maxResults: 1, // batch 당 1개씩 → cursor 한도 도달까지 진행
        );
        if (r.suggestions.isEmpty) break;
        allShown.addAll(r.suggestions.map((s) => s.templateName));
        batches++;
        cursor = r.nextCursor;
        if (cursor == null) break;
      }
      expect(cursor, isNull, reason: 'cursor 가 결국 null 이 되어야 함');
      expect(batches, greaterThanOrEqualTo(1));
    });

    test('canvas 비율 다르면 매핑이 달라질 수 있음 (loss 변화 확인)', () {
      final rSquare = suggest(
        media: photos2Mixed,
        canvas: const CanvasRatio.square(),
      );
      final rPortrait = suggest(
        media: photos2Mixed,
        canvas: const CanvasRatio.portrait916(),
      );
      // 첫 suggestion 의 loss 가 다르거나 templateName 이 달라야 함
      expect(
        rSquare.suggestions.first.loss != rPortrait.suggestions.first.loss ||
            rSquare.suggestions.first.templateName !=
                rPortrait.suggestions.first.templateName,
        isTrue,
        reason: 'canvas 비율이 매핑·loss 에 영향을 줘야 함',
      );
    });

    test('weightOf hook — 모두 1.0 이면 weightOf null 과 동일 결과', () {
      final rNullWeight = suggest(
        media: photos2Mixed,
        canvas: const CanvasRatio.square(),
      );
      final rOneWeight = suggest(
        media: photos2Mixed,
        canvas: const CanvasRatio.square(),
        weightOf: (_) => 1.0,
      );
      expect(
        rNullWeight.suggestions.map((s) => s.loss).toList(),
        rOneWeight.suggestions.map((s) => s.loss).toList(),
      );
    });
  });

  group('suggest() — 입력 검증', () {
    test('N=1 → ArgumentError', () {
      const media = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
      ];
      expect(
        () => suggest(media: media, canvas: const CanvasRatio.square()),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
