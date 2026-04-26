import 'dart:collection';

import '../models/named_template.dart';
import '_n2_templates.dart';

/// N → 큐레이션된 템플릿 list.
///
/// Phase A 는 N=2 만. Phase B 에서 N=3..9 추가 시 새 N별 파일을 만들고 이 Map 의 정적 선언에 추가.
/// 외부에서 Map/List 변경을 막기 위해 [UnmodifiableMapView]·[UnmodifiableListView] 로 노출.
/// 무결성 invariant 는 templates_test 에서 검증.
final Map<int, List<NamedTemplate>> kGridTemplates =
    UnmodifiableMapView<int, List<NamedTemplate>>({
  2: UnmodifiableListView<NamedTemplate>(n2Templates),
});
