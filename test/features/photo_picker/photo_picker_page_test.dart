import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gridset/features/photo_picker/photo_picker_page.dart';
import 'package:gridset/features/photo_picker/providers/permission_provider.dart';

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
          routes: [GoRoute(path: '/', builder: (_, __) => child)],
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
  });
}
