// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grid_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GridSuggestion {
  GridNode get tree => throw _privateConstructorUsedError;
  Map<int, String> get mediaByCellId => throw _privateConstructorUsedError;
  double get loss => throw _privateConstructorUsedError;
  String get templateName => throw _privateConstructorUsedError;

  /// Create a copy of GridSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GridSuggestionCopyWith<GridSuggestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GridSuggestionCopyWith<$Res> {
  factory $GridSuggestionCopyWith(
    GridSuggestion value,
    $Res Function(GridSuggestion) then,
  ) = _$GridSuggestionCopyWithImpl<$Res, GridSuggestion>;
  @useResult
  $Res call({
    GridNode tree,
    Map<int, String> mediaByCellId,
    double loss,
    String templateName,
  });
}

/// @nodoc
class _$GridSuggestionCopyWithImpl<$Res, $Val extends GridSuggestion>
    implements $GridSuggestionCopyWith<$Res> {
  _$GridSuggestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GridSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tree = null,
    Object? mediaByCellId = null,
    Object? loss = null,
    Object? templateName = null,
  }) {
    return _then(
      _value.copyWith(
            tree: null == tree
                ? _value.tree
                : tree // ignore: cast_nullable_to_non_nullable
                      as GridNode,
            mediaByCellId: null == mediaByCellId
                ? _value.mediaByCellId
                : mediaByCellId // ignore: cast_nullable_to_non_nullable
                      as Map<int, String>,
            loss: null == loss
                ? _value.loss
                : loss // ignore: cast_nullable_to_non_nullable
                      as double,
            templateName: null == templateName
                ? _value.templateName
                : templateName // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GridSuggestionImplCopyWith<$Res>
    implements $GridSuggestionCopyWith<$Res> {
  factory _$$GridSuggestionImplCopyWith(
    _$GridSuggestionImpl value,
    $Res Function(_$GridSuggestionImpl) then,
  ) = __$$GridSuggestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    GridNode tree,
    Map<int, String> mediaByCellId,
    double loss,
    String templateName,
  });
}

/// @nodoc
class __$$GridSuggestionImplCopyWithImpl<$Res>
    extends _$GridSuggestionCopyWithImpl<$Res, _$GridSuggestionImpl>
    implements _$$GridSuggestionImplCopyWith<$Res> {
  __$$GridSuggestionImplCopyWithImpl(
    _$GridSuggestionImpl _value,
    $Res Function(_$GridSuggestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GridSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tree = null,
    Object? mediaByCellId = null,
    Object? loss = null,
    Object? templateName = null,
  }) {
    return _then(
      _$GridSuggestionImpl(
        tree: null == tree
            ? _value.tree
            : tree // ignore: cast_nullable_to_non_nullable
                  as GridNode,
        mediaByCellId: null == mediaByCellId
            ? _value._mediaByCellId
            : mediaByCellId // ignore: cast_nullable_to_non_nullable
                  as Map<int, String>,
        loss: null == loss
            ? _value.loss
            : loss // ignore: cast_nullable_to_non_nullable
                  as double,
        templateName: null == templateName
            ? _value.templateName
            : templateName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$GridSuggestionImpl implements _GridSuggestion {
  const _$GridSuggestionImpl({
    required this.tree,
    required final Map<int, String> mediaByCellId,
    required this.loss,
    required this.templateName,
  }) : _mediaByCellId = mediaByCellId;

  @override
  final GridNode tree;
  final Map<int, String> _mediaByCellId;
  @override
  Map<int, String> get mediaByCellId {
    if (_mediaByCellId is EqualUnmodifiableMapView) return _mediaByCellId;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_mediaByCellId);
  }

  @override
  final double loss;
  @override
  final String templateName;

  @override
  String toString() {
    return 'GridSuggestion(tree: $tree, mediaByCellId: $mediaByCellId, loss: $loss, templateName: $templateName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GridSuggestionImpl &&
            (identical(other.tree, tree) || other.tree == tree) &&
            const DeepCollectionEquality().equals(
              other._mediaByCellId,
              _mediaByCellId,
            ) &&
            (identical(other.loss, loss) || other.loss == loss) &&
            (identical(other.templateName, templateName) ||
                other.templateName == templateName));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    tree,
    const DeepCollectionEquality().hash(_mediaByCellId),
    loss,
    templateName,
  );

  /// Create a copy of GridSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GridSuggestionImplCopyWith<_$GridSuggestionImpl> get copyWith =>
      __$$GridSuggestionImplCopyWithImpl<_$GridSuggestionImpl>(
        this,
        _$identity,
      );
}

abstract class _GridSuggestion implements GridSuggestion {
  const factory _GridSuggestion({
    required final GridNode tree,
    required final Map<int, String> mediaByCellId,
    required final double loss,
    required final String templateName,
  }) = _$GridSuggestionImpl;

  @override
  GridNode get tree;
  @override
  Map<int, String> get mediaByCellId;
  @override
  double get loss;
  @override
  String get templateName;

  /// Create a copy of GridSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GridSuggestionImplCopyWith<_$GridSuggestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
