// test/test_helpers/widget_test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// 디자인 캔버스 크기 — `AppSpacing` / `AppTextStyles` 가 이 기준으로 `.w`/`.h`/`.sp` 적용.
const Size kDesignSize = Size(393, 852);

/// 테스트 뷰포트를 디자인 캔버스(393×852) 로 강제 설정.
///
/// 기본 뷰포트(600×800) 와 디자인 크기 불일치 시 `.w`/`.h` 스케일이 1.0 이 아니게 되어
/// 컴포넌트가 과도하게 커지거나 작아져 layout overflow / 검증 오류 발생.
/// 모든 위젯 테스트는 이 함수가 끝난 후 build 해야 한다.
void _useDesignViewport(WidgetTester tester) {
  tester.view.physicalSize = kDesignSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 단일 위젯 테스트용 래퍼 — Center 안에 child 를 두는 Scaffold 로 감쌈.
///
/// `AppColors` / `AppTextStyles` / `AppSpacing` 모두 ScreenUtil 에 의존하므로
/// init 과 viewport 강제 설정 둘 다 필요.
Future<void> pumpWithScreenUtil(WidgetTester tester, Widget child) async {
  _useDesignViewport(tester);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: kDesignSize,
      minTextAdapt: true,
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
  _useDesignViewport(tester);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: kDesignSize,
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(home: page),
    ),
  );
  await tester.pump();
}
