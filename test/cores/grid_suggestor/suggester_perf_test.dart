import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

import 'fixtures/photos.dart';

void main() {
  group('suggester perf', () {
    // PRD §11 모바일 예산 < 3000ms. 테스트 러너(macOS host / CI runner)에서
    // 고정 임계값 단정은 환경 편차로 flaky 하므로:
    //   1) warmup 으로 JIT/lazy init 비용 제거,
    //   2) 평균 대신 median (이상치 강건),
    //   3) 임계값을 1000ms (3x 마진) 로 완화.
    // 회귀는 알고리즘 복잡도 변화(N!→더 큰 차수) 수준만 잡아도 충분.
    test('N=9 suggest() median < 1000ms', () {
      const warmup = 2;
      const iterations = 11; // 홀수 — median 단일 값
      for (var i = 0; i < warmup; i++) {
        suggest(media: photos9Mixed, canvas: const CanvasRatio.portrait916());
      }

      final samples = <int>[];
      for (var i = 0; i < iterations; i++) {
        final sw = Stopwatch()..start();
        suggest(media: photos9Mixed, canvas: const CanvasRatio.portrait916());
        sw.stop();
        samples.add(sw.elapsedMicroseconds);
      }
      samples.sort();
      final medianUs = samples[samples.length ~/ 2];
      final medianMs = medianUs / 1000.0;

      // 회귀 디버깅용 — CI 로그에 남음.
      // ignore: avoid_print
      print(
        'N=9 suggest median: ${medianMs.toStringAsFixed(1)}ms '
        '(min ${(samples.first / 1000.0).toStringAsFixed(1)}ms / '
        'max ${(samples.last / 1000.0).toStringAsFixed(1)}ms)',
      );

      expect(
        medianMs,
        lessThan(1000),
        reason: 'N=9 median 응답 < 1000ms 위반 — 알고리즘 복잡도 회귀 의심',
      );
    });
  });
}
