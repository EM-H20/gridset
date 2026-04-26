import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';

/// 비율 chip — outlined card + 선택 시 border 강조.
///
/// 내부 모양 박스의 비율로 시각 힌트, 라벨/캡션은 16배수 폰트 유지.
class RatioChip extends StatelessWidget {
  const RatioChip({
    super.key,
    required this.ratio,
    required this.label,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final double ratio;
  final String label;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Border.all(color: AppColors.charcoal40, width: 1.5)
        : Border.all(color: AppColors.lightCream);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $caption',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: border,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowFocus,
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.charcoal82,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.body_16.copyWith(
                  color: AppColors.charcoal,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                caption,
                style: AppTextStyles.caption_16.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
