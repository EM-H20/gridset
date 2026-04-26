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
}
