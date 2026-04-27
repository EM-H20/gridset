import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/share/models/cell_source.dart';
import 'package:gridset/features/share/providers/video_composer.dart';

class _FakeComposer implements VideoComposer {
  bool cancelled = false;
  double? lastProgress;

  @override
  Future<String> composeMp4({
    required List<CellSource> cells,
    required CanvasRatio canvas,
    required int longEdgePx,
    required int fps,
    required int tMinMs,
    required void Function(double) onProgress,
  }) async {
    onProgress(0.5);
    lastProgress = 0.5;
    return '/tmp/fake.mp4';
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
  }
}

void main() {
  test('인터페이스 — composeMp4 + cancel', () async {
    final fake = _FakeComposer();
    final path = await fake.composeMp4(
      cells: const [],
      canvas: const CanvasRatio.square(),
      longEdgePx: 1080,
      fps: 30,
      tMinMs: 5000,
      onProgress: (_) {},
    );
    expect(path, '/tmp/fake.mp4');
    expect(fake.lastProgress, 0.5);
    await fake.cancel();
    expect(fake.cancelled, isTrue);
  });

  test('videoComposerProvider — 기본 구현 VideoComposer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final composer = container.read(videoComposerProvider);
    expect(composer, isA<VideoComposer>());
  });
}
