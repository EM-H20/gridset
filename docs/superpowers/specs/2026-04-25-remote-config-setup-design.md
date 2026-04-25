# Firebase Remote Config 통합 + 앱 부트스트랩 설계

**작성일**: 2026-04-25
**상태**: 승인됨 (사용자 승인 후 구현 플랜으로 전환)
**스코프**: Remote Config 초기화, 버전/점검 게이팅, 부트스트랩 라우팅, 누락 의존성 복원

---

## 1. 배경

`lib/cores/services/remote_config/` 는 다른 프로젝트(copsandrobbers)에서 복사한 3개 파일로 구성돼 있다:

- `remote_config_service.dart` — Firebase Remote Config 싱글톤 (의존성 문제 없음)
- `app_version_checker.dart` — 버전 비교 + 결과 enum (의존성 문제 없음)
- `update_dialog_helper.dart` — 결과별 페이지 이동/다이얼로그 분기 (**의존성 4개 누락**)

현재 gridset 프로젝트는 `main.dart`가 기본 카운터 템플릿이고 라우터·Firebase 부트스트랩·다이얼로그 컴포넌트가 전혀 없다. Firebase Remote Config은 이미 웹 콘솔에서 프로젝트(`gridset-28a66`) 생성 + 5개 파라미터(`minimum_version` / `latest_version` / `force_update` / `maintenance` / `maintenance_message`) 등록이 완료됐고, `flutterfire configure` 로 iOS/Android 설정 파일도 생성된 상태이다.

## 2. 목표

1. `update_dialog_helper.dart` 의 누락 의존성 4개를 gridset 디자인 시스템(Lovable + MoneygraphyPixel 기반 Design.md)에 맞게 신규 생성한다.
2. Firebase Remote Config 초기화와 버전 체크를 앱 부트스트랩 플로우에 연결하여 실제로 동작하는 상태로 만든다.
3. `maintenance` / `forceUpdate` 를 풀스크린 페이지로, `optionalUpdate` / `recommendUpdate` 를 다이얼로그로 처리하는 원본 설계를 그대로 포팅한다.

## 3. 비목표

- 실제 Splash 브랜딩 애니메이션, 홈 화면 기능 구현 (플레이스홀더만)
- `AppUrls` 의 실제 gridset 값 확정 — 현재 스토어 미등록 상태라 copsandrobbers URL을 `// TODO:` 주석과 함께 임시 사용
- Remote Config 파라미터 스키마 확장 (기존 5개 파라미터만 사용)
- 위젯 테스트 (단순 뷰라 YAGNI, 버전 비교 유닛 테스트만 대상)

## 4. 아키텍처 결정

### 4.1 Feature 구조 — Clean Architecture 부분 적용

사용자 선호는 `data / domain / presentation` 분리지만, 이번 스코프 4개 화면(Splash / Maintenance / ForceUpdate / Home 플레이스홀더)은 데이터 소스도 도메인 로직도 없는 단순 뷰다. 단일 파일로 두고, 실제 도메인 로직이 있는 feature가 추가될 때 그 feature부터 3-layer 분리를 시작한다. YAGNI + CLAUDE.md의 "many small files" 원칙.

### 4.2 라우팅 — go_router 풀 도입

`pubspec.yaml` 에 `go_router: ^17.0.1` 이 이미 있고, `maintenance` / `forceUpdate` 를 **뒤로가기가 소비되지 않는 풀스크린 차단 화면**으로 만들려면 라우터가 필요하다. 다이얼로그 only로는 Android 백버튼·iOS 에지 스와이프를 완벽히 막기 어렵다.

### 4.3 폴더명 정규화

- 기존 `lib/routers/` (복수형) 유지 → 복사된 `update_dialog_helper.dart` 의 `../../../router/` 를 `../../../routers/` 로 수정
- `lib/cores/utils/` 생성 (사용자가 언급한 `lib/core/utils/` 는 프로젝트 convention인 `cores/` 에 맞춤)

## 5. 파일 명세

### 5.1 신규 파일 (10개)

| 경로 | 역할 |
| --- | --- |
| `lib/cores/constants/app_urls.dart` | `storeUrl` (Platform 분기), `privacyPolicy`, `termsOfService`, `locationTerms`, `marketingConsent` — 전부 copsandrobbers URL + `// TODO(gridset):` 주석 |
| `lib/cores/utils/url_launcher_util.dart` | `Future<bool> launchExternalUrl(String urlString)` — 외부 브라우저 오픈 |
| `lib/cores/utils/custom_page_transitions.dart` | 사용자 제공 코드 그대로 (buildDirectionalSlide / buildInstantTransition / buildSmoothFade) |
| `lib/cores/widgets/dialogs/app_dialog.dart` | Lovable 풀 커스텀 다이얼로그 — 정적 `AppDialog.show(...)` API |
| `lib/routers/route_paths.dart` | `/`, `/home`, `/maintenance`, `/force-update` 상수 |
| `lib/routers/app_router.dart` | `GoRouter` 인스턴스, 각 Route는 `custom_page_transitions` 활용 |
| `lib/features/splash/splash_page.dart` | 중앙 SVG(`assets/splash.svg`) + cream 배경. initState에서 버전 체크 실행 후 분기 |
| `lib/features/maintenance/maintenance_page.dart` | 점검 안내 풀스크린 (스펙 §7.4) |
| `lib/features/force_update/force_update_page.dart` | 강제 업데이트 풀스크린 (스펙 §7.5) |
| `lib/features/home/home_page.dart` | "Gridset" 텍스트만 보이는 플레이스홀더 |

### 5.2 수정 파일 (3개)

| 경로 | 변경 내용 |
| --- | --- |
| `lib/main.dart` | 전체 재작성. `dotenv` 로드 → `Firebase.initializeApp` → `RemoteConfigService.initialize()` → `runApp(ProviderScope(ScreenUtilInit(MaterialApp.router)))` |
| `lib/cores/services/remote_config/update_dialog_helper.dart` | import 경로 수정: `../../../router/route_paths.dart` → `../../../routers/route_paths.dart`. 나머지 3개 import는 경로 유지 (`../../constants/app_urls.dart`, `../../utils/url_launcher_util.dart`, `../../widgets/dialogs/app_dialog.dart`) |
| `pubspec.yaml` | `flutter.assets` 에 `- assets/splash.svg` 추가 |

## 6. 부트스트랩 플로우

```
main()
 ├─ WidgetsFlutterBinding.ensureInitialized()
 ├─ await dotenv.load(fileName: '.env')
 ├─ await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
 ├─ await RemoteConfigService.instance.initialize()  // fetch는 여기서 완료
 └─ runApp(
      ProviderScope(
        ScreenUtilInit(
          designSize: Size(393, 852),                 // iPhone 16 Pro 기준
          MaterialApp.router(routerConfig: appRouter)
        )
      )
    )

appRouter (initialLocation = '/')
  /                → SplashPage          (buildInstantTransition)
  /home            → HomePage            (buildDirectionalSlide, isForward: true)
  /maintenance     → MaintenancePage     (buildInstantTransition)
  /force-update    → ForceUpdatePage     (buildInstantTransition)

SplashPage.initState → WidgetsBinding.addPostFrameCallback(
  () async {
    final result = await AppVersionChecker.check();
    if (!mounted) return;
    final canProceed = await UpdateDialogHelper.handleResult(context, result);
    if (!mounted) return;
    if (canProceed) context.go('/home');
    // canProceed == false 이면 handleResult 내부에서 이미 maintenance/force-update로 이동 완료
  }
)
```

### 6.1 에러 처리 (fail-open)

- `Firebase.initializeApp` 실패: `runZonedGuarded` 로 잡되 앱은 계속 실행 (Remote Config 없이도 홈 진입 가능)
- `RemoteConfigService.initialize()` 내부 fetch 실패: 이미 try/catch + defaults 적용돼 있음 — 그대로 활용
- `AppVersionChecker.check()` 예외: SplashPage 에서 catch → `VersionCheckResult.upToDate` 취급 후 `/home` 진입

### 6.2 디버그 모드

- `AppVersionChecker.check()` 는 `kDebugMode` 일 때 무조건 `upToDate` 반환 (원본 코드 그대로 유지)
- 개발 중 실수로 Remote Config 가 maintenance/forceUpdate 상태여도 앱 흐름이 막히지 않음

## 7. AppDialog 스펙 (Lovable 풀 커스텀)

### 7.1 정적 API

```dart
AppDialog.show({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = '확인',
  String? cancelText,                  // null이면 single-button
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool barrierDismissible = true,
});
```

### 7.2 비주얼 스펙 (Design.md 준수)

| 요소 | 값 |
| --- | --- |
| 배경 | `AppColors.cream` |
| Border | `1px solid AppColors.lightCream` |
| Radius | 12 (`AppSpacing.md` 사용 X — Lovable Card 규격인 12 고정) |
| Padding | horizontal 24, vertical 20 (Lovable editorial generosity) |
| Inner gap | 16 (title ↔ message ↔ buttons) |
| Title | `AppTextStyles.cardTitle_32` + `AppColors.charcoal` |
| Message | `AppTextStyles.body_16` + `AppColors.charcoal82` |
| Confirm button | 다크 charcoal 배경 + `AppColors.offWhite` 텍스트 + inset shadow (Design.md Primary Dark), padding 8×16, radius 6 |
| Cancel button | 투명 배경 + `1px solid AppColors.charcoal40` border + `AppColors.charcoal` 텍스트, padding 8×16, radius 6 |
| Button row | 둘 다 `Expanded`, 가로 배치, `SizedBox(width: 8)` gap. Single-button이면 `cancelText == null` 시 full-width confirm |

### 7.3 Inset Shadow 구현

```dart
BoxDecoration(
  color: AppColors.charcoal,
  borderRadius: BorderRadius.circular(6),
  boxShadow: [
    // 상단 1px 하이라이트
    BoxShadow(color: AppColors.insetHighlight, offset: Offset(0, 0.5), spreadRadius: 0),
    // 외곽 0.5px 링
    BoxShadow(color: AppColors.insetRing, spreadRadius: 0.5),
    // 하단 드롭
    BoxShadow(color: AppColors.insetDrop, offset: Offset(0, 1), blurRadius: 2),
  ],
)
```

> Note: Flutter의 `BoxShadow` 로 완벽한 inset 재현은 불가 (inset 키워드가 CSS 전용). 위 코드는 "inset 느낌"의 근사치. Design.md 허용 범위 내.

### 7.4 MaintenancePage 스펙

- `Scaffold(backgroundColor: AppColors.cream)` + `PopScope(canPop: false)`
- Center `Column`:
  - Title: `"점검 중이에요"` — `AppTextStyles.subHeading_48` + `AppColors.charcoal`
  - Gap: 24 (`AppSpacing.xl`)
  - Message: `RemoteConfigService.instance.maintenanceMessage.isEmpty ? "더 좋은 서비스로 찾아올게요.\n잠시만 기다려주세요." : maintenanceMessage` — `AppTextStyles.body_16` + `AppColors.charcoal82`, `textAlign: center`
  - 버튼 없음 (유저는 대기만)
- horizontal padding 32

### 7.5 ForceUpdatePage 스펙

- `Scaffold(backgroundColor: AppColors.cream)` + `PopScope(canPop: false)`
- Center `Column`:
  - Title: `"업데이트 필요"` — `AppTextStyles.subHeading_48` + `AppColors.charcoal`
  - Gap: 24
  - Message: `"원활한 사용을 위해\n최신 버전으로 업데이트해주세요."` — `AppTextStyles.body_16` + `AppColors.charcoal82`, center
  - Gap: 32 (`AppSpacing.xxl`)
  - Primary Dark 버튼 (`AppDialog` 확인 버튼과 동일 스펙): `"업데이트"` → `launchExternalUrl(AppUrls.storeUrl)` — `AppTextStyles.button_16` + `AppColors.offWhite`
- horizontal padding 32

### 7.6 SplashPage 스펙

- `Scaffold(backgroundColor: AppColors.cream)` (SVG 배경색 `#F7F4ED` 와 동일하게 이음매 없이 표시)
- Center: `SvgPicture.asset('assets/splash.svg')` — SVG 원본 비율(1400×400) 유지
- 상태 위젯 없음. `initState` 에서 post-frame callback 으로 버전 체크 → 라우팅. 체크 중에는 SVG만 보임.

### 7.7 HomePage 플레이스홀더

- `Scaffold(backgroundColor: AppColors.cream, appBar: AppBar(...))`
- Center: `Text("Gridset", style: AppTextStyles.displayAlt_80)`
- AppBar는 Design.md 준수 (cream bg, 하단 border `1px lightCream`, 타이틀 없음 또는 16px)

## 8. Remote Config 파라미터 (사용자 등록 완료 확인)

| Key | Type | 기본값 | 용도 |
| --- | --- | --- | --- |
| `minimum_version` | String | `"1.0.0"` | 이 버전 미만은 optional/force 업데이트 대상 |
| `latest_version` | String | `"1.0.0"` | 이 버전 미만은 recommend (권고) 대상 |
| `force_update` | bool | `false` | true + `minimum_version` 미만이면 forceUpdate (차단) |
| `maintenance` | bool | `false` | true면 maintenance 페이지로 강제 이동 |
| `maintenance_message` | String | `""` | 점검 안내 하단 문구 (빈 문자열이면 기본 메시지) |

## 9. 테스트 전략

- **대상**: `AppVersionChecker._isVersionLower` — 버전 비교 로직 (유닛)
- **Case**: 같음, major/minor/patch 각 자리별 낮음/높음, 비정상 문자열
- **위젯 테스트**: 스킵 (플레이스홀더 수준이라 의미 적음)
- **커버리지**: 글로벌 규칙 80%는 이번 스코프에서 유닛 대상만 집계

## 10. 오픈 이슈

- **`ScreenUtilInit.designSize`**: iPhone 16 Pro 기준인 `Size(393, 852)` 로 확정.
- **스토어 URL**: 배포 시점에 `AppUrls.storeUrl` 만 교체 (iOS App Store ID + Android package `com.innocare.gridset`).

## 11. 참고

- Design.md (`/.claude/rules/Design.md`)
- CLAUDE.md (프로젝트 루트)
- 복사 원본: copsandrobbers 프로젝트 `lib/cores/services/remote_config/*`
