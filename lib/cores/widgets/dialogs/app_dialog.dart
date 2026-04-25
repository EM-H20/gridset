import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';
import '../buttons/app_button.dart';

/// Lovable 스타일 풀 커스텀 다이얼로그 (Design.md 준수).
///
/// - 배경 cream + 12px radius + lightCream border
/// - 타이틀 cardTitle_32 / 본문 body_16
/// - 확인 버튼: Primary Dark + inset shadow
/// - 취소 버튼: Ghost (charcoal40 border, 투명 배경)
///
/// 정적 API [AppDialog.show] 로만 사용한다.
class AppDialog extends StatelessWidget {
  const AppDialog._({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// 다이얼로그 표시.
  ///
  /// [cancelText] 가 null 이면 확인 버튼만 노출되는 single-button 다이얼로그.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '확인',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AppDialog._(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightCream, width: 1),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style:
                  AppTextStyles.cardTitle_32.copyWith(color: AppColors.charcoal),
            ),
            SizedBox(height: AppSpacing.base),
            Text(
              message,
              style:
                  AppTextStyles.body_16.copyWith(color: AppColors.charcoal82),
            ),
            SizedBox(height: AppSpacing.base),
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: AppButton.outlined(
                      label: cancelText!,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel?.call();
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: AppButton.primary(
                    label: confirmText,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
