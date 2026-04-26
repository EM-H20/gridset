import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('MediaItem', () {
    test('photo: durationMs 는 null 허용', () {
      const item = MediaItem(
        id: 'p1',
        type: MediaType.photo,
        aspectRatio: 1.5,
      );
      expect(item.id, 'p1');
      expect(item.type, MediaType.photo);
      expect(item.aspectRatio, 1.5);
      expect(item.durationMs, isNull);
    });

    test('video: durationMs 가 들어감', () {
      const item = MediaItem(
        id: 'v1',
        type: MediaType.video,
        aspectRatio: 0.5625,
        durationMs: 5000,
      );
      expect(item.type, MediaType.video);
      expect(item.durationMs, 5000);
    });

    test('동일 값으로 만든 두 인스턴스는 == ', () {
      const a = MediaItem(id: 'x', type: MediaType.photo, aspectRatio: 1.0);
      const b = MediaItem(id: 'x', type: MediaType.photo, aspectRatio: 1.0);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('JSON round-trip', () {
      const original = MediaItem(
        id: 'v1',
        type: MediaType.video,
        aspectRatio: 1.778,
        durationMs: 3000,
      );
      final json = original.toJson();
      final restored = MediaItem.fromJson(json);
      expect(restored, equals(original));
    });
  });
}
