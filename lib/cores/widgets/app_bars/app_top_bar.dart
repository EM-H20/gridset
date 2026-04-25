// lib/cores/widgets/app_bars/app_top_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';
import '../buttons/app_icon_button.dart';

enum _AppTopBarVariant { titleLeft, backWithMore, closeWithSave }

/// 3 variant 의 상단 앱 바 — Design.md 단일 cream 테마, border 없음.
///
/// `PreferredSizeWidget` 구현 — `Scaffold(appBar: ...)` 슬롯에 직접 사용 가능.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 화면 1: 좌측 큰 wordmark + 옵션 trailing.
  const AppTopBar.title({
    super.key,
    required this.title,
    this.trailing,
  })  : _variant = _AppTopBarVariant.titleLeft,
        onBack = null,
        onMore = null,
        onClose = null,
        onSave = null;

  /// 화면 2: 뒤로 + 중앙 타이틀 + 더보기.
  const AppTopBar.backWithMore({
    super.key,
    required this.title,
    required VoidCallback this.onBack,
    required VoidCallback this.onMore,
  })  : _variant = _AppTopBarVariant.backWithMore,
        trailing = null,
        onClose = null,
        onSave = null;

  /// 화면 3: 닫기 텍스트버튼 + 중앙 타이틀 + 저장 텍스트버튼 (`onSave: null` = 비활성).
  const AppTopBar.closeWithSave({
    super.key,
    required this.title,
    required VoidCallback this.onClose,
    required this.onSave,
  })  : _variant = _AppTopBarVariant.closeWithSave,
        trailing = null,
        onBack = null,
        onMore = null;

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onClose;
  final VoidCallback? onSave;
  final _AppTopBarVariant _variant;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_variant) {
      _AppTopBarVariant.titleLeft => _TitleVariantBody(
          title: title,
          trailing: trailing,
        ),
      _AppTopBarVariant.backWithMore => _BackWithMoreVariantBody(
          title: title,
          onBack: onBack,
          onMore: onMore,
        ),
      _AppTopBarVariant.closeWithSave => _CloseWithSaveVariantBody(
          title: title,
          onClose: onClose,
          onSave: onSave,
        ),
    };

    return Container(
      height: preferredSize.height,
      color: AppColors.cream,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
      child: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Private variant body widgets
// ---------------------------------------------------------------------------

class _TitleVariantBody extends StatelessWidget {
  const _TitleVariantBody({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.cardTitle_32),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _BackWithMoreVariantBody extends StatelessWidget {
  const _BackWithMoreVariantBody({
    required this.title,
    required this.onBack,
    required this.onMore,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: onBack,
          semanticLabel: '뒤로 가기',
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
            ),
          ),
        ),
        AppIconButton(
          icon: Icons.more_horiz,
          onPressed: onMore,
          semanticLabel: '더보기',
        ),
      ],
    );
  }
}

class _CloseWithSaveVariantBody extends StatelessWidget {
  const _CloseWithSaveVariantBody({
    required this.title,
    required this.onClose,
    required this.onSave,
  });

  final String title;
  final VoidCallback? onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final saveColor = onSave == null ? AppColors.charcoal40 : AppColors.charcoal;

    return Row(
      children: [
        TextButton(
          onPressed: onClose,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            foregroundColor: AppColors.charcoal,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, color: AppColors.charcoal, size: 16.sp),
              SizedBox(width: AppSpacing.xs.w),
              Text(
                '닫기',
                style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
            ),
          ),
        ),
        TextButton(
          onPressed: onSave,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            foregroundColor: saveColor,
          ),
          child: Text(
            '저장',
            style: AppTextStyles.body_16.copyWith(color: saveColor),
          ),
        ),
      ],
    );
  }
}
