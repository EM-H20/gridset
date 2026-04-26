import 'geometry/cell_geometry.dart';
import 'matching/media_to_cell_matcher.dart';
import 'models/canvas_ratio.dart';
import 'models/grid_suggestion.dart';
import 'models/media_item.dart';
import 'models/suggest_cursor.dart';
import 'ranking/candidate_ranker.dart';
import 'templates/grid_templates.dart';
import 'validation/input_validator.dart';

/// PRD §9-2-1 step 5 — "첫 호출 + 다른 제안 3회 = 최대 4 batch" 한도.
///
/// `batchIndex` 는 0-indexed 이므로 0..3 범위가 정상,
/// `>= _kMaxBatchCount` 면 stale cursor 로 간주.
const int _kMaxBatchCount = 4;

/// 자동 레이아웃 제안 — Phase A 진입점.
///
/// 7단계 파이프라인 (spec §4-1):
/// 1) 입력 검증, 2) 템플릿 조회, 3) 셀 기하, 4) 매핑, 5) 랭킹·dedup,
/// 6) top maxResults 선택, 7) cursor 갱신.
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
  // 1단계: 입력 검증
  validateSuggestInput(media: media, weightOf: weightOf);

  // cursor 초기화
  final activeCursor = cursor ??
      const SuggestCursor(
        shownTemplateNames: {},
        batchIndex: 0,
      );

  // PRD 한도 초과 cursor 방어
  if (activeCursor.batchIndex >= _kMaxBatchCount) {
    return (suggestions: const [], nextCursor: null);
  }

  // 2단계: 템플릿 조회
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

  // 3·4단계: 각 템플릿마다 셀 종횡비 계산 + 최적 매핑 탐색
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

  // 5·6단계: 랭킹 + dedup + top maxResults
  final ranked = rankCandidates(candidates).take(maxResults).toList();

  // 7단계: cursor 갱신
  // PRD 한도(4 batch) 또는 다음 batch 에 더 이상 보여줄 템플릿이 없으면 null.
  final nextShown = {
    ...activeCursor.shownTemplateNames,
    ...ranked.map((s) => s.templateName),
  };
  final nextAvailable = allTemplates
      .where((t) => !nextShown.contains(t.name))
      .isNotEmpty;
  // batchIndex == _kMaxBatchCount - 1 이면 이번이 마지막 batch — nextCursor null.
  final atLimit = activeCursor.batchIndex >= _kMaxBatchCount - 1 ||
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
