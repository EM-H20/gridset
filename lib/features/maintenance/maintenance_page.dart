import 'package:flutter/material.dart';

import '../../cores/services/remote_config/remote_config_service.dart';
import '../../cores/widgets/pages/blocking_info_page.dart';

/// 점검 안내 풀스크린 — `BlockingInfoPage` 위에 메시지 주입.
///
/// `RemoteConfigService.maintenanceMessage` 가 비어있으면 기본 문구 사용.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = RemoteConfigService.instance.maintenanceMessage;
    final message = raw.isEmpty
        ? '더 좋은 서비스로 찾아올게요.\n잠시만 기다려주세요.'
        : raw;

    return BlockingInfoPage(
      title: '점검 중이에요',
      message: message,
    );
  }
}
