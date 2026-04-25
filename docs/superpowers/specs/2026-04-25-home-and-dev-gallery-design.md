# Home Screen + Dev Component Gallery v1 — Design Spec

**Date:** 2026-04-25
**Scope:** 홈 화면(`/home`) 본 구현 + Dev 컴포넌트 갤러리(`/dev`) — 첫 사용자 화면 동작 가능 + 컴포넌트 시각 검증 환경
**Source mockups:** `~/Documents/project_doc/GridSet/1.png` (홈)
**Depends on:** `docs/superpowers/specs/2026-04-25-core-ui-primitives-design.md` (AppButton/AppIconButton/AppTopBar 사용)

---

## 1. 결정 요약

| 항목 | 결정 | 근거 |
| --- | --- | --- |
| 진행 순서 | 홈만 먼저 → 제안 → 에디터 | 화면 독립성 높음, 첫 결과물 빠르게 검증 |
| Debug 진입점 | 홈 우상단 십자 아이콘을 `kDebugMode`에서 `/dev` 라우트로 | 디자인 변경 0, release 빌드에선 onPressed null |
| "이어서 만들기" 섹션 | **이번 spec 에선 미도입** | 에디터 없어 드래프트 생성 불가 → 빈 리스트 고정 → 도달 불가 코드. 화면 3 끝난 후 도입 |
| CTA 동작 | SnackBar stub ("준비 중") + debug log | `/suggestion` 라우트 미존재. 화면 2 spec 들어오면 `context.go(suggestion)` 한 줄 교체 |
| Icon size 통일 | `Icons.close` / `Icons.image` 의 `18.sp` → `16.sp` | Design.md 16-배수 정신 + 본문 `16.sp` 와 시각 정합 |
| Dev 갤러리 라우트 | `/dev` 항상 등록, 진입은 `kDebugMode` 게이트 | 라우트 자체는 등록되어야 deep-link 디버깅 가능 |

---

## 2. 아키텍처

### 파일 배치

```
lib/
├── features/
│   ├── home/
│   │   └── home_page.dart                    # 재작성 (placeholder 교체)
│   └── dev/
│       ├── dev_gallery_page.dart
│       └── widgets/
│           ├── gallery_section.dart          # 제목 + 카드 컨테이너
│           └── color_swatch.dart             # 색상 스왓치 (이름 + hex 라벨)
└── routers/
    ├── app_router.dart                        # /dev 라우트 추가
    └── route_paths.dart                       # RoutePaths.dev 추가
```

### 의존성 규칙 (전 spec 동일)

- 색·텍스트·간격 모두 `AppColors` / `AppTextStyles` / `AppSpacing` 만 사용
- UI 텍스트에 이모지 0건 — `IconData` 만
- `flutter_screenutil` `.sp` / `.w` / `.h` 일관 사용
- 전역 primitive (AppButton/AppIconButton/AppTopBar) 만 사용 — Material 위젯 직접 호출 금지
  - **레이아웃 예외:** `Scaffold`, `SafeArea`, `ListView`, `Column`, `Row`, `SizedBox`, `Padding`, `Container`, `Stack`
  - **인프라 예외:** `ScaffoldMessenger` + `SnackBar` (전역 토스트), `Semantics`, `Icon`, `Text`

---

## 3. 18.sp → 16.sp 정리 (선행 작업)

본 spec 의 **첫 작업**으로, primitive v1 에서 미해결로 둔 `18.sp` icon size 를 `16.sp` 로 통일한다.

**대상:**
- `lib/cores/widgets/app_bars/app_top_bar.dart` — `Icon(Icons.close, ..., size: 18.sp)` → `16.sp`
- `lib/cores/widgets/buttons/app_button.dart` — `Icon(widget.icon, ..., size: 18.sp)` → `16.sp`

**근거:** Design.md §3 의 16-배수 규칙은 fontSize 중심이지만, icon 사이즈가 본문 16.sp 와 어긋나면 시각 일관성 깨짐. `18.sp` 자체가 Design.md 어디에도 명시 없음 (구현 임의값).

> 위 변경은 기존 위젯 테스트 결과에 영향 없음 (사이즈만 변경). 별도 테스트 추가 불필요.

---

## 4. 홈 화면 (`/home`)

### 레이아웃

```
Scaffold (backgroundColor: AppColors.cream)
├── appBar: AppTopBar.title(
│             title: 'Gridset',
│             trailing: _DebugEntryButton,    // private widget
│           )
└── body: SafeArea
        └── Padding (horizontal: AppSpacing.base)
            └── Column (crossAxisAlignment: stretch)
                ├── SizedBox(height: AppSpacing.xxxl)              # 48
                ├── Text("오늘은\n뭐 모아볼까?",
                │     style: AppTextStyles.subHeading_48
                │              .copyWith(color: AppColors.charcoal))
                ├── SizedBox(height: AppSpacing.xxxl)              # 48
                ├── AppButton.primary(
                │     label: '사진·영상 고르기',
                │     icon: Icons.image,
                │     onPressed: () => _showStubSnackBar(context),
                │   )
                ├── SizedBox(height: AppSpacing.md)                # 12
                ├── AppButton.outlined(
                │     label: '비율 먼저 정하기',
                │     onPressed: () => _showStubSnackBar(context),
                │   )
                # HomeDraftsSection 은 본 spec 에서 제외 (화면 3 후 도입)
```

### `_DebugEntryButton`

```dart
// 홈 우상단 십자 아이콘. kDebugMode 일 때만 /dev 진입.
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

> Release 빌드: `onPressed: null` → 버튼 disabled (opacity 0.4). 추후 본래 의도(센터/포커스) 정해지면 onPressed 교체.

### `_showStubSnackBar`

```dart
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
```

---

## 5. Dev 컴포넌트 갤러리 (`/dev`)

### 라우트

```dart
// route_paths.dart
static const String dev = '/dev';

// app_router.dart 의 routes 배열에 추가
GoRoute(
  path: RoutePaths.dev,
  pageBuilder: (context, state) => buildDirectionalSlide(
    key: state.pageKey,
    child: const DevGalleryPage(),
  ),
),
```

### 페이지 구조

```
Scaffold (backgroundColor: AppColors.cream)
├── appBar: AppTopBar.backWithMore(
│             title: 'Components',
│             onBack: () => context.go(RoutePaths.home),
│             onMore: () {},                          // v1 placeholder (no-op + debug log)
│           )
└── body: SafeArea
        └── ListView.separated(
              padding: EdgeInsets.all(AppSpacing.base.w),
              itemCount: 5,
              separatorBuilder: (_, __) => SizedBox(height: AppSpacing.xl.h),
              itemBuilder: (context, i) => switch(i) {
                0 => GallerySection('AppButton', ...),
                1 => GallerySection('AppIconButton', ...),
                2 => GallerySection('AppTopBar', ...),
                3 => GallerySection('Colors (AppColors)', ...),
                4 => GallerySection('Typography (AppTextStyles)', ...),
                _ => SizedBox.shrink(),
              },
            )
```

### `GallerySection`

```dart
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
          ...children.map((c) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                child: c,
              )),
        ],
      ),
    );
  }
}
```

### 갤러리 콘텐츠 명세

각 아이템은 작은 라벨(`AppTextStyles.caption_16` color charcoal82) + 위젯 본체.

**AppButton 섹션:**
1. `primary (full, with icon)` — `AppButton.primary(label: '사진·영상 고르기', icon: Icons.image, onPressed: () {})`
2. `primary (full, no icon)` — `AppButton.primary(label: '이걸로', onPressed: () {})`
3. `primary (auto-width, Row of 2 with Expanded)` — `Row[Expanded(AppButton.primary(label:'다른 제안', isFullWidth: false)), gap, Expanded(AppButton.primary(label:'빈 캔버스', isFullWidth: false))]`
4. `primary (disabled)` — `AppButton.primary(label:'비활성', onPressed: null)`
5. `outlined (full)` — `AppButton.outlined(label: '비율 먼저 정하기', onPressed: () {})`
6. `outlined (Row of 2)` — 동일 패턴
7. `outlined (disabled)` — `AppButton.outlined(label:'비활성', onPressed: null)`

**AppIconButton 섹션:**
1. `default (size: 40)` — `AppIconButton(icon: Icons.arrow_back_ios_new, onPressed: () {})`
2. `small (size: 32, hit area still 44pt)` — `AppIconButton(icon: Icons.close, onPressed: () {}, size: 32)`
3. `disabled` — `AppIconButton(icon: Icons.more_horiz, onPressed: null)`
4. `with semanticLabel` — `AppIconButton(icon: Icons.gps_fixed, onPressed: () {}, semanticLabel: '센터')`

**AppTopBar 섹션:**
각 항목은 `Container(border)` 안에 변형 배치 (preferredSize 적용 안 됨 — 시각 비교용):
1. `.title with trailing` — `AppTopBar.title(title: 'Gridset', trailing: AppIconButton(icon: Icons.gps_fixed, onPressed: () {}))`
2. `.backWithMore` — `AppTopBar.backWithMore(title: '제안 1/3', onBack: () {}, onMore: () {})`
3. `.closeWithSave (active)` — `AppTopBar.closeWithSave(title: 'Gridset', onClose: () {}, onSave: () {})`
4. `.closeWithSave (save disabled)` — `AppTopBar.closeWithSave(title: 'Gridset', onClose: () {}, onSave: null)`

**Colors 섹션** (`ColorSwatch` grid, 4 col × n row):
- cream / charcoal / offWhite
- charcoal83 / charcoal82 / charcoal40 / charcoal04 / charcoal03
- mutedGray / lightCream / ringBlue
- shadowFocus / insetHighlight / insetRing / insetDrop

**Typography 섹션** (각 스타일별 한 줄 샘플 — 한글 한국어 텍스트 사용):
- displayHero_96 — "Gridset"
- displayAlt_80 — "Gridset"
- sectionHeading_64 — "오늘은"
- subHeading_48 — "오늘은 뭐 만들까?"
- cardTitle_32 — "이어서 만들기"
- bodyLarge_32 — "큰 본문 텍스트"
- body_16 — "표준 본문 텍스트입니다"
- button_16 — "버튼 라벨"
- link_16 — "링크 텍스트"
- caption_16 — "캡션·메타데이터"

> displayHero_96 / displayAlt_80 같은 매우 큰 사이즈는 한 줄 안 들어갈 수 있음 → `Container(constraints: BoxConstraints(maxHeight: 120.h))` 으로 시각 클립 허용 + 필요 시 `FittedBox(fit: BoxFit.scaleDown)`.

### `ColorSwatch`

```dart
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
        Text(name, style: AppTextStyles.caption_16.copyWith(color: AppColors.charcoal82)),
      ],
    );
  }
}
```

---

## 6. 라우팅 변경

### `route_paths.dart`

```dart
abstract class RoutePaths {
  RoutePaths._();
  static const String splash = '/';
  static const String home = '/home';
  static const String maintenance = '/maintenance';
  static const String forceUpdate = '/force-update';
  static const String dev = '/dev';   // 추가
}
```

### `app_router.dart`

기존 `routes` 배열 끝에 `/dev` GoRoute 추가. `buildDirectionalSlide` 사용 (forward 슬라이드 — 일반 navigation 흐름).

---

## 7. 데이터

이번 spec 에서 도입하는 상태/모델 **없음**.
- 드래프트 모델: 화면 3 spec 에서 도입
- Riverpod provider: 도입 사유 없음 (홈은 정적 + CTA stub, 갤러리는 정적)
- 로컬 저장: 미사용

---

## 8. 테스팅

### 위젯 테스트 (필수)

`test/features/home/home_page_test.dart`:
- 헤딩 "오늘은 뭐 모아볼까?" 텍스트 렌더링
- 두 CTA 라벨 렌더링
- "사진·영상 고르기" tap → SnackBar "다음 화면 준비 중" 표시
- "비율 먼저 정하기" tap → SnackBar 표시
- 우상단 디버그 진입 버튼 렌더링 (kDebugMode 가정)

`test/features/dev/dev_gallery_page_test.dart`:
- 페이지 렌더링 (5개 GallerySection 모두 보임)
- `AppTopBar.backWithMore` 의 back 탭 → 라우터 호출 검증 (mock router)

### 범위 외

- DevGalleryPage 내 모든 위젯 인스턴스 개별 테스트 (시각 검증이 본질)
- GallerySection / ColorSwatch 단위 테스트 (단순 위젯)
- Golden 테스트 — v2

### 커버리지 목표

전역 80% 룰. 홈 페이지는 단순하므로 위 테스트만으로 충분 도달.

---

## 9. Out of Scope

- 화면 2 (제안) / 화면 3 (에디터) — 별도 spec
- 드래프트 데이터 모델 / 로컬 저장
- "이어서 만들기" 섹션 — 화면 3 끝나고 도입
- 다국어 / accessibility hint 추가 보강
- Dev 갤러리의 dark mode 토글 / 디바이스 프레임 미리보기 — v2

---

## 10. Open Questions / 후속

(없음 — 본 spec 의 모든 결정 사항 명시 완료)

후속:
1. 본 spec 승인 → `writing-plans` 로 구현 plan 작성
2. plan 따라 SDD (subagent-driven-development) 로 실행
3. 화면 2 (제안) spec 작성 시 본 spec 의 라우팅/CTA stub 패턴 재사용
