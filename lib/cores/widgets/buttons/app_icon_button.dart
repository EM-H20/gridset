// lib/cores/widgets/buttons/app_icon_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';

/// Design.md §4 Pill / Icon Button 응용 — outlined 원형 (size = 외곽 지름).
///
/// 사용:
/// ```dart
/// AppIconButton(
///   icon: Icons.arrow_back_ios_new,
///   onPressed: () => Navigator.pop(context),
///   semanticLabel: '뒤로 가기',
/// )
/// ```
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// 외곽 원의 지름. 기본 40 (.w 적용 후 디바이스 너비 기준 스케일).
  final double size;

  /// 접근성 라벨. 가능하면 항상 지정 권장.
  final String? semanticLabel;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null;

  void _setPressed(bool value) {
    if (_isDisabled) return;
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = widget.size.w;
    final iconSize = (widget.size * 0.45).sp;
    final opacity = _isDisabled ? 0.4 : (_isPressed ? 0.8 : 1.0);

    final core = Container(
      width: dim,
      height: dim,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(width: 1, color: AppColors.charcoal40),
      ),
      child: Icon(widget.icon, color: AppColors.charcoal, size: iconSize),
    );

    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: opacity,
        child: core,
      ),
    );

    if (widget.semanticLabel != null) {
      result = Semantics(
        button: true,
        label: widget.semanticLabel,
        child: result,
      );
    }

    return result;
  }
}
