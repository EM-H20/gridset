// lib/cores/widgets/buttons/app_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';

enum _AppButtonVariant { primary, outlined }

/// Design.md §4 Buttons 준수 — Primary(charcoal filled) / Outlined(transparent + border).
///
/// 사용:
/// ```dart
/// AppButton.primary(label: '사진·영상 고르기', icon: Icons.image, onPressed: () {})
/// AppButton.outlined(label: '비율 먼저 정하기', onPressed: () {})
/// ```
class AppButton extends StatefulWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.isFullWidth = true,
  })  : _variant = _AppButtonVariant.outlined,
        icon = null;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final _AppButtonVariant _variant;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null;
  bool get _isPrimary => widget._variant == _AppButtonVariant.primary;

  void _setPressed(bool value) {
    if (_isDisabled) return;
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isPrimary ? AppColors.charcoal : Colors.transparent;
    final textColor = _isPrimary ? AppColors.offWhite : AppColors.charcoal;
    final border = _isPrimary
        ? Border.all(width: 0.5, color: AppColors.insetRing)
        : Border.all(width: 1, color: AppColors.charcoal40);
    final shadow = _isPrimary
        ? <BoxShadow>[
            BoxShadow(
              color: AppColors.insetDrop,
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ]
        : null;

    final textStyle = AppTextStyles.button_16.copyWith(color: textColor);

    final rowChildren = <Widget>[
      if (widget.icon != null) ...[
        Icon(widget.icon, color: textColor, size: 18.sp),
        SizedBox(width: AppSpacing.sm.w),
      ],
      Text(widget.label, style: textStyle),
    ];

    final inner = Container(
      width: widget.isFullWidth ? double.infinity : null,
      // alignment is only set for full-width buttons; setting it on a shrink-wrap
      // button causes Container to expand to fill the parent (defeating IntrinsicWidth).
      alignment: widget.isFullWidth ? Alignment.center : null,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: border,
        boxShadow: shadow,
      ),
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm.h,
        horizontal: AppSpacing.base.w,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: rowChildren,
      ),
    );

    final opacity = _isDisabled ? 0.4 : (_isPressed ? 0.8 : 1.0);

    final gestureDetector = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: opacity,
        child: inner,
      ),
    );

    // IntrinsicWidth alone cannot loosen tight constraints from
    // Column(crossAxisAlignment: stretch). Wrapping with Align first
    // breaks the tight constraint so IntrinsicWidth can shrink-wrap.
    return widget.isFullWidth
        ? gestureDetector
        : Align(
            alignment: Alignment.centerLeft,
            child: IntrinsicWidth(child: gestureDetector),
          );
  }
}
