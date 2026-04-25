// test/cores/widgets/buttons/app_icon_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/widgets/buttons/app_icon_button.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  group('AppIconButton', () {
    testWidgets('아이콘이 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppIconButton(icon: Icons.arrow_back_ios_new, onPressed: () {}),
      );

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('탭하면 onPressed 콜백이 호출된다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        AppIconButton(
          icon: Icons.more_horiz,
          onPressed: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(AppIconButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onPressed 가 null 이면 탭해도 콜백이 호출되지 않는다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        const AppIconButton(icon: Icons.close, onPressed: null),
      );

      await tester.tap(find.byType(AppIconButton), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('semanticLabel 이 Semantics 트리에 노출된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () {},
          semanticLabel: '뒤로 가기',
        ),
      );

      expect(find.bySemanticsLabel('뒤로 가기'), findsOneWidget);
    });

    testWidgets('semanticLabel 가 없어도 button 역할이 Semantics 트리에 노출된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppIconButton(icon: Icons.close, onPressed: () {}),
      );

      final semantics = tester.getSemantics(find.byType(AppIconButton));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('size=32 이어도 탭 영역은 최소 44px', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppIconButton(icon: Icons.close, onPressed: () {}, size: 32),
      );

      final size = tester.getSize(find.byType(AppIconButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });
}
