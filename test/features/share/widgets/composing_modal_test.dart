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

  testWidgets('ComposingModal — 배경 charcoal82', (tester) async {
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

    final coloredBox = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(ComposingModal),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(coloredBox.color, AppColors.charcoal82);
  });
}
