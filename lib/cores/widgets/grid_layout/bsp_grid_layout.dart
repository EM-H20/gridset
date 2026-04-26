import 'package:flutter/material.dart' hide Split;

import '../../grid_suggestor/grid_suggestor.dart';

/// 셀 빌더 시그니처 — 셀 id 와 정규화 bbox(0..1) 를 받아 위젯 반환.
typedef BspCellBuilder = Widget Function(int cellId, Rect normalizedBBox);

/// BSP 트리를 화면 비율(`aspectRatio`)에 맞춰 셀 단위 위젯으로 펼쳐주는 primitive.
///
/// 알고리즘 모듈의 [cellBBoxes] 를 사용해 트리를 정규화 좌표(0..1)로 펼치고,
/// [AspectRatio] 컨테이너의 [Stack] + [Positioned.fromRect] 로 각 셀에 빌더 호출.
///
/// 두 use case 가 공유:
/// - dev 갤러리: 셀 안에 cellId 텍스트 표시 (`GridTemplatePreview`)
/// - production suggestion: 셀 안에 placeholder / 사진 매핑 (`SuggestionCard`)
class BspGridLayout extends StatelessWidget {
  const BspGridLayout({
    super.key,
    required this.tree,
    required this.aspectRatio,
    required this.cellBuilder,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.borderColor,
  });

  final GridNode tree;
  final double aspectRatio;
  final BspCellBuilder cellBuilder;
  final BorderRadius borderRadius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final bboxes = cellBBoxes(tree);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  for (final entry in bboxes.entries)
                    Positioned.fromRect(
                      rect: Rect.fromLTWH(
                        entry.value.left * w,
                        entry.value.top * h,
                        entry.value.width * w,
                        entry.value.height * h,
                      ),
                      child: cellBuilder(
                        entry.key,
                        Rect.fromLTWH(
                          entry.value.left,
                          entry.value.top,
                          entry.value.width,
                          entry.value.height,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
