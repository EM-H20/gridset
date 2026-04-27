import 'package:flutter/material.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';
import '../../../cores/widgets/buttons/app_button.dart';

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
              // Padding 이 이미 horizontal: xxl 적용 → SizedBox 는 무한 너비
              // 로 두고 부모 제약을 따른다. 디바이스별 화면 폭 차이에 맞춰 자연
              // 확장.
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: '영상 합성 진행 중',
                  value: '${(progress.clamp(0.0, 1.0) * 100).toInt()}퍼센트',
                  child: LinearProgressIndicator(
                    value: progress,
                    color: AppColors.offWhite,
                    backgroundColor: AppColors.charcoal40,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              // AppButton.outlined 는 cream 배경 가정의 charcoal40 border 라
              // 본 dark dim modal 위에서는 시각이 약함. 별 변형 추가는 본 PR
              // 범위 밖 — 우선 AppButton 디자인 시스템 일관성 유지하고 후속에
              // dark variant 검토. (시각이 정말 약하면 ComposingModal 의 배경
              // 을 dark 가 아닌 cream 으로 변경하는 것도 후속 옵션.)
              AppButton.outlined(
                label: '취소',
                onPressed: onCancel,
                isFullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
