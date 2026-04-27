// test/features/home/home_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/cores/widgets/buttons/app_icon_button.dart';
import 'package:gridset/features/home/home_page.dart';
import 'package:gridset/features/suggestion/providers/selected_assets_provider.dart';
import 'package:gridset/flow/flow_selection_provider.dart';
import 'package:photo_manager/photo_manager.dart';

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

    // 회귀 — flow.media + selectedAssets 가 keepAlive 라 home CTA 진입 시
    // 둘 다 명시적 reset 필요. 한 쪽만 비우면 다음 흐름에서 잔재 lookup 발생.
    testWidgets('CTA "사진·영상 고르기" 진입 시 flow.media + selectedAssets 둘 다 reset',
        (tester) async {
      _useDesignViewport(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 이전 흐름 상태 가짜로 채워놓기.
      container
          .read(flowSelectionNotifierProvider.notifier)
          .setMedia(const [
        MediaItem(id: 'old', type: MediaType.photo, aspectRatio: 1.0),
      ]);
      container
          .read(selectedAssetsNotifierProvider.notifier)
          .setAssets([
        AssetEntity(id: 'old', typeInt: 1, width: 100, height: 100),
      ]);

      final router = GoRouter(initialLocation: '/', routes: [
        GoRoute(path: '/', builder: (_, _) => const HomePage()),
        GoRoute(
            path: '/photo-picker',
            builder: (_, _) => const Scaffold(body: Text('photo-picker-stub'))),
        GoRoute(
            path: '/canvas-picker',
            builder: (_, _) =>
                const Scaffold(body: Text('canvas-picker-stub'))),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: _kDesignSize,
          minTextAdapt: true,
          builder: (context, _) => MaterialApp.router(routerConfig: router),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('사진·영상 고르기'));
      await tester.pumpAndSettle();

      expect(container.read(flowSelectionNotifierProvider).media, isEmpty);
      expect(container.read(selectedAssetsNotifierProvider), isEmpty,
          reason: 'keepAlive 라 명시 reset 안 하면 잔재 lookup');
    });

    testWidgets('CTA "비율 먼저 정하기" 진입 시 flow.media + selectedAssets 둘 다 reset',
        (tester) async {
      _useDesignViewport(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(flowSelectionNotifierProvider.notifier)
          .setMedia(const [
        MediaItem(id: 'old', type: MediaType.photo, aspectRatio: 1.0),
      ]);
      container
          .read(selectedAssetsNotifierProvider.notifier)
          .setAssets([
        AssetEntity(id: 'old', typeInt: 1, width: 100, height: 100),
      ]);

      final router = GoRouter(initialLocation: '/', routes: [
        GoRoute(path: '/', builder: (_, _) => const HomePage()),
        GoRoute(
            path: '/photo-picker',
            builder: (_, _) => const Scaffold(body: Text('photo-picker-stub'))),
        GoRoute(
            path: '/canvas-picker',
            builder: (_, _) =>
                const Scaffold(body: Text('canvas-picker-stub'))),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: _kDesignSize,
          minTextAdapt: true,
          builder: (context, _) => MaterialApp.router(routerConfig: router),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('비율 먼저 정하기'));
      await tester.pumpAndSettle();

      expect(container.read(flowSelectionNotifierProvider).media, isEmpty);
      expect(container.read(selectedAssetsNotifierProvider), isEmpty);
    });
  });
}
