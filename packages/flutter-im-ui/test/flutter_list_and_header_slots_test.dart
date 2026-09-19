import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-038 and FR-039: the pieces the Flutter app had to build around the kit — pull to refresh on a
// list container, its own empty state for an empty directory, a tappable avatar and a header that
// takes one. The kit owns them now, so the app wires instead of wrapping.

const _strings = FlareStrings();

Widget _host(Widget child) => FlareStringsScope(
  strings: _strings,
  child: MaterialApp(
    home: FlareTheme(
      mode: FlareThemeMode.light,
      child: Scaffold(body: child),
    ),
  ),
);

FlareContact _contact(String id) =>
    FlareContact(id: id, name: 'Ada $id', avatarUrl: null);

void main() {
  testWidgets(
    'a list container takes the pull-to-refresh gesture only when the host asks for it',
    (tester) async {
      var refreshed = 0;
      await tester.pumpWidget(
        _host(
          FlareConversationListContainer(
            onRefresh: () async => refreshed++,
            child: ListView(
              children: const [SizedBox(height: 600, child: Text('list'))],
            ),
          ),
        ),
      );
      expect(find.byType(RefreshIndicator), findsOneWidget);

      await tester.fling(find.text('list'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();
      expect(refreshed, 1);

      await tester.pumpWidget(
        _host(
          FlareConversationListContainer(
            child: ListView(
              children: const [SizedBox(height: 600, child: Text('list'))],
            ),
          ),
        ),
      );
      expect(
        find.byType(RefreshIndicator),
        findsNothing,
        reason: 'no handler, no gesture',
      );
    },
  );

  testWidgets('a loading or failed container does not offer to refresh', (
    tester,
  ) async {
    for (final state in const [
      FlareViewState<List<Object?>>(status: FlareViewStatus.loading),
      FlareViewState<List<Object?>>(
        status: FlareViewStatus.error,
        error: '加载失败',
      ),
    ]) {
      await tester.pumpWidget(
        _host(
          FlareConversationListContainer(
            state: state,
            onRefresh: () async {},
            child: const Text('list'),
          ),
        ),
      );
      expect(
        find.byType(RefreshIndicator),
        findsNothing,
        reason: '${state.status}',
      );
    }
  });

  testWidgets('an empty directory draws the kit state, or the host\'s own', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const FlareContactList(items: [])));
    expect(find.text(_strings.noContacts), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const FlareContactList(
          items: [],
          empty: Center(child: Text('先去加个好友')),
        ),
      ),
    );
    expect(find.text('先去加个好友'), findsOneWidget);
    expect(find.text(_strings.noContacts), findsNothing);

    await tester.pumpWidget(
      _host(
        FlareContactList(items: [_contact('a')], empty: const Text('先去加个好友')),
      ),
    );
    expect(
      find.text('先去加个好友'),
      findsNothing,
      reason: 'the slot is for an empty list only',
    );
  });

  testWidgets('an empty directory can still be pulled to refresh', (
    tester,
  ) async {
    var refreshed = 0;
    await tester.pumpWidget(
      _host(
        FlareConversationListContainer(
          onRefresh: () async => refreshed++,
          child: const FlareContactList(items: []),
        ),
      ),
    );

    await tester.fling(
      find.text(_strings.noContacts),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();
    expect(
      refreshed,
      1,
      reason: 'an empty directory is exactly when someone pulls',
    );
  });

  testWidgets('an avatar with a handler is a named button with a real target', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var opened = 0;
    await tester.pumpWidget(
      _host(
        Center(
          child: FlareAvatar(
            userId: 'u1',
            displayName: 'Ada Chen',
            size: 32,
            onTap: () => opened++,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Ada Chen'), findsOneWidget);
    final box = tester.getSize(find.byType(FlareAvatar));
    expect(box.width, greaterThanOrEqualTo(FlareSizes.touchTarget));
    expect(box.height, greaterThanOrEqualTo(FlareSizes.touchTarget));

    await tester.tap(find.byType(FlareAvatar));
    expect(opened, 1);
    handle.dispose();
  });

  testWidgets(
    'an avatar without a handler is not a button and keeps its size',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const Center(
            child: FlareAvatar(userId: 'u1', displayName: 'Ada Chen', size: 32),
          ),
        ),
      );
      expect(tester.getSize(find.byType(FlareAvatar)).width, 32);
      expect(find.byType(GestureDetector), findsNothing);
    },
  );

  testWidgets('the screen header draws a leading widget before the title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const FlareScreenHeader(
          title: '通讯录',
          leading: FlareAvatar(userId: 'u1', displayName: 'Ada Chen', size: 32),
        ),
      ),
    );

    final header = tester.getRect(find.byType(FlareScreenHeader));
    final avatar = tester.getRect(find.byType(FlareAvatar));
    final title = tester.getRect(find.text('通讯录'));
    expect(avatar.left, greaterThanOrEqualTo(header.left));
    expect(
      avatar.right,
      lessThanOrEqualTo(title.left),
      reason: 'leading comes first',
    );
  });
}
