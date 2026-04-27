// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flow_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$flowSelectionNotifierHash() =>
    r'c638ca12dfbcdba9c9ae528207fd38ceb80e76fd';

/// 흐름 공유 상태 Notifier.
///
/// - `home → CTA` 진입 시 canvas/media 셋업
/// - picker (canvas/photo) 화면들은 `ref.read(...).setX()` 만 호출하므로
///   listener 가 없다. `keepAlive: true` 로 두어야 picker → suggestion 이동
///   사이의 microtask 동안 state 가 보존된다 (autoDispose 였다면 race 로
///   media 가 default 로 초기화됨).
/// - 흐름 시작 시점 (home 두 CTA) 에서 명시적으로 media/canvas 를 reset 해
///   이전 흐름 잔재를 제거한다.
///
/// Copied from [FlowSelectionNotifier].
@ProviderFor(FlowSelectionNotifier)
final flowSelectionNotifierProvider =
    NotifierProvider<FlowSelectionNotifier, FlowSelection>.internal(
      FlowSelectionNotifier.new,
      name: r'flowSelectionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$flowSelectionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FlowSelectionNotifier = Notifier<FlowSelection>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
