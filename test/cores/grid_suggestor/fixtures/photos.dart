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

/// 3장 — 가로 1, 세로 1, 정사각 1 (다양성 mix).
const photos3Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.0),
];

/// 4장 — 2 가로 + 2 세로.
const photos4Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
];

/// 5장 — 2 가로 + 2 세로 + 1 정사각.
const photos5Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 1.0),
];

/// 6장 — 3 가로 + 3 세로.
const photos6Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p6', type: MediaType.photo, aspectRatio: 0.667),
];

/// 7장 — 3 가로 + 3 세로 + 1 정사각.
const photos7Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p6', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p7', type: MediaType.photo, aspectRatio: 1.0),
];

/// 8장 — 4 가로 + 4 세로.
const photos8Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p6', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p7', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p8', type: MediaType.photo, aspectRatio: 0.667),
];

/// 9장 — 3 가로 + 3 세로 + 3 정사각 (perf 측정 + 골든 모두 사용).
const photos9Mixed = <MediaItem>[
  MediaItem(id: 'p1', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p2', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p3', type: MediaType.photo, aspectRatio: 1.5),
  MediaItem(id: 'p4', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p5', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p6', type: MediaType.photo, aspectRatio: 0.667),
  MediaItem(id: 'p7', type: MediaType.photo, aspectRatio: 1.0),
  MediaItem(id: 'p8', type: MediaType.photo, aspectRatio: 1.0),
  MediaItem(id: 'p9', type: MediaType.photo, aspectRatio: 1.0),
];
