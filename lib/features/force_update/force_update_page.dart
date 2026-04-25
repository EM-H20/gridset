import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/constants/app_urls.dart';
import '../../cores/utils/url_launcher_util.dart';
import '../../cores/widgets/buttons/app_button.dart';

/// 강제 업데이트 풀스크린.
///
/// `PopScope(canPop: false)` 로 뒤로가기 차단.
/// "업데이트" 버튼은 `AppUrls.storeUrl` 로 외부 브라우저 이동.
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    '업데이트 필요',
                    style: AppTextStyles.subHeading_48
                        .copyWith(color: AppColors.charcoal),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Text(
                    '원활한 사용을 위해\n최신 버전으로 업데이트해주세요.',
                    style: AppTextStyles.body_16
                        .copyWith(color: AppColors.charcoal82),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  AppButton.primary(
                    label: '업데이트',
                    isFullWidth: false,
                    onPressed: () => launchExternalUrl(AppUrls.storeUrl),
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
