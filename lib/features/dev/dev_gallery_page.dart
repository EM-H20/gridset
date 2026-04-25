// lib/features/dev/dev_gallery_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/widgets/buttons/app_button.dart';
import '../../cores/widgets/buttons/app_icon_button.dart';
import '../../routers/route_paths.dart';
import 'widgets/color_swatch.dart';
import 'widgets/gallery_section.dart';

/// Dev 컴포넌트 갤러리 — kDebugMode 시 홈 우상단 버튼에서 진입.
///
/// 4개 섹션: AppButton, AppIconButton, Colors, Typography.
class DevGalleryPage extends StatelessWidget {
  const DevGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm.w),
          child: AppIconButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => context.go(RoutePaths.home),
            semanticLabel: '뒤로 가기',
          ),
        ),
        title: Text(
          'Components',
          style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
        ),
        centerTitle: true,
        actions: [
          AppIconButton(
            icon: Icons.more_horiz,
            onPressed: () => debugPrint('🛠️ Dev gallery more menu (v2)'),
            semanticLabel: '더보기',
          ),
          SizedBox(width: AppSpacing.base.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.base.w),
          child: Column(
            children: [
              const _AppButtonSection(),
              SizedBox(height: AppSpacing.xl.h),
              const _AppIconButtonSection(),
              SizedBox(height: AppSpacing.xl.h),
              const _ColorsSection(),
              SizedBox(height: AppSpacing.xl.h),
              const _TypographySection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private section widgets
// ---------------------------------------------------------------------------

class _AppButtonSection extends StatelessWidget {
  const _AppButtonSection();

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'AppButton',
      children: [
        _ItemLabel('primary (full, with icon)'),
        AppButton.primary(
          label: '사진·영상 고르기',
          icon: Icons.image,
          onPressed: () {},
        ),
        _ItemLabel('primary (full, no icon)'),
        AppButton.primary(label: '이걸로', onPressed: () {}),
        _ItemLabel('primary (auto-width, Row of 2)'),
        Row(
          children: [
            Expanded(
              child: AppButton.primary(
                label: '다른 제안',
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: AppButton.primary(
                label: '빈 캔버스',
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
          ],
        ),
        _ItemLabel('primary (disabled)'),
        const AppButton.primary(label: '비활성', onPressed: null),
        _ItemLabel('outlined (full)'),
        AppButton.outlined(label: '비율 먼저 정하기', onPressed: () {}),
        _ItemLabel('outlined (auto-width, Row of 2)'),
        Row(
          children: [
            Expanded(
              child: AppButton.outlined(
                label: '다른 제안',
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: AppButton.outlined(
                label: '빈 캔버스',
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
          ],
        ),
        _ItemLabel('outlined (disabled)'),
        const AppButton.outlined(label: '비활성', onPressed: null),
      ],
    );
  }
}

class _AppIconButtonSection extends StatelessWidget {
  const _AppIconButtonSection();

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'AppIconButton',
      children: [
        _ItemLabel('default (size: 40)'),
        AppIconButton(icon: Icons.arrow_back_ios_new, onPressed: () {}),
        _ItemLabel('small (size: 32, 탭 영역 ≥44pt 보장)'),
        AppIconButton(icon: Icons.close, onPressed: () {}, size: 32),
        _ItemLabel('disabled'),
        const AppIconButton(icon: Icons.more_horiz, onPressed: null),
        _ItemLabel('with semanticLabel'),
        AppIconButton(
          icon: Icons.gps_fixed,
          onPressed: () {},
          semanticLabel: '센터',
        ),
      ],
    );
  }
}

class _ColorsSection extends StatelessWidget {
  const _ColorsSection();

  static const _entries = [
    ('cream', AppColors.cream),
    ('charcoal', AppColors.charcoal),
    ('offWhite', AppColors.offWhite),
    ('charcoal83', AppColors.charcoal83),
    ('charcoal82', AppColors.charcoal82),
    ('charcoal40', AppColors.charcoal40),
    ('charcoal04', AppColors.charcoal04),
    ('charcoal03', AppColors.charcoal03),
    ('mutedGray', AppColors.mutedGray),
    ('lightCream', AppColors.lightCream),
    ('ringBlue', AppColors.ringBlue),
    ('shadowFocus', AppColors.shadowFocus),
    ('insetHighlight', AppColors.insetHighlight),
    ('insetRing', AppColors.insetRing),
    ('insetDrop', AppColors.insetDrop),
  ];

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Colors (AppColors)',
      children: [
        Wrap(
          spacing: AppSpacing.md.w,
          runSpacing: AppSpacing.md.h,
          children: _entries
              .map((e) => AppColorSwatch(name: e.$1, color: e.$2))
              .toList(),
        ),
      ],
    );
  }
}

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  // AppTextStyles uses .sp (ScreenUtil getter) — cannot be const
  static List<(String, TextStyle, String)> get _entries => [
    ('displayHero_96', AppTextStyles.displayHero_96, 'Gridset'),
    ('displayAlt_80', AppTextStyles.displayAlt_80, 'Gridset'),
    ('sectionHeading_64', AppTextStyles.sectionHeading_64, '오늘은'),
    ('subHeading_48', AppTextStyles.subHeading_48, '오늘은 뭐 만들까?'),
    ('cardTitle_32', AppTextStyles.cardTitle_32, '이어서 만들기'),
    ('bodyLarge_32', AppTextStyles.bodyLarge_32, '큰 본문 텍스트'),
    ('body_16', AppTextStyles.body_16, '표준 본문 텍스트입니다'),
    ('button_16', AppTextStyles.button_16, '버튼 라벨'),
    ('link_16', AppTextStyles.link_16, '링크 텍스트'),
    ('caption_16', AppTextStyles.caption_16, '캡션·메타데이터'),
  ];

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Typography (AppTextStyles)',
      children: _entries.expand((e) {
        return [
          _ItemLabel(e.$1),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 120.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                e.$3,
                style: e.$2.copyWith(color: AppColors.charcoal),
              ),
            ),
          ),
        ];
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared private helpers
// ---------------------------------------------------------------------------

/// 갤러리 항목 라벨 (라벨 + 위젯 본체 패턴).
class _ItemLabel extends StatelessWidget {
  const _ItemLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Text(
        text,
        style: AppTextStyles.caption_16
            .copyWith(color: AppColors.charcoal82),
      ),
    );
  }
}
