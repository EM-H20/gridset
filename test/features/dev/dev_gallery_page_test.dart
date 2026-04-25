// test/features/dev/dev_gallery_page_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/widgets/buttons/app_button.dart';
import 'package:gridset/features/dev/dev_gallery_page.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  group('DevGalleryPage', () {
    testWidgets('"Components" 타이틀이 렌더링된다', (tester) async {
      await pumpPage(tester, const DevGalleryPage());

      expect(find.text('Components'), findsOneWidget);
    });

    testWidgets('5개 GallerySection 의 제목이 모두 렌더링된다', (tester) async {
      await pumpPage(tester, const DevGalleryPage());

      // ListView 가 lazy 라 처음엔 첫 섹션만 보일 수 있어 스크롤 필요할 수 있음.
      // 모든 섹션 제목을 찾기 위해 마지막 섹션이 보일 때까지 스크롤.
      expect(find.text('AppButton'), findsOneWidget);
      // 나머지는 보이지 않아도 위젯 트리에는 존재할 수 있음 — pump 로 lazy build 강제
      await tester.pump();

      expect(find.text('AppButton'), findsOneWidget);
      // AppIconButton, AppTopBar, Colors, Typography 는 스크롤 후 검증
      await tester.scrollUntilVisible(
        find.text('Typography (AppTextStyles)'),
        300,
      );

      expect(find.text('AppIconButton'), findsOneWidget);
      expect(find.text('AppTopBar'), findsOneWidget);
      expect(find.text('Colors (AppColors)'), findsOneWidget);
      expect(find.text('Typography (AppTextStyles)'), findsOneWidget);
    });

    testWidgets('AppButton 섹션에 다수 AppButton 인스턴스가 존재한다 (변형 시각 검증)', (tester) async {
      await pumpPage(tester, const DevGalleryPage());

      // 갤러리는 첫 섹션이 ListView 첫 항목으로 자동 표시.
      // AppButton 섹션에 정확한 인스턴스 수는 구현 디테일이라 강하게 묶지 않고,
      // 최소 5개 이상 존재함을 sanity-check.
      expect(find.byType(AppButton), findsAtLeastNWidgets(5));
    });
  });
}
