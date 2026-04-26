/// 큐레이션 분할 위치 화이트리스트 (spec §5-1).
///
/// 모든 `Split.positions` 의 각 값은 이 set 에 속해야 한다.
/// PRD §9-2-3 에디터 스냅 가이드(½, ⅓, ⅔)에 4분할 균등용 ¼·¾ 추가.
/// v1.x 사용자 데이터 보고 set 확장 가능 (e.g., 황금비 0.382/0.618).
///
/// 부동소수 비교 오차 허용은 [isAllowedPosition] 사용.
///
/// 구현 메모: `const Set<double>` 은 Dart 3.x 에서 `1/3` 같은 division 결과가
/// "primitive equality 미지원" 으로 거부되어 컴파일 안 됨 (Phase A 보정 02cb71f
/// 와 동일 한계). 따라서 `final` 로 선언.
final Set<double> kAllowedPositions = <double>{
  1 / 4, // 0.25 — 4-row/4-col 균등 분할용
  1 / 3, // 0.333...
  0.4,
  0.5,
  0.6,
  2 / 3, // 0.666...
  3 / 4, // 0.75 — 4-row/4-col 균등 분할용
};

/// 부동소수 오차 허용 비교 (절대 오차 ≤ [tolerance], 기본 1e-9).
///
/// 1/3, 2/3 같은 무한소수 표현 차이 + 큐레이션 코드의 직접 입력 모두 허용.
bool isAllowedPosition(double position, {double tolerance = 1e-9}) {
  for (final allowed in kAllowedPositions) {
    if ((position - allowed).abs() <= tolerance) return true;
  }
  return false;
}
