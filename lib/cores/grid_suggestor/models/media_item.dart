import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_item.freezed.dart';
part 'media_item.g.dart';

/// 알고리즘 입력 미디어 단위.
///
/// `aspectRatio` 는 W/H, 양의 유한값. 호출부가 EXIF orientation 반영 후 넘김.
/// `durationMs` 는 영상에서만 사용. v1 알고리즘은 무시 (가중치 1.0).
@freezed
class MediaItem with _$MediaItem {
  const factory MediaItem({
    required String id,
    required MediaType type,
    required double aspectRatio,
    int? durationMs,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}

enum MediaType { photo, video }
