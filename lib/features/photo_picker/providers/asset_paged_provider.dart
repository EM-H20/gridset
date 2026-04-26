import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'asset_paged_provider.g.dart';

/// "Recent" album 의 asset 페이지네이션.
///
/// 60장씩 lazy load — 호출부에서 [loadMore] 누적 호출.
/// `keepAlive: false` (autoDispose) — picker 라우트 떠나면 초기화.
@Riverpod(keepAlive: false)
class AssetPagedNotifier extends _$AssetPagedNotifier {
  static const int _pageSize = 60;
  AssetPathEntity? _album;
  int _page = 0;
  bool _exhausted = false;

  @override
  Future<List<AssetEntity>> build() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common, // image + video
      onlyAll: true,
    );
    if (albums.isEmpty) {
      _exhausted = true;
      return const [];
    }
    _album = albums.first;
    final first = await _album!.getAssetListPaged(page: 0, size: _pageSize);
    _page = 1;
    _exhausted = first.length < _pageSize;
    return first;
  }

  Future<void> loadMore() async {
    if (_exhausted || _album == null) return;
    final cur = state.valueOrNull ?? const [];
    final next = await _album!.getAssetListPaged(page: _page, size: _pageSize);
    _page += 1;
    _exhausted = next.length < _pageSize;
    state = AsyncData([...cur, ...next]);
  }

  bool get isExhausted => _exhausted;
}
