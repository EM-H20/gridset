import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_text_style.dart';

/// 홈 플레이스홀더.
///
/// 실제 홈 feature 는 별도 브랜치/플랜에서 구축 예정.
/// 현재는 cream 배경 + "Gridset" 로고 텍스트만.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.lightCream, width: 1),
        ),
      ),
      body: Center(
        child: Text(
          'Gridset',
          style: AppTextStyles.displayAlt_80
              .copyWith(color: AppColors.charcoal),
        ),
      ),
    );
  }
}
