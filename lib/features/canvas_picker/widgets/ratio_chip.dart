import 'package:flutter/material.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';

/// 카드 표준 radius (Design.md §"Border Radius Scale" Card = 12).
const double _kCardRadius = 12;

/// 내부 비율 박스의 modest radius (Design.md "Micro 4px").
const double _kInnerRadius = 4;

/// 선택 상태 강조 border 두께 (Design.md "interactive 1.5px"). spacing 토큰이
/// 아닌 stroke 두께라 별도 file-local const 유지.
const double _kSelectedBorderWidth = 1.5;

/// Focus shadow geometry (Design.md §6 Level 3).
const Offset _kFocusShadowOffset = Offset(0, 4);
const double _kFocusShadowBlur = 12;

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
        ? Border.all(
            color: AppColors.charcoal40,
            width: _kSelectedBorderWidth,
          )
        : Border.all(color: AppColors.lightCream);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $caption',
      child: InkWell(
        borderRadius: BorderRadius.circular(_kCardRadius),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: border,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowFocus,
                      offset: _kFocusShadowOffset,
                      blurRadius: _kFocusShadowBlur,
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
                        borderRadius: BorderRadius.circular(_kInnerRadius),
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
