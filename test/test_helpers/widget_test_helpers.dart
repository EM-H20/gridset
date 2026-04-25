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

/// 전체 페이지(Scaffold 포함) 위젯 테스트용 래퍼.
///
/// `pumpWithScreenUtil` 은 Scaffold(body: Center(child: ...)) 로 감싸서
/// Scaffold 가 자체 포함된 페이지를 펌프할 때 중첩 Scaffold 가 됨.
/// 이 헬퍼는 child 를 그대로 MaterialApp.home 에 두어 페이지가 자기 Scaffold 를 가진 상황에 적합.
Future<void> pumpPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp(home: page),
    ),
  );
  await tester.pump();
}
