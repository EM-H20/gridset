import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/constants/app_urls.dart';
import '../../cores/utils/url_launcher_util.dart';

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
                  _UpdateButton(
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

class _UpdateButton extends StatelessWidget {
  const _UpdateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: AppColors.insetHighlight,
              offset: Offset(0, 0.5),
            ),
            BoxShadow(color: AppColors.insetRing, spreadRadius: 0.5),
            BoxShadow(
              color: AppColors.insetDrop,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(
          '업데이트',
          style:
              AppTextStyles.button_16.copyWith(color: AppColors.offWhite),
        ),
      ),
    );
  }
}
