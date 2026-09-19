import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Round 5 Batch 2b: the header's default action labels and its subtitle come
// from the strings table (K8), and a More menu that would hold one action is
// that action's own button (K3).

const _strings = FlareStrings();

Widget _host(Widget child, {double width = 720}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(width: width, child: child),
  ),
);

void main() {
  test('default actions are labelled from the strings table', () {
    const group = FlareConversationIdentity(
      id: 'g',
      title: 'Team',
      kind: FlareConversationHeaderKind.group,
    );
    const direct = FlareConversationIdentity(id: 'd', title: 'Ann');
    Map<String, String> labels(
      FlareConversationIdentity identity, [
      FlareStrings strings = _strings,
    ]) => {
      for (final action in resolveConversationHeaderActions(
        identity: identity,
        strings: strings,
      ))
        action.id: action.label,
    };

    expect(labels(group), {
      'search': '搜索消息',
      'audioCall': '发起语音通话',
      'videoCall': '发起视频通话',
      'addMember': '添加成员',
      'share': '分享会话',
      'details': '会话详情',
    });
    expect(labels(direct).keys, [
      'search',
      'audioCall',
      'videoCall',
      'share',
      'details',
    ]);
    // A host that changes the language changes the defaults with it.
    final english = _strings.copyWith(
      conversationHeaderSearch: 'Search messages',
      conversationHeaderDetails: 'Details',
    );
    expect(labels(direct, english)['search'], 'Search messages');
    expect(labels(direct, english)['details'], 'Details');
  });

  testWidgets('the header reads the ambient strings for defaults, back and '
      'the subtitle', (tester) async {
    await tester.pumpWidget(
      _host(
        FlareConversationHeader(
          identity: const FlareConversationIdentity(
            id: 'g',
            title: 'Team',
            kind: FlareConversationHeaderKind.group,
            memberCount: 12,
          ),
          showBack: true,
          onBack: () {},
          onAction: (_) {},
        ),
      ),
    );
    expect(find.byTooltip(_strings.conversationHeaderSearch), findsOneWidget);
    expect(find.byTooltip(_strings.back), findsOneWidget);
    expect(
      find.text(_strings.conversationHeaderMemberCount(12)),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _host(
        const FlareConversationHeader(
          identity: FlareConversationIdentity(
            id: 'd',
            title: 'Ann',
            presence: FlarePresence.busy,
            // A member count belongs to groups; a direct chat shows presence.
            memberCount: 2,
          ),
        ),
      ),
    );
    expect(find.text(_strings.presenceBusy), findsOneWidget);
    expect(find.text('busy'), findsNothing);
  });

  group('overflow', () {
    const identity = FlareConversationIdentity(
      id: 'd',
      title: 'Ann',
      kind: FlareConversationHeaderKind.direct,
    );

    testWidgets('one overflow action is performed by the More button itself', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final picked = <String>[];
      await tester.pumpWidget(
        _host(
          FlareConversationHeader(
            identity: identity,
            onAction: (action) => picked.add(action.id),
          ),
        ),
      );
      // The More glyph stays; its name is the action's label.
      final more = find.byIcon(Icons.more_horiz_rounded);
      expect(more, findsOneWidget);
      expect(
        find.byTooltip(_strings.conversationHeaderDetails),
        findsOneWidget,
      );
      expect(
        find.byTooltip(_strings.conversationHeaderMoreActions),
        findsNothing,
      );
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(picked, ['details']);
      // Straight to the action: no menu opened in between.
      expect(find.text(_strings.conversationHeaderDetails), findsNothing);
      semantics.dispose();
    });

    testWidgets('two or more overflow actions keep the menu', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(
          FlareConversationHeader(
            identity: identity,
            actions: const [
              FlareConversationHeaderAction(
                id: 'export',
                label: 'Export',
                placement: FlareConversationHeaderActionPlacement.overflow,
                order: 95,
              ),
            ],
            onAction: (action) => picked.add(action.id),
          ),
        ),
      );
      expect(
        find.byTooltip(_strings.conversationHeaderMoreActions),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(picked, isEmpty);
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(picked, ['export']);
    });

    testWidgets('a compact header folds a primary action into a sole More '
        'button', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(
          FlareConversationHeader(
            identity: identity,
            capabilities: const FlareConversationHeaderCapabilities(
              availableActionIds: {'search', 'audioCall'},
            ),
            onAction: (action) => picked.add(action.id),
          ),
          width: 360,
        ),
      );
      // One primary fits; the other is the only overflow action.
      expect(find.byTooltip(_strings.conversationHeaderSearch), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(picked, ['audioCall']);
    });
  });
}
