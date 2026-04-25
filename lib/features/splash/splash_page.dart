import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
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

  /// 스플래시 최소 노출 시간.
  ///
  /// 버전 체크가 즉시 완료되더라도 스플래시가 이 시간만큼은 유지되어
  /// 깜빡임을 방지하고 브랜드 노출을 확보한다.
  static const Duration _minSplashDuration = Duration(seconds: 2);

  Future<void> _bootstrap() async {
    final startTime = DateTime.now();

    try {
      final result = await AppVersionChecker.check();
      if (!mounted) return;

      // 최소 노출 시간 보장 — 어떤 분기로 가든 동일한 템포.
      await _waitRemaining(startTime);
      if (!mounted) return;

      final canProceed = await UpdateDialogHelper.handleResult(context, result);
      if (!mounted) return;
      if (canProceed) {
        context.go(RoutePaths.home);
      }
      // canProceed == false 인 경우 handleResult 내부에서 이미 라우팅 완료.
    } catch (e, s) {
      // 체크 실패 시에도 앱 흐름이 막히지 않도록 home 으로 진행.
      debugPrint('⚠️ Splash bootstrap failed: $e\n$s');
      await _waitRemaining(startTime);
      if (!mounted) return;
      context.go(RoutePaths.home);
    }
  }

  /// 시작 시각 기준 [_minSplashDuration] 이 남아있으면 대기.
  Future<void> _waitRemaining(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    final remaining = _minSplashDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          // 우측 이동(translate) + 화면 폭 대비 확대(FractionallySizedBox).
          // FractionallySizedBox 가 size 자체를 키우므로 Padding 과 달리
          // 이미지 축소 부작용 없이 원하는 크기를 얻을 수 있다.
          child: Transform.translate(
            offset: const Offset(AppSpacing.xl, 0),
            child: FractionallySizedBox(
              widthFactor: 1.2,
              child: Image.asset('assets/splash.png', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
