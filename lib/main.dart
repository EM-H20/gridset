import 'package:firebase_core/firebase_core.dart';
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
