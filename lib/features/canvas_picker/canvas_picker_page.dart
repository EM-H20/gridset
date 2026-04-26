import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';

/// 캔버스 비율 선택 화면 (placeholder — Task 6 에서 구현).
class CanvasPickerPage extends StatelessWidget {
  const CanvasPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('비율')),
      body: const Center(child: Text('CanvasPickerPage')),
    );
  }
}
