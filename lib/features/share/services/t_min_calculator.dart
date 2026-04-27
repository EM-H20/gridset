/// 영상 셀 duration 들 중 최솟값으로 T_min 계산.
///
/// 1초 floor: 0.x초 영상은 사용자 인지 불가 → 1초로 올림.
/// 15초 cap: PRD §9-2-4 MVP 한도.
/// 빈 입력: 사진만 카드 → 호출자가 PNG 분기로 우회 (반환 0).
int computeTMinMs(Iterable<int> videoDurationsMs) {
  if (videoDurationsMs.isEmpty) return 0;
  final minMs = videoDurationsMs.reduce((a, b) => a < b ? a : b);
  return minMs.clamp(1000, 15000);
}
