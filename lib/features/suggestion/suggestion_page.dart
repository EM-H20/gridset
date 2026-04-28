import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/widgets/snackbars/app_snackbar.dart';
import '../share/share_coordinator.dart';
import '../share/widgets/composing_modal.dart';
import 'providers/selected_assets_provider.dart';
import 'providers/suggestion_notifier.dart';
import 'providers/suggestion_state.dart';
import 'widgets/suggestion_card.dart';
import 'widgets/suggestion_cta_bar.dart';
import 'widgets/suggestion_dots.dart';

/// 후보 화면 — PageView 가로 풀브리드 + edge peek (viewportFraction 0.92) +
/// dots + CTA bar (인스타 캐러셀 식).
class SuggestionPage extends ConsumerStatefulWidget {
  const SuggestionPage({super.key});

  @override
  ConsumerState<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends ConsumerState<SuggestionPage> {
  // 인스타 캐러셀 식: 메인 카드 거의 풀폭(92%) + 양 옆 인접 카드 모서리만 살짝.
  final PageController _controller =
      PageController(viewportFraction: 0.92, initialPage: 0);

  // 카드별 RepaintBoundary GlobalKey 영구 보유 — index → GlobalKey.
  //
  // 이전엔 selected 카드 1개에만 RepaintBoundary+key 부착했는데, swipe 마다
  // RepaintBoundary 의 key 가 widget tree 에서 add/remove 되면서 element 가
  // 파괴+재생성 → _MappedThumb State.dispose → _future 재생성 → 썸네일 재로드
  // (사용자가 본 깜빡임). 카드마다 고정 GlobalKey 로 element 안정화 + State
  // 보존. ImageCapturer 는 selectedIndex 의 key 사용.
  final List<GlobalKey> _cardKeys = [];

  GlobalKey _keyFor(int i) {
    while (_cardKeys.length <= i) {
      _cardKeys.add(GlobalKey());
    }
    return _cardKeys[i];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suggestionNotifierProvider);
    final assetsById = ref.watch(selectedAssetsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '제안',
          style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal),
        ),
      ),
      body: SafeArea(
        child: switch (state) {
          SuggestionStateEmpty() => const _Empty(),
          SuggestionStateError(:final message) => _Error(message: message),
          SuggestionStateLoaded() => _Loaded(
              state: state,
              assetsById: assetsById,
              controller: _controller,
              keyFor: _keyFor,
              onPageChanged: (i) =>
                  ref.read(suggestionNotifierProvider.notifier).selectIndex(i),
              onPick: () => _onPick(context, ref, state),
              onMore: state.cursor == null
                  ? null
                  : () => _onMore(context, ref),
              onBlank: () => _stub(context, '에디터는 곧 준비됩니다'),
            ),
        },
      ),
    );
  }

  void _stub(BuildContext context, String message) {
    AppSnackbar.show(
      context,
      message: message,
      iconPath: 'assets/icons/icon_copy.svg',
    );
  }

  /// "이걸로" 콜백 — ShareCoordinator 를 통해 사진/영상 분기 처리.
  ///
  /// 200ms 지연 후 ComposingModal 노출 — 사진 분기는 보통 그 전에 끝나
  /// modal 이 불필요하게 뜨지 않는다. 영상 분기는 수초 걸려 modal + progress bar 로
  /// 사용자에게 진행 상황 명시. cancel 은 coordinator.cancel() 을 통해 VideoComposer 로 전달.
  Future<void> _onPick(
    BuildContext context,
    WidgetRef ref,
    SuggestionStateLoaded state,
  ) async {
    final container = ProviderScope.containerOf(context);
    final coordinator = ShareCoordinator(container);
    final suggestion = state.suggestions[state.selectedIndex];
    final assetsById = ref.read(selectedAssetsNotifierProvider);

    // dialog 노출/닫힘 명시 추적 — `Navigator.of(context).canPop()` 만 보면
    // SuggestionPage 자체가 pop 가능한 라우트라 dialog 닫힌 후에도 true 라
    // pop 시 SuggestionPage 가 홈으로 튕겨 나가는 회귀 위험. 별 플래그로 추적.
    var dialogOpen = false;
    var cancelInFlight = false;
    var completed = false; // run() 종료 — Timer / 늦은 modal 노출 차단.
    double progress = 0;
    StateSetter? rebuildModal;
    Timer? modalDelayTimer;

    void closeDialogIfOpen() {
      // dialog dispose 후 stale setter 호출 방지 — null 화 먼저.
      rebuildModal = null;
      if (!dialogOpen) return;
      if (!context.mounted) {
        // 라우트가 이미 unmount — 플래그만 정리.
        dialogOpen = false;
        return;
      }
      dialogOpen = false;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    void showModalIfNotYet() {
      // run() 이 200ms 안에 끝났으면 modal 띄우지 않음 — stray dialog 차단.
      if (completed) return;
      if (dialogOpen) return;
      if (!context.mounted) return;
      dialogOpen = true;
      // ignore: use_build_context_synchronously
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        // 화면 전체 (AppBar 포함) 를 dark dim 으로 덮어 cream 카드만 부각.
        // default barrierColor (Colors.black54) 보다 진한 charcoal82 사용.
        barrierColor: AppColors.charcoal82,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (_, setStateDialog) {
            rebuildModal = setStateDialog;
            return ComposingModal(
              progress: progress,
              onCancel: () async {
                // 두 번 탭 race 차단 — 첫 호출 in-flight 동안 두 번째 무시.
                if (cancelInFlight) return;
                cancelInFlight = true;
                // dialog 를 먼저 닫고 cancel 호출 — dialogCtx 의 mounted 가
                // pop 후 false 가 되므로 async gap 전에 처리. ffmpeg cancel
                // 자체는 fire-and-forget (사용자는 이미 dialog 닫혔다고 인지).
                dialogOpen = false;
                rebuildModal = null;
                if (Navigator.of(dialogCtx).canPop()) {
                  Navigator.of(dialogCtx).pop();
                }
                unawaited(coordinator.cancel());
              },
            );
          },
        ),
      ).whenComplete(() {
        // 사용자가 시스템 back 등 다른 경로로 dialog 닫히는 케이스 추적.
        dialogOpen = false;
        rebuildModal = null;
      });
    }

    // 200ms 후 modal 노출 — 사진 분기는 보통 그 전에 끝나 불필요한 modal 방지.
    // Timer 사용해 run 완료 시 cancel 가능하게 (Future.delayed 는 cancel 불가).
    modalDelayTimer = Timer(
      const Duration(milliseconds: 200),
      showModalIfNotYet,
    );

    try {
      await coordinator.run(
        cardKey: _keyFor(state.selectedIndex),
        suggestion: suggestion,
        canvas: state.canvas,
        assetsById: assetsById,
        onProgress: (p) {
          // dialog 닫힌 후 onProgress 호출 시 stale setter 호출 방지.
          if (!dialogOpen) return;
          progress = p;
          rebuildModal?.call(() {});
        },
      );
    } catch (e) {
      completed = true;
      modalDelayTimer.cancel();
      if (!context.mounted) return;
      closeDialogIfOpen();
      // cancel 로 인한 throw 라면 사용자 의도이므로 SnackBar 무음. 그 외는 안내.
      if (!cancelInFlight) {
        AppSnackbar.show(
          context,
          message: '영상 만들기에 실패했어요',
          iconPath: 'assets/icons/icon_siren.svg',
        );
      }
      return;
    }

    completed = true;
    modalDelayTimer.cancel();
    if (!context.mounted) return;
    closeDialogIfOpen();
  }

  /// "다른 제안" 콜백 — loadMore 후 cursor 가 null 로 떨어지면 풀 소진을
  /// 명시적으로 알려서 사용자가 "왜 다음부터 비활성?" 의문을 갖지 않게 한다.
  ///
  /// 풀 소진 케이스는 알고리즘이 다음 batch 후보가 없거나 PRD 한도(4 batch)에
  /// 도달했을 때 발생. v1 의 작은 template 풀(N별 3~5개)에서는 1~2 batch 만에
  /// 자주 발생 — 풀 보강은 후속 Phase D PR.
  void _onMore(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(suggestionNotifierProvider.notifier);
    notifier.loadMore();

    final after = ref.read(suggestionNotifierProvider);
    if (after is SuggestionStateLoaded && after.cursor == null) {
      // copy 아이콘은 복사 행위 전용. 마지막 제안 안내는 기본 siren 톤.
      AppSnackbar.show(
        context,
        message: '이게 마지막 제안이에요',
        iconPath: 'assets/icons/icon_siren.svg',
      );
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          '먼저 사진을 2장 이상 골라주세요',
          style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal82),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          '이 조합으론 제안을 만들 수 없어요\n$message',
          style: AppTextStyles.body_16.copyWith(color: AppColors.charcoal82),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.assetsById,
    required this.controller,
    required this.keyFor,
    required this.onPageChanged,
    required this.onPick,
    required this.onMore,
    required this.onBlank,
  });

  final SuggestionStateLoaded state;
  final Map<String, AssetEntity> assetsById;
  final PageController controller;
  // 카드 index → 고정 GlobalKey. swipe 시 key 변동 없이 element 안정화.
  final GlobalKey Function(int index) keyFor;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPick;
  final VoidCallback? onMore;
  final VoidCallback onBlank;

  @override
  Widget build(BuildContext context) {
    // PageView 만 화면 가장자리까지 풀브리드, 헤더/dots/CTA 는 base padding.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.md),
              Text(
                '${state.suggestions.length}개 후보',
                style: AppTextStyles.cardTitle_32
                    .copyWith(color: AppColors.charcoal),
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: controller,
            // 인접 1장 백그라운드 빌드 → _MappedThumb 의 FutureBuilder 가
            // 미리 시작되어 swipe 시점에 photo_manager 캐시 적재 완료. 깜빡임 0.
            allowImplicitScrolling: true,
            onPageChanged: onPageChanged,
            itemCount: state.suggestions.length,
            itemBuilder: (_, i) {
              final selected = i == state.selectedIndex;
              final card = SuggestionCard(
                suggestion: state.suggestions[i],
                canvas: state.canvas,
                assetsById: assetsById,
              );
              return Padding(
                // viewportFraction 92% 가 양 옆 4% gap 을 만든다 — 추가 gap 은
                // xxs 만 줘서 카드끼리 너무 붙지 않게 한다.
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1.0 : 0.5,
                  // PageView 의 SliverFillViewport 는 자식을 양 axis tight 로
                  // 강제하므로 안쪽 BspGridLayout 의 AspectRatio 가 무력화된다.
                  // Center 로 감싸 자식이 비율대로 자기 사이즈 결정 + 가운데 정렬.
                  // 결과: 9:16 → 세로 길게, 1:1 → 정사각형, 16:9 → 가로 길게.
                  child: Center(
                    // 모든 카드를 RepaintBoundary 로 wrapping — 카드별 고정
                    // GlobalKey 부착해 swipe 시 element 재생성 차단. 캡처는
                    // ImageCapturer 가 selectedIndex 의 key 사용.
                    child: RepaintBoundary(
                      key: keyFor(i),
                      child: card,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SuggestionDots(
                count: state.suggestions.length,
                current: state.selectedIndex,
              ),
              SuggestionCtaBar(
                onPick: onPick,
                onMore: onMore,
                onBlank: onBlank,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
