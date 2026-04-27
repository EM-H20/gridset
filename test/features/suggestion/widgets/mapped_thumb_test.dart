import 'dart:typed_data';

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/constants/app_colors.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/suggestion/providers/thumbnail_loader.dart';
import 'package:gridset/features/suggestion/widgets/suggestion_card.dart';
import 'package:photo_manager/photo_manager.dart';

class _FakeLoader implements ThumbnailLoader {
  _FakeLoader({this.bytesById = const {}, this.failIds = const {}});
  final Map<String, Uint8List> bytesById;
  final Set<String> failIds;
  int callCount = 0;

  @override
  Future<Uint8List?> load(AssetEntity asset,
      {required ThumbnailSize size}) async {
    callCount += 1;
    if (failIds.contains(asset.id)) return null;
    return bytesById[asset.id];
  }
}

// 1×1 transparent PNG — 위젯이 Image.memory 로 렌더할 수 있는 가장 작은 byte.
final Uint8List _kTinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

AssetEntity _photo(String id) =>
    AssetEntity(id: id, typeInt: 1, width: 100, height: 100);
AssetEntity _video(String id) =>
    AssetEntity(id: id, typeInt: 2, width: 100, height: 100);

Widget _harness({
  required Widget child,
  required _FakeLoader loader,
}) {
  return ProviderScope(
    overrides: [thumbnailLoaderProvider.overrideWith((_) => loader)],
    child: ScreenUtilInit(
      designSize: const Size(393, 852),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

GridSuggestion _twoCellSuggestion({
  String idA = 'a',
  String idB = 'b',
}) =>
    GridSuggestion(
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      ),
      mediaByCellId: {0: idA, 1: idB},
      loss: 0.0,
      templateName: 'test_2',
    );

void main() {
  testWidgets('(a) 정상 매핑 → Image 노드, fit cover', (tester) async {
    final loader = _FakeLoader(bytesById: {'a': _kTinyPng, 'b': _kTinyPng});
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();

    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, hasLength(2), reason: '두 leaf → 두 Image');
    for (final img in images) {
      expect(img.fit, BoxFit.cover);
      expect(img.gaplessPlayback, isTrue);
    }
  });

  testWidgets('(b) assetsById 누락 → placeholder 톤', (tester) async {
    final loader = _FakeLoader();
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: const {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    final placeholders = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(SuggestionCard),
            matching: find.byType(Container),
          ),
        )
        .where((c) {
      final dec = c.decoration;
      return dec is BoxDecoration && dec.color == AppColors.lightCream;
    });
    expect(placeholders, hasLength(2));
    expect(loader.callCount, 0, reason: 'asset 없으면 loader 호출 X');
  });

  testWidgets('(c) loader 가 null → placeholder', (tester) async {
    final loader = _FakeLoader(failIds: {'a', 'b'});
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(loader.callCount, 2);
  });

  testWidgets('(d) 영상 자산 → ▶ icon overlay', (tester) async {
    final loader = _FakeLoader(bytesById: {'v': _kTinyPng});
    final suggestion = GridSuggestion(
      tree: const Leaf(0),
      mediaByCellId: const {0: 'v'},
      loss: 0.0,
      templateName: 'test_1',
    );
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: suggestion,
        canvas: const CanvasRatio.square(),
        assetsById: {'v': _video('v')},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    // SvgPicture.asset 으로 그려진 ▶ icon — asset path 가 'icon_play' 포함되는지로 식별.
    expect(
      find.byWidgetPredicate((w) =>
          w is SvgPicture && w.bytesLoader.toString().contains('icon_play')),
      findsOneWidget,
      reason: '영상 셀은 ▶ overlay 가 깔림',
    );
  });

  testWidgets(
      '(e) rebuild 후에도 동일 (cellId, asset) 에 대한 callCount == 1',
      (tester) async {
    final loader = _FakeLoader(bytesById: {'a': _kTinyPng, 'b': _kTinyPng});
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();
    final initial = loader.callCount;
    expect(initial, 2, reason: '셀 2개 × 1회');

    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();

    expect(loader.callCount, initial,
        reason: '동일 (cellId, asset) → didUpdateWidget 비교 후 재호출 X');
  });

  testWidgets('(f) asset 변경 시 callCount 증가', (tester) async {
    final loader = _FakeLoader(
      bytesById: {'a': _kTinyPng, 'b': _kTinyPng, 'a2': _kTinyPng},
    );
    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(idA: 'a'),
        canvas: const CanvasRatio.square(),
        assetsById: {'a': _photo('a'), 'b': _photo('b')},
      ),
    ));
    await tester.pumpAndSettle();
    final before = loader.callCount;

    await tester.pumpWidget(_harness(
      loader: loader,
      child: SuggestionCard(
        suggestion: _twoCellSuggestion(idA: 'a2'),
        canvas: const CanvasRatio.square(),
        assetsById: {
          'a': _photo('a'),
          'a2': _photo('a2'),
          'b': _photo('b'),
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(loader.callCount, greaterThan(before),
        reason: 'cell 0 의 asset 이 바뀌었으므로 재로드 1회 발생');
  });
}
