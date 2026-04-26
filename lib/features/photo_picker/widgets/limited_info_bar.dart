import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';

/// iOS limited photo access 안내 bar — picker 그리드 상단 고정.
///
/// 탭 시 [PhotoManager.presentLimited] — 사용자가 추가 사진 선택 가능.
/// v1: 권한 상태가 limited 인 한 매번 표시 (dismiss 상태 저장 X).
class LimitedInfoBar extends StatelessWidget {
  const LimitedInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.charcoal04,
      child: InkWell(
        onTap: () => PhotoManager.presentLimited(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '선택한 사진만 보여요. 더 보려면',
                  style: AppTextStyles.body_16
                      .copyWith(color: AppColors.charcoal82),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.charcoal82, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
