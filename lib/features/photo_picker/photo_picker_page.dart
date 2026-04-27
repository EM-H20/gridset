import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/grid_suggestor/grid_suggestor.dart';
import '../../cores/widgets/buttons/app_button.dart';
import '../../flow/flow_selection_provider.dart';
import '../../routers/route_paths.dart';
import '../suggestion/providers/selected_assets_provider.dart';
import 'asset_to_media_item.dart';
import 'providers/asset_selection_provider.dart';
import 'providers/permission_provider.dart';
import 'widgets/asset_grid.dart';
import 'widgets/limited_info_bar.dart';
import 'widgets/permission_denied_view.dart';

/// 사진/영상 picker 화면 — 권한 분기 + AssetGrid + "다음" CTA.
class PhotoPickerPage extends ConsumerWidget {
  const PhotoPickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permAsync = ref.watch(photoPermissionProvider);
    final selection = ref.watch(assetSelectionNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '사진 고르기 ${selection.length}/9',
          style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
        ),
      ),
      body: SafeArea(
        child: permAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) =>
              const PermissionDeniedView(state: AppPermissionState.denied),
          data: (state) {
            switch (state) {
              case AppPermissionState.authorized:
              case AppPermissionState.limited:
                return Column(
                  children: [
                    if (state == AppPermissionState.limited)
                      const LimitedInfoBar(),
                    const Expanded(child: AssetGrid()),
                    _BottomBar(
                      onNext: selection.length >= 2
                          ? () => _onNext(context, ref)
                          : null,
                      selectionCount: selection.length,
                    ),
                  ],
                );
              case AppPermissionState.denied:
              case AppPermissionState.restricted:
                return PermissionDeniedView(state: state);
            }
          },
        ),
      ),
    );
  }

  void _onNext(BuildContext context, WidgetRef ref) {
    final assets = ref.read(assetSelectionNotifierProvider);
    final items = assets
        .map(assetToMediaItem)
        .whereType<MediaItem>()
        .toList(growable: false);

    // 페어 호출 — flowSelection 은 알고리즘 입력 (MediaItem),
    // selectedAssets 는 렌더링 자원 (AssetEntity). 둘 중 하나만 호출되면
    // suggestion 화면이 silent 실패 (모든 셀 placeholder).
    //
    // 순서는 flowSelection → selectedAssets 로 고정한다. 둘 다 동기 setter
    // 라 race 가 없지만, 향후 listener / async middleware 가 어느 한 쪽에
    // 먼저 붙는 경우를 가정해 "알고리즘 입력이 먼저 정해진 뒤 자원이 따라
    // 붙는다" 는 의미를 코드 순서로도 유지한다.
    ref.read(flowSelectionNotifierProvider.notifier).setMedia(items);
    ref
        .read(selectedAssetsNotifierProvider.notifier)
        .setAssets(assets);

    context.push(RoutePaths.suggestion);
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onNext, required this.selectionCount});

  final VoidCallback? onNext;
  final int selectionCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectionCount < 2)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '2장 이상 골라주세요',
                style: AppTextStyles.caption_16
                    .copyWith(color: AppColors.mutedGray),
                textAlign: TextAlign.center,
              ),
            ),
          AppButton.primary(label: '다음', onPressed: onNext),
        ],
      ),
    );
  }
}
