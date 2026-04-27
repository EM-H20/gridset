import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_assets_provider.g.dart';

/// picker → suggestion 흐름 동안 `Map<String, AssetEntity>` 보존.
///
/// `flowSelectionProvider` 와 페어로 picker `_onNext` 에서 채워짐.
/// `_MappedThumb` 가 cellId → assetId → AssetEntity 를 해석할 때 lookup.
///
/// `keepAlive: true` — picker 라우트 떠난 직후 microtask 에서도 state 가
/// 살아있어야 suggestion 화면이 처음 build 될 때 빈 map 으로 떨어지지 않음.
/// (`flowSelectionProvider` 와 동일한 라이프사이클.)
@Riverpod(keepAlive: true)
class SelectedAssetsNotifier extends _$SelectedAssetsNotifier {
  @override
  Map<String, AssetEntity> build() => const {};

  /// `id → AssetEntity` 로 정규화. List 의 순서는 알고리즘 입력
  /// (`flow.media`) 에서만 의미 있고, 본 provider 는 lookup 용이라 Map.
  /// `Map.unmodifiable` 로 외부 mutation 차단.
  void setAssets(List<AssetEntity> items) =>
      state = Map.unmodifiable({for (final a in items) a.id: a});
}
