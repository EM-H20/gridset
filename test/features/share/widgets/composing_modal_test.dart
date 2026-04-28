import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/constants/app_colors.dart';
import 'package:gridset/features/share/widgets/composing_modal.dart';

void main() {
  testWidgets('ComposingModal — 진행 progress 표시 + cancel 콜백', (tester) async {
    var cancelled = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        child: MaterialApp(
          home: Scaffold(
            body: ComposingModal(
              progress: 0.5,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('영상 만드는 중...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);

    final progressBar =
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progressBar.value, 0.5);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
  });

  testWidgets('ComposingModal — Lovable cream 카드 (Material color)',
      (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        child: MaterialApp(
          home: Scaffold(
            body: ComposingModal(progress: 0.0, onCancel: () {}),
          ),
        ),
      ),
    );

    // 카드 root Material 색이 cream — Lovable Card §4 정합.
    // dim 배경은 호출자(showDialog barrierColor)가 담당하므로 위젯 자체는 검증 X.
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(ComposingModal),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, AppColors.cream);
  });
}
