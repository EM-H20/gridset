import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/features/photo_picker/providers/permission_provider.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  group('AppPermissionState.fromPlatform', () {
    test('authorized 매핑', () {
      expect(
        AppPermissionState.fromPlatform(PermissionState.authorized),
        AppPermissionState.authorized,
      );
    });
    test('limited 매핑', () {
      expect(
        AppPermissionState.fromPlatform(PermissionState.limited),
        AppPermissionState.limited,
      );
    });
    test('denied 매핑', () {
      expect(
        AppPermissionState.fromPlatform(PermissionState.denied),
        AppPermissionState.denied,
      );
    });
    test('restricted 매핑', () {
      expect(
        AppPermissionState.fromPlatform(PermissionState.restricted),
        AppPermissionState.restricted,
      );
    });
    test('notDetermined 은 denied 로 fallback', () {
      expect(
        AppPermissionState.fromPlatform(PermissionState.notDetermined),
        AppPermissionState.denied,
      );
    });
  });
}
