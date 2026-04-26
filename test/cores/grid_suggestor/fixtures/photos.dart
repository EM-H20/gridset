import 'package:gridset/cores/grid_suggestor/grid_suggestor.dart';

/// 2장 사진 — 가로 한 장, 세로 한 장.
const photos2Mixed = <MediaItem>[
  MediaItem(id: 'p_wide', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p_tall', type: MediaType.photo, aspectRatio: 0.667),
];

/// 2장 모두 정사각.
const photos2Square = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.0),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.0),
];
