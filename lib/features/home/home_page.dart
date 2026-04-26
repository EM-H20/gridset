// lib/features/home/home_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/grid_suggestor/grid_suggestor.dart';
import '../../cores/widgets/buttons/app_button.dart';
import '../../cores/widgets/buttons/app_icon_button.dart';
import '../../flow/flow_selection_provider.dart';
import '../../routers/route_paths.dart';

/// 홈 화면 — Gridset 의 첫 화면.
///
/// 구성:
/// - 상단 자체 헤더 (wordmark.svg + 우상단 디버그 진입 버튼) — AppBar 없음
/// - 큰 헤딩 "오늘은\n뭐 모아볼까?"
/// - Expanded 그리드 프리뷰 (앱 정체성 시각 전달)
/// - 하단 두 CTA: "사진·영상 고르기" (primary, with icon), "비율 먼저 정하기" (outlined)
///
/// 디버그 진입 버튼은 kDebugMode 일 때만 /dev 라우트로 이동.
/// 두 CTA 는 실제 흐름으로 라우팅: 첫 번째는 기본 9:16 비율 설정 후 photo-picker,
/// 두 번째는 canvas-picker (비율 선택) 로 이동.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.md),
              const _HomeHeader(),
              SizedBox(height: AppSpacing.base),
              Text(
                '오늘은\n뭐 모아볼까?',
                style: AppTextStyles.cardTitle_32.copyWith(
                  color: AppColors.charcoal,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              const Expanded(child: _GridPreview()),
              SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: '사진·영상 고르기',
                icon: Icons.image,
                onPressed: () {
                  ref
                      .read(flowSelectionNotifierProvider.notifier)
                      .setCanvas(const CanvasRatio.portrait916());
                  context.push(RoutePaths.photoPicker);
                },
              ),
              SizedBox(height: AppSpacing.md),
              AppButton.outlined(
                label: '비율 먼저 정하기',
                onPressed: () => context.push(RoutePaths.canvasPicker),
              ),
              SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }
}

/// 홈 상단 헤더 — wordmark.svg 좌측 + 우상단 디버그 진입 버튼.
///
/// AppBar 대체 — Scaffold appBar 슬롯을 쓰지 않아 풀브리드 자유 레이아웃.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/wordmark.svg',
          height: 48,
          semanticsLabel: 'Gridset',
        ),
        const Spacer(),
        const _DebugEntryButton(),
      ],
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
      onPressed: kDebugMode ? () => context.go(RoutePaths.dev) : null,
      semanticLabel: kDebugMode ? '개발 도구' : null,
    );
  }
}

/// 앱 정체성 시각 전달용 그리드 프리뷰.
///
/// 4개 카드 (2×2) 에 각기 다른 그리드 레이아웃 변형을 abstract 색상 블록으로 표시.
/// "사진을 이런 그리드로 배치해줘요" 메시지를 비주얼만으로 전달.
class _GridPreview extends StatelessWidget {
  const _GridPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: const [
              Expanded(child: _PreviewCard(layout: _PreviewLayout.split1plus2)),
              SizedBox(width: 12),
              Expanded(child: _PreviewCard(layout: _PreviewLayout.grid2x2)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: const [
              Expanded(child: _PreviewCard(layout: _PreviewLayout.split1plus3)),
              SizedBox(width: 12),
              Expanded(child: _PreviewCard(layout: _PreviewLayout.split2plus1)),
            ],
          ),
        ),
      ],
    );
  }
}

enum _PreviewLayout { split1plus2, grid2x2, split1plus3, split2plus1 }

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.layout});

  final _PreviewLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.lightCream),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: _buildLayout(),
    );
  }

  Widget _buildLayout() {
    switch (layout) {
      case _PreviewLayout.split1plus2:
        // 좌측 큰 블록 / 우측 상하 2분할
        return Row(
          children: [
            Expanded(child: _block(AppColors.charcoal82)),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _block(AppColors.mutedGray)),
                  const SizedBox(height: 4),
                  Expanded(child: _block(AppColors.lightCream)),
                ],
              ),
            ),
          ],
        );
      case _PreviewLayout.grid2x2:
        // 2×2 정사각 4분할
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _block(AppColors.mutedGray)),
                  const SizedBox(width: 4),
                  Expanded(child: _block(AppColors.charcoal40)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _block(AppColors.lightCream)),
                  const SizedBox(width: 4),
                  Expanded(child: _block(AppColors.charcoal82)),
                ],
              ),
            ),
          ],
        );
      case _PreviewLayout.split1plus3:
        // 상단 큰 블록 / 하단 3분할
        return Column(
          children: [
            Expanded(flex: 2, child: _block(AppColors.charcoal82)),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _block(AppColors.mutedGray)),
                  const SizedBox(width: 4),
                  Expanded(child: _block(AppColors.charcoal40)),
                  const SizedBox(width: 4),
                  Expanded(child: _block(AppColors.lightCream)),
                ],
              ),
            ),
          ],
        );
      case _PreviewLayout.split2plus1:
        // 상단 2분할 / 하단 큰 블록
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _block(AppColors.mutedGray)),
                  const SizedBox(width: 4),
                  Expanded(child: _block(AppColors.lightCream)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(flex: 2, child: _block(AppColors.charcoal82)),
          ],
        );
    }
  }

  Widget _block(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
