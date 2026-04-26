import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/widgets/snackbars/app_snackbar.dart';
import 'providers/suggestion_notifier.dart';
import 'providers/suggestion_state.dart';
import 'widgets/suggestion_card.dart';
import 'widgets/suggestion_cta_bar.dart';
import 'widgets/suggestion_dots.dart';

/// 후보 화면 — PageView + Peek (viewportFraction 0.7) + dots + CTA bar.
class SuggestionPage extends ConsumerStatefulWidget {
  const SuggestionPage({super.key});

  @override
  ConsumerState<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends ConsumerState<SuggestionPage> {
  final PageController _controller =
      PageController(viewportFraction: 0.7, initialPage: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suggestionNotifierProvider);

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
              controller: _controller,
              onPageChanged: (i) =>
                  ref.read(suggestionNotifierProvider.notifier).selectIndex(i),
              onPick: () => _stub(context, '에디터는 곧 준비됩니다'),
              onMore: state.cursor == null
                  ? null
                  : () {
                      ref
                          .read(suggestionNotifierProvider.notifier)
                          .loadMore();
                    },
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
    required this.controller,
    required this.onPageChanged,
    required this.onPick,
    required this.onMore,
    required this.onBlank,
  });

  final SuggestionStateLoaded state;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPick;
  final VoidCallback? onMore;
  final VoidCallback onBlank;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.md),
          Text(
            '${state.suggestions.length}개 후보',
            style: AppTextStyles.cardTitle_32.copyWith(color: AppColors.charcoal),
          ),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: state.suggestions.length,
              itemBuilder: (_, i) {
                final selected = i == state.selectedIndex;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: selected ? 1.0 : 0.5,
                    child: SuggestionCard(
                      suggestion: state.suggestions[i],
                      canvas: state.canvas,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: AppSpacing.md),
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
    );
  }
}
