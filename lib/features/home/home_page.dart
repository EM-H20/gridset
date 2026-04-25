// lib/features/home/home_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/widgets/app_bars/app_top_bar.dart';
import '../../cores/widgets/buttons/app_button.dart';
import '../../cores/widgets/buttons/app_icon_button.dart';
import '../../routers/route_paths.dart';

/// 홈 화면 — Gridset 의 첫 화면.
///
/// 구성:
/// - 상단 AppTopBar.title (Gridset 워드마크 + 디버그 진입 버튼)
/// - 큰 헤딩 "오늘은\n뭐 모아볼까?"
/// - 두 CTA: "사진·영상 고르기" (primary, with icon), "비율 먼저 정하기" (outlined)
///
/// 디버그 진입 버튼은 kDebugMode 일 때만 /dev 라우트로 이동.
/// CTA 는 화면 2 (suggestion) 미구현이라 SnackBar stub.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showStubSnackBar(BuildContext context) {
    debugPrint('🚧 CTA 동작 — 다음 화면(suggestion) 미구현');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.charcoal,
        content: Text(
          '다음 화면 준비 중',
          style: AppTextStyles.body_16.copyWith(color: AppColors.offWhite),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppTopBar.title(
        title: 'Gridset',
        trailing: const _DebugEntryButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xxxl.h),
              Text(
                '오늘은\n뭐 모아볼까?',
                style: AppTextStyles.subHeading_48
                    .copyWith(color: AppColors.charcoal),
              ),
              SizedBox(height: AppSpacing.xxxl.h),
              AppButton.primary(
                label: '사진·영상 고르기',
                icon: Icons.image,
                onPressed: () => _showStubSnackBar(context),
              ),
              SizedBox(height: AppSpacing.md.h),
              AppButton.outlined(
                label: '비율 먼저 정하기',
                onPressed: () => _showStubSnackBar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 우상단 디버그 진입 버튼.
///
/// kDebugMode 일 때만 /dev 라우트로 이동. release 빌드에선 onPressed null → disabled.
class _DebugEntryButton extends StatelessWidget {
  const _DebugEntryButton();

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.gps_fixed,
      onPressed: kDebugMode
          ? () => context.go(RoutePaths.dev)
          : null,
      semanticLabel: kDebugMode ? '개발 도구' : null,
    );
  }
}
