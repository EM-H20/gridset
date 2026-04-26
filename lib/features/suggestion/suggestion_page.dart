import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';

/// 후보 화면 (placeholder — Task 12~14 에서 구현).
class SuggestionPage extends StatelessWidget {
  const SuggestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('제안')),
      body: const Center(child: Text('SuggestionPage')),
    );
  }
}
