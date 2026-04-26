import 'dart:math';

/// 셀 ↔ 미디어 매핑 결과.
///
/// `mapping[i]` = i 번째 셀에 배정된 미디어 인덱스.
/// `loss` = log 비율 차이의 가중합 (낮을수록 좋음).
///
/// `mapping` 은 [bestMapping] 반환 시 [List.unmodifiable] 로 wrap 되어 외부 변조 차단.
/// (`const` 빈 리스트 fallback 도 native immutable.)
class MappingResult {
  final List<int> mapping;
  final double loss;
  const MappingResult({required this.mapping, required this.loss});
}

/// 모든 N! permutation 을 평가해 최소 loss 매핑 반환.
///
/// Loss 함수: `Σᵢ wₘ(σ(i)) × |ln(cellAspectᵢ) - ln(mediaAspectσ(i))|`
/// - log 비율 차이로 가로/세로 비율 비대칭을 대칭으로 평가.
/// - 미디어 가중치는 v1 에서 모두 1.0, v1.x 에서 영상에 1.5.
///
/// N≤9 라 ~362,880 permutations × 9 비교 = ~3.3M ops, 모바일 < 300ms.
/// tie 발생 시 첫 번째 permutation 채택 (브루트포스 lexicographic 순).
MappingResult bestMapping({
  required List<double> cellAspects,
  required List<double> mediaAspects,
  required List<double> mediaWeights,
}) {
  assert(cellAspects.length == mediaAspects.length);
  assert(cellAspects.length == mediaWeights.length);
  final n = cellAspects.length;
  if (n == 0) {
    return const MappingResult(mapping: [], loss: 0);
  }

  final cellLogs = cellAspects.map(log).toList();
  final mediaLogs = mediaAspects.map(log).toList();

  var bestLoss = double.infinity;
  List<int>? bestPerm;

  final indices = List<int>.generate(n, (i) => i);
  void recurse(List<int> current, Set<int> used) {
    if (current.length == n) {
      var loss = 0.0;
      for (var i = 0; i < n; i++) {
        final mi = current[i];
        loss += mediaWeights[mi] * (cellLogs[i] - mediaLogs[mi]).abs();
      }
      if (loss < bestLoss) {
        bestLoss = loss;
        bestPerm = List.of(current);
      }
      return;
    }
    for (final i in indices) {
      if (used.contains(i)) continue;
      current.add(i);
      used.add(i);
      recurse(current, used);
      current.removeLast();
      used.remove(i);
    }
  }

  recurse(<int>[], <int>{});
  // n >= 1 이면 recurse 가 적어도 1회 완전 permutation 을 만들어 bestPerm 을 설정하므로 ! 안전.
  // List.unmodifiable 로 wrap — 외부 호출자가 .add/.removeAt 등으로 변조하지 못하게 차단.
  return MappingResult(mapping: List.unmodifiable(bestPerm!), loss: bestLoss);
}
