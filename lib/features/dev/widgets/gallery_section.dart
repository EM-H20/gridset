// lib/features/dev/widgets/gallery_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';

/// Dev 갤러리의 카드형 섹션 — 제목 + 자식 위젯들 수직 나열.
class GallerySection extends StatelessWidget {
  const GallerySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.lightCream),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle_32),
          SizedBox(height: AppSpacing.base.h),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: AppSpacing.md.h),
          ],
        ],
      ),
    );
  }
}
