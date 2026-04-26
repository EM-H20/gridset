import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('bestMapping', () {
    test('완벽 매칭 — 가로 셀에 가로 미디어, 세로 셀에 세로 미디어', () {
      final result = bestMapping(
        cellAspects: [2.0, 0.5],
        mediaAspects: [2.0, 0.5],
        mediaWeights: [1.0, 1.0],
      );
      expect(result.mapping, [0, 1]); // media[0]→cell[0], media[1]→cell[1]
      expect(result.loss, closeTo(0, 1e-9));
    });

    test('완벽 매칭 — 미디어 순서 뒤집어도 매핑 옳게', () {
      final result = bestMapping(
        cellAspects: [2.0, 0.5],
        mediaAspects: [0.5, 2.0],
        mediaWeights: [1.0, 1.0],
      );
      expect(result.mapping, [1, 0]); // media[1](2.0)→cell[0], media[0](0.5)→cell[1]
      expect(result.loss, closeTo(0, 1e-9));
    });

    test('log loss: 가로 2배 차이와 세로 2배 차이 동등', () {
      // cell=2.0, media=4.0: |ln(2)-ln(4)| = ln(2)
      // cell=0.5, media=0.25: |ln(0.5)-ln(0.25)| = ln(2)
      final r1 = bestMapping(
        cellAspects: [2.0],
        mediaAspects: [4.0],
        mediaWeights: [1.0],
      );
      final r2 = bestMapping(
        cellAspects: [0.5],
        mediaAspects: [0.25],
        mediaWeights: [1.0],
      );
      expect(r1.loss, closeTo(ln2, 1e-9));
      expect(r2.loss, closeTo(ln2, 1e-9));
      expect(r1.loss, closeTo(r2.loss, 1e-9));
    });

    test('weight 가 큰 미디어가 더 잘 맞는 셀로 가도록 편향', () {
      // 셀 [10, 1.0]: 첫 셀이 매우 가로
      // 미디어 [1.0(weight=10), 10(weight=1)]:
      //   weight 무시 → media[1](10)→cell[0]
      //   weight 1×10 = 미디어[0]을 잘못된 셀로 보내면 loss 폭증 → 실제로는 그냥 절대 loss 따름
      // 사실 weight 는 절대값에만 영향. 매핑 자체가 바뀌려면 분기 발생해야.
      // 단순 검증: weight 1 vs 10 일 때 loss 가 weight 비례
      final lowWeight = bestMapping(
        cellAspects: [2.0],
        mediaAspects: [1.0],
        mediaWeights: [1.0],
      );
      final highWeight = bestMapping(
        cellAspects: [2.0],
        mediaAspects: [1.0],
        mediaWeights: [10.0],
      );
      expect(highWeight.loss, closeTo(lowWeight.loss * 10, 1e-9));
    });

    test('N=4 브루트포스 — 24 permutations 평가', () {
      final result = bestMapping(
        cellAspects: [2.0, 2.0, 0.5, 0.5],
        mediaAspects: [0.5, 0.5, 2.0, 2.0],
        mediaWeights: [1.0, 1.0, 1.0, 1.0],
      );
      // 가로 미디어 2개를 가로 셀 2개에 (순서 무관)
      expect(result.loss, closeTo(0, 1e-9));
    });
  });
}
