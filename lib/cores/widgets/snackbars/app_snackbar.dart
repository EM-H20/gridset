import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';

/// 앱 전역 커스텀 스낵바 — Design.md §4 Primary Dark 톤 정합.
///
/// Material 기본 [SnackBar] 가 아닌 [Overlay] 기반.
/// 화면 하단에 슬라이드업 + 페이드로 진입/퇴장한다.
/// 한 번에 1개만 표시되며, 새 호출 시 직전 스낵바를 dismiss 한다.
///
/// 디자인 시스템 정합:
/// - 배경: [AppColors.charcoal]
/// - 텍스트: [AppColors.offWhite] + [AppTextStyles.body_16]
/// - 아이콘: `assets/icons/` SVG, [AppColors.offWhite] tint, 20pt
/// - radius: 12 (Design.md 카드 표준)
/// - shadow: focus shadow 톤 (`AppColors.shadowFocus`, 부드러운 0.1 alpha)
///
/// 사용 예시:
/// ```dart
/// AppSnackbar.show(context, message: '저장되었습니다.');
/// AppSnackbar.show(
///   context,
///   message: '복사되었어요',
///   iconPath: 'assets/icons/icon_copy.svg',
/// );
/// AppSnackbar.show(
///   context,
///   message: '한 번에 9장까지 만들 수 있어요',
///   iconPath: 'assets/icons/icon_block.svg',
/// );
/// ```
class AppSnackbar {
  AppSnackbar._();

  static OverlayEntry? _currentEntry;

  /// 스낵바 표시.
  ///
  /// [message] 표시할 텍스트.
  /// [iconPath] SVG 아이콘 경로 — 기본 `icon_siren.svg` (경고/에러 톤).
  /// 정보성 메시지엔 `icon_copy.svg`, 차단/제한엔 `icon_block.svg` 권장.
  /// [duration] 표시 시간 (기본 3초).
  static void show(
    BuildContext context, {
    required String message,
    String iconPath = 'assets/icons/icon_siren.svg',
    Duration duration = const Duration(seconds: 3),
  }) {
    dismiss();

    final entry = OverlayEntry(
      builder: (_) => _SnackbarOverlay(
        message: message,
        iconPath: iconPath,
        duration: duration,
        onDismissed: _handleDismissed,
      ),
    );

    _currentEntry = entry;
    Overlay.of(context).insert(entry);
  }

  /// 현재 표시 중인 스낵바 즉시 제거.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void _handleDismissed() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

/// 스낵바 [Overlay] 위젯 (애니메이션 포함).
class _SnackbarOverlay extends StatefulWidget {
  const _SnackbarOverlay({
    required this.message,
    required this.iconPath,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final String iconPath;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_SnackbarOverlay> createState() => _SnackbarOverlayState();
}

class _SnackbarOverlayState extends State<_SnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      if (!mounted) return;
      _controller.reverse().then((_) {
        if (mounted) widget.onDismissed();
      });
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 nav bar / home indicator 위로 떠있도록 viewPadding 보정.
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Positioned(
      left: AppSpacing.base,
      right: AppSpacing.base,
      bottom: bottomInset + AppSpacing.xxl,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowFocus,
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    widget.iconPath,
                    width: 20.w,
                    height: 20.w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.offWhite,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppTextStyles.body_16.copyWith(
                        color: AppColors.offWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
