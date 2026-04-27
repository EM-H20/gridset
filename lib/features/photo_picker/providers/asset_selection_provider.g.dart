// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$assetSelectionNotifierHash() =>
    r'ead3250e9963223c009b29dcc33dffa37c88fd74';

/// 선택된 [AssetEntity] 들을 순서 보존해서 들고 있음.
///
/// 토글:
/// - 이미 있음 → 제거
/// - 없음 + length==9 → no-op + AppSnackbar 안내
/// - 없음 + AR 비정상 → no-op + AppSnackbar 안내
///
/// Copied from [AssetSelectionNotifier].
@ProviderFor(AssetSelectionNotifier)
final assetSelectionNotifierProvider =
    AutoDisposeNotifierProvider<
      AssetSelectionNotifier,
      List<AssetEntity>
    >.internal(
      AssetSelectionNotifier.new,
      name: r'assetSelectionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$assetSelectionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AssetSelectionNotifier = AutoDisposeNotifier<List<AssetEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
