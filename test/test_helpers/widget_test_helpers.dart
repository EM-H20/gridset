// test/test_helpers/widget_test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// 위젯 테스트용 ScreenUtilInit + MaterialApp + Scaffold 래퍼.
///
/// AppColors / AppTextStyles 가 .sp/.w/.h 에 의존하므로
/// init 없이 위젯을 펌프하면 사이즈가 모두 0 으로 잡혀 테스트가 의미 없어진다.
Future<void> pumpWithScreenUtil(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  // ScreenUtilInit 은 첫 build 후 한 프레임 더 필요할 수 있음
  await tester.pump();
}
