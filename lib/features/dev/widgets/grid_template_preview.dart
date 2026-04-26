// lib/features/dev/widgets/grid_template_preview.dart
import 'package:flutter/material.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';
import '../../../cores/grid_suggestor/grid_suggestor.dart';
import '../../../cores/widgets/grid_layout/bsp_grid_layout.dart';

/// 큐레이션 템플릿 시각 미리보기 카드 (`/dev` 갤러리용).
///
/// 셀 자리잡기는 [BspGridLayout] 에 위임, 셀 안에는 cellId 텍스트만 표시.
/// production suggestion 화면도 동일 [BspGridLayout] 을 다른 cellBuilder 로 사용.
class GridTemplatePreview extends StatelessWidget {
  const GridTemplatePreview({
    super.key,
    required this.template,
    required this.canvas,
  });

  final NamedTemplate template;
  final CanvasRatio canvas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          template.name,
          style:
              AppTextStyles.caption_16.copyWith(color: AppColors.charcoal82),
        ),
        SizedBox(height: AppSpacing.xs),
        BspGridLayout(
          tree: template.tree,
          aspectRatio: canvas.value,
          borderColor: AppColors.charcoal40,
          cellBuilder: (cellId, _) => _CellTile(cellId: cellId),
        ),
      ],
    );
  }
}

class _CellTile extends StatelessWidget {
  const _CellTile({required this.cellId});
  final int cellId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal04,
        border: Border.all(color: AppColors.lightCream),
      ),
      padding: EdgeInsets.all(AppSpacing.xs),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          '$cellId',
          style: AppTextStyles.caption_16.copyWith(color: AppColors.charcoal),
        ),
      ),
    );
  }
}
