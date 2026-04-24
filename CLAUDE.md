# gridset

Flutter 앱 프로젝트. 모든 커뮤니케이션은 **한국어**.

## 참조 문서 (먼저 확인)

- **디자인 시스템**: `.claude/rules/Design.md`
- **글로벌 규칙**: `~/.claude/rules/*.md` (coding-style / testing / git-workflow / security / code-review)

> 이 파일은 프로젝트 고유 규칙만 담는다. 공통 규칙은 위 참조 파일을 따른다.

## Tech Stack

- **Flutter** (Dart SDK `^3.9.2`)
- **상태 관리**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **데이터 모델**: Freezed + `json_serializable`
- **라우팅**: `go_router`
- **로컬 저장소**: `shared_preferences`
- **환경 변수**: `flutter_dotenv` (`.env`)
- **Firebase**: `firebase_core`, `firebase_remote_config`
- **UI**: `flutter_screenutil`, `flutter_svg`, `animations`

## 앱 상수 (무조건 사용 — 하드코딩 금지)

모든 색상/간격/타이포는 `lib/cores/constants/` 에서만 참조한다. Widget/화면 코드에 raw 값 직접 작성 금지.

- **색상**: `AppColors` (`lib/cores/constants/app_colors.dart`) — `Color(0xFF...)`, `Colors.red` 등 직접 사용 금지
- **간격/크기**: `AppSpacing` (`lib/cores/constants/app_spacing.dart`) — `EdgeInsets.all(16)` 같은 매직 넘버 금지
- **텍스트 스타일**: `AppTextStyle` (`lib/cores/constants/app_text_style.dart`) — `TextStyle(fontSize: ...)` 인라인 금지
- 새로운 값이 필요하면 **상수 파일에 먼저 추가한 뒤** 참조한다
- 상수는 pixel-perfect 16배수 규칙(폰트)과 일관되게 정의

## 폰트 규칙 (픽셀 폰트 — 중요)

- Primary: `MoneygraphyPixel` (`assets/fonts/Moneygraphy-Pixel.ttf`)
- **`fontSize`는 반드시 16의 정수배** — 16/32/48/64/80/96… (그 외 글리프 깨짐)
- `letterSpacing: 0`, `fontWeight.w400` 고정, bold/italic 합성 금지
- 사용은 반드시 `AppTextStyle`을 통해서만. 세부는 `.claude/rules/Design.md` §3

## 필수 커맨드

```bash
flutter pub get
dart run build_runner watch --delete-conflicting-outputs   # Freezed/Riverpod/JSON 코드 생성
flutter analyze
flutter test
```

## 보안

- **커밋 금지**: `.env` (실제 시크릿). 이미 `.gitignore` 처리됨
- Firebase 설정(`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`)은 커밋 OK — 보안은 Firestore Rules / App Check / API 키 제한으로 처리
- 모든 시크릿은 `.env` + `flutter_dotenv`로만 로드

## DevOps (SUH-DEVOPS-TEMPLATE)

- 버전 자동 관리: `version.yml` (main 푸시 → 자동 증가 → Git 태그)
- 체인지로그: `deploy` 브랜치 PR 시 CodeRabbit 자동 리뷰 + 생성
- 설정 가이드: `SUH-DEVOPS-TEMPLATE-SETUP-GUIDE.md`

## 디렉터리 구조

```
lib/
  cores/       # 공통 유틸, 상수, 테마, TextStyle
  features/    # 기능별 모듈 (UI + Provider + Repository)
assets/
  fonts/       # MoneygraphyPixel
.env           # 환경 변수 (gitignored)
```
