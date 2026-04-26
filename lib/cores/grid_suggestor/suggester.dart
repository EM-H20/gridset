import 'geometry/cell_geometry.dart';
import 'matching/media_to_cell_matcher.dart';
import 'models/canvas_ratio.dart';
import 'models/grid_suggestion.dart';
import 'models/media_item.dart';
import 'models/suggest_cursor.dart';
import 'ranking/candidate_ranker.dart';
import 'templates/grid_templates.dart';
import 'validation/input_validator.dart';

/// 자동 레이아웃 제안 — Phase A 진입점.
///
/// 7-step pipeline (spec §4-1):
/// 1) validate, 2) templateLookup, 3) cellGeometry, 4) matcher, 5) ranker,
/// 6) pick top maxResults, 7) advance cursor.
///
/// PRD §9-2-1 step 5: 첫 호출 + 다른 제안 3회 = 최대 4 batch.
/// nextCursor == null 이면 풀 소진 또는 PRD 한도 도달.
({List<GridSuggestion> suggestions, SuggestCursor? nextCursor}) suggest({
  required List<MediaItem> media,
  required CanvasRatio canvas,
  SuggestCursor? cursor,
  double Function(MediaItem item)? weightOf,
  int maxResults = 3,
}) {
  // Step 1: validate
  validateSuggestInput(media: media, weightOf: weightOf);

  // cursor 초기화
  final activeCursor = cursor ??
      const SuggestCursor(
        shownTemplateNames: {},
        batchIndex: 0,
      );

  // PRD 한도 초과 cursor 방어
  if (activeCursor.batchIndex >= 4) {
    return (suggestions: const [], nextCursor: null);
  }

  // Step 2: templateLookup
  final allTemplates = kGridTemplates[media.length] ?? const [];
  final available = allTemplates
      .where((t) => !activeCursor.shownTemplateNames.contains(t.name))
      .toList();
  if (available.isEmpty) {
    return (suggestions: const [], nextCursor: null);
  }

  // 미디어 정규화
  final mediaAspects = media.map((m) => m.aspectRatio).toList();
  final mediaWeights = media.map((m) => weightOf?.call(m) ?? 1.0).toList();

  // Step 3-4: 각 템플릿마다 cellAspects + bestMapping
  final candidates = <GridSuggestion>[];
  for (final template in available) {
    final aspectsByCell = cellAspectRatios(template.tree, canvas);
    // template.cellIds 순서 유지하며 cellAspects 추출
    final cellAspects =
        template.cellIds.map((id) => aspectsByCell[id]!).toList();

    final mapping = bestMapping(
      cellAspects: cellAspects,
      mediaAspects: mediaAspects,
      mediaWeights: mediaWeights,
    );

    final mediaByCellId = <int, String>{};
    for (var i = 0; i < template.cellIds.length; i++) {
      mediaByCellId[template.cellIds[i]] = media[mapping.mapping[i]].id;
    }

    candidates.add(GridSuggestion(
      tree: template.tree,
      mediaByCellId: mediaByCellId,
      loss: mapping.loss,
      templateName: template.name,
    ));
  }

  // Step 5-6: rank + dedup + top maxResults
  final ranked = rankCandidates(candidates).take(maxResults).toList();

  // Step 7: cursor 갱신
  // PRD 한도(4 batch) 또는 다음 batch 에 더 이상 보여줄 템플릿이 없으면 null.
  final nextShown = {
    ...activeCursor.shownTemplateNames,
    ...ranked.map((s) => s.templateName),
  };
  final nextAvailable = allTemplates
      .where((t) => !nextShown.contains(t.name))
      .isNotEmpty;
  final atLimit = activeCursor.batchIndex >= 3 ||
      ranked.isEmpty ||
      !nextAvailable;
  final nextCursor = atLimit
      ? null
      : SuggestCursor(
          shownTemplateNames: nextShown,
          batchIndex: activeCursor.batchIndex + 1,
        );

  return (suggestions: ranked, nextCursor: nextCursor);
}
