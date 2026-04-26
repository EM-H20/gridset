/// 캔버스 종횡비 — 알고리즘이 셀 종횡비 계산 시 사용.
///
/// PRD §F10: 9:16 / 1:1 / 4:5 / 16:9 + custom 지원.
/// `value` 는 W / H 양의 유한값.
sealed class CanvasRatio {
  const CanvasRatio();
  double get value;

  const factory CanvasRatio.portrait916() = _R916;
  const factory CanvasRatio.square() = _R11;
  const factory CanvasRatio.portrait45() = _R45;
  const factory CanvasRatio.landscape169() = _R169;
  const factory CanvasRatio.custom(double w, double h) = _RCustom;
}

final class _R916 extends CanvasRatio {
  const _R916();
  @override
  double get value => 9 / 16;

  @override
  bool operator ==(Object other) => other is _R916;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class _R11 extends CanvasRatio {
  const _R11();
  @override
  double get value => 1;

  @override
  bool operator ==(Object other) => other is _R11;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class _R45 extends CanvasRatio {
  const _R45();
  @override
  double get value => 4 / 5;

  @override
  bool operator ==(Object other) => other is _R45;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class _R169 extends CanvasRatio {
  const _R169();
  @override
  double get value => 16 / 9;

  @override
  bool operator ==(Object other) => other is _R169;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class _RCustom extends CanvasRatio {
  final double w;
  final double h;
  const _RCustom(this.w, this.h)
      : assert(w > 0, 'w must be positive'),
        assert(h > 0, 'h must be positive');

  @override
  double get value => w / h;

  @override
  bool operator ==(Object other) =>
      other is _RCustom && other.w == w && other.h == h;

  @override
  int get hashCode => Object.hash(w, h);
}
