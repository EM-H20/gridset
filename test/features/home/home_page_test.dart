// test/features/home/home_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/widgets/buttons/app_icon_button.dart';
import 'package:gridset/features/home/home_page.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  group('HomePage', () {
    testWidgets('상단에 Gridset 워드마크가 렌더링된다', (tester) async {
      await pumpPage(tester, const HomePage());

      // AppTopBar.title 의 'Gridset' (워드마크). 테스트 페이지 내 다른 곳에 'Gridset' 없으므로 1건.
      expect(find.text('Gridset'), findsOneWidget);
    });

    testWidgets('헤딩 "오늘은\\n뭐 모아볼까?" 가 렌더링된다', (tester) async {
      await pumpPage(tester, const HomePage());

      expect(find.text('오늘은\n뭐 모아볼까?'), findsOneWidget);
    });

    testWidgets('두 CTA 라벨이 렌더링된다', (tester) async {
      await pumpPage(tester, const HomePage());

      expect(find.text('사진·영상 고르기'), findsOneWidget);
      expect(find.text('비율 먼저 정하기'), findsOneWidget);
    });

    testWidgets('"사진·영상 고르기" 탭하면 SnackBar 가 표시된다', (tester) async {
      await pumpPage(tester, const HomePage());

      await tester.tap(find.text('사진·영상 고르기'));
      await tester.pump(); // SnackBar 등장 트리거

      expect(find.text('다음 화면 준비 중'), findsOneWidget);
    });

    testWidgets('"비율 먼저 정하기" 탭하면 SnackBar 가 표시된다', (tester) async {
      await pumpPage(tester, const HomePage());

      await tester.tap(find.text('비율 먼저 정하기'));
      await tester.pump();

      expect(find.text('다음 화면 준비 중'), findsOneWidget);
    });

    testWidgets('우상단에 디버그 진입용 AppIconButton 이 렌더링된다 (gps_fixed 아이콘)', (tester) async {
      await pumpPage(tester, const HomePage());

      // trailing 슬롯의 AppIconButton — 우상단
      expect(find.byType(AppIconButton), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    });
  });
}
