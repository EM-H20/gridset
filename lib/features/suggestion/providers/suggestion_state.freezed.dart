// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'suggestion_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SuggestionState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(String message) error,
    required TResult Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )
    loaded,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(String message)? error,
    TResult? Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )?
    loaded,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(String message)? error,
    TResult Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )?
    loaded,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SuggestionStateEmpty value) empty,
    required TResult Function(SuggestionStateError value) error,
    required TResult Function(SuggestionStateLoaded value) loaded,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SuggestionStateEmpty value)? empty,
    TResult? Function(SuggestionStateError value)? error,
    TResult? Function(SuggestionStateLoaded value)? loaded,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SuggestionStateEmpty value)? empty,
    TResult Function(SuggestionStateError value)? error,
    TResult Function(SuggestionStateLoaded value)? loaded,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SuggestionStateCopyWith<$Res> {
  factory $SuggestionStateCopyWith(
    SuggestionState value,
    $Res Function(SuggestionState) then,
  ) = _$SuggestionStateCopyWithImpl<$Res, SuggestionState>;
}

/// @nodoc
class _$SuggestionStateCopyWithImpl<$Res, $Val extends SuggestionState>
    implements $SuggestionStateCopyWith<$Res> {
  _$SuggestionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SuggestionState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SuggestionStateEmptyImplCopyWith<$Res> {
  factory _$$SuggestionStateEmptyImplCopyWith(
    _$SuggestionStateEmptyImpl value,
    $Res Function(_$SuggestionStateEmptyImpl) then,
  ) = __$$SuggestionStateEmptyImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SuggestionStateEmptyImplCopyWithImpl<$Res>
    extends _$SuggestionStateCopyWithImpl<$Res, _$SuggestionStateEmptyImpl>
    implements _$$SuggestionStateEmptyImplCopyWith<$Res> {
  __$$SuggestionStateEmptyImplCopyWithImpl(
    _$SuggestionStateEmptyImpl _value,
    $Res Function(_$SuggestionStateEmptyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SuggestionState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SuggestionStateEmptyImpl implements SuggestionStateEmpty {
  const _$SuggestionStateEmptyImpl();

  @override
  String toString() {
    return 'SuggestionState.empty()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuggestionStateEmptyImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(String message) error,
    required TResult Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )
    loaded,
  }) {
    return empty();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(String message)? error,
    TResult? Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )?
    loaded,
  }) {
    return empty?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(String message)? error,
    TResult Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )?
    loaded,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SuggestionStateEmpty value) empty,
    required TResult Function(SuggestionStateError value) error,
    required TResult Function(SuggestionStateLoaded value) loaded,
  }) {
    return empty(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SuggestionStateEmpty value)? empty,
    TResult? Function(SuggestionStateError value)? error,
    TResult? Function(SuggestionStateLoaded value)? loaded,
  }) {
    return empty?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SuggestionStateEmpty value)? empty,
    TResult Function(SuggestionStateError value)? error,
    TResult Function(SuggestionStateLoaded value)? loaded,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty(this);
    }
    return orElse();
  }
}

abstract class SuggestionStateEmpty implements SuggestionState {
  const factory SuggestionStateEmpty() = _$SuggestionStateEmptyImpl;
}

/// @nodoc
abstract class _$$SuggestionStateErrorImplCopyWith<$Res> {
  factory _$$SuggestionStateErrorImplCopyWith(
    _$SuggestionStateErrorImpl value,
    $Res Function(_$SuggestionStateErrorImpl) then,
  ) = __$$SuggestionStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$SuggestionStateErrorImplCopyWithImpl<$Res>
    extends _$SuggestionStateCopyWithImpl<$Res, _$SuggestionStateErrorImpl>
    implements _$$SuggestionStateErrorImplCopyWith<$Res> {
  __$$SuggestionStateErrorImplCopyWithImpl(
    _$SuggestionStateErrorImpl _value,
    $Res Function(_$SuggestionStateErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SuggestionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$SuggestionStateErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SuggestionStateErrorImpl implements SuggestionStateError {
  const _$SuggestionStateErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'SuggestionState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuggestionStateErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of SuggestionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuggestionStateErrorImplCopyWith<_$SuggestionStateErrorImpl>
  get copyWith =>
      __$$SuggestionStateErrorImplCopyWithImpl<_$SuggestionStateErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(String message) error,
    required TResult Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )
    loaded,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(String message)? error,
    TResult? Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )?
    loaded,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(String message)? error,
    TResult Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )?
    loaded,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SuggestionStateEmpty value) empty,
    required TResult Function(SuggestionStateError value) error,
    required TResult Function(SuggestionStateLoaded value) loaded,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SuggestionStateEmpty value)? empty,
    TResult? Function(SuggestionStateError value)? error,
    TResult? Function(SuggestionStateLoaded value)? loaded,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SuggestionStateEmpty value)? empty,
    TResult Function(SuggestionStateError value)? error,
    TResult Function(SuggestionStateLoaded value)? loaded,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class SuggestionStateError implements SuggestionState {
  const factory SuggestionStateError(final String message) =
      _$SuggestionStateErrorImpl;

  String get message;

  /// Create a copy of SuggestionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuggestionStateErrorImplCopyWith<_$SuggestionStateErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SuggestionStateLoadedImplCopyWith<$Res> {
  factory _$$SuggestionStateLoadedImplCopyWith(
    _$SuggestionStateLoadedImpl value,
    $Res Function(_$SuggestionStateLoadedImpl) then,
  ) = __$$SuggestionStateLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<MediaItem> media,
    CanvasRatio canvas,
    List<GridSuggestion> suggestions,
    int selectedIndex,
    SuggestCursor? cursor,
  });

  $SuggestCursorCopyWith<$Res>? get cursor;
}

/// @nodoc
class __$$SuggestionStateLoadedImplCopyWithImpl<$Res>
    extends _$SuggestionStateCopyWithImpl<$Res, _$SuggestionStateLoadedImpl>
    implements _$$SuggestionStateLoadedImplCopyWith<$Res> {
  __$$SuggestionStateLoadedImplCopyWithImpl(
    _$SuggestionStateLoadedImpl _value,
    $Res Function(_$SuggestionStateLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SuggestionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? media = null,
    Object? canvas = null,
    Object? suggestions = null,
    Object? selectedIndex = null,
    Object? cursor = freezed,
  }) {
    return _then(
      _$SuggestionStateLoadedImpl(
        media: null == media
            ? _value._media
            : media // ignore: cast_nullable_to_non_nullable
                  as List<MediaItem>,
        canvas: null == canvas
            ? _value.canvas
            : canvas // ignore: cast_nullable_to_non_nullable
                  as CanvasRatio,
        suggestions: null == suggestions
            ? _value._suggestions
            : suggestions // ignore: cast_nullable_to_non_nullable
                  as List<GridSuggestion>,
        selectedIndex: null == selectedIndex
            ? _value.selectedIndex
            : selectedIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        cursor: freezed == cursor
            ? _value.cursor
            : cursor // ignore: cast_nullable_to_non_nullable
                  as SuggestCursor?,
      ),
    );
  }

  /// Create a copy of SuggestionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SuggestCursorCopyWith<$Res>? get cursor {
    if (_value.cursor == null) {
      return null;
    }

    return $SuggestCursorCopyWith<$Res>(_value.cursor!, (value) {
      return _then(_value.copyWith(cursor: value));
    });
  }
}

/// @nodoc

class _$SuggestionStateLoadedImpl implements SuggestionStateLoaded {
  const _$SuggestionStateLoadedImpl({
    required final List<MediaItem> media,
    required this.canvas,
    required final List<GridSuggestion> suggestions,
    required this.selectedIndex,
    this.cursor,
  }) : _media = media,
       _suggestions = suggestions;

  final List<MediaItem> _media;
  @override
  List<MediaItem> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  final CanvasRatio canvas;
  final List<GridSuggestion> _suggestions;
  @override
  List<GridSuggestion> get suggestions {
    if (_suggestions is EqualUnmodifiableListView) return _suggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_suggestions);
  }

  @override
  final int selectedIndex;
  @override
  final SuggestCursor? cursor;

  @override
  String toString() {
    return 'SuggestionState.loaded(media: $media, canvas: $canvas, suggestions: $suggestions, selectedIndex: $selectedIndex, cursor: $cursor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuggestionStateLoadedImpl &&
            const DeepCollectionEquality().equals(other._media, _media) &&
            (identical(other.canvas, canvas) || other.canvas == canvas) &&
            const DeepCollectionEquality().equals(
              other._suggestions,
              _suggestions,
            ) &&
            (identical(other.selectedIndex, selectedIndex) ||
                other.selectedIndex == selectedIndex) &&
            (identical(other.cursor, cursor) || other.cursor == cursor));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_media),
    canvas,
    const DeepCollectionEquality().hash(_suggestions),
    selectedIndex,
    cursor,
  );

  /// Create a copy of SuggestionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuggestionStateLoadedImplCopyWith<_$SuggestionStateLoadedImpl>
  get copyWith =>
      __$$SuggestionStateLoadedImplCopyWithImpl<_$SuggestionStateLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(String message) error,
    required TResult Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )
    loaded,
  }) {
    return loaded(media, canvas, suggestions, selectedIndex, cursor);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(String message)? error,
    TResult? Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )?
    loaded,
  }) {
    return loaded?.call(media, canvas, suggestions, selectedIndex, cursor);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(String message)? error,
    TResult Function(
      List<MediaItem> media,
      CanvasRatio canvas,
      List<GridSuggestion> suggestions,
      int selectedIndex,
      SuggestCursor? cursor,
    )?
    loaded,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(media, canvas, suggestions, selectedIndex, cursor);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SuggestionStateEmpty value) empty,
    required TResult Function(SuggestionStateError value) error,
    required TResult Function(SuggestionStateLoaded value) loaded,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SuggestionStateEmpty value)? empty,
    TResult? Function(SuggestionStateError value)? error,
    TResult? Function(SuggestionStateLoaded value)? loaded,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SuggestionStateEmpty value)? empty,
    TResult Function(SuggestionStateError value)? error,
    TResult Function(SuggestionStateLoaded value)? loaded,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class SuggestionStateLoaded implements SuggestionState {
  const factory SuggestionStateLoaded({
    required final List<MediaItem> media,
    required final CanvasRatio canvas,
    required final List<GridSuggestion> suggestions,
    required final int selectedIndex,
    final SuggestCursor? cursor,
  }) = _$SuggestionStateLoadedImpl;

  List<MediaItem> get media;
  CanvasRatio get canvas;
  List<GridSuggestion> get suggestions;
  int get selectedIndex;
  SuggestCursor? get cursor;

  /// Create a copy of SuggestionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuggestionStateLoadedImplCopyWith<_$SuggestionStateLoadedImpl>
  get copyWith => throw _privateConstructorUsedError;
}
