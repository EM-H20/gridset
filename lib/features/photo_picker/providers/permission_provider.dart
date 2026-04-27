import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_provider.g.dart';

/// 사진/영상 갤러리 접근 권한 상태.
///
/// `notDetermined` 는 enum 외 — `requestPermissionExtend` 호출 시점에
/// 시스템이 dialog 띄워주고 결과는 반드시 4 값 중 하나로 resolve.
enum AppPermissionState {
  authorized,
  limited,
  denied,
  restricted;

  static AppPermissionState fromPlatform(PermissionState ps) {
    switch (ps) {
      case PermissionState.authorized:
        return AppPermissionState.authorized;
      case PermissionState.limited:
        return AppPermissionState.limited;
      case PermissionState.denied:
        return AppPermissionState.denied;
      case PermissionState.restricted:
        return AppPermissionState.restricted;
      case PermissionState.notDetermined:
        // 호출 결과로 notDetermined 가 오는 경우는 사실상 없음.
        // 안전하게 denied 매핑.
        return AppPermissionState.denied;
    }
  }
}

/// 권한 요청 + 상태 매핑. 진입 시 자동으로 시스템 dialog 가 뜬다 (notDetermined 인 경우).
///
/// `keepAlive: false` (autoDispose) — picker 라우트 dispose 시 재초기화.
@Riverpod(keepAlive: false)
Future<AppPermissionState> photoPermission(Ref ref) async {
  final ps = await PhotoManager.requestPermissionExtend();
  return AppPermissionState.fromPlatform(ps);
}
