// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flow_selection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$FlowSelection {
  CanvasRatio get canvas => throw _privateConstructorUsedError;
  List<MediaItem> get media => throw _privateConstructorUsedError;

  /// Create a copy of FlowSelection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FlowSelectionCopyWith<FlowSelection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FlowSelectionCopyWith<$Res> {
  factory $FlowSelectionCopyWith(
    FlowSelection value,
    $Res Function(FlowSelection) then,
  ) = _$FlowSelectionCopyWithImpl<$Res, FlowSelection>;
  @useResult
  $Res call({CanvasRatio canvas, List<MediaItem> media});
}

/// @nodoc
class _$FlowSelectionCopyWithImpl<$Res, $Val extends FlowSelection>
    implements $FlowSelectionCopyWith<$Res> {
  _$FlowSelectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FlowSelection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? canvas = null, Object? media = null}) {
    return _then(
      _value.copyWith(
            canvas: null == canvas
                ? _value.canvas
                : canvas // ignore: cast_nullable_to_non_nullable
                      as CanvasRatio,
            media: null == media
                ? _value.media
                : media // ignore: cast_nullable_to_non_nullable
                      as List<MediaItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FlowSelectionImplCopyWith<$Res>
    implements $FlowSelectionCopyWith<$Res> {
  factory _$$FlowSelectionImplCopyWith(
    _$FlowSelectionImpl value,
    $Res Function(_$FlowSelectionImpl) then,
  ) = __$$FlowSelectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({CanvasRatio canvas, List<MediaItem> media});
}

/// @nodoc
class __$$FlowSelectionImplCopyWithImpl<$Res>
    extends _$FlowSelectionCopyWithImpl<$Res, _$FlowSelectionImpl>
    implements _$$FlowSelectionImplCopyWith<$Res> {
  __$$FlowSelectionImplCopyWithImpl(
    _$FlowSelectionImpl _value,
    $Res Function(_$FlowSelectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FlowSelection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? canvas = null, Object? media = null}) {
    return _then(
      _$FlowSelectionImpl(
        canvas: null == canvas
            ? _value.canvas
            : canvas // ignore: cast_nullable_to_non_nullable
                  as CanvasRatio,
        media: null == media
            ? _value._media
            : media // ignore: cast_nullable_to_non_nullable
                  as List<MediaItem>,
      ),
    );
  }
}

/// @nodoc

class _$FlowSelectionImpl implements _FlowSelection {
  const _$FlowSelectionImpl({
    required this.canvas,
    final List<MediaItem> media = const <MediaItem>[],
  }) : _media = media;

  @override
  final CanvasRatio canvas;
  final List<MediaItem> _media;
  @override
  @JsonKey()
  List<MediaItem> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  String toString() {
    return 'FlowSelection(canvas: $canvas, media: $media)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FlowSelectionImpl &&
            (identical(other.canvas, canvas) || other.canvas == canvas) &&
            const DeepCollectionEquality().equals(other._media, _media));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    canvas,
    const DeepCollectionEquality().hash(_media),
  );

  /// Create a copy of FlowSelection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FlowSelectionImplCopyWith<_$FlowSelectionImpl> get copyWith =>
      __$$FlowSelectionImplCopyWithImpl<_$FlowSelectionImpl>(this, _$identity);
}

abstract class _FlowSelection implements FlowSelection {
  const factory _FlowSelection({
    required final CanvasRatio canvas,
    final List<MediaItem> media,
  }) = _$FlowSelectionImpl;

  @override
  CanvasRatio get canvas;
  @override
  List<MediaItem> get media;

  /// Create a copy of FlowSelection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FlowSelectionImplCopyWith<_$FlowSelectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
