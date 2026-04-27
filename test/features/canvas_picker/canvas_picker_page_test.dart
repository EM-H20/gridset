import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/canvas_picker/canvas_picker_page.dart';
import 'package:gridset/flow/flow_selection_provider.dart';

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
        builder: (context, state) =>
            const Scaffold(body: Text('photo-stub')),
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
  testWidgets('chip 선택 → "다음" 활성 → push', (tester) async {
    _useDesignViewport(tester);
    await tester.pumpWidget(_harness(const CanvasPickerPage()));
    await tester.pumpAndSettle();

    // 9:16 chip 탭
    await tester.tap(find.text('9:16'));
    await tester.pumpAndSettle();

    // "다음" 탭
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // photo-picker stub 화면으로 이동
    expect(find.text('photo-stub'), findsOneWidget);
  });

  testWidgets(
      'chip 만 탭한 상태 — flowSelectionProvider canvas 미반영 (다음 누름 전)',
      (tester) async {
    _useDesignViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: _kDesignSize,
          minTextAdapt: true,
          builder: (context, _) =>
              MaterialApp(home: const CanvasPickerPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 4:5 chip 탭
    await tester.tap(find.text('4:5'));
    await tester.pumpAndSettle();

    // setCanvas 는 "다음" 탭 시점이므로 chip 만 탭한 상태에선 미반영.
    expect(
      container.read(flowSelectionNotifierProvider).canvas,
      const CanvasRatio.portrait916(), // 디폴트
    );
  });

  // 회귀 — chip 선택값이 setCanvas 까지 정확히 흘러야 한다. 시뮬레이터에서
  // "어떤 비율을 골라도 같은 모양" 으로 보이는 인상이 보고된 적 있어 가드.
  for (final entry in const {
    '1:1': CanvasRatio.square(),
    '4:5': CanvasRatio.portrait45(),
    '16:9': CanvasRatio.landscape169(),
    '9:16': CanvasRatio.portrait916(),
  }.entries) {
    testWidgets(
      '${entry.key} chip 선택 → 다음 → flow.canvas == ${entry.value.value}',
      (tester) async {
        _useDesignViewport(tester);
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const CanvasPickerPage(),
            ),
            GoRoute(
              path: '/photo-picker',
              builder: (context, state) =>
                  const Scaffold(body: Text('photo-stub')),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: ScreenUtilInit(
              designSize: _kDesignSize,
              minTextAdapt: true,
              builder: (context, _) =>
                  MaterialApp.router(routerConfig: router),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();

        expect(
          container.read(flowSelectionNotifierProvider).canvas,
          entry.value,
          reason:
              '${entry.key} chip 을 선택하고 "다음" 누르면 flow.canvas 가 그 값이어야 함',
        );
      },
    );
  }
}
