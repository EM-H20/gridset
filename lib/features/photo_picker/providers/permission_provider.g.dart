// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$photoPermissionHash() => r'd11908680be84fea2fbf673ed071e52a5fea7d1d';

/// 권한 요청 + 상태 매핑. 진입 시 자동으로 시스템 dialog 가 뜬다 (notDetermined 인 경우).
///
/// `keepAlive: false` (autoDispose) — picker 라우트 dispose 시 재초기화.
///
/// Copied from [photoPermission].
@ProviderFor(photoPermission)
final photoPermissionProvider =
    AutoDisposeFutureProvider<AppPermissionState>.internal(
      photoPermission,
      name: r'photoPermissionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$photoPermissionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PhotoPermissionRef = AutoDisposeFutureProviderRef<AppPermissionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
