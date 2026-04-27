// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_assets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedAssetsNotifierHash() =>
    r'8bc6ebd5d6154f61f713504a30f91ac098fd4559';

/// picker → suggestion 흐름 동안 `Map<String, AssetEntity>` 보존.
///
/// `flowSelectionProvider` 와 페어로 picker `_onNext` 에서 채워짐.
/// `_MappedThumb` 가 cellId → assetId → AssetEntity 를 해석할 때 lookup.
///
/// `keepAlive: true` — picker 라우트 떠난 직후 microtask 에서도 state 가
/// 살아있어야 suggestion 화면이 처음 build 될 때 빈 map 으로 떨어지지 않음.
/// (`flowSelectionProvider` 와 동일한 라이프사이클.)
///
/// Copied from [SelectedAssetsNotifier].
@ProviderFor(SelectedAssetsNotifier)
final selectedAssetsNotifierProvider =
    NotifierProvider<SelectedAssetsNotifier, Map<String, AssetEntity>>.internal(
      SelectedAssetsNotifier.new,
      name: r'selectedAssetsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedAssetsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedAssetsNotifier = Notifier<Map<String, AssetEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
