// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$suggestionNotifierHash() =>
    r'08ecdfd5c3d04b9591605df96f24cf3e590a82b1';

/// 후보 화면 상태 — flowSelection 을 watch 해서 진입 시 자동 suggest 호출.
///
/// `keepAlive: false` — suggestion 라우트 떠나면 초기화.
///
/// Copied from [SuggestionNotifier].
@ProviderFor(SuggestionNotifier)
final suggestionNotifierProvider =
    AutoDisposeNotifierProvider<SuggestionNotifier, SuggestionState>.internal(
      SuggestionNotifier.new,
      name: r'suggestionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$suggestionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SuggestionNotifier = AutoDisposeNotifier<SuggestionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
