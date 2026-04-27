import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/suggestion/suggestion_page.dart';
import 'package:gridset/flow/flow_selection_provider.dart';

void main() {
  testWidgets('media 비어있음 → empty 안내', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        child: const MaterialApp(home: SuggestionPage()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('먼저 사진을 2장 이상 골라주세요'), findsOneWidget);
  });

  testWidgets('media >= 2 → "N개 후보" 표시', (tester) async {
    const media = [
      MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
      MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
      MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
    ];

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(flowSelectionNotifierProvider.notifier).setMedia(media);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        child: const MaterialApp(home: SuggestionPage()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('개 후보'), findsOneWidget);
    expect(find.text('이걸로'), findsOneWidget);
    expect(find.text('다른 제안'), findsOneWidget);
    expect(find.text('빈 캔버스'), findsOneWidget);
  });

  // 회귀 방지 — spec(2026-04-27) §4-3-2 "PageView + Edge peek (인스타 캐러셀 식)":
  // viewportFraction 0.92 + 가로 풀브리드 (외곽 horizontal padding 0).
  testWidgets(
    'PageView 가 viewportFraction 0.92 + 가로 풀브리드 (헤더/CTA 만 base padding)',
    (tester) async {
      const media = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1.5),
        MediaItem(id: 'c', type: MediaType.photo, aspectRatio: 0.7),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(flowSelectionNotifierProvider.notifier).setMedia(media);

      const screenSize = Size(393, 852);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: screenSize,
          child: const MaterialApp(home: SuggestionPage()),
        ),
      ));
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.viewportFraction, 0.92,
          reason: '인스타 캐러셀 식 viewportFraction');

      // PageView 좌우가 화면 가장자리(0, 393)에 닿는지 확인 — 풀브리드.
      final pageViewRect = tester.getRect(find.byType(PageView));
      expect(pageViewRect.left, 0.0, reason: '좌측 풀브리드');
      expect(pageViewRect.right, screenSize.width, reason: '우측 풀브리드');
    },
  );
}
