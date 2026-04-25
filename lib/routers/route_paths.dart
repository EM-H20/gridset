/// 앱 전역 라우트 경로 상수.
///
/// go_router 의 각 [GoRoute.path] 및 `context.go(...)` 이동에서 참조한다.
abstract class RoutePaths {
  RoutePaths._();

  /// 스플래시 (초기 라우트)
  static const String splash = '/';

  /// 홈
  static const String home = '/home';

  /// 점검 안내 (풀스크린 차단)
  static const String maintenance = '/maintenance';

  /// 강제 업데이트 (풀스크린 차단)
  static const String forceUpdate = '/force-update';
}
