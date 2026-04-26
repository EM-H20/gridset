import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../cores/grid_suggestor/grid_suggestor.dart';
// SuggestCursor Freezed CopyWith 타입을 노출하기 위해 직접 import.
// grid_suggestor 배럴은 $SuggestCursorCopyWith 을 export 하지 않음.
import '../../../cores/grid_suggestor/models/suggest_cursor.dart';

part 'suggestion_state.freezed.dart';

@freezed
sealed class SuggestionState with _$SuggestionState {
  const factory SuggestionState.empty() = SuggestionStateEmpty;
  const factory SuggestionState.error(String message) = SuggestionStateError;
  const factory SuggestionState.loaded({
    required List<MediaItem> media,
    required CanvasRatio canvas,
    required List<GridSuggestion> suggestions,
    required int selectedIndex,
    SuggestCursor? cursor,
  }) = SuggestionStateLoaded;
}
