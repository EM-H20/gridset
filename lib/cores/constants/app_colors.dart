import 'package:flutter/material.dart';

/// 앱 전역 Color 상수 (Design.md §2 기반)
///
/// 사용법:
/// ```dart
/// Scaffold(backgroundColor: AppColors.cream)
/// Text('제목', style: TextStyle(color: AppColors.charcoal))
/// Container(
///   decoration: BoxDecoration(
///     color: AppColors.cream,
///     border: Border.all(color: AppColors.lightCream),
///   ),
/// )
/// ```
///
/// Design.md 원칙:
/// - 페이지 배경은 반드시 cream(#f7f4ed) — 순백(#ffffff) 금지
/// - 모든 gray 는 charcoal(#1c1c1c) 의 opacity 변주로 파생
/// - 경계는 그림자 대신 border (#eceae4) 로 표현
/// - 채도 높은 accent 컬러 도입 금지 (warm-neutral 유지)
///
/// opacity → alpha hex 변환 표 (Color const 유지용):
/// - 0.83 → 0xD4 / 0.82 → 0xD1 / 0.40 → 0x66
/// - 0.10 → 0x1A / 0.04 → 0x0A / 0.03 → 0x08 / 0.20 → 0x33
abstract class AppColors {
  AppColors._();

  // ============================================
  // Primary
  // ============================================

  /// Cream — 페이지 배경, 카드 surface, 버튼 surface
  static const Color cream = Color(0xFFF7F4ED);

  /// Charcoal — 주 텍스트, 제목, 다크 버튼 배경 (pure black 아님)
  static const Color charcoal = Color(0xFF1C1C1C);

  /// Off-White — 다크 버튼 위 텍스트, subtle highlight
  static const Color offWhite = Color(0xFFFCFBF8);

  /// Functional — 완전 투명. Material color 슬롯에서 페인트를 끄고 자체 BoxDecoration
  /// 으로 painting 을 위임하고 싶을 때 (예: 오버레이 위 커스텀 컨테이너).
  /// Colors.transparent 직접 사용 대신 토큰 경유.
  static const Color transparent = Color(0x00000000);

  // ============================================
  // Neutral Scale (Charcoal Opacity)
  // ============================================

  /// Charcoal 83% — 강한 보조 텍스트
  static const Color charcoal83 = Color(0xD41C1C1C);

  /// Charcoal 82% — 본문
  static const Color charcoal82 = Color(0xD11C1C1C);

  /// Muted Gray — 보조 텍스트, 설명, 캡션
  static const Color mutedGray = Color(0xFF5F5F5D);

  /// Charcoal 40% — 인터랙티브 테두리, 버튼 아웃라인
  static const Color charcoal40 = Color(0x661C1C1C);

  /// Charcoal 4% — subtle hover 배경, 마이크로 틴트
  static const Color charcoal04 = Color(0x0A1C1C1C);

  /// Charcoal 3% — 매우 옅은 오버레이, 배경 깊이
  static const Color charcoal03 = Color(0x081C1C1C);

  // ============================================
  // Surface & Border
  // ============================================

  /// Light Cream — 카드 border, divider, 이미지 outline (passive)
  static const Color lightCream = Color(0xFFECEAE4);

  /// Cream Surface — 카드 배경, 섹션 fill (페이지 배경과 동일)
  static const Color creamSurface = cream;

  // ============================================
  // Interactive
  // ============================================

  /// Ring Blue 50% — 키보드 포커스 ring
  static const Color ringBlue = Color(0x803B82F6);

  // ============================================
  // Shadow Colors (BoxShadow 생성 시 사용)
  // ============================================

  /// Focus shadow color — rgba(0,0,0,0.1), offset (0,4), blur 12
  static const Color shadowFocus = Color(0x1A000000);

  /// Button inset — 상단 하이라이트 rgba(255,255,255,0.2)
  static const Color insetHighlight = Color(0x33FFFFFF);

  /// Button inset — 외곽 링 rgba(0,0,0,0.2)
  static const Color insetRing = Color(0x33000000);

  /// Button inset — 하단 드롭 rgba(0,0,0,0.05)
  static const Color insetDrop = Color(0x0D000000);
}
