import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';
import '../../../cores/widgets/buttons/app_button.dart';
import '../providers/permission_provider.dart';

/// 권한 거부/제한 시 안내 화면.
///
/// `denied` — "설정 열기" CTA 활성, [PhotoManager.openSetting] 호출
/// (iOS/Android 모두 시스템 앱 설정으로 이동).
/// `restricted` — CTA disabled (parental controls).
class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({super.key, required this.state});

  final AppPermissionState state;

  @override
  Widget build(BuildContext context) {
    assert(
      state == AppPermissionState.denied ||
          state == AppPermissionState.restricted,
      'PermissionDeniedView 는 denied/restricted 일 때만 사용',
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/icon_siren.svg',
              width: 48.w,
              height: 48.w,
              colorFilter: const ColorFilter.mode(
                AppColors.charcoal40,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: AppSpacing.base),
            Text(
              '갤러리 접근이 막혀있어요',
              style: AppTextStyles.cardTitle_32
                  .copyWith(color: AppColors.charcoal),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              state == AppPermissionState.restricted
                  ? '시스템 정책으로 접근이 제한되어 있어요'
                  : '설정에서 사진 접근을 허용하면 시작할 수 있어요',
              style: AppTextStyles.body_16
                  .copyWith(color: AppColors.charcoal82),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            AppButton.primary(
              label: '설정 열기',
              onPressed: state == AppPermissionState.restricted
                  ? null
                  : () => PhotoManager.openSetting(),
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
