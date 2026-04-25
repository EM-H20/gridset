// lib/features/dev/dev_gallery_page.dart
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
import 'widgets/color_swatch.dart' as swatch;
import 'widgets/gallery_section.dart';

/// Dev 컴포넌트 갤러리 — kDebugMode 시 홈 우상단 버튼에서 진입.
///
/// 5개 섹션: AppButton, AppIconButton, AppTopBar, Colors, Typography.
class DevGalleryPage extends StatelessWidget {
  const DevGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppTopBar.backWithMore(
        title: 'Components',
        onBack: () => context.go(RoutePaths.home),
        onMore: () => debugPrint('🛠️ Dev gallery more menu (v2)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.base.w),
          child: Column(
            children: [
              _buildAppButtonSection(),
              SizedBox(height: AppSpacing.xl.h),
              _buildAppIconButtonSection(),
              SizedBox(height: AppSpacing.xl.h),
              _buildAppTopBarSection(),
              SizedBox(height: AppSpacing.xl.h),
              _buildColorsSection(),
              SizedBox(height: AppSpacing.xl.h),
              _buildTypographySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppButtonSection() {
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

  Widget _buildAppIconButtonSection() {
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

  Widget _buildAppTopBarSection() {
    return GallerySection(
      title: 'AppTopBar',
      children: [
        _ItemLabel('.title (with trailing)'),
        SizedBox(
          height: 64.h,
          child: AppTopBar.title(
            title: 'Gridset',
            trailing: AppIconButton(
              icon: Icons.gps_fixed,
              onPressed: () {},
            ),
          ),
        ),
        _ItemLabel('.backWithMore'),
        SizedBox(
          height: 64.h,
          child: AppTopBar.backWithMore(
            title: '제안 1/3',
            onBack: () {},
            onMore: () {},
          ),
        ),
        _ItemLabel('.closeWithSave (active)'),
        SizedBox(
          height: 64.h,
          child: AppTopBar.closeWithSave(
            title: 'Gridset',
            onClose: () {},
            onSave: () {},
          ),
        ),
        _ItemLabel('.closeWithSave (save disabled)'),
        SizedBox(
          height: 64.h,
          child: AppTopBar.closeWithSave(
            title: 'Gridset',
            onClose: () {},
            onSave: null,
          ),
        ),
      ],
    );
  }

  Widget _buildColorsSection() {
    final entries = [
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

    return GallerySection(
      title: 'Colors (AppColors)',
      children: [
        Wrap(
          spacing: AppSpacing.md.w,
          runSpacing: AppSpacing.md.h,
          children: entries
              .map((e) => swatch.ColorSwatch(name: e.$1, color: e.$2))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTypographySection() {
    final entries = [
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

    return GallerySection(
      title: 'Typography (AppTextStyles)',
      children: entries.expand((e) {
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
