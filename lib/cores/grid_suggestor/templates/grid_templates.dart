import 'dart:collection';

import '../models/named_template.dart';
import '_n2_templates.dart';
import '_n3_templates.dart';
import '_n4_templates.dart';
import '_n5_templates.dart';
import '_n6_templates.dart';
import '_n7_templates.dart';
import '_n8_templates.dart';

/// N → 큐레이션된 템플릿 list.
///
/// Phase B 진행 중 — N=2..8 등록 완료. Task 8 에서 N=9 추가.
/// 외부에서 Map/List 변경을 막기 위해 [UnmodifiableMapView]·[UnmodifiableListView] 로 노출.
/// 무결성 invariant 는 templates_test 에서 검증.
final Map<int, List<NamedTemplate>> kGridTemplates =
    UnmodifiableMapView<int, List<NamedTemplate>>({
  2: UnmodifiableListView<NamedTemplate>(n2Templates),
  3: UnmodifiableListView<NamedTemplate>(n3Templates),
  4: UnmodifiableListView<NamedTemplate>(n4Templates),
  5: UnmodifiableListView<NamedTemplate>(n5Templates),
  6: UnmodifiableListView<NamedTemplate>(n6Templates),
  7: UnmodifiableListView<NamedTemplate>(n7Templates),
  8: UnmodifiableListView<NamedTemplate>(n8Templates),
});
