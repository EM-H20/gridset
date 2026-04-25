import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/services/remote_config/remote_config_service.dart';

/// 점검 안내 풀스크린.
///
/// `PopScope(canPop: false)` 로 뒤로가기 차단.
/// `RemoteConfigService.maintenanceMessage` 가 비어있으면 기본 문구 사용.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = RemoteConfigService.instance.maintenanceMessage;
    final message = raw.isEmpty
        ? '더 좋은 서비스로 찾아올게요.\n잠시만 기다려주세요.'
        : raw;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '점검 중이에요',
                    style: AppTextStyles.subHeading_48
                        .copyWith(color: AppColors.charcoal),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Text(
                    message,
                    style: AppTextStyles.body_16
                        .copyWith(color: AppColors.charcoal82),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
