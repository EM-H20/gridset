// integration_test/flow_test.dart
//
// 흐름 통합 테스트: 비율 먼저 정하기 → canvas-picker → photo-picker 라우팅 검증.
//
// NOTE: Firebase/dotenv 초기화가 호스트 테스트 러너에서 동작하지 않으므로
// GridsetApp 전체를 기동하지 않고 appRouter + ScreenUtilInit 기반
// 경량 하네스를 사용한다 (기존 canvas_picker_page_test 패턴 참조).
// 실 디바이스/시뮬레이터 없이도 host-mode 에서 실행 가능한 범위까지만 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/canvas_picker/canvas_picker_page.dart';
import 'package:gridset/features/photo_picker/providers/permission_provider.dart';
import 'package:gridset/features/photo_picker/photo_picker_page.dart';
import 'package:gridset/flow/flow_selection_provider.dart';
import 'package:integration_test/integration_test.dart';

const _kDesignSize = Size(393, 852);

/// 테스트용 GoRouter 기반 하네스 팩토리.
///
/// canvas-picker 에서 시작해 photo-picker 스텁까지 이동 가능한 최소 라우터.
/// [container] 를 외부에서 주입하면 상태 검사에 활용할 수 있다.
Widget _buildHarness({
  ProviderContainer? container,
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    initialLocation: '/canvas-picker',
    routes: [
      GoRoute(
        path: '/canvas-picker',
        builder: (_, _) => const CanvasPickerPage(),
      ),
      GoRoute(
        path: '/photo-picker',
        builder: (_, _) => const PhotoPickerPage(),
      ),
      GoRoute(
        path: '/suggestion',
        builder: (_, _) => const Scaffold(body: Text('suggestion-stub')),
      ),
    ],
  );

  final scope = container != null
      ? UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: _kDesignSize,
            minTextAdapt: true,
            builder: (_, _) => MaterialApp.router(
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            ),
          ),
        )
      : ProviderScope(
          overrides: overrides,
          child: ScreenUtilInit(
            designSize: _kDesignSize,
            minTextAdapt: true,
            builder: (_, _) => MaterialApp.router(
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            ),
          ),
        );

  return scope;
}

void _useDesignViewport(WidgetTester tester) {
  tester.view.physicalSize = _kDesignSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── 흐름 1: 비율 먼저 정하기 → photo-picker 진입 ─────────────────────────────
  testWidgets(
    '비율 먼저 흐름: canvas-picker 에서 4:5 선택 → 다음 → photo-picker 진입',
    (tester) async {
      _useDesignViewport(tester);

      await tester.pumpWidget(
        _buildHarness(
          overrides: [
            // photo-picker 진입 시 권한 요청 platform call 을 차단하기 위해 override.
            photoPermissionProvider
                .overrideWith((ref) async => AppPermissionState.authorized),
          ],
        ),
      );
      await tester.pump(); // 첫 프레임
      await tester.pump(const Duration(milliseconds: 100)); // 라우터 settle

      // canvas-picker 화면 확인
      expect(find.text('캔버스 비율'), findsOneWidget);

      // 4:5 chip 탭
      await tester.tap(find.text('4:5'));
      await tester.pump();

      // "다음" 버튼 탭
      await tester.tap(find.text('다음'));
      await tester.pump(const Duration(milliseconds: 200));

      // photo-picker 화면 AppBar 제목 확인 ('사진 고르기 0/9' 형태)
      expect(find.textContaining('사진 고르기'), findsOneWidget);
    },
  );

  // ── 흐름 2: canvas-picker 다음 → flowSelectionNotifier.canvas 업데이트 ────────
  testWidgets(
    '비율 먼저 흐름: canvas-picker 다음 누름 시 flowSelectionNotifier.canvas 업데이트',
    (tester) async {
      _useDesignViewport(tester);

      final container = ProviderContainer(
        overrides: [
          // photo-picker 로 push 된 후 permission call 막기.
          photoPermissionProvider
              .overrideWith((ref) async => AppPermissionState.authorized),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildHarness(container: container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // autoDispose provider 를 활성 상태로 유지하기 위해 listener 등록.
      // keepAlive: false 이므로 subscriber 없으면 dispose 되어 read 시 초기값 반환.
      final subscription = container.listen(
        flowSelectionNotifierProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      // canvas-picker 초기 상태: 기본값 9:16
      expect(
        container.read(flowSelectionNotifierProvider).canvas,
        const CanvasRatio.portrait916(),
      );

      // 4:5 chip 탭 — 아직 다음 미클릭, canvas 여전히 기본값
      await tester.tap(find.text('4:5'));
      await tester.pump();
      expect(
        container.read(flowSelectionNotifierProvider).canvas,
        const CanvasRatio.portrait916(),
      );

      // "다음" 탭 → setCanvas 호출 → canvas 가 4:5 로 변경
      await tester.tap(find.text('다음'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        container.read(flowSelectionNotifierProvider).canvas,
        const CanvasRatio.portrait45(),
      );
    },
  );

  // ── 흐름 3: flowSelectionNotifier.setMedia smoke ──────────────────────────
  testWidgets(
    'flowSelectionNotifier.setMedia — seed 주입 후 media 상태 반영 및 FlowSelection 불변성',
    (tester) async {
      const seed = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
        MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // media 주입
      container.read(flowSelectionNotifierProvider.notifier).setMedia(seed);

      final state = container.read(flowSelectionNotifierProvider);
      expect(state.media, seed);
      expect(state.media.length, 3);

      // FlowSelection 은 immutable copyWith — 원본 변경 없이 새 객체 반환.
      final updated = state.copyWith(canvas: const CanvasRatio.square());
      expect(updated.media, seed); // media 유지
      expect(updated.canvas, const CanvasRatio.square());
      expect(state.canvas, const CanvasRatio.portrait916()); // 원본 불변
    },
  );
}
