import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/features/share/services/t_min_calculator.dart';

void main() {
  test('빈 입력 → 0', () {
    expect(computeTMinMs(const []), 0);
  });

  test('1개 → 그 값 (cap/floor 안)', () {
    expect(computeTMinMs(const [5000]), 5000);
  });

  test('여러 개 → 최소값', () {
    expect(computeTMinMs(const [8000, 3000, 12000]), 3000);
  });

  test('1초 floor — 0.5초는 1초로 올림', () {
    expect(computeTMinMs(const [500]), 1000);
  });

  test('15초 cap — 16초는 15초로 자름', () {
    expect(computeTMinMs(const [16000, 20000]), 15000);
  });

  test('floor + cap 동시 적용', () {
    expect(computeTMinMs(const [200, 30000]), 1000);
  });
}
