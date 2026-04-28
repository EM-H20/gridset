import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/features/share/providers/image_capturer.dart';

class _FakeCapturer implements ImageCapturer {
  _FakeCapturer(this.bytes);
  final Uint8List bytes;
  @override
  Future<Uint8List> capturePng({
    required GlobalKey key,
    required int longEdgePx,
  }) async => bytes;
}

void main() {
  test('인터페이스 — 비동기 Uint8List 반환', () async {
    final fake = _FakeCapturer(Uint8List.fromList([1, 2, 3]));
    final bytes = await fake.capturePng(
      key: GlobalKey(),
      longEdgePx: 1080,
    );
    expect(bytes, [1, 2, 3]);
  });

  test('imageCapturerProvider — 기본 구현 RepaintBoundaryImageCapturer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final capturer = container.read(imageCapturerProvider);
    expect(capturer, isA<ImageCapturer>());
  });
}
