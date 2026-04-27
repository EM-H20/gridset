import 'package:flutter/material.dart';

import '../../../cores/constants/app_spacing.dart';
import '../../../cores/widgets/buttons/app_button.dart';

/// CTA bar — primary "이걸로" + outlined "다른 제안" / "빈 캔버스".
///
/// "다른 제안" 은 cursor 소진 시 비활성. "이걸로"/"빈 캔버스" 는 v1 stub
/// (Editor 미구현 — 호출부에서 SnackBar).
class SuggestionCtaBar extends StatelessWidget {
  const SuggestionCtaBar({
    super.key,
    required this.onPick,
    required this.onMore,
    required this.onBlank,
  });

  final VoidCallback onPick;
  final VoidCallback? onMore;
  final VoidCallback onBlank;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton.primary(label: '이걸로', onPressed: onPick),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton.outlined(
                  label: '다른 제안',
                  onPressed: onMore,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.outlined(
                  label: '빈 캔버스',
                  onPressed: onBlank,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
