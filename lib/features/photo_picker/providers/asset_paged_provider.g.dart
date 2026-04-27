// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_paged_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$assetPagedNotifierHash() =>
    r'bdafdf0ea855ac1dc3b3bc6fb7c14882b4e6814a';

/// "Recent" album 의 asset 페이지네이션.
///
/// 60장씩 lazy load — 호출부에서 [loadMore] 누적 호출.
/// `keepAlive: false` (autoDispose) — picker 라우트 떠나면 초기화.
///
/// Copied from [AssetPagedNotifier].
@ProviderFor(AssetPagedNotifier)
final assetPagedNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      AssetPagedNotifier,
      List<AssetEntity>
    >.internal(
      AssetPagedNotifier.new,
      name: r'assetPagedNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$assetPagedNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AssetPagedNotifier = AutoDisposeAsyncNotifier<List<AssetEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
