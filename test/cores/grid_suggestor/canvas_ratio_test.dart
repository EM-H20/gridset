import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('CanvasRatio', () {
    test('portrait916 = 9/16', () {
      expect(const CanvasRatio.portrait916().value, closeTo(9 / 16, 1e-12));
    });

    test('square = 1', () {
      expect(const CanvasRatio.square().value, 1.0);
    });

    test('portrait45 = 4/5', () {
      expect(const CanvasRatio.portrait45().value, closeTo(0.8, 1e-12));
    });

    test('landscape169 = 16/9', () {
      expect(const CanvasRatio.landscape169().value, closeTo(16 / 9, 1e-12));
    });

    test('custom(3, 2) = 1.5', () {
      expect(const CanvasRatio.custom(3, 2).value, closeTo(1.5, 1e-12));
    });

    test('custom: 동일 값으로 만든 인스턴스는 ==', () {
      expect(
        const CanvasRatio.custom(3, 2),
        equals(const CanvasRatio.custom(3, 2)),
      );
    });

    test('custom: w<=0 또는 h<=0 은 assert 로 막힘', () {
      expect(() => CanvasRatio.custom(0, 1), throwsA(isA<AssertionError>()));
      expect(() => CanvasRatio.custom(1, 0), throwsA(isA<AssertionError>()));
      expect(() => CanvasRatio.custom(-1, 1), throwsA(isA<AssertionError>()));
    });

    test('custom: hashCode 가 == 와 일관 (Set/Map 안전)', () {
      const c1 = CanvasRatio.custom(3, 2);
      const c2 = CanvasRatio.custom(3, 2);
      expect(c1, equals(c2));
      expect(c1.hashCode, c2.hashCode);
      final set = <CanvasRatio>{c1};
      expect(set.contains(c2), isTrue);
    });

    test('preset: 같은 preset 인스턴스끼리 == + hashCode 일관', () {
      const a = CanvasRatio.portrait916();
      const b = CanvasRatio.portrait916();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('preset: 서로 다른 preset 은 ≠', () {
      expect(
        const CanvasRatio.portrait916(),
        isNot(equals(const CanvasRatio.square())),
      );
    });
  });
}
