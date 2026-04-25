# Core UI Primitives v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 3 core reusable widgets (`AppButton`, `AppIconButton`, `AppTopBar`) with TDD coverage, ready to power 홈/제안/에디터 화면 구현.

**Architecture:**
- `AppButton` 와 `AppIconButton` 는 pressed-opacity 피드백을 위해 `StatefulWidget`. `AppTopBar` 는 `StatelessWidget` + `PreferredSizeWidget`.
- 모든 색/타이포/간격은 `AppColors`, `AppTextStyles`, `AppSpacing` 상수 경유. raw 값 금지.
- Pressed 상태 처리: `GestureDetector` + `AnimatedOpacity` (Design.md "Active: opacity 0.8" 충실 재현). Material `InkWell` ripple 사용 안 함.
- 이모지 정책: UI 텍스트에 이모지 0건. 모든 시각 기호는 `IconData`.

**Tech Stack:** Flutter 3.x, `flutter_screenutil` (393×852 design size), `flutter_test`, Material `Icons.*`.

**Spec reference:** `docs/superpowers/specs/2026-04-25-core-ui-primitives-design.md`

---

## File Structure

**Lib (생성):**
- `lib/cores/widgets/buttons/app_button.dart` — AppButton.primary / .outlined
- `lib/cores/widgets/buttons/app_icon_button.dart` — AppIconButton 단일 variant
- `lib/cores/widgets/app_bars/app_top_bar.dart` — AppTopBar.title / .backWithMore / .closeWithSave

**Test (생성):**
- `test/test_helpers/widget_test_helpers.dart` — `pumpWithScreenUtil` 헬퍼
- `test/cores/widgets/buttons/app_button_test.dart`
- `test/cores/widgets/buttons/app_icon_button_test.dart`
- `test/cores/widgets/app_bars/app_top_bar_test.dart`

각 파일은 1 위젯 책임 — 폴더 카테고리 분리(buttons / app_bars)가 namespace 역할.

---

## Task 1: 위젯 테스트 헬퍼 추가

**Files:**
- Create: `test/test_helpers/widget_test_helpers.dart`

위젯 코드가 `flutter_screenutil` 의 `.sp/.w/.h` 에 의존하므로, 테스트마다 `ScreenUtilInit` 으로 감싸야 한다. 헬퍼로 보일러플레이트 제거.

- [ ] **Step 1: 헬퍼 파일 생성**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add test/test_helpers/widget_test_helpers.dart
git commit -m "test : 위젯 테스트용 ScreenUtilInit 헬퍼 추가"
```

---

## Task 2: AppButton — 테스트 작성

**Files:**
- Create: `test/cores/widgets/buttons/app_button_test.dart`

먼저 4개 핵심 동작에 대한 위젯 테스트를 작성한다. AppButton.primary / .outlined 모두 커버.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// test/cores/widgets/buttons/app_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/widgets/buttons/app_button.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  group('AppButton.primary', () {
    testWidgets('라벨 텍스트가 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppButton.primary(label: '사진·영상 고르기', onPressed: () {}),
      );

      expect(find.text('사진·영상 고르기'), findsOneWidget);
    });

    testWidgets('icon 파라미터가 제공되면 아이콘이 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppButton.primary(
          label: '사진·영상 고르기',
          icon: Icons.image,
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('탭하면 onPressed 콜백이 호출된다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        AppButton.primary(label: '눌러봐', onPressed: () => tapped = true),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onPressed 가 null 이면 탭해도 콜백이 호출되지 않는다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        const AppButton.primary(label: '비활성', onPressed: null),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
      expect(find.text('비활성'), findsOneWidget);
    });
  });

  group('AppButton.outlined', () {
    testWidgets('라벨 텍스트가 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppButton.outlined(label: '비율 먼저 정하기', onPressed: () {}),
      );

      expect(find.text('비율 먼저 정하기'), findsOneWidget);
    });

    testWidgets('탭하면 onPressed 콜백이 호출된다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        AppButton.outlined(label: '다른 제안', onPressed: () => tapped = true),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onPressed 가 null 이면 탭해도 콜백이 호출되지 않는다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        const AppButton.outlined(label: '비활성', onPressed: null),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/cores/widgets/buttons/app_button_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:gridset/cores/widgets/buttons/app_button.dart'`

---

## Task 3: AppButton — 구현

**Files:**
- Create: `lib/cores/widgets/buttons/app_button.dart`

- [ ] **Step 1: AppButton 구현**

```dart
// lib/cores/widgets/buttons/app_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';

enum _AppButtonVariant { primary, outlined }

/// Design.md §4 Buttons 준수 — Primary(charcoal filled) / Outlined(transparent + border).
///
/// 사용:
/// ```dart
/// AppButton.primary(label: '사진·영상 고르기', icon: Icons.image, onPressed: () {})
/// AppButton.outlined(label: '비율 먼저 정하기', onPressed: () {})
/// ```
class AppButton extends StatefulWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.isFullWidth = true,
  })  : _variant = _AppButtonVariant.outlined,
        icon = null;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final _AppButtonVariant _variant;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null;
  bool get _isPrimary => widget._variant == _AppButtonVariant.primary;

  void _setPressed(bool value) {
    if (_isDisabled) return;
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isPrimary ? AppColors.charcoal : Colors.transparent;
    final textColor = _isPrimary ? AppColors.offWhite : AppColors.charcoal;
    final border = _isPrimary
        ? Border.all(width: 0.5, color: AppColors.insetRing)
        : Border.all(width: 1, color: AppColors.charcoal40);
    final shadow = _isPrimary
        ? <BoxShadow>[
            BoxShadow(
              color: AppColors.insetDrop,
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ]
        : null;

    final textStyle = AppTextStyles.button_16.copyWith(color: textColor);

    final rowChildren = <Widget>[
      if (widget.icon != null) ...[
        Icon(widget.icon, color: textColor, size: 18.sp),
        SizedBox(width: AppSpacing.sm.w),
      ],
      Text(widget.label, style: textStyle),
    ];

    final inner = Container(
      width: widget.isFullWidth ? double.infinity : null,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: border,
        boxShadow: shadow,
      ),
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm.h,
        horizontal: AppSpacing.base.w,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: rowChildren,
      ),
    );

    final opacity = _isDisabled ? 0.4 : (_isPressed ? 0.8 : 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: opacity,
        child: inner,
      ),
    );
  }
}
```

- [ ] **Step 2: 테스트 통과 확인**

Run: `flutter test test/cores/widgets/buttons/app_button_test.dart`
Expected: PASS — 7개 테스트 모두 green

- [ ] **Step 3: Commit**

```bash
git add lib/cores/widgets/buttons/app_button.dart test/cores/widgets/buttons/app_button_test.dart
git commit -m "feat : AppButton.primary / .outlined 구현 (TDD)"
```

---

## Task 4: AppIconButton — 테스트 작성

**Files:**
- Create: `test/cores/widgets/buttons/app_icon_button_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// test/cores/widgets/buttons/app_icon_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/widgets/buttons/app_icon_button.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  group('AppIconButton', () {
    testWidgets('아이콘이 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppIconButton(icon: Icons.arrow_back_ios_new, onPressed: () {}),
      );

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('탭하면 onPressed 콜백이 호출된다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        AppIconButton(
          icon: Icons.more_horiz,
          onPressed: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(AppIconButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onPressed 가 null 이면 탭해도 콜백이 호출되지 않는다', (tester) async {
      var tapped = false;
      await pumpWithScreenUtil(
        tester,
        const AppIconButton(icon: Icons.close, onPressed: null),
      );

      await tester.tap(find.byType(AppIconButton), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('semanticLabel 이 Semantics 트리에 노출된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () {},
          semanticLabel: '뒤로 가기',
        ),
      );

      expect(find.bySemanticsLabel('뒤로 가기'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/cores/widgets/buttons/app_icon_button_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:gridset/cores/widgets/buttons/app_icon_button.dart'`

---

## Task 5: AppIconButton — 구현

**Files:**
- Create: `lib/cores/widgets/buttons/app_icon_button.dart`

- [ ] **Step 1: AppIconButton 구현**

```dart
// lib/cores/widgets/buttons/app_icon_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';

/// Design.md §4 Pill / Icon Button 응용 — outlined 원형 (size = 외곽 지름).
///
/// 사용:
/// ```dart
/// AppIconButton(
///   icon: Icons.arrow_back_ios_new,
///   onPressed: () => Navigator.pop(context),
///   semanticLabel: '뒤로 가기',
/// )
/// ```
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// 외곽 원의 지름. 기본 40 (.w 적용 후 디바이스 너비 기준 스케일).
  final double size;

  /// 접근성 라벨. 가능하면 항상 지정 권장.
  final String? semanticLabel;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null;

  void _setPressed(bool value) {
    if (_isDisabled) return;
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = widget.size.w;
    final iconSize = (widget.size * 0.45).sp;
    final opacity = _isDisabled ? 0.4 : (_isPressed ? 0.8 : 1.0);

    final core = Container(
      width: dim,
      height: dim,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(width: 1, color: AppColors.charcoal40),
      ),
      child: Icon(widget.icon, color: AppColors.charcoal, size: iconSize),
    );

    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: opacity,
        child: core,
      ),
    );

    if (widget.semanticLabel != null) {
      result = Semantics(
        button: true,
        label: widget.semanticLabel,
        child: result,
      );
    }

    return result;
  }
}
```

- [ ] **Step 2: 테스트 통과 확인**

Run: `flutter test test/cores/widgets/buttons/app_icon_button_test.dart`
Expected: PASS — 4개 테스트 모두 green

- [ ] **Step 3: Commit**

```bash
git add lib/cores/widgets/buttons/app_icon_button.dart test/cores/widgets/buttons/app_icon_button_test.dart
git commit -m "feat : AppIconButton 구현 (TDD)"
```

---

## Task 6: AppTopBar — 테스트 작성

**Files:**
- Create: `test/cores/widgets/app_bars/app_top_bar_test.dart`

3 variant 모두 커버. `.title` / `.backWithMore` / `.closeWithSave`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// test/cores/widgets/app_bars/app_top_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/widgets/app_bars/app_top_bar.dart';
import 'package:gridset/cores/widgets/buttons/app_icon_button.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  group('AppTopBar.title', () {
    testWidgets('타이틀이 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        const AppTopBar.title(title: 'Gridset'),
      );

      expect(find.text('Gridset'), findsOneWidget);
    });

    testWidgets('trailing 이 제공되면 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppTopBar.title(
          title: 'Gridset',
          trailing: AppIconButton(
            icon: Icons.center_focus_strong,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(AppIconButton), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
    });
  });

  group('AppTopBar.backWithMore', () {
    testWidgets('타이틀이 중앙에 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppTopBar.backWithMore(
          title: '제안 1/3',
          onBack: () {},
          onMore: () {},
        ),
      );

      expect(find.text('제안 1/3'), findsOneWidget);
    });

    testWidgets('back 탭 시 onBack 콜백이 호출된다', (tester) async {
      var backed = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.backWithMore(
          title: '제안 1/3',
          onBack: () => backed = true,
          onMore: () {},
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      expect(backed, isTrue);
    });

    testWidgets('more 탭 시 onMore 콜백이 호출된다', (tester) async {
      var mored = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.backWithMore(
          title: '제안 1/3',
          onBack: () {},
          onMore: () => mored = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pump();

      expect(mored, isTrue);
    });
  });

  group('AppTopBar.closeWithSave', () {
    testWidgets('타이틀, 닫기, 저장 모두 렌더링된다', (tester) async {
      await pumpWithScreenUtil(
        tester,
        AppTopBar.closeWithSave(
          title: 'Gridset',
          onClose: () {},
          onSave: () {},
        ),
      );

      expect(find.text('Gridset'), findsOneWidget);
      expect(find.text('닫기'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('닫기 탭 시 onClose 콜백이 호출된다', (tester) async {
      var closed = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.closeWithSave(
          title: 'Gridset',
          onClose: () => closed = true,
          onSave: () {},
        ),
      );

      await tester.tap(find.text('닫기'));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('저장 탭 시 onSave 콜백이 호출된다', (tester) async {
      var saved = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.closeWithSave(
          title: 'Gridset',
          onClose: () {},
          onSave: () => saved = true,
        ),
      );

      await tester.tap(find.text('저장'));
      await tester.pump();

      expect(saved, isTrue);
    });

    testWidgets('onSave 가 null 이면 저장 탭해도 콜백이 호출되지 않는다', (tester) async {
      var saved = false;
      await pumpWithScreenUtil(
        tester,
        AppTopBar.closeWithSave(
          title: 'Gridset',
          onClose: () {},
          onSave: null,
        ),
      );

      await tester.tap(find.text('저장'), warnIfMissed: false);
      await tester.pump();

      expect(saved, isFalse);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/cores/widgets/app_bars/app_top_bar_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:gridset/cores/widgets/app_bars/app_top_bar.dart'`

---

## Task 7: AppTopBar — 구현

**Files:**
- Create: `lib/cores/widgets/app_bars/app_top_bar.dart`

- [ ] **Step 1: AppTopBar 구현**

```dart
// lib/cores/widgets/app_bars/app_top_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';
import '../buttons/app_icon_button.dart';

enum _AppTopBarVariant { titleLeft, backWithMore, closeWithSave }

/// 3 variant 의 상단 앱 바 — Design.md 단일 cream 테마, border 없음.
///
/// `PreferredSizeWidget` 구현 — `Scaffold(appBar: ...)` 슬롯에 직접 사용 가능.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 화면 1: 좌측 큰 wordmark + 옵션 trailing.
  const AppTopBar.title({
    super.key,
    required this.title,
    this.trailing,
  })  : _variant = _AppTopBarVariant.titleLeft,
        onBack = null,
        onMore = null,
        onClose = null,
        onSave = null;

  /// 화면 2: 뒤로 + 중앙 타이틀 + 더보기.
  const AppTopBar.backWithMore({
    super.key,
    required this.title,
    required VoidCallback this.onBack,
    required VoidCallback this.onMore,
  })  : _variant = _AppTopBarVariant.backWithMore,
        trailing = null,
        onClose = null,
        onSave = null;

  /// 화면 3: 닫기 텍스트버튼 + 중앙 타이틀 + 저장 텍스트버튼 (`onSave: null` = 비활성).
  const AppTopBar.closeWithSave({
    super.key,
    required this.title,
    required VoidCallback this.onClose,
    required this.onSave,
  })  : _variant = _AppTopBarVariant.closeWithSave,
        trailing = null,
        onBack = null,
        onMore = null;

  final String title;
  final AppIconButton? trailing;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onClose;
  final VoidCallback? onSave;
  final _AppTopBarVariant _variant;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      color: AppColors.cream,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_variant) {
      case _AppTopBarVariant.titleLeft:
        return _buildTitleVariant();
      case _AppTopBarVariant.backWithMore:
        return _buildBackWithMoreVariant();
      case _AppTopBarVariant.closeWithSave:
        return _buildCloseWithSaveVariant();
    }
  }

  Widget _buildTitleVariant() {
    return Row(
      children: [
        Text(title, style: AppTextStyles.cardTitle_32),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _buildBackWithMoreVariant() {
    return Row(
      children: [
        AppIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: onBack,
          semanticLabel: '뒤로 가기',
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
            ),
          ),
        ),
        AppIconButton(
          icon: Icons.more_horiz,
          onPressed: onMore,
          semanticLabel: '더보기',
        ),
      ],
    );
  }

  Widget _buildCloseWithSaveVariant() {
    final saveColor = onSave == null ? AppColors.charcoal40 : AppColors.charcoal;

    return Row(
      children: [
        TextButton(
          onPressed: onClose,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            foregroundColor: AppColors.charcoal,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, color: AppColors.charcoal, size: 18.sp),
              SizedBox(width: AppSpacing.xs.w),
              Text(
                '닫기',
                style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
            ),
          ),
        ),
        TextButton(
          onPressed: onSave,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            foregroundColor: saveColor,
          ),
          child: Text(
            '저장',
            style: AppTextStyles.body_16.copyWith(color: saveColor),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 테스트 통과 확인**

Run: `flutter test test/cores/widgets/app_bars/app_top_bar_test.dart`
Expected: PASS — 9개 테스트 모두 green

- [ ] **Step 3: Commit**

```bash
git add lib/cores/widgets/app_bars/app_top_bar.dart test/cores/widgets/app_bars/app_top_bar_test.dart
git commit -m "feat : AppTopBar 3 variant 구현 (TDD)"
```

---

## Task 8: 전체 테스트 + 커버리지 검증

**Files:**
- Run only

- [ ] **Step 1: 전체 테스트 통과 확인**

Run: `flutter test`
Expected: PASS — 본 plan 의 20개 신규 테스트 + 기존 테스트 모두 green

- [ ] **Step 2: 커버리지 측정 (선택, 80%+ 목표)**

Run: `flutter test --coverage && lcov --summary coverage/lcov.info 2>/dev/null || true`

신규 3개 위젯 파일 라인 커버리지가 80%+ 인지 확인. 미달 시 누락 분기(특히 disabled / variant 분기)에 테스트 추가.

> `lcov` 미설치 시 Step 2 는 생략 가능. 핵심은 Step 1.

- [ ] **Step 3: 빈 커밋 또는 미커밋 변경 없음 확인**

Run: `git status`
Expected: `working tree clean`

---

## 작업 완료 기준

- 7개 신규 파일 (3 lib + 1 test helper + 3 test) 추가
- 20개 위젯 테스트 모두 green
- 4개 기능 커밋 (헬퍼 / AppButton / AppIconButton / AppTopBar)
- 모든 위젯이 `AppColors`, `AppTextStyles`, `AppSpacing` 만 사용 (raw 값 0)
- 이모지 0건 (UI 코드 안)

---

## Out of Scope (이 plan 범위 외)

- 화면 1·2·3 구현 — 별도 plan 으로
- 골든 테스트
- AppHintPill / AppPageIndicator / AppGridPreviewCard / AppBottomToolbar / AppDragHandle / AppSectionLabel
- font_awesome_flutter 추가
- Inset shadow 의 top highlight layer (`AppColors.insetHighlight` 토큰만 보존, 미사용)
