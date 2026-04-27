import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridset/features/suggestion/providers/selected_assets_provider.dart';
import 'package:photo_manager/photo_manager.dart';

// 테스트용 가짜 AssetEntity — id 만 사용. photo_manager 의 AssetEntity 는
// final 클래스라 `AssetEntity(id: ..., typeInt: 1, width: 1, height: 1)` 로
// 직접 생성해도 native 호출이 일어나지 않으므로 unit test 안전.
AssetEntity _fake(String id) => AssetEntity(
      id: id,
      typeInt: 1, // image
      width: 100,
      height: 100,
    );

void main() {
  test('초기 state 는 빈 map', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(selectedAssetsNotifierProvider), isEmpty);
  });

  test('setAssets — list → id 키 map', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier =
        container.read(selectedAssetsNotifierProvider.notifier);

    notifier.setAssets([_fake('a'), _fake('b')]);

    final state = container.read(selectedAssetsNotifierProvider);
    expect(state.keys, ['a', 'b']);
    expect(state['a']!.id, 'a');
    expect(state['b']!.id, 'b');
  });

  test('setAssets — 빈 리스트 → 빈 map', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier =
        container.read(selectedAssetsNotifierProvider.notifier);

    notifier.setAssets(const []);
    expect(container.read(selectedAssetsNotifierProvider), isEmpty);
  });

  test('setAssets — 동일 id 중복 → 후입력 우선 (last-wins)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier =
        container.read(selectedAssetsNotifierProvider.notifier);

    final first = _fake('x');
    final second = _fake('x'); // 같은 id 의 다른 인스턴스
    notifier.setAssets([first, second]);

    final state = container.read(selectedAssetsNotifierProvider);
    expect(state.length, 1);
    expect(identical(state['x'], second), isTrue,
        reason: 'Map literal 의 last-wins 시맨틱과 일관');
  });

  test('state map 은 수정 불가', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier =
        container.read(selectedAssetsNotifierProvider.notifier);

    notifier.setAssets([_fake('a')]);
    final state = container.read(selectedAssetsNotifierProvider);

    expect(() => state['b'] = _fake('b'), throwsUnsupportedError);
  });
}
