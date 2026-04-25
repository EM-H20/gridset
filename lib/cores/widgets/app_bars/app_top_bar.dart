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
  final AppIconButton? trailing;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onClose;
  final VoidCallback? onSave;
  final _AppTopBarVariant _variant;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      color: AppColors.cream,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_variant) {
      case _AppTopBarVariant.titleLeft:
        return _buildTitleVariant();
      case _AppTopBarVariant.backWithMore:
        return _buildBackWithMoreVariant();
      case _AppTopBarVariant.closeWithSave:
        return _buildCloseWithSaveVariant();
    }
  }

  Widget _buildTitleVariant() {
    return Row(
      children: [
        Text(title, style: AppTextStyles.cardTitle_32),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _buildBackWithMoreVariant() {
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

  Widget _buildCloseWithSaveVariant() {
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
              Icon(Icons.close, color: AppColors.charcoal, size: 18.sp),
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
