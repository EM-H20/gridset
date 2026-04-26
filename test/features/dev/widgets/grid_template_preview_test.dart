// test/features/dev/widgets/grid_template_preview_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/dev/widgets/grid_template_preview.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  group('GridTemplatePreview (smoke)', () {
    // N=4 의 1+3 비대칭 패턴 — 다중 셀 의미 있는 fixture
    final fixtureTemplate = NamedTemplate(
      name: 'n4_left1_right3',
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: [
          const Leaf(0),
          Split(
            axis: SplitAxis.horizontal,
            positions: const [1 / 3, 2 / 3],
            children: const [Leaf(1), Leaf(2), Leaf(3)],
          ),
        ],
      ),
      cellIds: const [0, 1, 2, 3],
    );

    testWidgets('템플릿 이름 라벨이 표시된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        GridTemplatePreview(
          template: fixtureTemplate,
          canvas: const CanvasRatio.portrait916(),
        ),
      );

      expect(find.text('n4_left1_right3'), findsOneWidget);
    });

    testWidgets('각 cellId 번호가 정확히 한 번씩 표시된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        GridTemplatePreview(
          template: fixtureTemplate,
          canvas: const CanvasRatio.square(),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}
