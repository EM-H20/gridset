import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';
import 'package:gridset/features/photo_picker/asset_to_media_item.dart';

void main() {
  group('mediaItemFromMetrics', () {
    test('photo 정상 → MediaItem 반환', () {
      final r = mediaItemFromMetrics(
        id: 'a',
        isVideo: false,
        width: 1080,
        height: 1920,
        videoMs: null,
      );
      expect(r, isNotNull);
      expect(r!.id, 'a');
      expect(r.type, MediaType.photo);
      expect(r.aspectRatio, closeTo(1080 / 1920, 0.0001));
      expect(r.durationMs, isNull);
    });

    test('video 정상 → durationMs 채워짐', () {
      final r = mediaItemFromMetrics(
        id: 'v',
        isVideo: true,
        width: 1920,
        height: 1080,
        videoMs: 12000,
      );
      expect(r, isNotNull);
      expect(r!.type, MediaType.video);
      expect(r.durationMs, 12000);
    });

    test('width 또는 height 0 → null', () {
      expect(
        mediaItemFromMetrics(
            id: 'x', isVideo: false, width: 0, height: 1920, videoMs: null),
        isNull,
      );
      expect(
        mediaItemFromMetrics(
            id: 'x', isVideo: false, width: 1080, height: 0, videoMs: null),
        isNull,
      );
    });

    test('AR ≥10:1 또는 ≤1:10 → null (검증 차단)', () {
      expect(
        mediaItemFromMetrics(
            id: 'x', isVideo: false, width: 11000, height: 1000, videoMs: null),
        isNull,
      );
      expect(
        mediaItemFromMetrics(
            id: 'x', isVideo: false, width: 1000, height: 11000, videoMs: null),
        isNull,
      );
    });
  });
}
