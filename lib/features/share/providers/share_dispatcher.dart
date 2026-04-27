import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'share_dispatcher.g.dart';

/// share_plus 호출을 1점 격리하는 어댑터.
///
/// 테스트는 `shareDispatcherProvider.overrideWith((_) => FakeDispatcher())`
/// 로 주입.
abstract interface class ShareDispatcher {
  Future<void> share({required List<String> filePaths, String? subject});
}

/// 프로덕션 구현 — share_plus.share + ShareParams 위임.
class SharePlusDispatcher implements ShareDispatcher {
  const SharePlusDispatcher();

  @override
  Future<void> share({
    required List<String> filePaths,
    String? subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: filePaths.map(XFile.new).toList(),
        subject: subject,
      ),
    );
  }
}

@Riverpod(keepAlive: true)
ShareDispatcher shareDispatcher(Ref ref) => const SharePlusDispatcher();
