import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/services/remote_config/app_version_checker.dart';

void main() {
  group('AppVersionChecker.isVersionLower', () {
    test('current < minimum (minor 차이)', () {
      expect(AppVersionChecker.isVersionLower('1.2.3', '1.3.0'), isTrue);
    });

    test('current < minimum (major 차이)', () {
      expect(AppVersionChecker.isVersionLower('1.9.9', '2.0.0'), isTrue);
    });

    test('current < minimum (patch 차이)', () {
      expect(AppVersionChecker.isVersionLower('1.0.0', '1.0.1'), isTrue);
    });

    test('current == minimum 은 false', () {
      expect(AppVersionChecker.isVersionLower('1.0.0', '1.0.0'), isFalse);
    });

    test('current > minimum', () {
      expect(AppVersionChecker.isVersionLower('2.0.0', '1.9.9'), isFalse);
    });

    test('짧은 버전 문자열 (1.0) 도 0 패딩 처리', () {
      expect(AppVersionChecker.isVersionLower('1.0', '1.0.1'), isTrue);
      expect(AppVersionChecker.isVersionLower('1.0.1', '1.0'), isFalse);
    });

    test('비정상 토큰은 0 으로 취급해도 크래시 없음', () {
      expect(
        () => AppVersionChecker.isVersionLower('abc', '1.0.0'),
        returnsNormally,
      );
    });
  });
}
