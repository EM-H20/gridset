import '../models/named_template.dart';
import '_n2_templates.dart';

/// N → 큐레이션된 템플릿 list.
///
/// Phase A 는 N=2 만. Phase B 에서 N=3..9 추가.
/// 무결성 invariant 는 templates_test 에서 검증.
final Map<int, List<NamedTemplate>> kGridTemplates = {
  2: n2Templates,
};
