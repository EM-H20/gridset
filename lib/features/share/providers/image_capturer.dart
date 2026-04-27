import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_capturer.g.dart';

/// 화면에 떠있는 위젯의 RepaintBoundary 를 캡처해 PNG bytes 반환.
///
/// `key` 는 RepaintBoundary 를 wrapping 한 위젯의 GlobalKey.
/// 호출자가 widget tree 의 RepaintBoundary(key: ...) 로 카드를 감싸야 함.
abstract interface class ImageCapturer {
  Future<Uint8List> capturePng({
    required GlobalKey key,
    required int longEdgePx,
  });
}

/// 프로덕션 구현 — RenderRepaintBoundary.toImage(pixelRatio) 위임.
///
/// pixelRatio 는 카드 dp 사이즈 기준으로 longEdgePx 가 나오게 동적 계산.
/// (iPhone 14 360dp 카드 → pixelRatio 3 → 1080px.)
class RepaintBoundaryImageCapturer implements ImageCapturer {
  const RepaintBoundaryImageCapturer();

  @override
  Future<Uint8List> capturePng({
    required GlobalKey key,
    required int longEdgePx,
  }) async {
    final ctx = key.currentContext;
    if (ctx == null) {
      throw StateError('ImageCapturer: GlobalKey.currentContext == null. '
          'RepaintBoundary 가 mount 되어있는지 확인.');
    }
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
    final size = boundary.size;
    final longEdgeDp = math.max(size.width, size.height);
    final pixelRatio = longEdgePx / longEdgeDp;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('ImageCapturer: PNG byteData == null');
    }
    return byteData.buffer.asUint8List();
  }
}

@Riverpod(keepAlive: true)
ImageCapturer imageCapturer(Ref ref) => const RepaintBoundaryImageCapturer();
