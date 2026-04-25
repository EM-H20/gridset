# Core UI Primitives v1 — Design Spec

**Date:** 2026-04-25
**Scope:** `AppButton`, `AppIconButton`, `AppTopBar` — 화면 1·2·3(홈/제안/에디터) 구현 전 공용 컴포넌트 도출
**Source mockups:** `~/Documents/project_doc/GridSet/{1,2,3}.png`
**Design rules:** `.claude/rules/Design.md` (Lovable-inspired warm-cream system)

---

## 1. 결정 요약

| 항목 | 결정 | 근거 |
| --- | --- | --- |
| 스코프 | 핵심 primitive 3개만 (Button / IconButton / TopBar) | 3 화면 모두 등장 확정. 나머지(Pill, PageIndicator 등)는 화면 구현하면서 필요 시 추가 (YAGNI) |
| API 패턴 | Named constructors | Flutter 표준 패턴 일치, variant별 파라미터 강제 가능 |
| 테마 | 단일 cream 테마 | Design.md에 dark mode 미정의, 모든 mockup이 cream 단일 톤 |
| Radius | 6px (Design.md 준수) | 사용자 지시 "rules에 있는 디자인 철학 적용" |
| 이모지 | UI 전체 금지, 아이콘만 사용 | 사용자 지시 정책 |
| Inset shadow | 외부 drop + 0.5px 링만 (top highlight 생략) | Flutter는 CSS inset shadow 비지원, 모바일 고DPI에서 시각 차이 미미 |

---

## 2. 아키텍처

### 파일 배치

```
lib/cores/widgets/
├── buttons/
│   ├── app_button.dart
│   └── app_icon_button.dart
└── app_bars/
    └── app_top_bar.dart
```

### 의존성 규칙

모든 primitive 위젯은 다음 규칙을 준수한다:

- **색**: `AppColors.*` 만 사용. raw hex (`Color(0xFF...)`) 금지
- **텍스트 스타일**: `AppTextStyles.*` 만 사용. raw `fontSize` / `fontFamily` 금지
- **간격/사이즈**: `AppSpacing.*` + flutter_screenutil(`.sp`/`.w`/`.h`) 조합. raw double 금지
  - 예외: 1~2px 미세값 (border width, micro radius) 직접 허용
- **Material 위젯 직접 사용 금지**: `ElevatedButton`, `IconButton` 등은 우리 wrapper(AppButton/AppIconButton)를 통해서만 사용

---

## 3. AppButton

### API

```dart
class AppButton extends StatelessWidget {
  // Primary (charcoal filled, optional leading icon)
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
  }) : _variant = _AppButtonVariant.primary;

  // Outlined (transparent + charcoal40 border)
  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.isFullWidth = true,
  }) : _variant = _AppButtonVariant.outlined,
       icon = null;

  final String label;
  final VoidCallback? onPressed;   // null = disabled
  final IconData? icon;             // primary only
  final bool isFullWidth;
  final _AppButtonVariant _variant;
}
```

### 스타일 매트릭스

| 속성 | Primary | Outlined |
| --- | --- | --- |
| Background | `AppColors.charcoal` | `Colors.transparent` |
| Text color | `AppColors.offWhite` | `AppColors.charcoal` |
| Border | `Border.all(width: 0.5, color: AppColors.insetRing)` | `Border.all(width: 1, color: AppColors.charcoal40)` |
| Padding | `EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.base)` | 동일 |
| Radius | `BorderRadius.circular(6)` | 동일 |
| Text style | `AppTextStyles.button_16.copyWith(color: <위 텍스트색>)` | 동일 |
| Shadow | `[BoxShadow(color: AppColors.insetDrop, offset: Offset(0, 1), blurRadius: 2)]` | 없음 |
| Pressed (active) | opacity 0.8 | 동일 |
| Disabled (`onPressed == null`) | opacity 0.4 | 동일 |
| Tap 피드백 구현 | `Material` + `InkWell` (cream 배경 위 ripple) | 동일 |

### 너비 처리

- `isFullWidth: true` (기본): 부모 가용 폭 가득 채움
- `isFullWidth: false`: `IntrinsicWidth` — 라벨 길이만큼
- 좌우 분할 레이아웃(예: "다른 제안" / "빈 캔버스")은 호출부에서 `Row` + `Expanded` 책임 — 버튼은 관여 안 함

### Inset shadow 구현 방침

Design.md 시그니처(3-layer inset)를 다음으로 근사:

| Layer | 구현 | 처리 |
| --- | --- | --- |
| 외부 drop (`rgba(0,0,0,0.05)`) | `BoxShadow` | ✅ 정확히 재현 (`AppColors.insetDrop`) |
| 0.5px inset 링 (`rgba(0,0,0,0.2)`) | `Border.all(width: 0.5)` | ✅ 근사 (`AppColors.insetRing`) |
| 0.5px top highlight (`rgba(255,255,255,0.2)`) | — | ❌ 생략 (모바일 고DPI 시각 차이 미미) |

`AppColors`에 3 토큰 모두 정의돼 있어 v2에서 top highlight 추가 시 비용 0.

---

## 4. AppIconButton

### API

```dart
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;              // 외곽 원 지름 (.w 내부 적용)
  final String? semanticLabel;    // 접근성 (예: '뒤로 가기')
}
```

### 스타일

| 속성 | 값 |
| --- | --- |
| Shape | 원형 — `BorderRadius.circular(size / 2)` |
| Background | `Colors.transparent` |
| Border | `Border.all(width: 1, color: AppColors.charcoal40)` |
| Icon color | `AppColors.charcoal` |
| Icon size | `size * 0.45` (예: 40 → 18) — Icon 폰트 그리드는 16배수 규칙 무관 |
| Tap feedback | `InkResponse` + `customBorder: CircleBorder()` |
| Pressed | opacity 0.8 |
| Disabled | opacity 0.4 |

### 의도적 단순화

- **Variant 안 만듦** — 모든 mockup의 원형 아이콘 버튼이 동일 outlined-circle 스타일. Pill bg-filled 형태 미등장 → YAGNI
- **사이즈는 `size` 파라미터 하나** — undo/redo가 약간 작게 보일 수 있으나 36~40 범위는 같은 컴포넌트로 흡수

---

## 5. AppTopBar

### API (3 named constructors)

```dart
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  // 화면 1: 큰 wordmark + 옵션 액션
  const AppTopBar.title({
    super.key,
    required this.title,
    this.trailing,
  }) : _variant = _AppTopBarVariant.titleLeft,
       onBack = null, onMore = null, onClose = null, onSave = null;

  // 화면 2: 뒤로 + 중앙 타이틀 + 더보기
  const AppTopBar.backWithMore({
    super.key,
    required this.title,
    required VoidCallback this.onBack,
    required VoidCallback this.onMore,
  }) : _variant = _AppTopBarVariant.backWithMore,
       trailing = null, onClose = null, onSave = null;

  // 화면 3: 닫기 텍스트버튼 + 중앙 타이틀 + 저장 텍스트버튼
  const AppTopBar.closeWithSave({
    super.key,
    required this.title,
    required VoidCallback this.onClose,
    required this.onSave,    // null = 저장 비활성
  }) : _variant = _AppTopBarVariant.closeWithSave,
       trailing = null, onBack = null, onMore = null;

  final String title;
  final AppIconButton? trailing;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onClose;
  final VoidCallback? onSave;
  final _AppTopBarVariant _variant;

  @override
  Size get preferredSize => Size.fromHeight(64);
}
```

### 공통 스타일

| 속성 | 값 |
| --- | --- |
| Height | `64.h` |
| Background | `AppColors.cream` |
| Border | 없음 |
| 좌우 padding | `EdgeInsets.symmetric(horizontal: AppSpacing.base)` |

### Variant별 레이아웃

| Variant | Leading | Center | Trailing | Title 스타일 |
| --- | --- | --- | --- | --- |
| `.title` | `Text(title)` (left-align, wordmark급) | — | 옵션 `AppIconButton` | `AppTextStyles.cardTitle_32` |
| `.backWithMore` | `AppIconButton(Icons.arrow_back_ios_new)` | `Text(title)` 중앙 | `AppIconButton(Icons.more_horiz)` | `AppTextStyles.body_16` |
| `.closeWithSave` | `TextButton(onPressed: onClose, child: Row[Icon(Icons.close, 18.sp), SizedBox(width: AppSpacing.xs), Text("닫기")])` | `Text(title)` 중앙 | `TextButton(onPressed: onSave, child: Text("저장"))` | `AppTextStyles.body_16` |

### 이모지 정책 적용

목업의 "×" literal 문자는 `Icon(Icons.close)` 위젯으로 대체. UI 텍스트 안에 이모지/특수문자 도형 사용 금지.

### 텍스트 버튼

`closeWithSave`의 "닫기"/"저장"은 별도 컴포넌트 미도입 — 1군데만 등장, 추상화 가치 없음. 내부에서 `TextButton` + `AppTextStyles.body_16` + `AppColors.charcoal`로 처리.

---

## 6. 의존성 추가

이번 spec 범위 안에서 **새 패키지 추가 없음**. 필요 아이콘(`Icons.arrow_back_ios_new`, `Icons.more_horiz`, `Icons.close`, `Icons.image`) 모두 Material에 존재.

화면 구현 단계에서 부족하면 `font_awesome_flutter` 추가 검토 (사용자 확인 후 pubspec 갱신).

---

## 7. 테스팅

### 범위

`test/cores/widgets/` 아래 위젯 테스트 3 파일.

**AppButton (`app_button_test.dart`):**
- `.primary` 라벨/탭/아이콘 렌더링
- `.outlined` 라벨/탭 렌더링
- `onPressed: null` 시 비활성 상태 검증

**AppIconButton (`app_icon_button_test.dart`):**
- 아이콘 렌더링 + 탭 콜백
- `semanticLabel` Semantics 트리 노출
- `onPressed: null` 비활성

**AppTopBar (`app_top_bar_test.dart`):**
- 3 variant 각각 필수 요소 렌더링
- `.backWithMore` 콜백 검증
- `.closeWithSave` `onSave: null` 비활성 검증

### 범위 외

- 골든 테스트 — v2 (디자인 안정화 후)
- 통합/라우팅 테스트 — 화면 단위 spec에서 다룸

### 커버리지 목표

전역 80% 룰 적용. 위 위젯 테스트만으로 도달 가능 (위젯 자체가 단순).

---

## 8. 비범위 (Out of Scope)

이번 spec에서 **하지 않는 것**:

- 화면 1·2·3 구현 — 별도 spec
- AppHintPill, AppPageIndicator, AppGridPreviewCard, AppBottomToolbar, AppDragHandle, AppSectionLabel — 화면 구현 시 필요할 때 추가
- Dark mode / theme variants
- 골든 테스트
- font_awesome_flutter 추가
- Inset shadow의 top highlight layer

---

## 9. Open Questions / 후속 작업

- (없음 — 결정 사항 모두 본 문서에 명시)

후속:
1. 본 spec 승인 → `writing-plans` 스킬로 구현 계획 작성
2. 계획에 따라 TDD로 3개 위젯 구현
3. 화면 1(홈) spec 작성 — 본 primitive 사용 확인
