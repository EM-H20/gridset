import 'package:flutter/material.dart' hide Split;
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/cores/widgets/grid_layout/bsp_grid_layout.dart';

void main() {
  group('BspGridLayout', () {
    testWidgets('1+2 트리 — cellBuilder 가 cellId 1, 2, 3 으로 호출됨',
        (tester) async {
      final calledIds = <int>[];
      final tree = Split(
        axis: SplitAxis.vertical,
        positions: [0.5],
        children: [
          const Leaf(1),
          Split(
            axis: SplitAxis.horizontal,
            positions: [0.5],
            children: const [Leaf(2), Leaf(3)],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(
          width: 360,
          height: 640,
          child: BspGridLayout(
            tree: tree,
            aspectRatio: 9 / 16,
            cellBuilder: (id, _) {
              calledIds.add(id);
              return ColoredBox(color: Colors.amber, child: Text('$id'));
            },
          ),
        ),
      ));

      expect(calledIds, [1, 2, 3]);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('aspectRatio 값이 AspectRatio 위젯에 반영',
        (tester) async {
      const tree = Leaf(1);

      await tester.pumpWidget(MaterialApp(
        home: SizedBox(
          width: 200,
          child: BspGridLayout(
            tree: tree,
            aspectRatio: 1.0,
            cellBuilder: (_, _) => const SizedBox.shrink(),
          ),
        ),
      ));

      final ar = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(ar.aspectRatio, 1.0);
    });
  });
}
