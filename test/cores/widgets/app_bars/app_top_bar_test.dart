// test/cores/widgets/app_bars/app_top_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/widgets/app_bars/app_top_bar.dart';
import 'package:gridset/cores/widgets/buttons/app_icon_button.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  group('AppTopBar.title', () {
    testWidgets('타이틀이 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        const AppTopBar.title(title: 'Gridset'),
      );

      expect(find.text('Gridset'), findsOneWidget);
    });

    testWidgets('trailing 이 제공되면 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppTopBar.title(
          title: 'Gridset',
          trailing: AppIconButton(
            icon: Icons.center_focus_strong,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(AppIconButton), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
    });
  });

  group('AppTopBar.backWithMore', () {
    testWidgets('타이틀이 중앙에 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppTopBar.backWithMore(
          title: '제안 1/3',
          onBack: () {},
          onMore: () {},
        ),
      );

      expect(find.text('제안 1/3'), findsOneWidget);
    });

    testWidgets('back 탭 시 onBack 콜백이 호출된다', (tester) async {
      var backed = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.backWithMore(
          title: '제안 1/3',
          onBack: () => backed = true,
          onMore: () {},
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      expect(backed, isTrue);
    });

    testWidgets('more 탭 시 onMore 콜백이 호출된다', (tester) async {
      var mored = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.backWithMore(
          title: '제안 1/3',
          onBack: () {},
          onMore: () => mored = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pump();

      expect(mored, isTrue);
    });
  });

  group('AppTopBar.closeWithSave', () {
    testWidgets('타이틀, 닫기, 저장 모두 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppTopBar.closeWithSave(
          title: 'Gridset',
          onClose: () {},
          onSave: () {},
        ),
      );

      expect(find.text('Gridset'), findsOneWidget);
      expect(find.text('닫기'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('닫기 탭 시 onClose 콜백이 호출된다', (tester) async {
      var closed = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.closeWithSave(
          title: 'Gridset',
          onClose: () => closed = true,
          onSave: () {},
        ),
      );

      await tester.tap(find.text('닫기'));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('저장 탭 시 onSave 콜백이 호출된다', (tester) async {
      var saved = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.closeWithSave(
          title: 'Gridset',
          onClose: () {},
          onSave: () => saved = true,
        ),
      );

      await tester.tap(find.text('저장'));
      await tester.pump();

      expect(saved, isTrue);
    });

    testWidgets('onSave 가 null 이면 저장 탭해도 콜백이 호출되지 않는다', (tester) async {
      var saved = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.closeWithSave(
          title: 'Gridset',
          onClose: () {},
          onSave: null,
        ),
      );

      await tester.tap(find.text('저장'), warnIfMissed: false);
      await tester.pump();

      expect(saved, isFalse);
    });
  });
}
