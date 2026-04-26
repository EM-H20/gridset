import 'package:flutter_test/flutter_test.dart';

// private 모듈을 직접 import — 테스트가 그 외 파일에서 못 끌어와야 함을 의도.
import 'package:gridset/cores/grid_suggestor/templates/_allowed_positions.dart';

void main() {
  group('kAllowedPositions', () {
    test('정확히 7개 — {1/4, 1/3, 0.4, 0.5, 0.6, 2/3, 3/4}', () {
      expect(kAllowedPositions, hasLength(7));
      expect(kAllowedPositions, contains(closeTo(1 / 4, 1e-9)));
      expect(kAllowedPositions, contains(closeTo(1 / 3, 1e-9)));
      expect(kAllowedPositions, contains(closeTo(0.4, 1e-9)));
      expect(kAllowedPositions, contains(closeTo(0.5, 1e-9)));
      expect(kAllowedPositions, contains(closeTo(0.6, 1e-9)));
      expect(kAllowedPositions, contains(closeTo(2 / 3, 1e-9)));
      expect(kAllowedPositions, contains(closeTo(3 / 4, 1e-9)));
    });
  });

  group('isAllowedPosition', () {
    test('정확히 일치하는 값 — true', () {
      expect(isAllowedPosition(0.5), isTrue);
      expect(isAllowedPosition(1 / 3), isTrue);
      expect(isAllowedPosition(2 / 3), isTrue);
    });

    test('1e-9 이내 오차 — true (부동소수 오차 허용)', () {
      expect(isAllowedPosition(0.5 + 1e-10), isTrue);
      expect(isAllowedPosition(1 / 3 - 1e-10), isTrue);
    });

    test('화이트리스트 외 값 — false', () {
      expect(isAllowedPosition(0.45), isFalse);
      expect(isAllowedPosition(0.7), isFalse);
      expect(isAllowedPosition(0.0), isFalse);
      expect(isAllowedPosition(1.0), isFalse);
    });
  });
}
