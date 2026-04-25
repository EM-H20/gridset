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
