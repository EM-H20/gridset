// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'suggest_cursor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SuggestCursor {
  Set<String> get shownTemplateNames => throw _privateConstructorUsedError;
  int get batchIndex => throw _privateConstructorUsedError;

  /// Create a copy of SuggestCursor
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SuggestCursorCopyWith<SuggestCursor> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SuggestCursorCopyWith<$Res> {
  factory $SuggestCursorCopyWith(
    SuggestCursor value,
    $Res Function(SuggestCursor) then,
  ) = _$SuggestCursorCopyWithImpl<$Res, SuggestCursor>;
  @useResult
  $Res call({Set<String> shownTemplateNames, int batchIndex});
}

/// @nodoc
class _$SuggestCursorCopyWithImpl<$Res, $Val extends SuggestCursor>
    implements $SuggestCursorCopyWith<$Res> {
  _$SuggestCursorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SuggestCursor
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? shownTemplateNames = null, Object? batchIndex = null}) {
    return _then(
      _value.copyWith(
            shownTemplateNames: null == shownTemplateNames
                ? _value.shownTemplateNames
                : shownTemplateNames // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            batchIndex: null == batchIndex
                ? _value.batchIndex
                : batchIndex // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SuggestCursorImplCopyWith<$Res>
    implements $SuggestCursorCopyWith<$Res> {
  factory _$$SuggestCursorImplCopyWith(
    _$SuggestCursorImpl value,
    $Res Function(_$SuggestCursorImpl) then,
  ) = __$$SuggestCursorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Set<String> shownTemplateNames, int batchIndex});
}

/// @nodoc
class __$$SuggestCursorImplCopyWithImpl<$Res>
    extends _$SuggestCursorCopyWithImpl<$Res, _$SuggestCursorImpl>
    implements _$$SuggestCursorImplCopyWith<$Res> {
  __$$SuggestCursorImplCopyWithImpl(
    _$SuggestCursorImpl _value,
    $Res Function(_$SuggestCursorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SuggestCursor
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? shownTemplateNames = null, Object? batchIndex = null}) {
    return _then(
      _$SuggestCursorImpl(
        shownTemplateNames: null == shownTemplateNames
            ? _value._shownTemplateNames
            : shownTemplateNames // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        batchIndex: null == batchIndex
            ? _value.batchIndex
            : batchIndex // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$SuggestCursorImpl implements _SuggestCursor {
  const _$SuggestCursorImpl({
    required final Set<String> shownTemplateNames,
    required this.batchIndex,
  }) : _shownTemplateNames = shownTemplateNames;

  final Set<String> _shownTemplateNames;
  @override
  Set<String> get shownTemplateNames {
    if (_shownTemplateNames is EqualUnmodifiableSetView)
      return _shownTemplateNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_shownTemplateNames);
  }

  @override
  final int batchIndex;

  @override
  String toString() {
    return 'SuggestCursor(shownTemplateNames: $shownTemplateNames, batchIndex: $batchIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuggestCursorImpl &&
            const DeepCollectionEquality().equals(
              other._shownTemplateNames,
              _shownTemplateNames,
            ) &&
            (identical(other.batchIndex, batchIndex) ||
                other.batchIndex == batchIndex));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_shownTemplateNames),
    batchIndex,
  );

  /// Create a copy of SuggestCursor
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuggestCursorImplCopyWith<_$SuggestCursorImpl> get copyWith =>
      __$$SuggestCursorImplCopyWithImpl<_$SuggestCursorImpl>(this, _$identity);
}

abstract class _SuggestCursor implements SuggestCursor {
  const factory _SuggestCursor({
    required final Set<String> shownTemplateNames,
    required final int batchIndex,
  }) = _$SuggestCursorImpl;

  @override
  Set<String> get shownTemplateNames;
  @override
  int get batchIndex;

  /// Create a copy of SuggestCursor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuggestCursorImplCopyWith<_$SuggestCursorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
