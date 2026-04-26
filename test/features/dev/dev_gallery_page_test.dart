// test/features/dev/dev_gallery_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gridset/cores/widgets/buttons/app_button.dart';
import 'package:gridset/features/dev/dev_gallery_page.dart';
import 'package:gridset/features/dev/widgets/grid_template_preview.dart';
import 'package:gridset/routers/route_paths.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  group('DevGalleryPage', () {
    testWidgets('"Components" 타이틀이 렌더링된다', (tester) async {
      await pumpPage(tester, const DevGalleryPage());

      expect(find.text('Components'), findsOneWidget);
    });

    testWidgets('5개 GallerySection 의 제목이 모두 렌더링된다', (tester) async {
      await pumpPage(tester, const DevGalleryPage());

      expect(find.text('AppButton'), findsOneWidget);
      // 마지막 섹션까지 스크롤하여 lazy build 강제
      await tester.scrollUntilVisible(
        find.text('Grid Templates'),
        300,
      );

      expect(find.text('AppIconButton'), findsOneWidget);
      expect(find.text('Colors (AppColors)'), findsOneWidget);
      expect(find.text('Typography (AppTextStyles)'), findsOneWidget);
      expect(find.text('Grid Templates'), findsOneWidget);
    });

    testWidgets('AppButton 섹션에 다수 AppButton 인스턴스가 존재한다 (변형 시각 검증)', (tester) async {
      await pumpPage(tester, const DevGalleryPage());

      // 갤러리는 첫 섹션이 ListView 첫 항목으로 자동 표시.
      // AppButton 섹션에 정확한 인스턴스 수는 구현 디테일이라 강하게 묶지 않고,
      // 최소 5개 이상 존재함을 sanity-check.
      expect(find.byType(AppButton), findsAtLeastNWidgets(5));
    });

    group('Grid Templates 섹션', () {
      testWidgets('N=2..9 의 모든 템플릿(31개)이 카드로 렌더된다', (tester) async {
        await pumpPage(tester, const DevGalleryPage());

        // 마지막 섹션까지 스크롤하여 lazy build 강제
        await tester.scrollUntilVisible(
          find.text('Grid Templates'),
          300,
        );

        // GridTemplatePreview 인스턴스가 31개 (kGridTemplates 합계) — sweep 회귀 안전망
        expect(find.byType(GridTemplatePreview), findsNWidgets(31));
      });

      testWidgets('비율 chip 4개가 모두 노출된다 (9:16 / 1:1 / 4:5 / 16:9)', (tester) async {
        await pumpPage(tester, const DevGalleryPage());
        await tester.scrollUntilVisible(find.text('Grid Templates'), 300);

        expect(find.text('9:16'), findsOneWidget);
        expect(find.text('1:1'), findsOneWidget);
        expect(find.text('4:5'), findsOneWidget);
        expect(find.text('16:9'), findsOneWidget);
      });
    });

    testWidgets('back 탭 시 /home 으로 이동한다', (tester) async {
      // 실제 GoRouter 셋업 — DevGalleryPage 의 onBack 이 context.go(RoutePaths.home) 를
      // 호출하므로 양쪽 라우트가 모두 등록되어야 한다.
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: RoutePaths.dev,
        routes: [
          GoRoute(
            path: RoutePaths.dev,
            builder: (context, state) => const DevGalleryPage(),
          ),
          GoRoute(
            path: RoutePaths.home,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('home-placeholder')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // /dev 페이지에서 시작
      expect(find.text('Components'), findsOneWidget);

      // back 아이콘 탭 (AppBar leading 의 AppIconButton, semanticLabel '뒤로 가기')
      await tester.tap(find.bySemanticsLabel('뒤로 가기'));
      await tester.pumpAndSettle();

      // /home 으로 이동
      expect(router.routerDelegate.currentConfiguration.uri.path, RoutePaths.home);
      expect(find.text('home-placeholder'), findsOneWidget);
    });
  });
}
