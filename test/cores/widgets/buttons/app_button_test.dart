// test/cores/widgets/buttons/app_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/widgets/buttons/app_button.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  group('AppButton.primary', () {
    testWidgets('라벨 텍스트가 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppButton.primary(label: '사진·영상 고르기', onPressed: () {}),
      );

      expect(find.text('사진·영상 고르기'), findsOneWidget);
    });

    testWidgets('icon 파라미터가 제공되면 아이콘이 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppButton.primary(
          label: '사진·영상 고르기',
          icon: Icons.image,
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('탭하면 onPressed 콜백이 호출된다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        AppButton.primary(label: '눌러봐', onPressed: () => tapped = true),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onPressed 가 null 이면 탭해도 콜백이 호출되지 않는다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        const AppButton.primary(label: '비활성', onPressed: null),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
      expect(find.text('비활성'), findsOneWidget);
    });
  });

  group('AppButton.outlined', () {
    testWidgets('라벨 텍스트가 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppButton.outlined(label: '비율 먼저 정하기', onPressed: () {}),
      );

      expect(find.text('비율 먼저 정하기'), findsOneWidget);
    });

    testWidgets('탭하면 onPressed 콜백이 호출된다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        AppButton.outlined(label: '다른 제안', onPressed: () => tapped = true),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onPressed 가 null 이면 탭해도 콜백이 호출되지 않는다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        const AppButton.outlined(label: '비활성', onPressed: null),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
    });
  });
}
