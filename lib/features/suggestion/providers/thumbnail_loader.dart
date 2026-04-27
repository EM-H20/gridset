import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'thumbnail_loader.g.dart';

/// photo_manager 의 `thumbnailDataWithSize` 호출을 1점에 격리하는 어댑터.
///
/// 테스트는 `thumbnailLoaderProvider.overrideWith((_) => FakeLoader(...))`
/// 로 주입한다 — `_MappedThumb` 가 인터페이스에만 의존하므로 byte-level
/// 모킹이 단순.
abstract class ThumbnailLoader {
  Future<Uint8List?> load(AssetEntity asset, {required ThumbnailSize size});
}

/// 프로덕션 구현 — photo_manager 직접 위임.
class PhotoManagerThumbnailLoader implements ThumbnailLoader {
  const PhotoManagerThumbnailLoader();

  @override
  Future<Uint8List?> load(AssetEntity asset, {required ThumbnailSize size}) =>
      asset.thumbnailDataWithSize(size);
}

/// `keepAlive: true` — 어댑터 자체는 stateless 라 dispose 부담 없음.
/// 매번 새 인스턴스를 만들 이유도 없으므로 keepAlive.
@Riverpod(keepAlive: true)
ThumbnailLoader thumbnailLoader(Ref ref) =>
    const PhotoManagerThumbnailLoader();
