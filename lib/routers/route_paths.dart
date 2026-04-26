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

  /// 캔버스 비율 선택 (비율 먼저 정하기 흐름)
  static const String canvasPicker = '/canvas-picker';

  /// 사진/영상 picker
  static const String photoPicker = '/photo-picker';

  /// 자동 레이아웃 후보 화면
  static const String suggestion = '/suggestion';

  /// Dev 컴포넌트 갤러리 (kDebugMode 진입)
  static const String dev = '/dev';
}
