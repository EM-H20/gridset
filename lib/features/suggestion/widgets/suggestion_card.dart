import 'package:flutter/material.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/grid_suggestor/grid_suggestor.dart';
import '../../../cores/widgets/grid_layout/bsp_grid_layout.dart';

/// 후보 카드 한 개 — BspGridLayout 위에 placeholder 셀.
///
/// v1.x 에서 사진 썸네일 매핑 추가 예정 — cellBuilder 만 교체.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.canvas,
  });

  final GridSuggestion suggestion;
  final CanvasRatio canvas;

  @override
  Widget build(BuildContext context) {
    return BspGridLayout(
      tree: suggestion.tree,
      aspectRatio: canvas.value,
      borderColor: AppColors.lightCream,
      cellBuilder: (_, _) => const _PlaceholderCell(),
    );
  }
}

class _PlaceholderCell extends StatelessWidget {
  const _PlaceholderCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal04,
        border: Border.all(color: AppColors.lightCream),
      ),
    );
  }
}
