import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/constants/app_colors.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/suggestion/widgets/suggestion_card.dart';

void main() {
  // 회귀 방지 — spec(2026-04-27-suggestion-flow-design.md) 의
  // "Suggestion v1: lightCream 배경 + charcoal04 border" 와 코드가 swap 되어
  // 셀 분할이 cream 배경 위에서 시각적으로 사라졌던 사례.
  //
  // v1.x mapped-thumb-design 도입 후: assetsById 가 비어있는 fallback 경로에서도
  // 동일한 placeholder 톤이 유지됨을 보증.
  testWidgets(
    'SuggestionCard — assetsById 누락 시 placeholder 톤 유지 (lightCream + charcoal04)',
    (tester) async {
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
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(393, 852),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SuggestionCard(
                    suggestion: suggestion,
                    canvas: const CanvasRatio.square(),
                    assetsById: const {}, // 매핑 누락 — fallback 경로
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // _PlaceholderCell 의 Container 만 lightCream 배경을 가짐.
      final placeholders = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(SuggestionCard),
              matching: find.byType(Container),
            ),
          )
          .where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == AppColors.lightCream;
      });
      expect(placeholders, hasLength(2),
          reason: 'leaf 마다 placeholder 한 개');

      for (final c in placeholders) {
        final decoration = c.decoration as BoxDecoration;
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
