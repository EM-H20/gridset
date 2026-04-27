import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';

/// PageView 현재 페이지 dots indicator — 활성은 길쭉한 pill, 나머지는 작은 점.
class SuggestionDots extends StatelessWidget {
  const SuggestionDots({
    super.key,
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == current;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: on ? 16.w : 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: on ? AppColors.charcoal : AppColors.charcoal40,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
