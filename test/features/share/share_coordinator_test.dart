import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart' hide Split;
import 'package:gridset/cores/grid_suggestor/models/grid_node.dart'
    show Split, SplitAxis, Leaf;
import 'package:gridset/features/share/models/cell_source.dart';
import 'package:gridset/features/share/providers/image_capturer.dart';
import 'package:gridset/features/share/providers/share_dispatcher.dart';
import 'package:gridset/features/share/providers/video_composer.dart';
import 'package:gridset/features/share/share_coordinator.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// path_provider native 의존을 차단 — 테스트 환경에서 임시 디렉터리 반환.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

class _FakeImageCapturer implements ImageCapturer {
  final Uint8List bytes = Uint8List.fromList([1, 2, 3]);
  int callCount = 0;

  @override
  Future<Uint8List> capturePng({
    required GlobalKey key,
    required int longEdgePx,
  }) async {
    callCount++;
    return bytes;
  }
}

class _FakeVideoComposer implements VideoComposer {
  final String outPath = '${Directory.systemTemp.path}/fake_gridset.mp4';
  int callCount = 0;
  bool cancelled = false;

  @override
  Future<String> composeMp4({
    required List<CellSource> cells,
    required CanvasRatio canvas,
    required int longEdgePx,
    required int fps,
    required int tMinMs,
    required void Function(double) onProgress,
  }) async {
    callCount++;
    onProgress(1.0);
    return outPath;
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
  }
}

class _FakeDispatcher implements ShareDispatcher {
  List<String>? lastFilePaths;
  int callCount = 0;

  @override
  Future<void> share({required List<String> filePaths, String? subject}) async {
    callCount++;
    lastFilePaths = filePaths;
  }
}

AssetEntity _photo(String id) =>
    AssetEntity(id: id, typeInt: 1, width: 100, height: 100);

// 영상 분기는 native 의존이라 widget 통합 테스트 어려움 — Phase E 매뉴얼 검증.
// _video 헬퍼는 후속 phase 에서 영상 분기 테스트 추가 시 활용 (현재 미사용).
// ignore: unused_element
AssetEntity _video(String id) =>
    AssetEntity(id: id, typeInt: 2, width: 100, height: 100, duration: 5);

GridSuggestion _suggestion(Map<int, String> mediaByCellId) => GridSuggestion(
      tree: Split(
        axis: SplitAxis.vertical,
        positions: const [0.5],
        children: const [Leaf(0), Leaf(1)],
      ),
      mediaByCellId: mediaByCellId,
      loss: 0.0,
      templateName: 'test_2',
    );

void main() {
  // path_provider 네이티브 채널을 fake 로 교체. 전역 singleton 이라 test 후
  // 복원 안 하면 후속 test 가 fake 를 그대로 사용 → 순서 의존 flaky.
  late PathProviderPlatform originalPathProvider;
  setUp(() {
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider();
  });
  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
  });

  test('사진만 — ImageCapturer 호출 + share PNG', () async {
    final cap = _FakeImageCapturer();
    final composer = _FakeVideoComposer();
    final dispatcher = _FakeDispatcher();

    final container = ProviderContainer(
      overrides: [
        imageCapturerProvider.overrideWith((_) => cap),
        videoComposerProvider.overrideWith((_) => composer),
        shareDispatcherProvider.overrideWith((_) => dispatcher),
      ],
    );
    addTearDown(container.dispose);

    // fake capturer 이므로 실제 RepaintBoundary mount 불필요.
    final cardKey = GlobalKey();
    final coordinator = ShareCoordinator(container);

    await coordinator.run(
      cardKey: cardKey,
      suggestion: _suggestion({0: 'a', 1: 'b'}),
      canvas: const CanvasRatio.square(),
      assetsById: {'a': _photo('a'), 'b': _photo('b')},
    );

    expect(cap.callCount, 1, reason: 'ImageCapturer 호출 1회');
    expect(composer.callCount, 0, reason: 'VideoComposer 호출 없음 (사진 분기)');
    expect(dispatcher.callCount, 1, reason: 'share 호출 1회');
    expect(dispatcher.lastFilePaths, hasLength(1));
    expect(
      dispatcher.lastFilePaths!.first,
      endsWith('.png'),
      reason: 'PNG 파일 share',
    );
  });

  test('cancel — VideoComposer.cancel 위임', () async {
    final composer = _FakeVideoComposer();
    final container = ProviderContainer(overrides: [
      videoComposerProvider.overrideWith((_) => composer),
    ]);
    addTearDown(container.dispose);

    final coordinator = ShareCoordinator(container);
    await coordinator.cancel();

    expect(composer.cancelled, isTrue);
  });
}
