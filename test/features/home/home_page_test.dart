// test/features/home/home_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gridset/cores/widgets/buttons/app_icon_button.dart';
import 'package:gridset/features/home/home_page.dart';

const _kDesignSize = Size(393, 852);

void _useDesignViewport(WidgetTester tester) {
  tester.view.physicalSize = _kDesignSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _harness(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/photo-picker',
        builder: (context, state) => const Scaffold(body: Text('photo-picker-stub')),
      ),
      GoRoute(
        path: '/canvas-picker',
        builder: (context, state) => const Scaffold(body: Text('canvas-picker-stub')),
      ),
    ],
  );

  return ProviderScope(
    child: ScreenUtilInit(
      designSize: _kDesignSize,
      minTextAdapt: true,
      builder: (context, _) => MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  group('HomePage', () {
    testWidgets('상단에 Gridset 워드마크 SVG 가 렌더링된다', (tester) async {
      _useDesignViewport(tester);
      await tester.pumpWidget(_harness(const HomePage()));

      // AppBar 제거 후 _HomeHeader 안 SvgPicture 로 워드마크 표시.
      expect(find.byType(SvgPicture), findsOneWidget);
      // semanticsLabel 로 'Gridset' 노출 (스크린리더 접근성)
      expect(find.bySemanticsLabel('Gridset'), findsOneWidget);
    });

    testWidgets('헤딩 "오늘은\\n뭐 모아볼까?" 가 렌더링된다', (tester) async {
      _useDesignViewport(tester);
      await tester.pumpWidget(_harness(const HomePage()));

      expect(find.text('오늘은\n뭐 모아볼까?'), findsOneWidget);
    });

    testWidgets('두 CTA 라벨이 렌더링된다', (tester) async {
      _useDesignViewport(tester);
      await tester.pumpWidget(_harness(const HomePage()));

      expect(find.text('사진·영상 고르기'), findsOneWidget);
      expect(find.text('비율 먼저 정하기'), findsOneWidget);
    });

    testWidgets('우상단에 디버그 진입용 AppIconButton 이 렌더링된다 (gps_fixed 아이콘)', (tester) async {
      _useDesignViewport(tester);
      await tester.pumpWidget(_harness(const HomePage()));

      // trailing 슬롯의 AppIconButton — 우상단
      expect(find.byType(AppIconButton), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    });
  });
}
