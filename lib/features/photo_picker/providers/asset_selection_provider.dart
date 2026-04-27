import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../cores/widgets/snackbars/app_snackbar.dart';

part 'asset_selection_provider.g.dart';

const int _kMaxSelection = 9;

/// 가로/세로 비율이 10:1 초과이면 레이아웃 계산이 불가능하므로 차단.
const double _kMaxAspectRatio = 10.0;

/// 세로/가로 비율이 10:1 초과(= 가로/세로 0.1 미만)도 마찬가지로 차단.
const double _kMinAspectRatio = 0.1;

/// 선택된 [AssetEntity] 들을 순서 보존해서 들고 있음.
///
/// 토글:
/// - 이미 있음 → 제거
/// - 없음 + length==9 → no-op + AppSnackbar 안내
/// - 없음 + AR 비정상 → no-op + AppSnackbar 안내
@Riverpod(keepAlive: false)
class AssetSelectionNotifier extends _$AssetSelectionNotifier {
  @override
  List<AssetEntity> build() => const [];

  /// [context] 는 SnackBar 표시용 — 테스트에서는 null 가능.
  void toggle(AssetEntity a, BuildContext? context) {
    final idx = state.indexWhere((e) => e.id == a.id);
    if (idx >= 0) {
      // 이미 선택된 항목 → 제거
      state = [...state.sublist(0, idx), ...state.sublist(idx + 1)];
      return;
    }

    if (state.length >= _kMaxSelection) {
      if (context != null) {
        AppSnackbar.show(
          context,
          message: '한 번에 9장까지 만들 수 있어요',
          iconPath: 'assets/icons/icon_block.svg',
        );
      }
      return;
    }

    if (a.width <= 0 || a.height <= 0) return;
    final ar = a.width / a.height;
    if (ar > _kMaxAspectRatio || ar < _kMinAspectRatio) {
      if (context != null) {
        AppSnackbar.show(
          context,
          message: '이 사진은 비율이 너무 길어 빠졌어요',
          iconPath: 'assets/icons/icon_block.svg',
        );
      }
      return;
    }

    state = [...state, a];
  }

  /// 검증 회피 fast-path — 테스트용.
  void replaceAll(List<AssetEntity> items) => state = items;
}
