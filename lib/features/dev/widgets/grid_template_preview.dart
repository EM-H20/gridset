// lib/features/dev/widgets/grid_template_preview.dart
import 'package:flutter/material.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';
import '../../../cores/grid_suggestor/grid_suggestor.dart';

/// 큐레이션 템플릿 시각 미리보기 카드 (`/dev` 갤러리용).
///
/// 알고리즘 모듈의 [cellBBoxes] 를 재사용해 BSP 트리를 정규화 좌표(0..1)로 풀고,
/// [AspectRatio] 컨테이너 안의 [Stack] + [Positioned.fromRect] 로 셀들을 그린다.
/// 캔버스 비율 변경 시 AspectRatio 가 갱신되어 셀 종횡비가 즉시 반영.
///
/// 디자인: [AppColors.lightCream] 셀 테두리 + 옅은 셀 배경([AppColors.charcoal04]),
/// cellId 번호는 [AppTextStyles.caption_16] 로 셀 좌상단 작게.
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
    final bboxes = cellBBoxes(template.tree);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          template.name,
          style: AppTextStyles.caption_16.copyWith(color: AppColors.charcoal82),
        ),
        SizedBox(height: AppSpacing.xs),
        AspectRatio(
          aspectRatio: canvas.value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.charcoal40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    children: [
                      for (final entry in bboxes.entries)
                        Positioned.fromRect(
                          rect: Rect.fromLTWH(
                            entry.value.left * w,
                            entry.value.top * h,
                            entry.value.width * w,
                            entry.value.height * h,
                          ),
                          child: _CellTile(cellId: entry.key),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
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
