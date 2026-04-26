// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flow_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$flowSelectionNotifierHash() =>
    r'df2a5ca2bf1c5afb9395e91bcd77c50f23a90996';

/// 흐름 공유 상태 Notifier.
///
/// - `home → CTA` 진입 시 canvas/media 셋업
/// - `home` 으로 돌아가면 라우트 dispose → autoDispose → build() 재호출
///   (명시 reset 불필요).
///
/// Copied from [FlowSelectionNotifier].
@ProviderFor(FlowSelectionNotifier)
final flowSelectionNotifierProvider =
    AutoDisposeNotifierProvider<FlowSelectionNotifier, FlowSelection>.internal(
      FlowSelectionNotifier.new,
      name: r'flowSelectionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$flowSelectionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FlowSelectionNotifier = AutoDisposeNotifier<FlowSelection>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
