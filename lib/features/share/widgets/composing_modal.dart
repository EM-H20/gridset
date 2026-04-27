import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';

/// 영상 합성 진행 modal — full-screen charcoal82 dim + 진행 bar + 취소 버튼.
///
/// 호출자가 200ms 이후만 노출하도록 timing 제어하는 게 UX상 적절.
/// 본 위젯은 stateless presentation 전용 — 상태 관리는 상위 위젯.
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
    return ColoredBox(
      color: AppColors.charcoal82,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '영상 만드는 중...',
                style: AppTextStyles.body_16.copyWith(color: AppColors.offWhite),
              ),
              SizedBox(height: AppSpacing.xl),
              SizedBox(
                // 디자인 상 360dp 기준 progress bar 너비 — 좌우 32dp padding 제외.
                width: 360.w,
                child: LinearProgressIndicator(
                  value: progress,
                  color: AppColors.offWhite,
                  backgroundColor: AppColors.charcoal40,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.offWhite),
                ),
                child: Text(
                  '취소',
                  style: AppTextStyles.body_16.copyWith(color: AppColors.offWhite),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
