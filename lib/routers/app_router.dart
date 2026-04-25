import 'package:go_router/go_router.dart';

import '../cores/utils/custom_page_transitions.dart';
import '../features/dev/dev_gallery_page.dart';
import '../features/force_update/force_update_page.dart';
import '../features/home/home_page.dart';
import '../features/maintenance/maintenance_page.dart';
import '../features/splash/splash_page.dart';
import 'route_paths.dart';

/// 앱 전역 GoRouter.
///
/// 전환 애니메이션 원칙:
/// - Splash / Home / Maintenance / ForceUpdate: `buildInstantTransition`
///   (부트스트랩 흐름 — 애니메이션 없이 즉시 전환)
/// - 추후 일반 forward 이동이 필요한 라우트는 `buildDirectionalSlide` 로 추가.
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
      pageBuilder: (context, state) => buildInstantTransition(
        key: state.pageKey,
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
    GoRoute(
      path: RoutePaths.dev,
      pageBuilder: (context, state) => buildDirectionalSlide(
        key: state.pageKey,
        isForward: true,
        child: const DevGalleryPage(),
      ),
    ),
  ],
);
