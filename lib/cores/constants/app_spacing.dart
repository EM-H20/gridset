import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4px 최소 단위 기반 간격 토큰 (8px 중심 + 12 보조).
///
/// flutter_screenutil `.w` 를 내부에서 적용하므로
/// **호출부에서는 `.w/.h/.sp` 를 다시 붙이지 않는다**.
/// `EdgeInsets.symmetric(horizontal: AppSpacing.base)` 처럼 그대로 사용.
///
/// `.w` 단일 스케일 — flutter_screenutil 공식 컨벤션, 모바일 세로
/// 화면에서 vertical/horizontal 차이 미미.
abstract class AppSpacing {
  AppSpacing._();

  static double get xxs => 2.w;
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 12.w;
  static double get base => 16.w;
  static double get lg => 20.w;
  static double get xl => 24.w;
  static double get xxl => 32.w;
  static double get xxxl => 48.w;
}
