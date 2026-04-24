/// 4px 최소 단위 기반 간격 토큰 (8px 중심 + 12 보조).
/// 인라인 하드코딩 대신 반드시 이 상수를 참조할 것.
abstract class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}
