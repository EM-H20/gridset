import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 앱 전역 TextStyle 상수 (Design.md 기반)
///
/// 사용법:
/// ```dart
/// Text('그리드셋', style: AppTextStyles.displayHero_96)
/// Text('본문', style: AppTextStyles.body_16)
/// Text('빨간 제목', style: AppTextStyles.sectionHeading_64.copyWith(color: Colors.red))
/// ```
///
/// Design.md 규칙:
/// - fontFamily: 'MoneygraphyPixel' 단일 사용
/// - fontSize: 16의 배수 (16, 32, 48, 64, 80, 96…)
/// - fontWeight: FontWeight.w400 고정 (bold/italic 합성 금지)
/// - letterSpacing: 0 고정
/// - height: 1.0 (디스플레이/헤딩) 또는 1.5 (본문)
abstract class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'MoneygraphyPixel';
  static const FontWeight _weight = FontWeight.w400;
  static const double _letterSpacing = 0;

  // ============================================
  // Display (height: 1.0)
  // ============================================

  /// Display Hero — 메인 히어로 타이틀 (96px)
  static TextStyle get displayHero_96 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 96.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.0,
  );

  /// Display Alt — 대체 히어로 / 큰 헤드라인 (80px)
  static TextStyle get displayAlt_80 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 80.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.0,
  );

  // ============================================
  // Heading (height: 1.0)
  // ============================================

  /// Section Heading — 피처 섹션 타이틀 (64px)
  static TextStyle get sectionHeading_64 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 64.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.0,
  );

  /// Sub-heading — 서브 섹션 (48px)
  static TextStyle get subHeading_48 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.0,
  );

  /// Card Title — 카드 제목 / 통계 숫자 (32px)
  static TextStyle get cardTitle_32 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.0,
  );

  // ============================================
  // Body (height: 1.5)
  // ============================================

  /// Body Large — 인트로 / 강조 본문 (32px, 줄높이 1.5)
  static TextStyle get bodyLarge_32 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.5,
  );

  /// Body — 표준 본문 (16px, 줄높이 1.5)
  static TextStyle get body_16 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.5,
  );

  // ============================================
  // UI (height: 1.5, 모두 16px — hierarchy는 padding/opacity로)
  // ============================================

  /// Button — 버튼 라벨 (16px)
  static TextStyle get button_16 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.5,
  );

  /// Link — 링크 텍스트 (16px, underline)
  static TextStyle get link_16 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.5,
    decoration: TextDecoration.underline,
  );

  /// Caption — 메타데이터 / 캡션 (16px)
  static TextStyle get caption_16 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: _weight,
    letterSpacing: _letterSpacing,
    height: 1.5,
  );
}
