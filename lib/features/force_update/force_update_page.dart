import 'package:flutter/material.dart';

import '../../cores/constants/app_urls.dart';
import '../../cores/utils/url_launcher_util.dart';
import '../../cores/widgets/buttons/app_button.dart';
import '../../cores/widgets/pages/blocking_info_page.dart';

/// 강제 업데이트 풀스크린 — `BlockingInfoPage` 위에 업데이트 CTA 주입.
///
/// "업데이트" 버튼은 `AppUrls.storeUrl` 로 외부 브라우저 이동.
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlockingInfoPage(
      title: '업데이트 필요',
      message: '원활한 사용을 위해\n최신 버전으로 업데이트해주세요.',
      action: AppButton.primary(
        label: '업데이트',
        isFullWidth: false,
        onPressed: () => launchExternalUrl(AppUrls.storeUrl),
      ),
    );
  }
}
