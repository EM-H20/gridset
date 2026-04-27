import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/features/share/providers/share_dispatcher.dart';

class _RecordingDispatcher implements ShareDispatcher {
  List<String>? lastFilePaths;
  String? lastSubject;

  @override
  Future<void> share({required List<String> filePaths, String? subject}) async {
    lastFilePaths = filePaths;
    lastSubject = subject;
  }
}

void main() {
  test('인터페이스 구현 가능 — 호출 인자 보존', () async {
    final fake = _RecordingDispatcher();
    await fake.share(filePaths: ['/tmp/a.png'], subject: 'Gridset');
    expect(fake.lastFilePaths, ['/tmp/a.png']);
    expect(fake.lastSubject, 'Gridset');
  });

  test('shareDispatcherProvider — 기본 구현 SharePlusDispatcher', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dispatcher = container.read(shareDispatcherProvider);
    expect(dispatcher, isA<ShareDispatcher>());
  });
}
