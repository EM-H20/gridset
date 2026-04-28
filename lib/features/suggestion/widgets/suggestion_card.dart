import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_spacing.dart';
import '../../../cores/grid_suggestor/grid_suggestor.dart';
import '../../../cores/widgets/grid_layout/bsp_grid_layout.dart';
import '../providers/thumbnail_loader.dart';

/// 후보 카드 한 개 — BspGridLayout 위에 사진 썸네일 매핑.
///
/// `mediaByCellId` (cellId → assetId) 와 `assetsById` (assetId →
/// AssetEntity) 두 lookup 을 거쳐 `_MappedThumb` 가 비동기 로드.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.canvas,
    required this.assetsById,
  });

  final GridSuggestion suggestion;
  final CanvasRatio canvas;
  final Map<String, AssetEntity> assetsById;

  @override
  Widget build(BuildContext context) {
    return BspGridLayout(
      tree: suggestion.tree,
      aspectRatio: canvas.value,
      borderColor: AppColors.lightCream,
      cellBuilder: (cellId, _) => _MappedThumb(
        cellId: cellId,
        mediaByCellId: suggestion.mediaByCellId,
        assetsById: assetsById,
      ),
    );
  }
}

/// 매핑된 셀 — id → AssetEntity → 썸네일 byte → Image.memory(cover).
///
/// stateful — `FutureBuilder` 가 매 rebuild 마다 새 Future 를 받으면 한
/// 프레임 `waiting` 으로 떨어져 깜빡임 발생. State 안에 future 를 1회만
/// 시작하고 의존 입력 (cellId / asset) 변경 시에만 재생성한다.
class _MappedThumb extends ConsumerStatefulWidget {
  const _MappedThumb({
    required this.cellId,
    required this.mediaByCellId,
    required this.assetsById,
  });

  final int cellId;
  final Map<int, String> mediaByCellId;
  final Map<String, AssetEntity> assetsById;

  @override
  ConsumerState<_MappedThumb> createState() => _MappedThumbState();
}

class _MappedThumbState extends ConsumerState<_MappedThumb>
    with AutomaticKeepAliveClientMixin {
  Future<Uint8List?>? _future;
  AssetEntity? _asset;

  // PageView 의 cache 밖으로 넘어가도 element/State dispose 되지 않게 keepAlive.
  // dispose → re-mount 시 _future 가 새로 생성되어 썸네일 재로드 + 깜빡임이
  // 발생. swipe 좌우로 부드럽게 넘기려면 셀 단위 keepAlive 가 필수.
  // SliverChildBuilderDelegate.addAutomaticKeepAlives default true 라 PageView 가
  // 본 mixin 의 KeepAliveNotification 을 받아 element 를 살려둔다.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _resolveAndLoad();
  }

  @override
  void didUpdateWidget(covariant _MappedThumb old) {
    super.didUpdateWidget(old);
    final prevId = old.mediaByCellId[old.cellId];
    final nextId = widget.mediaByCellId[widget.cellId];
    final prevAsset = prevId == null ? null : old.assetsById[prevId];
    final nextAsset = nextId == null ? null : widget.assetsById[nextId];
    // assetId 또는 asset.id 가 바뀐 경우에만 재로드.
    // identical() 은 매 pumpWidget 마다 새 AssetEntity 인스턴스가 생성될 때
    // 불필요한 재로드를 유발하므로 값(id) 비교로 대체한다.
    if (prevId != nextId || prevAsset?.id != nextAsset?.id) {
      _resolveAndLoad();
    }
  }

  void _resolveAndLoad() {
    final assetId = widget.mediaByCellId[widget.cellId];
    assert(assetId != null,
        'mediaByCellId 에 cellId=${widget.cellId} 매핑 없음 — 알고리즘 계약 위반');
    final asset = assetId == null ? null : widget.assetsById[assetId];
    _asset = asset;
    if (asset == null) {
      if (assetId != null) {
        debugPrint('⚠️ asset 누락 cellId=${widget.cellId} id=$assetId');
      }
      _future = null;
      return;
    }
    _future = ref
        .read(thumbnailLoaderProvider)
        .load(asset, size: const ThumbnailSize.square(512));
  }

  @override
  Widget build(BuildContext context) {
    // AutomaticKeepAliveClientMixin 사용 시 build 첫 줄에서 super 호출 필수.
    super.build(context);
    final asset = _asset;
    final future = _future;
    if (asset == null || future == null) {
      return const _PlaceholderCell();
    }
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _PlaceholderCell();
        }
        final bytes = snap.data;
        if (snap.hasError || bytes == null) {
          debugPrint(
            '⚠️ thumb load 실패 cellId=${widget.cellId} '
            'asset=${asset.id} err=${snap.error}',
          );
          return const _PlaceholderCell();
        }
        final image = Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
        if (asset.type == AssetType.video) {
          return Stack(
            fit: StackFit.expand,
            children: [
              image,
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: const _VideoIndicator(),
              ),
            ],
          );
        }
        return image;
      },
    );
  }
}

/// 영상 셀 우상단에 표시되는 ▶ 아이콘 오버레이.
///
/// charcoal40(반투명) 원형 배경 — 썸네일 색상에 관계없이 아이콘 가시성 확보.
class _VideoIndicator extends StatelessWidget {
  const _VideoIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xl,
      height: AppSpacing.xl,
      decoration: const BoxDecoration(
        color: AppColors.charcoal40,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/icons/icon_play.svg',
        width: AppSpacing.base,
        height: AppSpacing.base,
        colorFilter: const ColorFilter.mode(
          AppColors.offWhite,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _PlaceholderCell extends StatelessWidget {
  const _PlaceholderCell();

  @override
  Widget build(BuildContext context) {
    // 매핑 실패 / 로딩 중 모두 동일 톤. 사용자에게 위협 톤 노출 X.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightCream,
        border: Border.all(color: AppColors.charcoal04),
      ),
    );
  }
}
