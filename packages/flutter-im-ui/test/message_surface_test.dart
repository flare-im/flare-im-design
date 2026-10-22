import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The row a message draws (docs/design/message-surface-and-meta.md): one
/// container for cards, the meta where the placement vectors put it, retry
/// and read-summary keys with a full touch target, the deleted notice,
/// selection, the desktop menu and toolbar, the pane width and the row's
/// reading unit.
const _poll = FlarePluginViewModel(
  available: true,
  title: '周五去哪儿？',
  actions: [FlarePluginAction(id: 'join', label: '参加')],
);

FlareMessageData _msg({
  String id = 'm1',
  String sender = 'alice',
  String name = 'Alice',
  FlareMessageContent content = const FlareTextContent('明天见'),
  FlareMessageDeliveryStatus status = FlareMessageDeliveryStatus.sent,
  FlareMessageLifecycle? lifecycle,
  FlareMessageReadSummary? readSummary,
  FlareReplyTarget? replyTo,
}) => FlareMessageData(
  id: id,
  senderId: sender,
  senderName: name,
  timeLabel: '09:05',
  content: content,
  status: status,
  lifecycle: lifecycle,
  readSummary: readSummary,
  replyTo: replyTo,
);

Widget _plugin(
  BuildContext context,
  FlareMessageContent content,
  FlareContentContext ctx,
) => FlarePluginView(view: _poll, onAction: (_, _) => _pluginActions++);

int _pluginActions = 0;

Widget _host(Widget child, {double width = 390}) => MaterialApp(
  home: FlareContentScope(
    builders: const {'custom': _plugin},
    child: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

/// Every box drawn with a fill or an edge between [of] and the root of the
/// row: what would show as a container around the card.
List<BoxDecoration> _framesAround(WidgetTester tester, Finder of) => [
  for (final box in tester.widgetList<DecoratedBox>(
    find.ancestor(of: of, matching: find.byType(DecoratedBox)),
  ))
    if (box.decoration case final BoxDecoration d
        when d.color != null || d.border != null)
      d,
];

void main() {
  setUp(() => _pluginActions = 0);

  group('card surface', () {
    for (final self in [false, true]) {
      testWidgets(
        'a plugin card is one container (${self ? 'outgoing' : 'incoming'})',
        (tester) async {
          await tester.pumpWidget(
            _host(
              FlareMessageBubble(
                message: _msg(
                  sender: self ? 'me' : 'alice',
                  content: const FlareGenericContent(
                    contentType: 'custom:flare.plugin.message.v1',
                    label: 'poll',
                  ),
                ),
                currentUserId: 'me',
              ),
            ),
          );
          final card = find.byKey(const ValueKey('flare-plugin-card'));
          expect(card, findsOneWidget);
          expect(find.byKey(FlareMessageBubble.bubbleSurfaceKey), findsNothing);
          // Nothing with a fill or an edge sits around the card's own shell.
          expect(_framesAround(tester, card), isEmpty);
          // The meta sits under the card at its trailing edge.
          final meta = tester.getRect(find.byType(FlareMessageMeta));
          final shell = tester.getRect(card);
          expect(meta.top, greaterThanOrEqualTo(shell.bottom));
          expect((meta.right - shell.right).abs(), lessThan(1));
          // Under a card the meta takes the default palette.
          expect(
            tester.widget<Text>(find.text('09:05')).style!.color,
            FlareColors.light.messageMetaForeground,
          );
        },
      );
    }

    testWidgets('a contact card gets the kit card shell and no bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(
              sender: 'me',
              content: const FlareCardContent(userId: 'u9', title: 'Ivy'),
            ),
            currentUserId: 'me',
          ),
        ),
      );
      final shell = find.byKey(FlareMessageCardShell.surfaceKey);
      expect(shell, findsOneWidget);
      expect(find.byKey(FlareMessageBubble.bubbleSurfaceKey), findsNothing);
      expect(_framesAround(tester, shell), isEmpty);
      // On the card the text keeps the neutral palette, not the bubble's.
      expect(
        tester.widget<Text>(find.text('Ivy')).style!.color,
        FlareColors.light.textPrimary,
      );
    });

    testWidgets('a quote on a card goes inside the shell', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(
              content: const FlareGenericContent(
                contentType: 'custom:flare.plugin.message.v1',
                label: 'poll',
              ),
              replyTo: const FlareReplyTarget(senderName: 'Bo', summary: '吃什么'),
            ),
            currentUserId: 'me',
          ),
        ),
      );
      final card = find.byKey(const ValueKey('flare-plugin-card'));
      expect(
        find.descendant(of: card, matching: find.text('吃什么')),
        findsOneWidget,
      );
      expect(find.byKey(FlareMessageBubble.bubbleSurfaceKey), findsNothing);
    });
  });

  group('meta placement', () {
    testWidgets('inline: a short text keeps its time on the last line', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(FlareMessageBubble(message: _msg(), currentUserId: 'me')),
      );
      final text = tester.getRect(find.text('明天见'));
      final time = tester.getRect(find.text('09:05'));
      expect(time.left, greaterThan(text.right));
      expect((time.bottom - text.bottom).abs(), lessThan(4));
    });

    testWidgets('the meta never covers the text; a full line drops it', (
      tester,
    ) async {
      var dropped = 0, inline = 0;
      for (var n = 8; n <= 40; n++) {
        final text = '字' * n;
        await tester.pumpWidget(
          _host(
            FlareMessageBubble(
              message: _msg(content: FlareTextContent(text)),
              currentUserId: 'me',
            ),
          ),
        );
        final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
        final origin = paragraph.localToGlobal(Offset.zero);
        final lines = paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: text.length),
            )
            .map((box) => box.toRect().shift(origin))
            .toList();
        final meta = tester.getRect(find.byType(FlareMessageMeta));
        for (final line in lines) {
          expect(line.overlaps(meta.deflate(0.5)), isFalse, reason: 'n=$n');
        }
        if (meta.top >= lines.last.bottom - 0.5) {
          dropped++;
        } else {
          inline++;
          // Inline: on the last line, after its end, bottom-aligned.
          expect(meta.left, greaterThanOrEqualTo(lines.last.right));
          expect((meta.bottom - lines.last.bottom).abs(), lessThan(4));
        }
      }
      expect(inline, greaterThan(0));
      expect(dropped, greaterThan(0));
    });

    testWidgets('bare media: the time under the picture, default palette', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(
              sender: 'me',
              content: const FlareImageContent(url: ''),
            ),
            currentUserId: 'me',
          ),
        ),
      );
      final picture = tester.getRect(find.byType(FlareImageMessage));
      final time = tester.getRect(find.text('09:05'));
      expect(time.top, greaterThanOrEqualTo(picture.bottom));
      expect(
        tester.widget<Text>(find.text('09:05')).style!.color,
        FlareColors.light.messageMetaForeground,
      );
      // No address yet: loading, never "unsupported message".
      expect(find.byType(FlareUnknownMessage), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });
  });

  group('retry and read summary', () {
    testWidgets('a failed card says "发送失败，重试" below; its target is 48', (
      tester,
    ) async {
      var resent = 0;
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(
              sender: 'me',
              content: const FlareCardContent(userId: 'u9', title: 'Ivy'),
              status: FlareMessageDeliveryStatus.failed,
            ),
            currentUserId: 'me',
            onResend: (_) => resent++,
          ),
        ),
      );
      final key = find.byKey(FlareMessageMeta.retryTextKey);
      expect(find.text('发送失败，重试'), findsOneWidget);
      final rect = tester.getRect(key);
      expect(rect.height, lessThan(FlareSizes.touchTarget));
      // A tap inside its 48 square but outside the text still retries —
      // here above it, over the card's quiet bottom edge.
      await tester.tapAt(
        rect.center.translate(0, -(FlareSizes.touchTarget / 2 - 2)),
      );
      expect(resent, 1);
      await tester.tapAt(rect.center);
      expect(resent, 2);
    });

    testWidgets('below a card the key\'s square stays inside its row', (
      tester,
    ) async {
      var resent = 0;
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(
              sender: 'me',
              content: const FlareCardContent(userId: 'u9', title: 'Ivy'),
              status: FlareMessageDeliveryStatus.failed,
            ),
            currentUserId: 'me',
            onResend: (_) => resent++,
          ),
        ),
      );
      final rect = tester.getRect(find.byKey(FlareMessageMeta.retryTextKey));
      final row = tester.getRect(find.byType(FlareMessageBubble));
      expect(
        row.bottom,
        greaterThanOrEqualTo(rect.center.dy + FlareSizes.touchTarget / 2 - 1),
      );
      await tester.tapAt(
        rect.center.translate(0, FlareSizes.touchTarget / 2 - 2),
      );
      expect(resent, 1);
    });

    testWidgets('a failed bubble keeps its red edge; the glyph retries at 48', (
      tester,
    ) async {
      var resent = 0;
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(
              sender: 'me',
              status: FlareMessageDeliveryStatus.failed,
            ),
            currentUserId: 'me',
            onResend: (_) => resent++,
          ),
        ),
      );
      final bubble = tester.widget<DecoratedBox>(
        find.byKey(FlareMessageBubble.bubbleSurfaceKey),
      );
      final decoration = bubble.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.color, FlareColors.light.messageFailedBackground);
      final glyph = tester.getRect(find.byKey(FlareMessageStatus.retryKey));
      expect(glyph.width, lessThan(20));
      await tester.tapAt(
        glyph.center.translate(-(FlareSizes.touchTarget / 2 - 3), 0),
      );
      expect(resent, 1);
      // Far outside the square nothing retries.
      await tester.tapAt(glyph.center.translate(-60, 0));
      expect(resent, 1);
    });

    testWidgets('group read summary: "N 人未读" opens the receipt sheet', (
      tester,
    ) async {
      FlareMessageData? opened;
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(
              sender: 'me',
              readSummary: const FlareMessageReadSummary(
                readCount: 2,
                unreadCount: 3,
                total: 5,
              ),
            ),
            currentUserId: 'me',
            conversationKind: FlareConversationKind.group,
            onReadReceiptOpen: (m) => opened = m,
          ),
        ),
      );
      expect(find.text('3 人未读'), findsOneWidget);
      // The summary replaces the check.
      expect(find.byType(FlareMessageStatus), findsNothing);
      final rect = tester.getRect(find.byKey(FlareMessageMeta.readSummaryKey));
      await tester.tapAt(
        rect.center.translate(0, -(FlareSizes.touchTarget / 2 - 3)),
      );
      expect(opened?.id, 'm1');
    });

    testWidgets('all read is the read colour; single chats show the check', (
      tester,
    ) async {
      const all = FlareMessageReadSummary(
        readCount: 5,
        unreadCount: 0,
        total: 5,
      );
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(
              sender: 'me',
              content: const FlareImageContent(url: ''),
              readSummary: all,
            ),
            currentUserId: 'me',
            conversationKind: FlareConversationKind.group,
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('全部已读')).style!.color,
        FlareColors.light.messageStatusRead,
      );
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(sender: 'me', readSummary: all),
            currentUserId: 'me',
          ),
        ),
      );
      expect(find.text('全部已读'), findsNothing);
      expect(find.byType(FlareMessageStatus), findsOneWidget);
    });
  });

  testWidgets('a deleted message is the centred "消息已删除" notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareMessageBubble(
          message: _msg(
            lifecycle: const FlareMessageLifecycle(
              mutation: FlareMessageMutationState.deleted,
            ),
          ),
          currentUserId: 'me',
        ),
      ),
    );
    expect(find.text('消息已删除'), findsOneWidget);
    expect(find.text('明天见'), findsNothing);
    expect(find.byType(FlareAvatar), findsNothing);
  });

  testWidgets('in multi-select a card key toggles the row, not the action', (
    tester,
  ) async {
    var toggles = 0;
    await tester.pumpWidget(
      _host(
        FlareMessageBubble(
          message: _msg(
            content: const FlareGenericContent(
              contentType: 'custom:flare.plugin.message.v1',
              label: 'poll',
            ),
          ),
          currentUserId: 'me',
          multiSelectMode: true,
          onToggleSelect: (_) => toggles++,
        ),
      ),
    );
    await tester.tap(find.text('参加'), warnIfMissed: false);
    expect(_pluginActions, 0);
    expect(toggles, 1);
  });

  testWidgets('the bubble is sized by the pane, not the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const long = '一条足够长的消息一条足够长的消息一条足够长的消息一条足够长的消息一条足够长的消息一条足够长的消息';
    await tester.pumpWidget(
      _host(
        FlareMessageBubble(
          message: _msg(sender: 'me', content: const FlareTextContent(long)),
          currentUserId: 'me',
        ),
        width: 420,
      ),
    );
    final bubble = tester.getSize(
      find.byKey(FlareMessageBubble.bubbleSurfaceKey),
    );
    // 420 is a compact pane: at most 0.88 of it.
    expect(
      bubble.width,
      lessThanOrEqualTo(420 * FlareSizes.componentBubbleMaxWidthRatioCompact),
    );
  });

  testWidgets('the row is one reading unit with reply, menu and retry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(
              sender: 'me',
              name: '我',
              status: FlareMessageDeliveryStatus.failed,
            ),
            currentUserId: 'me',
            locale: 'zh-CN',
            onReply: (_) {},
            onLongPress: (_) {},
            onResend: (_) {},
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(FlareMessageBubble));
      expect(node.label, '我，明天见，09:05，发送失败，重试');
      final actions = node.getSemanticsData().customSemanticsActionIds ?? [];
      expect(actions.length, 3);
    } finally {
      semantics.dispose();
    }
  });

  group('desktop', () {
    final desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgets(
      'a secondary click opens the message menu where it landed',
      variant: desktop,
      (tester) async {
        Offset? at;
        await tester.pumpWidget(
          _host(
            FlareMessageBubble(
              message: _msg(),
              currentUserId: 'me',
              onLongPress: (_) {},
              onContextMenu: (_, position) => at = position,
            ),
          ),
        );
        final point = tester.getCenter(find.text('明天见'));
        await tester.tapAt(point, buttons: kSecondaryButton);
        await tester.pump();
        expect(at, point);
      },
    );

    testWidgets('hovering shows react, reply and more', variant: desktop, (
      tester,
    ) async {
      FlareMessageData? replied;
      var menus = 0;
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _msg(),
            currentUserId: 'me',
            onReact: (_, _) {},
            onReply: (m) => replied = m,
            onLongPress: (_) => menus++,
          ),
        ),
      );
      expect(find.byKey(FlareMessageBubble.hoverToolbarKey), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('明天见')));
      await tester.pump();
      final bar = find.byKey(FlareMessageBubble.hoverToolbarKey);
      expect(bar, findsOneWidget);
      expect(
        find.descendant(of: bar, matching: find.byType(FlareIconButton)),
        findsNWidgets(3),
      );
      await tester.tap(
        find.descendant(
          of: bar,
          matching: find.bySemanticsLabel(
            const FlareStrings().messageActionReply,
          ),
        ),
      );
      expect(replied?.id, 'm1');
      await tester.tap(
        find.descendant(
          of: bar,
          matching: find.bySemanticsLabel(const FlareStrings().more),
        ),
      );
      expect(menus, 1);
    });
  });

  testWidgets('the system back leaves multi-select before the page', (
    tester,
  ) async {
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: FlareMessageList(
                  currentUserId: 'me',
                  multiSelectMode: true,
                  selectedIds: const {'m1'},
                  messages: [_msg()],
                ),
              ),
              FlareMessageBatchToolbar(
                selectedIds: const ['m1'],
                total: 1,
                capabilities: const FlareMessageBatchCapabilities(delete: true),
                onExit: () => exits++,
              ),
            ],
          ),
        ),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(await navigator.maybePop(), isTrue);
    expect(exits, 1);
  });
}
