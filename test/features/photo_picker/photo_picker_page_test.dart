import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/cores/widgets/buttons/app_button.dart';
import 'package:gridset/features/photo_picker/asset_to_media_item.dart';
import 'package:gridset/features/photo_picker/photo_picker_page.dart';
import 'package:gridset/features/photo_picker/providers/permission_provider.dart';
import 'package:gridset/features/suggestion/providers/selected_assets_provider.dart';
import 'package:gridset/flow/flow_selection_provider.dart';
import 'package:photo_manager/photo_manager.dart';

Widget _harness(Widget child, {required AppPermissionState perm}) {
  return ProviderScope(
    overrides: [
      photoPermissionProvider.overrideWith((ref) async => perm),
    ],
    child: ScreenUtilInit(
      designSize: const Size(393, 852),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [GoRoute(path: '/', builder: (_, _) => child)],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('denied — DeniedView 표시', (tester) async {
    await tester.pumpWidget(
        _harness(const PhotoPickerPage(), perm: AppPermissionState.denied));
    await tester.pumpAndSettle();

    expect(find.text('갤러리 접근이 막혀있어요'), findsOneWidget);
    expect(find.text('설정 열기'), findsOneWidget);
  });

  testWidgets('restricted — DeniedView "설정 열기" disabled', (tester) async {
    await tester.pumpWidget(_harness(const PhotoPickerPage(),
        perm: AppPermissionState.restricted));
    await tester.pumpAndSettle();

    expect(find.text('갤러리 접근이 막혀있어요'), findsOneWidget);
    expect(find.text('시스템 정책으로 접근이 제한되어 있어요'), findsOneWidget);

    // 시스템 정책 차단 — "설정 열기" 버튼은 onPressed null 로 disabled.
    final settingsBtn = tester.widget<AppButton>(
      find.ancestor(
        of: find.text('설정 열기'),
        matching: find.byType(AppButton),
      ),
    );
    expect(settingsBtn.onPressed, isNull,
        reason: 'restricted 면 부모 통제 등 시스템 정책으로 설정 진입 불가');
  });

  testWidgets('limited — LimitedInfoBar 노출', (tester) async {
    await tester.pumpWidget(
        _harness(const PhotoPickerPage(), perm: AppPermissionState.limited));
    await tester.pumpAndSettle();

    expect(find.text('선택한 사진만 보여요. 더 보려면'), findsOneWidget);
  });

  testWidgets('authorized + 0 선택 → "다음" 비활성 + 안내 노출', (tester) async {
    await tester.pumpWidget(_harness(const PhotoPickerPage(),
        perm: AppPermissionState.authorized));
    await tester.pumpAndSettle();

    expect(find.text('2장 이상 골라주세요'), findsOneWidget);

    // 0 selection 이면 "다음" 버튼은 onPressed null 로 disabled.
    final nextBtn = tester.widget<AppButton>(
      find.ancestor(
        of: find.text('다음'),
        matching: find.byType(AppButton),
      ),
    );
    expect(nextBtn.onPressed, isNull,
        reason: '2장 미만 선택 시 다음 버튼 비활성');
  });

  // _onNext 자체는 위젯 내부 private 메서드라 직접 호출 불가.
  // 두 setter 가 묶여 있어야 함을 contract-level 로 가드한다.
  // (회귀 시 Task 5 의 mapped_thumb_test 가 실패해 영향 검증.)
  test('flow.media + selectedAssets — 같은 source 로 함께 채워짐 (페어 contract)',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final assets = [
      AssetEntity(id: 'p1', typeInt: 1, width: 100, height: 100),
      AssetEntity(id: 'p2', typeInt: 1, width: 100, height: 100),
    ];

    final items = assets
        .map(assetToMediaItem)
        .whereType<MediaItem>()
        .toList(growable: false);

    container.read(flowSelectionNotifierProvider.notifier).setMedia(items);
    container
        .read(selectedAssetsNotifierProvider.notifier)
        .setAssets(assets);

    expect(
      container
          .read(flowSelectionNotifierProvider)
          .media
          .map((m) => m.id)
          .toList(),
      ['p1', 'p2'],
    );
    expect(
      container.read(selectedAssetsNotifierProvider).keys.toList(),
      ['p1', 'p2'],
    );
  });
}
