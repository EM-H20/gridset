import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

void main() {
  group('validateSuggestInput', () {
    const validMedia = [
      MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0),
      MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 0.75),
    ];

    test('정상 입력 — 통과', () {
      expect(
        () => validateSuggestInput(media: validMedia, weightOf: null),
        returnsNormally,
      );
    });

    test('N < 2 → ArgumentError', () {
      const media = [MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 1.0)];
      expect(
        () => validateSuggestInput(media: media, weightOf: null),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('≥ 2'))),
      );
    });

    test('N > 9 → ArgumentError', () {
      final media = List.generate(
        10,
        (i) => MediaItem(id: '$i', type: MediaType.photo, aspectRatio: 1.0),
      );
      expect(
        () => validateSuggestInput(media: media, weightOf: null),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('≤ 9'))),
      );
    });

    test('aspectRatio <= 0 → ArgumentError', () {
      const media = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: 0),
        MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1),
      ];
      expect(
        () => validateSuggestInput(media: media, weightOf: null),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('positive finite'))),
      );
    });

    test('aspectRatio NaN → ArgumentError', () {
      final media = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: double.nan),
        const MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1),
      ];
      expect(
        () => validateSuggestInput(media: media, weightOf: null),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('aspectRatio Infinity → ArgumentError', () {
      final media = [
        MediaItem(id: 'a', type: MediaType.photo, aspectRatio: double.infinity),
        const MediaItem(id: 'b', type: MediaType.photo, aspectRatio: 1),
      ];
      expect(
        () => validateSuggestInput(media: media, weightOf: null),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('동일 id 중복 → ArgumentError', () {
      const media = [
        MediaItem(id: 'dup', type: MediaType.photo, aspectRatio: 1),
        MediaItem(id: 'dup', type: MediaType.photo, aspectRatio: 1),
      ];
      expect(
        () => validateSuggestInput(media: media, weightOf: null),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('unique'))),
      );
    });

    test('weightOf 음수 반환 → ArgumentError', () {
      expect(
        () => validateSuggestInput(
          media: validMedia,
          weightOf: (item) => -1.0,
        ),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('non-negative'))),
      );
    });

    test('weightOf NaN 반환 → ArgumentError', () {
      expect(
        () => validateSuggestInput(
          media: validMedia,
          weightOf: (item) => double.nan,
        ),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('finite'))),
      );
    });

    test('weightOf Infinity 반환 → ArgumentError', () {
      expect(
        () => validateSuggestInput(
          media: validMedia,
          weightOf: (item) => double.infinity,
        ),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('finite'))),
      );
    });
  });
}
