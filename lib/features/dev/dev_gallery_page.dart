// lib/features/dev/dev_gallery_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/grid_suggestor/grid_suggestor.dart';
import '../../cores/widgets/buttons/app_button.dart';
import '../../cores/widgets/buttons/app_icon_button.dart';
import '../../routers/route_paths.dart';
import 'widgets/color_swatch.dart';
import 'widgets/gallery_section.dart';
import 'widgets/grid_template_preview.dart';

/// Dev 컴포넌트 갤러리 — kDebugMode 시 홈 우상단 버튼에서 진입.
///
/// 5개 섹션: AppButton, AppIconButton, Colors, Typography, Grid Templates.
class DevGalleryPage extends StatelessWidget {
  const DevGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm),
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
          SizedBox(width: AppSpacing.base),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.base),
          child: Column(
            children: [
              const _AppButtonSection(),
              SizedBox(height: AppSpacing.xl),
              const _AppIconButtonSection(),
              SizedBox(height: AppSpacing.xl),
              const _ColorsSection(),
              SizedBox(height: AppSpacing.xl),
              const _TypographySection(),
              SizedBox(height: AppSpacing.xl),
              const _GridTemplatesSection(),
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
            SizedBox(width: AppSpacing.sm),
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
            SizedBox(width: AppSpacing.sm),
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
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
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
// Grid Templates 섹션 (Phase C)
// ---------------------------------------------------------------------------

/// `kGridTemplates` 의 N=2..9 모든 큐레이션을 카드 sweep 으로 노출.
///
/// Task 2 단계: 캔버스 비율 hardcoded `portrait916`.
/// Task 3 에서 StatefulWidget 화 + 4 preset 토글 추가.
class _GridTemplatesSection extends StatelessWidget {
  const _GridTemplatesSection();

  // dev/dev_gallery 표시 비율 — Task 3 에서 setState 로 변경 가능.
  static const _canvas = CanvasRatio.portrait916();

  @override
  Widget build(BuildContext context) {
    final ns = kGridTemplates.keys.toList()..sort();
    return GallerySection(
      title: 'Grid Templates',
      children: [
        for (final n in ns) ...[
          _ItemLabel('N = $n (${kGridTemplates[n]!.length}개)'),
          // 한 줄에 카드들을 Wrap — 좁은 화면도 자동 줄바꿈
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final t in kGridTemplates[n]!)
                SizedBox(
                  // 한 카드당 폭 — 화면 폭의 약 1/3 가정 (393w 기준)
                  width: 120.w,
                  child: GridTemplatePreview(
                    template: t,
                    canvas: _canvas,
                  ),
                ),
            ],
          ),
        ],
      ],
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
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTextStyles.caption_16
            .copyWith(color: AppColors.charcoal82),
      ),
    );
  }
}
