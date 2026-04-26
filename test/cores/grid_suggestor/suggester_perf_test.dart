import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

import 'fixtures/photos.dart';

void main() {
  group('suggester perf', () {
    test('N=9 suggest() 10회 평균 < 300ms (테스트 러너 기준)', () {
      // PRD §11 < 3000ms (모바일) 에 10x 마진. 테스트 러너(macOS host) 기준.
      // 9! = 362,880 permutations × 9 비교 ≈ 3.3M ops — N=9 가 최악.
      const iterations = 10;
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        suggest(
          media: photos9Mixed,
          canvas: const CanvasRatio.portrait916(),
        );
      }
      sw.stop();
      final avgMs = sw.elapsedMilliseconds / iterations;
      // 디버깅 시 평균 확인용 — CI 에서도 stdout 에 남음.
      // ignore: avoid_print
      print('avg N=9 suggest: ${avgMs.toStringAsFixed(1)}ms');
      expect(
        avgMs,
        lessThan(300),
        reason: 'N=9 평균 응답 < 300ms 위반 — 알고리즘 회귀 의심',
      );
    });
  });
}
