# Home Screen + Dev Component Gallery v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈 화면 본 구현 + Dev 컴포넌트 갤러리(`/dev`) 도입 — 사용자 첫 동작 화면 + primitive 시각 검증 환경 완성.

**Architecture:** 단순 화면 2개. 상태 관리·로컬 저장 도입 없음. 홈은 정적 + CTA SnackBar stub, 갤러리는 정적 ListView. 라우팅은 기존 GoRouter 에 `/dev` 만 추가. Dev 진입은 `kDebugMode` 게이트.

**Tech Stack:** Flutter 3.x, `go_router`, `flutter_screenutil`, `flutter_test`, Material `Icons.*` + `SnackBar`. Riverpod·로컬 저장 미사용.

**Spec reference:** `docs/superpowers/specs/2026-04-25-home-and-dev-gallery-design.md`

---

## File Structure

**Lib (생성):**
- `lib/features/dev/dev_gallery_page.dart` — `/dev` 라우트 페이지
- `lib/features/dev/widgets/gallery_section.dart` — 제목 + 카드 컨테이너
- `lib/features/dev/widgets/color_swatch.dart` — 색상 스왓치

**Lib (수정):**
- `lib/cores/widgets/buttons/app_button.dart` — `18.sp` → `16.sp`
- `lib/cores/widgets/app_bars/app_top_bar.dart` — `18.sp` → `16.sp`
- `lib/routers/route_paths.dart` — `RoutePaths.dev` 추가
- `lib/routers/app_router.dart` — `/dev` GoRoute 추가
- `lib/features/home/home_page.dart` — placeholder 교체

**Test (생성):**
- `test/features/home/home_page_test.dart`
- `test/features/dev/dev_gallery_page_test.dart`

**Test (수정):**
- `test/test_helpers/widget_test_helpers.dart` — `pumpPage` 헬퍼 추가 (전체 페이지 위젯용)

---

## Task 1: 아이콘 사이즈 18.sp → 16.sp 통일

primitive v1 에서 미해결로 둔 픽셀 그리드 위반 정리. 본문 16.sp 와 시각 정합 + Design.md 16-배수 정신 준수.

**Files:**
- Modify: `lib/cores/widgets/buttons/app_button.dart` (1 line)
- Modify: `lib/cores/widgets/app_bars/app_top_bar.dart` (1 line)

- [ ] **Step 1: AppButton 의 아이콘 사이즈 변경**

`lib/cores/widgets/buttons/app_button.dart` 에서 `Icon(widget.icon, color: textColor, size: 18.sp)` 를 찾아 `size: 16.sp` 로 변경.

- [ ] **Step 2: AppTopBar 의 close 아이콘 사이즈 변경**

`lib/cores/widgets/app_bars/app_top_bar.dart` 의 `_CloseWithSaveVariantBody` 안에서 `Icon(Icons.close, color: AppColors.charcoal, size: 18.sp)` 를 찾아 `size: 16.sp` 로 변경.

- [ ] **Step 3: 전체 테스트 통과 확인**

Run: `flutter test`
Expected: PASS — 모든 기존 32개 테스트 green (사이즈만 변경, 동작 변화 없음)

- [ ] **Step 4: Commit**

```bash
git add lib/cores/widgets/buttons/app_button.dart lib/cores/widgets/app_bars/app_top_bar.dart
git commit -m "fix : primitive widget 의 18.sp 아이콘을 16.sp 로 통일

본문 16.sp 와 시각 정합 + Design.md §3 16-배수 정신 준수.
AppButton.icon, AppTopBar.closeWithSave 의 close 아이콘 둘 다 적용."
```

---

## Task 2: RoutePaths.dev + pumpPage 테스트 헬퍼 추가

`/dev` 라우트 상수 + 전체 페이지 위젯 펌프 헬퍼. (GoRoute 등록은 DevGalleryPage 만든 뒤 Task 8 에서 처리.)

**Files:**
- Modify: `lib/routers/route_paths.dart`
- Modify: `test/test_helpers/widget_test_helpers.dart`

- [ ] **Step 1: RoutePaths.dev 상수 추가**

`lib/routers/route_paths.dart` 의 `RoutePaths` 클래스 안 마지막 라인 (`forceUpdate` 다음) 에 추가:

```dart
  /// Dev 컴포넌트 갤러리 (kDebugMode 진입)
  static const String dev = '/dev';
```

- [ ] **Step 2: pumpPage 헬퍼 추가**

`test/test_helpers/widget_test_helpers.dart` 끝에 추가:

```dart
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
```

- [ ] **Step 3: 전체 테스트 통과 확인 (기존 테스트 영향 없음 검증)**

Run: `flutter test`
Expected: PASS — 32개 모두 green

- [ ] **Step 4: Commit**

```bash
git add lib/routers/route_paths.dart test/test_helpers/widget_test_helpers.dart
git commit -m "chore : RoutePaths.dev 상수 + pumpPage 테스트 헬퍼 추가"
```

---

## Task 3: HomePage 테스트 작성 (RED)

**Files:**
- Create: `test/features/home/home_page_test.dart`

- [ ] **Step 1: HomePage 테스트 작성**

```dart
// test/features/home/home_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/widgets/buttons/app_icon_button.dart';
import 'package:gridset/features/home/home_page.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  group('HomePage', () {
    testWidgets('상단에 Gridset 워드마크가 렌더링된다', (tester) async {
      await pumpPage(tester, const HomePage());

      // AppTopBar.title 의 'Gridset' (워드마크). 테스트 페이지 내 다른 곳에 'Gridset' 없으므로 1건.
      expect(find.text('Gridset'), findsOneWidget);
    });

    testWidgets('헤딩 "오늘은\\n뭐 모아볼까?" 가 렌더링된다', (tester) async {
      await pumpPage(tester, const HomePage());

      expect(find.text('오늘은\n뭐 모아볼까?'), findsOneWidget);
    });

    testWidgets('두 CTA 라벨이 렌더링된다', (tester) async {
      await pumpPage(tester, const HomePage());

      expect(find.text('사진·영상 고르기'), findsOneWidget);
      expect(find.text('비율 먼저 정하기'), findsOneWidget);
    });

    testWidgets('"사진·영상 고르기" 탭하면 SnackBar 가 표시된다', (tester) async {
      await pumpPage(tester, const HomePage());

      await tester.tap(find.text('사진·영상 고르기'));
      await tester.pump(); // SnackBar 등장 트리거

      expect(find.text('다음 화면 준비 중'), findsOneWidget);
    });

    testWidgets('"비율 먼저 정하기" 탭하면 SnackBar 가 표시된다', (tester) async {
      await pumpPage(tester, const HomePage());

      await tester.tap(find.text('비율 먼저 정하기'));
      await tester.pump();

      expect(find.text('다음 화면 준비 중'), findsOneWidget);
    });

    testWidgets('우상단에 디버그 진입용 AppIconButton 이 렌더링된다 (gps_fixed 아이콘)', (tester) async {
      await pumpPage(tester, const HomePage());

      // trailing 슬롯의 AppIconButton — 우상단
      expect(find.byType(AppIconButton), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/features/home/home_page_test.dart`
Expected: FAIL — 가장 첫 줄 import 에서 컴파일 실패 또는 기존 placeholder HomePage 가 새 expectation 들에 부합 안 해 다수 실패

---

## Task 4: HomePage 구현 (GREEN)

**Files:**
- Modify: `lib/features/home/home_page.dart` (전부 재작성)

- [ ] **Step 1: HomePage 구현**

```dart
// lib/features/home/home_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/widgets/app_bars/app_top_bar.dart';
import '../../cores/widgets/buttons/app_button.dart';
import '../../cores/widgets/buttons/app_icon_button.dart';
import '../../routers/route_paths.dart';

/// 홈 화면 — Gridset 의 첫 화면.
///
/// 구성:
/// - 상단 AppTopBar.title (Gridset 워드마크 + 디버그 진입 버튼)
/// - 큰 헤딩 "오늘은\n뭐 모아볼까?"
/// - 두 CTA: "사진·영상 고르기" (primary, with icon), "비율 먼저 정하기" (outlined)
///
/// 디버그 진입 버튼은 kDebugMode 일 때만 /dev 라우트로 이동.
/// CTA 는 화면 2 (suggestion) 미구현이라 SnackBar stub.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showStubSnackBar(BuildContext context) {
    debugPrint('🚧 CTA 동작 — 다음 화면(suggestion) 미구현');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.charcoal,
        content: Text(
          '다음 화면 준비 중',
          style: AppTextStyles.body_16.copyWith(color: AppColors.offWhite),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppTopBar.title(
        title: 'Gridset',
        trailing: const _DebugEntryButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xxxl.h),
              Text(
                '오늘은\n뭐 모아볼까?',
                style: AppTextStyles.subHeading_48
                    .copyWith(color: AppColors.charcoal),
              ),
              SizedBox(height: AppSpacing.xxxl.h),
              AppButton.primary(
                label: '사진·영상 고르기',
                icon: Icons.image,
                onPressed: () => _showStubSnackBar(context),
              ),
              SizedBox(height: AppSpacing.md.h),
              AppButton.outlined(
                label: '비율 먼저 정하기',
                onPressed: () => _showStubSnackBar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 우상단 디버그 진입 버튼.
///
/// kDebugMode 일 때만 /dev 라우트로 이동. release 빌드에선 onPressed null → disabled.
class _DebugEntryButton extends StatelessWidget {
  const _DebugEntryButton();

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.gps_fixed,
      onPressed: kDebugMode
          ? () => context.go(RoutePaths.dev)
          : null,
      semanticLabel: kDebugMode ? '개발 도구' : null,
    );
  }
}
```

- [ ] **Step 2: 테스트 통과 확인**

Run: `flutter test test/features/home/home_page_test.dart`
Expected: PASS — 6개 모두 green

- [ ] **Step 3: 전체 suite 통과 확인**

Run: `flutter test`
Expected: PASS — 모두 green

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/home_page.dart test/features/home/home_page_test.dart
git commit -m "feat : 홈 화면 본 구현 (CTA stub + 디버그 진입)

- AppTopBar.title + 헤딩 + 두 CTA (primary, outlined)
- CTA 는 SnackBar stub (다음 화면 준비 중) — 화면 2 들어오면 교체
- 우상단 _DebugEntryButton: kDebugMode 시 /dev 이동, release 시 disabled"
```

---

## Task 5: GallerySection + ColorSwatch 위젯

Dev 갤러리 보조 위젯. 단순 시각 위젯 — 단위 테스트 생략 (spec §8 명시).

**Files:**
- Create: `lib/features/dev/widgets/gallery_section.dart`
- Create: `lib/features/dev/widgets/color_swatch.dart`

- [ ] **Step 1: GallerySection 구현**

```dart
// lib/features/dev/widgets/gallery_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';

/// Dev 갤러리의 카드형 섹션 — 제목 + 자식 위젯들 수직 나열.
class GallerySection extends StatelessWidget {
  const GallerySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.lightCream),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle_32),
          SizedBox(height: AppSpacing.base.h),
          ...children.map(
            (c) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md.h),
              child: c,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: ColorSwatch 구현**

```dart
// lib/features/dev/widgets/color_swatch.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/constants/app_text_style.dart';

/// 색상 스왓치 — 64×64 색상 박스 + 이름 라벨.
class ColorSwatch extends StatelessWidget {
  const ColorSwatch({
    super.key,
    required this.color,
    required this.name,
  });

  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64.w,
          height: 64.h,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.charcoal40, width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          name,
          style: AppTextStyles.caption_16
              .copyWith(color: AppColors.charcoal82),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: 컴파일 확인 (전 테스트는 영향 없음)**

Run: `flutter analyze lib/features/dev/`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/dev/widgets/gallery_section.dart lib/features/dev/widgets/color_swatch.dart
git commit -m "feat : Dev 갤러리 보조 위젯 (GallerySection, ColorSwatch)"
```

---

## Task 6: DevGalleryPage 테스트 작성 (RED)

**Files:**
- Create: `test/features/dev/dev_gallery_page_test.dart`

- [ ] **Step 1: DevGalleryPage 테스트 작성**

```dart
// test/features/dev/dev_gallery_page_test.dart
import 'package:flutter/material.dart';
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
```

> 위 마지막 테스트는 정확한 카운트가 아니라 sanity check. DevGalleryPage 구현은 spec §5 의 항목 그대로 만들면 자연스럽게 통과.

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/features/dev/dev_gallery_page_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:gridset/features/dev/dev_gallery_page.dart'`

---

## Task 7: DevGalleryPage 구현 (GREEN)

**Files:**
- Create: `lib/features/dev/dev_gallery_page.dart`

- [ ] **Step 1: DevGalleryPage 구현**

```dart
// lib/features/dev/dev_gallery_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/widgets/app_bars/app_top_bar.dart';
import '../../cores/widgets/buttons/app_button.dart';
import '../../cores/widgets/buttons/app_icon_button.dart';
import '../../routers/route_paths.dart';
import 'widgets/color_swatch.dart';
import 'widgets/gallery_section.dart';

/// Dev 컴포넌트 갤러리 — kDebugMode 시 홈 우상단 버튼에서 진입.
///
/// 5개 섹션: AppButton, AppIconButton, AppTopBar, Colors, Typography.
class DevGalleryPage extends StatelessWidget {
  const DevGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppTopBar.backWithMore(
        title: 'Components',
        onBack: () => context.go(RoutePaths.home),
        onMore: () => debugPrint('🛠️ Dev gallery more menu (v2)'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.all(AppSpacing.base.w),
          itemCount: 5,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.xl.h),
          itemBuilder: (context, i) => switch (i) {
            0 => _buildAppButtonSection(),
            1 => _buildAppIconButtonSection(),
            2 => _buildAppTopBarSection(),
            3 => _buildColorsSection(),
            4 => _buildTypographySection(),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildAppButtonSection() {
    return GallerySection(
      title: 'AppButton',
      children: [
        _ItemLabel('primary (full, with icon)'),
        AppButton.primary(
          label: '사진·영상 고르기',
          icon: Icons.image,
          onPressed: () {},
        ),
        _ItemLabel('primary (full, no icon)'),
        AppButton.primary(label: '이걸로', onPressed: () {}),
        _ItemLabel('primary (auto-width, Row of 2)'),
        Row(
          children: [
            Expanded(
              child: AppButton.primary(
                label: '다른 제안',
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: AppButton.primary(
                label: '빈 캔버스',
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
          ],
        ),
        _ItemLabel('primary (disabled)'),
        const AppButton.primary(label: '비활성', onPressed: null),
        _ItemLabel('outlined (full)'),
        AppButton.outlined(label: '비율 먼저 정하기', onPressed: () {}),
        _ItemLabel('outlined (auto-width, Row of 2)'),
        Row(
          children: [
            Expanded(
              child: AppButton.outlined(
                label: '다른 제안',
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: AppButton.outlined(
                label: '빈 캔버스',
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
          ],
        ),
        _ItemLabel('outlined (disabled)'),
        const AppButton.outlined(label: '비활성', onPressed: null),
      ],
    );
  }

  Widget _buildAppIconButtonSection() {
    return GallerySection(
      title: 'AppIconButton',
      children: [
        _ItemLabel('default (size: 40)'),
        AppIconButton(icon: Icons.arrow_back_ios_new, onPressed: () {}),
        _ItemLabel('small (size: 32, 탭 영역 ≥44pt 보장)'),
        AppIconButton(icon: Icons.close, onPressed: () {}, size: 32),
        _ItemLabel('disabled'),
        const AppIconButton(icon: Icons.more_horiz, onPressed: null),
        _ItemLabel('with semanticLabel'),
        AppIconButton(
          icon: Icons.gps_fixed,
          onPressed: () {},
          semanticLabel: '센터',
        ),
      ],
    );
  }

  Widget _buildAppTopBarSection() {
    return GallerySection(
      title: 'AppTopBar',
      children: [
        _ItemLabel('.title (with trailing)'),
        SizedBox(
          height: 64.h,
          child: AppTopBar.title(
            title: 'Gridset',
            trailing: AppIconButton(
              icon: Icons.gps_fixed,
              onPressed: () {},
            ),
          ),
        ),
        _ItemLabel('.backWithMore'),
        SizedBox(
          height: 64.h,
          child: AppTopBar.backWithMore(
            title: '제안 1/3',
            onBack: () {},
            onMore: () {},
          ),
        ),
        _ItemLabel('.closeWithSave (active)'),
        SizedBox(
          height: 64.h,
          child: AppTopBar.closeWithSave(
            title: 'Gridset',
            onClose: () {},
            onSave: () {},
          ),
        ),
        _ItemLabel('.closeWithSave (save disabled)'),
        SizedBox(
          height: 64.h,
          child: AppTopBar.closeWithSave(
            title: 'Gridset',
            onClose: () {},
            onSave: null,
          ),
        ),
      ],
    );
  }

  Widget _buildColorsSection() {
    final entries = [
      ('cream', AppColors.cream),
      ('charcoal', AppColors.charcoal),
      ('offWhite', AppColors.offWhite),
      ('charcoal83', AppColors.charcoal83),
      ('charcoal82', AppColors.charcoal82),
      ('charcoal40', AppColors.charcoal40),
      ('charcoal04', AppColors.charcoal04),
      ('charcoal03', AppColors.charcoal03),
      ('mutedGray', AppColors.mutedGray),
      ('lightCream', AppColors.lightCream),
      ('ringBlue', AppColors.ringBlue),
      ('shadowFocus', AppColors.shadowFocus),
      ('insetHighlight', AppColors.insetHighlight),
      ('insetRing', AppColors.insetRing),
      ('insetDrop', AppColors.insetDrop),
    ];

    return GallerySection(
      title: 'Colors (AppColors)',
      children: [
        Wrap(
          spacing: AppSpacing.md.w,
          runSpacing: AppSpacing.md.h,
          children: entries
              .map((e) => ColorSwatch(name: e.$1, color: e.$2))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTypographySection() {
    final entries = [
      ('displayHero_96', AppTextStyles.displayHero_96, 'Gridset'),
      ('displayAlt_80', AppTextStyles.displayAlt_80, 'Gridset'),
      ('sectionHeading_64', AppTextStyles.sectionHeading_64, '오늘은'),
      ('subHeading_48', AppTextStyles.subHeading_48, '오늘은 뭐 만들까?'),
      ('cardTitle_32', AppTextStyles.cardTitle_32, '이어서 만들기'),
      ('bodyLarge_32', AppTextStyles.bodyLarge_32, '큰 본문 텍스트'),
      ('body_16', AppTextStyles.body_16, '표준 본문 텍스트입니다'),
      ('button_16', AppTextStyles.button_16, '버튼 라벨'),
      ('link_16', AppTextStyles.link_16, '링크 텍스트'),
      ('caption_16', AppTextStyles.caption_16, '캡션·메타데이터'),
    ];

    return GallerySection(
      title: 'Typography (AppTextStyles)',
      children: entries.expand((e) {
        return [
          _ItemLabel(e.$1),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 120.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                e.$3,
                style: e.$2.copyWith(color: AppColors.charcoal),
              ),
            ),
          ),
        ];
      }).toList(),
    );
  }
}

/// 갤러리 항목 라벨 (라벨 + 위젯 본체 패턴).
class _ItemLabel extends StatelessWidget {
  const _ItemLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Text(
        text,
        style: AppTextStyles.caption_16
            .copyWith(color: AppColors.charcoal82),
      ),
    );
  }
}
```

- [ ] **Step 2: 테스트 통과 확인**

Run: `flutter test test/features/dev/dev_gallery_page_test.dart`
Expected: PASS — 3개 모두 green

- [ ] **Step 3: Commit**

```bash
git add lib/features/dev/dev_gallery_page.dart test/features/dev/dev_gallery_page_test.dart
git commit -m "feat : DevGalleryPage 구현 — 5개 섹션 시각 카탈로그

AppButton / AppIconButton / AppTopBar / Colors / Typography 항목별 변형 시각 검증."
```

---

## Task 8: GoRoute /dev 등록 + 최종 검증

DevGalleryPage 가 존재하므로 라우터에 /dev 등록.

**Files:**
- Modify: `lib/routers/app_router.dart`

- [ ] **Step 1: app_router.dart 수정**

기존 `routes` 배열 끝(forceUpdate GoRoute 다음) 에 추가:

```dart
    GoRoute(
      path: RoutePaths.dev,
      pageBuilder: (context, state) => buildDirectionalSlide(
        key: state.pageKey,
        child: const DevGalleryPage(),
      ),
    ),
```

import 추가 (파일 상단):
```dart
import '../features/dev/dev_gallery_page.dart';
```

- [ ] **Step 2: 전체 테스트 통과 확인**

Run: `flutter test`
Expected: PASS — 모든 기존 테스트 + 본 plan 9개 신규 (Home 6 + Gallery 3) = 41 모두 green

- [ ] **Step 3: 빌드 분석 통과 확인 (lint/import 깨끗)**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 4: 워킹 트리 클린 확인**

Run: `git status`
Expected: changes only in `lib/routers/app_router.dart` (이번 step 의 수정만)

- [ ] **Step 5: Commit**

```bash
git add lib/routers/app_router.dart
git commit -m "feat : /dev 라우트 등록 (DevGalleryPage 진입)

홈 우상단 디버그 버튼 → /dev 슬라이드 전환. 기존 부트스트랩 라우트들과
구분된 buildDirectionalSlide 사용 (forward navigation 패턴)."
```

---

## 작업 완료 기준

- 8 task 완료
- 신규 파일 5개 (HomePage 재작성 1 + DevGalleryPage 1 + GallerySection 1 + ColorSwatch 1 + Home 테스트 1 + Gallery 테스트 1) + 헬퍼 1 수정
- 신규 테스트 9개 (Home 6 + Gallery 3) — 전체 41 green
- 6개 커밋 (18.sp fix / 라우트 상수 + 헬퍼 / Home / 갤러리 위젯 / DevGalleryPage / 라우트 등록)
- 모든 위젯이 `AppColors`, `AppTextStyles`, `AppSpacing` 만 사용
- 이모지 0건 (UI 코드 안)
- `flutter analyze` clean

---

## Out of Scope (이 plan 범위 외)

- 화면 2 (제안) / 화면 3 (에디터) 구현
- 드래프트 모델 / 로컬 저장 / Riverpod provider
- "이어서 만들기" 섹션 — 화면 3 끝나고 도입
- Dev 갤러리의 dark mode 토글 / 디바이스 프레임 등 v2
- HomePage 디버그 진입 버튼의 navigation 통합 테스트 (router mock 필요 — 단위 테스트 범위 밖)
