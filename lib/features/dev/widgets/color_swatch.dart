// lib/features/dev/widgets/color_swatch.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';

/// 색상 스왓치 — 64×64 색상 박스 + 이름 라벨.
class AppColorSwatch extends StatelessWidget {
  const AppColorSwatch({
    super.key,
    required this.color,
    required this.name,
  });

  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64.w,
          height: 64.h,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.charcoal40, width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          name,
          style: AppTextStyles.caption_16
              .copyWith(color: AppColors.charcoal82),
        ),
      ],
    );
  }
}
