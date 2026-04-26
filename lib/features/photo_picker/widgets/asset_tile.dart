import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_text_style.dart';
import '../providers/asset_selection_provider.dart';

/// 갤러리 그리드 셀 — 썸네일 + 선택 순서 badge + dim overlay.
class AssetTile extends ConsumerWidget {
  const AssetTile({super.key, required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(assetSelectionNotifierProvider);
    final selIndex = selection.indexWhere((e) => e.id == asset.id);
    final selected = selIndex >= 0;

    return GestureDetector(
      onTap: () => ref
          .read(assetSelectionNotifierProvider.notifier)
          .toggle(asset, context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(256),
            fit: BoxFit.cover,
          ),
          if (selected) Container(color: AppColors.charcoal40),
          if (selected)
            Positioned(
              top: 4.h,
              right: 4.h,
              child: Container(
                width: 24.w,
                height: 24.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.charcoal,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${selIndex + 1}',
                  style: AppTextStyles.caption_16.copyWith(
                    color: AppColors.offWhite,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
