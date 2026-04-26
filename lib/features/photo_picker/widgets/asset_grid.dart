import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';
import '../providers/asset_paged_provider.dart';
import 'asset_tile.dart';

/// 3-column lazy grid — paged provider 와 연동.
///
/// 갤러리 0장 시 안내 텍스트, 로딩 시 cream 배경, 오류 시 텍스트 안내.
class AssetGrid extends ConsumerWidget {
  const AssetGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagedAsync = ref.watch(assetPagedNotifierProvider);
    return pagedAsync.when(
      loading: () => Container(color: AppColors.charcoal04),
      error: (err, _) => Center(
        child: Text(
          '갤러리를 읽지 못했어요',
          style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal82),
        ),
      ),
      data: (assets) {
        if (assets.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text(
                '갤러리에 사진이 없어요',
                style: AppTextStyles.body_16.copyWith(
                  color: AppColors.charcoal82,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // 하단 200px 이내 진입 시 다음 페이지 로드
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
              ref.read(assetPagedNotifierProvider.notifier).loadMore();
            }
            return false;
          },
          child: GridView.builder(
            padding: EdgeInsets.all(AppSpacing.xs),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.0,
            ),
            itemCount: assets.length,
            itemBuilder: (_, i) => AssetTile(asset: assets[i]),
          ),
        );
      },
    );
  }
}
