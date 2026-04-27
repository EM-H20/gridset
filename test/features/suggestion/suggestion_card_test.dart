// material 의 Split (animation curve) 와 grid_suggestor 의 Split (BSP node) 이 동명.
// bsp_grid_layout.dart 와 동일하게 material 의 Split 을 hide 한다.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/constants/app_colors.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/suggestion/widgets/suggestion_card.dart';

void main() {
  // 회귀 방지 — spec(2026-04-27-suggestion-flow-design.md) 의
  // "Suggestion v1: lightCream 배경 + charcoal04 border" 와 코드가 swap 되어
  // 셀 분할이 cream 배경 위에서 시각적으로 사라졌던 사례.
  testWidgets(
    'SuggestionCard 의 placeholder 셀은 lightCream 배경 + charcoal04 분할선',
    (tester) async {
      // 두 셀을 가진 최소 트리 — V-split 좌/우.
      final suggestion = GridSuggestion(
        tree: Split(
          axis: SplitAxis.vertical,
          positions: const [0.5],
          children: const [Leaf(0), Leaf(1)],
        ),
        mediaByCellId: const {0: 'a', 1: 'b'},
        loss: 0.0,
        templateName: 'test_2',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SuggestionCard(
                suggestion: suggestion,
                canvas: const CanvasRatio.square(),
              ),
            ),
          ),
        ),
      );

      // SuggestionCard 안의 Container 는 _PlaceholderCell 의 것뿐 (BspGridLayout 은
      // DecoratedBox/ClipRRect 만 쓴다). 두 leaf → 두 Container.
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(SuggestionCard),
          matching: find.byType(Container),
        ),
      );

      expect(containers, hasLength(2),
          reason: 'leaf 마다 placeholder 한 개');

      for (final c in containers) {
        final decoration = c.decoration as BoxDecoration;
        expect(
          decoration.color,
          AppColors.lightCream,
          reason: 'spec: lightCream 배경 (cream 위에서 한 톤 어둡게 보여야 함)',
        );
        final border = decoration.border as Border;
        expect(
          border.top.color,
          AppColors.charcoal04,
          reason: 'spec: charcoal04 분할선',
        );
        expect(border.left.color, AppColors.charcoal04);
        expect(border.right.color, AppColors.charcoal04);
        expect(border.bottom.color, AppColors.charcoal04);
      }
    },
  );
}
