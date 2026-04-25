import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';

/// 사용자가 뒤로 가기 못 하고 안내 메시지를 봐야 하는 풀스크린 페이지.
///
/// `PopScope(canPop: false)` 로 시스템 백 차단. 점검/강제업데이트/치명적
/// 에러 안내 등 부트스트랩 흐름의 게이트 페이지에 공통 사용.
///
/// 사용:
/// ```dart
/// const BlockingInfoPage(
///   title: '점검 중이에요',
///   message: '잠시만 기다려주세요.',
/// )
///
/// BlockingInfoPage(
///   title: '업데이트 필요',
///   message: '최신 버전으로 업데이트해주세요.',
///   action: AppButton.primary(label: '업데이트', onPressed: ...),
/// )
/// ```
class BlockingInfoPage extends StatelessWidget {
  const BlockingInfoPage({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  /// 큰 헤딩 (subHeading_48, charcoal, 중앙 정렬)
  final String title;

  /// 본문 메시지 (body_16, charcoal82, 중앙 정렬, 멀티라인 가능)
  final String message;

  /// 옵션 — 본문 아래 표시할 액션 (보통 AppButton.primary).
  /// null 이면 액션 영역 미렌더.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
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
                  if (action != null) ...[
                    SizedBox(height: AppSpacing.xxl),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
