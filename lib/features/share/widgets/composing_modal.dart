import 'package:flutter/material.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';
import '../../../cores/widgets/buttons/app_button.dart';

/// 영상 합성 진행 modal — Lovable Cream Surface 카드.
///
/// 디자인 시스템 정합 (Design.md §4 Cream Surface + §"Border Radius Scale" Card):
/// - 카드: cream 배경, radius 12, focus shadow (Level 3), Padding xl
/// - 텍스트: charcoal body_16
/// - progress bar: charcoal value + charcoal04 background (Lovable subtle)
/// - 취소 버튼: AppButton.outlined (cream 톤 native 일관)
///
/// dim 배경은 호출자(`showDialog`) 의 `barrierColor: charcoal82` 가 담당 —
/// 화면 전체 (AppBar 포함) 를 dark dim 으로 덮어 카드만 부각.
///
/// `Material` root 로 wrap — Flutter debug 모드에서 Material 부모 없을 때
/// 발생하는 yellow underline 차단. `borderRadius` + `color` 직접 적용.
class ComposingModal extends StatelessWidget {
  const ComposingModal({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  /// 0.0 ~ 1.0 진행률. LinearProgressIndicator 에 직접 전달.
  final double progress;

  /// 사용자가 '취소' 버튼을 누를 때 호출되는 콜백.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Material(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowFocus,
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '영상 만드는 중...',
                  style: AppTextStyles.body_16
                      .copyWith(color: AppColors.charcoal),
                ),
                SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    label: '영상 합성 진행 중',
                    value:
                        '${(progress.clamp(0.0, 1.0) * 100).toInt()}퍼센트',
                    child: LinearProgressIndicator(
                      value: progress,
                      color: AppColors.charcoal,
                      backgroundColor: AppColors.charcoal04,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                // 취소 버튼은 카드 내 우측 정렬 — Lovable dialog 의 일반적인
                // action 정렬 (cancel/dismiss 가 우측 하단).
                AppButton.outlined(
                  label: '취소',
                  onPressed: onCancel,
                  isFullWidth: false,
                  alignment: Alignment.centerRight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
