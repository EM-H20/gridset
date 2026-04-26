import 'package:flutter/material.dart';

import '../../cores/constants/app_colors.dart';

/// 사진/영상 picker (placeholder — Task 7~10 에서 구현).
class PhotoPickerPage extends StatelessWidget {
  const PhotoPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('사진 고르기')),
      body: const Center(child: Text('PhotoPickerPage')),
    );
  }
}
