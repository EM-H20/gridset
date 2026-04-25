# Firebase Remote Config 통합 + 앱 부트스트랩 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 다른 프로젝트에서 복사해온 `lib/cores/services/remote_config/` 3개 파일의 누락 의존성을 현재 프로젝트 디자인 시스템(Lovable / MoneygraphyPixel)으로 복원하고, Firebase 초기화 + 부트스트랩 라우팅까지 연결해 실제로 동작하는 상태로 만든다.

**Architecture:** Feature 단위 단순 뷰(Splash/Maintenance/ForceUpdate/Home)는 data/domain 분리 없이 단일 파일. go_router + `custom_page_transitions` 유틸을 써서 라우팅. 다이얼로그는 Design.md Lovable 스펙의 풀 커스텀 `AppDialog`. 버전/점검 게이팅은 Remote Config 값을 비교하여 maintenance/forceUpdate는 풀스크린 페이지, optional/recommend는 다이얼로그로 처리.

**Tech Stack:** Flutter 3.35.5 / Dart ^3.9.2, Riverpod, go_router, flutter_screenutil, firebase_core, firebase_remote_config, flutter_dotenv, flutter_svg, url_launcher, package_info_plus.

**Spec:** [`docs/superpowers/specs/2026-04-25-remote-config-setup-design.md`](../specs/2026-04-25-remote-config-setup-design.md)

**Flutter 패키지명:** `gridset` (pubspec.yaml name 필드 기준) — 테스트 import 시 사용.

**공통 주의사항:**
- 한국어 커뮤니케이션, 한국어 주석 (WHY 중심)
- `flutter_screenutil` 의 `.sp` 는 `AppTextStyles` 내부에서만 사용 — 신규 코드는 `AppTextStyles.*` 참조
- 색/간격은 `AppColors`, `AppSpacing` 만 사용 — 하드코딩 금지
- `Co-Authored-By` 태그 금지, `git push` 금지

---

## File Structure (이 플랜에서 생성/수정되는 모든 파일)

```
lib/
├── main.dart                                       # MODIFY (bootstrap 재작성)
├── cores/
│   ├── constants/
│   │   └── app_urls.dart                           # CREATE
│   ├── utils/
│   │   ├── url_launcher_util.dart                  # CREATE
│   │   └── custom_page_transitions.dart            # CREATE
│   ├── widgets/
│   │   └── dialogs/
│   │       └── app_dialog.dart                     # CREATE
│   └── services/
│       └── remote_config/
│           ├── app_version_checker.dart            # MODIFY (expose _isVersionLower)
│           └── update_dialog_helper.dart           # MODIFY (import 경로 수정)
├── routers/
│   ├── route_paths.dart                            # CREATE
│   └── app_router.dart                             # CREATE
└── features/
    ├── splash/splash_page.dart                     # CREATE
    ├── maintenance/maintenance_page.dart           # CREATE
    ├── force_update/force_update_page.dart         # CREATE
    └── home/home_page.dart                         # CREATE

test/
└── cores/services/remote_config/
    └── app_version_checker_test.dart               # CREATE

pubspec.yaml                                        # MODIFY (splash.svg asset 추가)
```

---

## Task 1: AppUrls 상수 생성

**Files:**
- Create: `lib/cores/constants/app_urls.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/cores/constants/app_urls.dart
import 'dart:io';

/// 앱 외부 링크 URL 상수
///
/// 스토어 다운로드, 개인정보 처리방침, 이용약관 등 외부 웹 링크를 관리한다.
///
/// TODO(gridset): 스토어 배포 시점에 아래 URL 들을 gridset 실제 값으로 교체.
/// 현재는 copsandrobbers 프로젝트 값이 임시 placeholder 로 들어가 있음.
class AppUrls {
  AppUrls._();

  /// 스토어 다운로드 URL (플랫폼별 분기)
  static String get storeUrl {
    if (Platform.isAndroid) {
      // TODO(gridset): com.innocare.gridset 정식 배포 후 교체
      return 'https://play.google.com/store/apps/details?id=com.elipair.copsandrobbers';
    }
    // TODO(gridset): 정식 App Store ID 발급 후 교체
    return 'https://apps.apple.com/us/app/id6756843948';
  }

  // TODO(gridset): gridset 약관 페이지 작성 후 전부 교체
  /// 개인정보 처리방침
  static const String privacyPolicy =
      'https://sites.google.com/view/copsandrobbers-pp/%ED%99%88';

  /// 이용약관
  static const String termsOfService =
      'https://sites.google.com/view/copsandrobbers-tos/%ED%99%88';

  /// 위치정보 이용약관
  static const String locationTerms =
      'https://sites.google.com/view/copsandrobbers-lt/%ED%99%88';

  /// 마케팅 정보 수신
  static const String marketingConsent =
      'https://sites.google.com/view/copsandrobbers-mc/%ED%99%88';
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/cores/constants/app_urls.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/cores/constants/app_urls.dart
git commit -m "feat: add AppUrls constants with TODO placeholders"
```

---

## Task 2: launchExternalUrl 유틸 생성

**Files:**
- Create: `lib/cores/utils/url_launcher_util.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/cores/utils/url_launcher_util.dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 외부 URL을 브라우저에서 여는 유틸리티
///
/// [urlString] 을 외부 브라우저에서 연다.
/// 열 수 없는 URL 인 경우 디버그 로그를 남기고 `false` 를 반환한다.
Future<bool> launchExternalUrl(String urlString) async {
  final uri = Uri.parse(urlString);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  debugPrint('Cannot launch URL: $urlString');
  return false;
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/cores/utils/url_launcher_util.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/cores/utils/url_launcher_util.dart
git commit -m "feat: add launchExternalUrl utility"
```

---

## Task 3: custom_page_transitions 유틸 생성

**Files:**
- Create: `lib/cores/utils/custom_page_transitions.dart`

사용자 제공 코드를 그대로 사용한다.

- [ ] **Step 1: 파일 생성**

```dart
// lib/cores/utils/custom_page_transitions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 방향성 슬라이드 전환을 위한 CustomTransitionPage 빌더
///
/// GoRouter의 CustomTransitionPage를 사용하여 명시적인 방향 제어를 제공한다.
/// [isForward] 가 true면 우→좌 슬라이드, false면 좌→우 슬라이드.
CustomTransitionPage<T> buildDirectionalSlide<T>({
  required Widget child,
  required LocalKey key,
  required bool isForward,
  Duration? duration,
  Duration? reverseDuration,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = isForward
          ? const Offset(1.0, 0.0) // 우→좌
          : const Offset(-1.0, 0.0); // 좌→우

      final tween = Tween(
        begin: offset,
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeInOut));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: duration ?? const Duration(milliseconds: 300),
    reverseTransitionDuration:
        reverseDuration ?? const Duration(milliseconds: 200),
  );
}

/// 애니메이션 없는 즉각 전환
///
/// Splash 화면 등에서 사용하여 페이지 전환 시 애니메이션을 완전히 제거한다.
CustomTransitionPage<T> buildInstantTransition<T>({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (_, _, _, child) => child,
  );
}

/// 부드러운 페이드 전환
///
/// 매우 짧은 페이드 애니메이션으로 깜빡임 없이 부드럽게 전환한다.
CustomTransitionPage<T> buildSmoothFade<T>({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/cores/utils/custom_page_transitions.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/cores/utils/custom_page_transitions.dart
git commit -m "feat: add custom page transition builders"
```

---

## Task 4: AppVersionChecker 버전 비교 로직 테스트 (TDD 리팩터)

**목적:** 현재 `_isVersionLower` 가 private 라 유닛 테스트 불가. `@visibleForTesting` 으로 노출 후 테스트 추가.

**Files:**
- Modify: `lib/cores/services/remote_config/app_version_checker.dart` (method rename)
- Create: `test/cores/services/remote_config/app_version_checker_test.dart`

- [ ] **Step 1: 실패 테스트 먼저 작성**

```dart
// test/cores/services/remote_config/app_version_checker_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/services/remote_config/app_version_checker.dart';

void main() {
  group('AppVersionChecker.isVersionLower', () {
    test('current < minimum (minor 차이)', () {
      expect(AppVersionChecker.isVersionLower('1.2.3', '1.3.0'), isTrue);
    });

    test('current < minimum (major 차이)', () {
      expect(AppVersionChecker.isVersionLower('1.9.9', '2.0.0'), isTrue);
    });

    test('current < minimum (patch 차이)', () {
      expect(AppVersionChecker.isVersionLower('1.0.0', '1.0.1'), isTrue);
    });

    test('current == minimum 은 false', () {
      expect(AppVersionChecker.isVersionLower('1.0.0', '1.0.0'), isFalse);
    });

    test('current > minimum', () {
      expect(AppVersionChecker.isVersionLower('2.0.0', '1.9.9'), isFalse);
    });

    test('짧은 버전 문자열 (1.0) 도 0 패딩 처리', () {
      expect(AppVersionChecker.isVersionLower('1.0', '1.0.1'), isTrue);
      expect(AppVersionChecker.isVersionLower('1.0.1', '1.0'), isFalse);
    });

    test('비정상 토큰은 0 으로 취급해도 크래시 없음', () {
      expect(
        () => AppVersionChecker.isVersionLower('abc', '1.0.0'),
        returnsNormally,
      );
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 — 컴파일 실패 확인**

Run: `flutter test test/cores/services/remote_config/app_version_checker_test.dart`
Expected: 컴파일 에러 — `isVersionLower` is not defined (현재 `_isVersionLower` 로 private 하게 정의돼 있음)

- [ ] **Step 3: `_isVersionLower` → `isVersionLower` 공개 + `@visibleForTesting`**

`lib/cores/services/remote_config/app_version_checker.dart` 에서:

1행에 `import 'package:flutter/foundation.dart';` 가 이미 있는지 확인 (있음 — `kDebugMode` 때문)

82행의 메서드 시그니처를 다음과 같이 수정:

```dart
  /// 버전 A가 버전 B보다 낮은지 비교 (semantic versioning)
  ///
  /// 예: isVersionLower('1.2.3', '1.3.0') → true
  ///     isVersionLower('2.0.0', '1.9.9') → false
  ///
  /// `@visibleForTesting` — 내부 로직이지만 유닛 테스트 용도로 공개.
  @visibleForTesting
  static bool isVersionLower(String versionA, String versionB) {
```

그리고 62행과 71행의 호출부도 같이 수정:
- `_isVersionLower(currentVersion, minimumVersion)` → `isVersionLower(currentVersion, minimumVersion)`
- `_isVersionLower(currentVersion, latestVersion)` → `isVersionLower(currentVersion, latestVersion)`

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/cores/services/remote_config/app_version_checker_test.dart`
Expected: `All tests passed!` (7개 테스트)

- [ ] **Step 5: 커밋**

```bash
git add lib/cores/services/remote_config/app_version_checker.dart \
        test/cores/services/remote_config/app_version_checker_test.dart
git commit -m "test: add unit tests for AppVersionChecker.isVersionLower"
```

---

## Task 5: AppDialog 위젯 생성 (Lovable 풀 커스텀)

**Files:**
- Create: `lib/cores/widgets/dialogs/app_dialog.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/cores/widgets/dialogs/app_dialog.dart
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';

/// Lovable 스타일 풀 커스텀 다이얼로그 (Design.md 준수).
///
/// - 배경 cream + 12px radius + lightCream border
/// - 타이틀 cardTitle_32 / 본문 body_16
/// - 확인 버튼: Primary Dark + inset shadow
/// - 취소 버튼: Ghost (charcoal40 border, 투명 배경)
///
/// 정적 API [AppDialog.show] 로만 사용한다.
class AppDialog extends StatelessWidget {
  const AppDialog._({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// 다이얼로그 표시.
  ///
  /// [cancelText] 가 null 이면 확인 버튼만 노출되는 single-button 다이얼로그.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '확인',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AppDialog._(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightCream, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style:
                  AppTextStyles.cardTitle_32.copyWith(color: AppColors.charcoal),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              message,
              style:
                  AppTextStyles.body_16.copyWith(color: AppColors.charcoal82),
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: _GhostButton(
                      label: cancelText!,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: _PrimaryDarkButton(
                    label: confirmText,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryDarkButton extends StatelessWidget {
  const _PrimaryDarkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            // 상단 하이라이트
            BoxShadow(
              color: AppColors.insetHighlight,
              offset: Offset(0, 0.5),
            ),
            // 외곽 링
            BoxShadow(color: AppColors.insetRing, spreadRadius: 0.5),
            // 하단 드롭
            BoxShadow(
              color: AppColors.insetDrop,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(
          label,
          style:
              AppTextStyles.button_16.copyWith(color: AppColors.offWhite),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.charcoal40, width: 1),
        ),
        child: Text(
          label,
          style:
              AppTextStyles.button_16.copyWith(color: AppColors.charcoal),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/cores/widgets/dialogs/app_dialog.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/cores/widgets/dialogs/app_dialog.dart
git commit -m "feat: add AppDialog with Lovable design system"
```

---

## Task 6: RoutePaths 상수 생성

**Files:**
- Create: `lib/routers/route_paths.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/routers/route_paths.dart
/// 앱 전역 라우트 경로 상수.
///
/// go_router 의 각 [GoRoute.path] 및 `context.go(...)` 이동에서 참조한다.
abstract class RoutePaths {
  RoutePaths._();

  /// 스플래시 (초기 라우트)
  static const String splash = '/';

  /// 홈
  static const String home = '/home';

  /// 점검 안내 (풀스크린 차단)
  static const String maintenance = '/maintenance';

  /// 강제 업데이트 (풀스크린 차단)
  static const String forceUpdate = '/force-update';
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/routers/route_paths.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/routers/route_paths.dart
git commit -m "feat: add RoutePaths constants"
```

---

## Task 7: SplashPage 생성

**Files:**
- Create: `lib/features/splash/splash_page.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/features/splash/splash_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/services/remote_config/app_version_checker.dart';
import '../../cores/services/remote_config/update_dialog_helper.dart';
import '../../routers/route_paths.dart';

/// 스플래시 + 부트스트랩 게이트.
///
/// - 배경은 cream, 중앙에 `assets/splash.svg` 를 꽉 차지 않게 표시
/// - first frame 렌더 후 버전 체크 실행
/// - 결과에 따라 maintenance/forceUpdate 페이지로 이동하거나
///   optional/recommend 다이얼로그를 표시 후 home 으로 이동
/// - 예외 발생 시 fail-open 으로 home 진입
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final result = await AppVersionChecker.check();
      if (!mounted) return;
      final canProceed =
          await UpdateDialogHelper.handleResult(context, result);
      if (!mounted) return;
      if (canProceed) {
        context.go(RoutePaths.home);
      }
      // canProceed == false 인 경우 handleResult 내부에서 이미 라우팅 완료.
    } catch (e, s) {
      // 체크 실패 시에도 앱 흐름이 막히지 않도록 home 으로 진행.
      debugPrint('⚠️ Splash bootstrap failed: $e\n$s');
      if (!mounted) return;
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: SvgPicture.asset(
          'assets/splash.svg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/features/splash/splash_page.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/splash/splash_page.dart
git commit -m "feat: add SplashPage with post-frame version check"
```

---

## Task 8: MaintenancePage 생성

**Files:**
- Create: `lib/features/maintenance/maintenance_page.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/features/maintenance/maintenance_page.dart
import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/services/remote_config/remote_config_service.dart';

/// 점검 안내 풀스크린.
///
/// `PopScope(canPop: false)` 로 뒤로가기 차단.
/// `RemoteConfigService.maintenanceMessage` 가 비어있으면 기본 문구 사용.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = RemoteConfigService.instance.maintenanceMessage;
    final message = raw.isEmpty
        ? '더 좋은 서비스로 찾아올게요.\n잠시만 기다려주세요.'
        : raw;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '점검 중이에요',
                    style: AppTextStyles.subHeading_48
                        .copyWith(color: AppColors.charcoal),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    message,
                    style: AppTextStyles.body_16
                        .copyWith(color: AppColors.charcoal82),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/features/maintenance/maintenance_page.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/maintenance/maintenance_page.dart
git commit -m "feat: add MaintenancePage"
```

---

## Task 9: ForceUpdatePage 생성

**Files:**
- Create: `lib/features/force_update/force_update_page.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/features/force_update/force_update_page.dart
import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/constants/app_urls.dart';
import '../../cores/utils/url_launcher_util.dart';

/// 강제 업데이트 풀스크린.
///
/// `PopScope(canPop: false)` 로 뒤로가기 차단.
/// "업데이트" 버튼은 `AppUrls.storeUrl` 로 외부 브라우저 이동.
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '업데이트 필요',
                    style: AppTextStyles.subHeading_48
                        .copyWith(color: AppColors.charcoal),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    '원활한 사용을 위해\n최신 버전으로 업데이트해주세요.',
                    style: AppTextStyles.body_16
                        .copyWith(color: AppColors.charcoal82),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _UpdateButton(
                    onPressed: () => launchExternalUrl(AppUrls.storeUrl),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateButton extends StatelessWidget {
  const _UpdateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: AppColors.insetHighlight,
              offset: Offset(0, 0.5),
            ),
            BoxShadow(color: AppColors.insetRing, spreadRadius: 0.5),
            BoxShadow(
              color: AppColors.insetDrop,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(
          '업데이트',
          style:
              AppTextStyles.button_16.copyWith(color: AppColors.offWhite),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/features/force_update/force_update_page.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/force_update/force_update_page.dart
git commit -m "feat: add ForceUpdatePage"
```

---

## Task 10: HomePage 플레이스홀더 생성

**Files:**
- Create: `lib/features/home/home_page.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/features/home/home_page.dart
import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_text_style.dart';

/// 홈 플레이스홀더.
///
/// 실제 홈 feature 는 별도 브랜치/플랜에서 구축 예정.
/// 현재는 cream 배경 + "Gridset" 로고 텍스트만.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.lightCream, width: 1),
        ),
      ),
      body: Center(
        child: Text(
          'Gridset',
          style: AppTextStyles.displayAlt_80
              .copyWith(color: AppColors.charcoal),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/features/home/home_page.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/home/home_page.dart
git commit -m "feat: add HomePage placeholder"
```

---

## Task 11: AppRouter 생성

**Files:**
- Create: `lib/routers/app_router.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/routers/app_router.dart
import 'package:go_router/go_router.dart';

import '../cores/utils/custom_page_transitions.dart';
import '../features/force_update/force_update_page.dart';
import '../features/home/home_page.dart';
import '../features/maintenance/maintenance_page.dart';
import '../features/splash/splash_page.dart';
import 'route_paths.dart';

/// 앱 전역 GoRouter.
///
/// 전환 애니메이션 원칙:
/// - Splash / Maintenance / ForceUpdate: `buildInstantTransition` (부트스트랩 흐름 — 애니메이션 불필요)
/// - Home: `buildDirectionalSlide(isForward: true)` (일반 forward 이동)
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      pageBuilder: (context, state) => buildInstantTransition(
        key: state.pageKey,
        child: const SplashPage(),
      ),
    ),
    GoRoute(
      path: RoutePaths.home,
      pageBuilder: (context, state) => buildDirectionalSlide(
        key: state.pageKey,
        isForward: true,
        child: const HomePage(),
      ),
    ),
    GoRoute(
      path: RoutePaths.maintenance,
      pageBuilder: (context, state) => buildInstantTransition(
        key: state.pageKey,
        child: const MaintenancePage(),
      ),
    ),
    GoRoute(
      path: RoutePaths.forceUpdate,
      pageBuilder: (context, state) => buildInstantTransition(
        key: state.pageKey,
        child: const ForceUpdatePage(),
      ),
    ),
  ],
);
```

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/routers/app_router.dart`
Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/routers/app_router.dart
git commit -m "feat: add GoRouter with custom page transitions"
```

---

## Task 12: update_dialog_helper.dart import 경로 수정

**Files:**
- Modify: `lib/cores/services/remote_config/update_dialog_helper.dart`

현재 상태 (2행):
```dart
import '../../../router/route_paths.dart';
```

프로젝트 폴더는 `lib/routers/` (복수형) 이므로 수정 필요.

- [ ] **Step 1: import 경로 수정**

`lib/cores/services/remote_config/update_dialog_helper.dart` 4행을:

기존:
```dart
import '../../../router/route_paths.dart';
```

수정 후:
```dart
import '../../../routers/route_paths.dart';
```

- [ ] **Step 2: 전체 프로젝트 analyze**

Run: `flutter analyze`
Expected: `No issues found!`

(모든 이전 task 의 파일이 이 시점에 모두 존재하므로 완전 컴파일 가능)

- [ ] **Step 3: 커밋**

```bash
git add lib/cores/services/remote_config/update_dialog_helper.dart
git commit -m "fix: correct route_paths import path in update_dialog_helper"
```

---

## Task 13: pubspec.yaml 에 splash.svg asset 추가

**Files:**
- Modify: `pubspec.yaml`

현재 assets 블록 (56-57행):
```yaml
  assets:
    - .env
```

- [ ] **Step 1: assets 리스트에 splash.svg 추가**

`pubspec.yaml` 의 `flutter.assets` 블록을 다음과 같이 수정:

기존:
```yaml
  assets:
    - .env
```

수정 후:
```yaml
  assets:
    - .env
    - assets/splash.svg
```

- [ ] **Step 2: pub get 실행**

Run: `flutter pub get`
Expected: `Got dependencies!`

- [ ] **Step 3: 커밋**

```bash
git add pubspec.yaml
git commit -m "chore: register splash.svg as Flutter asset"
```

---

## Task 14: main.dart 재작성 (Firebase + ScreenUtil + Router 부트스트랩)

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: 전체 내용 교체**

`lib/main.dart` 의 전체 내용을 아래로 교체:

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cores/services/remote_config/remote_config_service.dart';
import 'firebase_options.dart';
import 'routers/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 로드 — 없어도 앱은 동작해야 하므로 실패 시 경고만.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env load failed (ignored): $e');
  }

  // Firebase 초기화 — 실패 시 Remote Config 불가하지만 앱 자체는 기동 가능 (fail-open).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await RemoteConfigService.instance.initialize();
  } catch (e, s) {
    debugPrint('⚠️ Firebase/RemoteConfig init failed: $e\n$s');
  }

  runApp(const ProviderScope(child: GridsetApp()));
}

class GridsetApp extends StatelessWidget {
  const GridsetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // iPhone 16 Pro 기준 — Design.md 의 MoneygraphyPixel 16px 그리드와 자연스럽게 정렬.
      designSize: const Size(393, 852),
      minTextAdapt: true,
      child: MaterialApp.router(
        title: 'Gridset',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
```

- [ ] **Step 2: 전체 analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: 전체 테스트 실행**

Run: `flutter test`
Expected: `All tests passed!` (Task 4 에서 추가한 7개 포함)

- [ ] **Step 4: 커밋**

```bash
git add lib/main.dart
git commit -m "feat: wire Firebase + ScreenUtil + GoRouter in main bootstrap"
```

---

## Task 15: 최종 검증 — 빌드 + 시뮬레이터 부팅 확인

**Files:** (없음 — 검증만)

- [ ] **Step 1: analyze 최종 통과**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: 전체 테스트 최종 통과**

Run: `flutter test`
Expected: `All tests passed!` (최소 7개)

- [ ] **Step 3: iOS 시뮬레이터 기동 확인 (가능한 경우)**

Run: `flutter run -d "iPhone 16 Pro"` (또는 사용 가능한 iOS 시뮬레이터)
Expected:
- 스플래시 화면 (`assets/splash.svg` 중앙, cream 배경) 노출
- 몇 초 뒤 Home 화면 (AppBar + "Gridset" 텍스트) 로 전환
- Debug 모드이므로 `AppVersionChecker` 가 즉시 `upToDate` 반환 → 다이얼로그 없음
- Remote Config 값은 debug 콘솔에서 `📱 현재 앱 버전: ...` 로그로 확인

- [ ] **Step 4: Android 에뮬레이터 기동 확인 (가능한 경우)**

Run: `flutter run -d emulator-5554` (또는 사용 가능한 Android 에뮬레이터)
Expected: iOS 와 동일한 흐름.

- [ ] **Step 5: Release 모드 버전 체크 경로 수동 확인 (선택, 스킵 가능)**

Firebase 콘솔에서 `minimum_version` 을 `99.0.0` 으로 세팅 후:

Run: `flutter run --release -d "iPhone 16 Pro"`
Expected:
- `force_update: false` → optional 업데이트 다이얼로그 (cream + charcoal 버튼) 표시 → "나중에" 누르면 home 진입
- `force_update: true` 로 바꾸면 ForceUpdatePage 풀스크린 표시, 뒤로가기 차단

확인 후 `minimum_version` 을 `1.0.0` 으로 되돌려 둘 것.

- [ ] **Step 6: 검증 완료 커밋 (선택 — 추가 변경 있을 때만)**

변경 사항이 없으면 스킵.

---

## Self-Review 메모 (작성자)

1. **Spec coverage**:
   - §5.1 신규 파일 10개 → Task 1/2/3/5/6/7/8/9/10/11 (총 10개) ✅
   - §5.2 수정 파일 3개 → Task 12/13/14 ✅
   - §4.1 Feature 구조(단일 파일) → Task 7-10 ✅
   - §6 부트스트랩 플로우 → Task 14 ✅
   - §6.1 fail-open 에러 처리 → Task 14 (try/catch) + Task 7 (SplashPage try/catch) ✅
   - §7 AppDialog 스펙 → Task 5 ✅
   - §7.4 MaintenancePage → Task 8 ✅
   - §7.5 ForceUpdatePage → Task 9 ✅
   - §7.6 SplashPage → Task 7 ✅
   - §7.7 HomePage → Task 10 ✅
   - §9 테스트 (isVersionLower 유닛) → Task 4 ✅
2. **Placeholder scan**: 모든 step 에 구체 코드/명령어/기대 출력 포함. "TBD"/"나중에"/"적절한 에러 처리" 없음. ✅
3. **Type consistency**: `AppDialog.show`, `AppVersionChecker.isVersionLower`, `appRouter`, `RoutePaths.*` 등 모두 Task 간 일관된 이름 사용. ✅
4. **추가 변경**: Task 4 에서 `_isVersionLower` → `isVersionLower` 공개 (spec §9 의 유닛 테스트 요구사항을 만족시키기 위해 필수). Spec §5.2 에는 없던 수정 파일이지만 같은 파일의 최소 변경이고 테스트 가능성을 위한 것이라 plan 에 포함.
