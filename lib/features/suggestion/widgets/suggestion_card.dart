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
    // spec(2026-04-27-suggestion-flow-design.md) §"GridTemplatePreview 승격" 표 기준:
    // lightCream(#ECEAE4) 채움 + charcoal04 분할선. cream(#F7F4ED) 카드 위에서
    // 셀 모자이크가 한 톤 어두운 warm-gray 로 또렷이 분할되어 보인다.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightCream,
        border: Border.all(color: AppColors.charcoal04),
      ),
    );
  }
}
