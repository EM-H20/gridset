import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cores/constants/app_colors.dart';
import '../../cores/constants/app_spacing.dart';
import '../../cores/constants/app_text_style.dart';
import '../../cores/grid_suggestor/grid_suggestor.dart';
import '../../cores/widgets/buttons/app_button.dart';
import '../../flow/flow_selection_provider.dart';
import '../../routers/route_paths.dart';
import 'widgets/ratio_chip.dart';

/// 캔버스 비율 선택 화면 — 4 preset chip + "다음" CTA.
///
/// chip 선택 시 로컬 상태 갱신, "다음" 누름 시 [FlowSelectionNotifier.setCanvas]
/// 후 [RoutePaths.photoPicker] 로 push.
class CanvasPickerPage extends ConsumerStatefulWidget {
  const CanvasPickerPage({super.key});

  @override
  ConsumerState<CanvasPickerPage> createState() => _CanvasPickerPageState();
}

class _CanvasPickerPageState extends ConsumerState<CanvasPickerPage> {
  CanvasRatio? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.md),
              Text(
                '캔버스 비율',
                style: AppTextStyles.cardTitle_32.copyWith(
                  color: AppColors.charcoal,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                '어떤 비율로 만들까요?',
                style: AppTextStyles.body_16.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.0,
                  children: [
                    _chipFor(
                      const CanvasRatio.portrait916(),
                      '9:16',
                      'Reels · Story',
                    ),
                    _chipFor(
                      const CanvasRatio.square(),
                      '1:1',
                      'Feed',
                    ),
                    _chipFor(
                      const CanvasRatio.portrait45(),
                      '4:5',
                      'Feed (세로)',
                    ),
                    _chipFor(
                      const CanvasRatio.landscape169(),
                      '16:9',
                      'YouTube',
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.base),
              AppButton.primary(
                label: '다음',
                onPressed: _selected == null ? null : _onNext,
              ),
              SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipFor(CanvasRatio ratio, String label, String caption) {
    return RatioChip(
      ratio: ratio.value,
      label: label,
      caption: caption,
      selected: _selected == ratio,
      onTap: () => setState(() => _selected = ratio),
    );
  }

  void _onNext() {
    ref.read(flowSelectionNotifierProvider.notifier).setCanvas(_selected!);
    context.push(RoutePaths.photoPicker);
  }
}
