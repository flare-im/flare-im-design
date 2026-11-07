import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

FlareMessageData _message(String id, {bool self = false, bool long = false}) =>
    FlareMessageData(
      id: id,
      senderId: self ? 'me' : 'bob',
      senderName: self ? 'Me' : 'Bob',
      content: FlareTextContent(
        long ? List.filled(8, 'A longer message').join(' ') : id,
      ),
      timeLabel: '14:32',
    );

Widget _host(
  List<FlareMessageData> messages, {
  double width = 900,
  FlareMessageSurface? surface,
  void Function(String messageId, String emoji)? react,
  ValueChanged<String>? reply,
  ValueChanged<String>? more,
}) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            for (final message in messages)
              FlareMessageBubble(
                message: message,
                currentUserId: 'me',
                surface: surface,
                onReact: (m, emoji) => react?.call(m.id, emoji),
                onReply: (m) => reply?.call(m.id),
                onContextMenu: (m, _) => more?.call(m.id),
              ),
          ],
        ),
      ),
    ),
  ),
);

Finder _row(String id) => find.byWidgetPredicate(
  (w) => w is FlareMessageBubble && w.message.id == id,
);
Finder _surface(String id) => find.descendant(
  of: _row(id),
  matching: find.byKey(FlareMessageBubble.bubbleSurfaceKey),
);
Finder get _toolbar => find.byKey(FlareMessageBubble.hoverToolbarKey);

Future<TestGesture> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(1, 1));
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump();
  return mouse;
}

void main() {
  final desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

  for (final self in [false, true]) {
    testWidgets(
      'toolbar stays beside the ${self ? 'outgoing' : 'incoming'} bubble',
      variant: desktop,
      (tester) async {
        await tester.pumpWidget(_host([_message('short', self: self)]));
        final bubbleBefore = tester.getRect(_surface('short'));
        expect(_toolbar, findsNothing);
        final mouse = await _hover(tester, _surface('short'));
        final bubble = tester.getRect(_surface('short'));
        final bar = tester.getRect(_toolbar);
        expect(
          bubble,
          bubbleBefore,
          reason: 'showing actions never moves the message',
        );
        if (self) {
          expect(bubble.left - bar.right, closeTo(FlareSizes.spacingSm, 0.1));
        } else {
          expect(bar.left - bubble.right, closeTo(FlareSizes.spacingSm, 0.1));
        }
        expect(bar.center.dy, closeTo(bubble.center.dy, 0.1));
        await mouse.moveTo(bar.center);
        await tester.pump();
        expect(
          _toolbar,
          findsOneWidget,
          reason: 'moving into the controls keeps them available',
        );
      },
    );
  }

  for (final self in [false, true]) {
    testWidgets(
      'card toolbar stays beside the ${self ? 'outgoing' : 'incoming'} card',
      variant: desktop,
      (tester) async {
        const contentType = 'desktop-toolbar-card';
        const cardKey = ValueKey('desktop-toolbar-card');
        FlareContentRegistry.register(
          contentType,
          (context, content, ctx) =>
              const SizedBox(key: cardKey, width: 320, height: 64),
        );
        addTearDown(() => FlareContentRegistry.unregister(contentType));
        await tester.pumpWidget(
          _host([
            FlareMessageData(
              id: 'card',
              senderId: self ? 'me' : 'bob',
              senderName: self ? 'Me' : 'Bob',
              content: const FlareGenericContent(
                contentType: contentType,
                label: 'card',
              ),
              timeLabel: '14:32',
            ),
          ], surface: FlareMessageSurface.card),
        );
        final before = tester.getRect(find.byKey(cardKey));
        await _hover(tester, find.byKey(cardKey));
        final card = tester.getRect(find.byKey(cardKey));
        final bar = tester.getRect(_toolbar);
        expect(card, before);
        expect(
          self ? card.left - bar.right : bar.left - card.right,
          closeTo(FlareSizes.spacingSm, 0.1),
        );
        expect(bar.center.dy, closeTo(card.center.dy, 0.1));
        expect(
          tester.getRect(find.byType(FlareMessageMeta)).right,
          closeTo(card.right, 0.1),
          reason:
              'the timestamp still ends at the card rather than the toolbar',
        );
      },
    );
  }

  for (final self in [false, true]) {
    testWidgets(
      'media toolbar centres on the ${self ? 'outgoing' : 'incoming'} frame, excluding its footer',
      variant: desktop,
      (tester) async {
        const type = 'desktop-toolbar-media';
        const frameKey = ValueKey('desktop-toolbar-media');
        FlareContentRegistry.register(
          type,
          (_, _, _) => const SizedBox(key: frameKey, width: 180, height: 96),
        );
        addTearDown(() => FlareContentRegistry.unregister(type));
        await tester.pumpWidget(
          _host([
            FlareMessageData(
              id: 'media',
              senderId: self ? 'me' : 'bob',
              senderName: 'Bob',
              content: const FlareGenericContent(
                contentType: type,
                label: 'media',
              ),
              timeLabel: '14:32',
            ),
          ], surface: FlareMessageSurface.bareMedia),
        );
        await _hover(tester, find.byKey(frameKey));
        final frame = tester.getRect(find.byKey(frameKey));
        final bar = tester.getRect(_toolbar);
        expect(bar.center.dy, closeTo(frame.center.dy, 0.1));
        expect(
          self ? frame.left - bar.right : bar.left - frame.right,
          closeTo(FlareSizes.spacingSm, 0.1),
        );
        expect(
          tester.getRect(find.byType(FlareMessageMeta)).right,
          closeTo(frame.right, 0.1),
        );
      },
    );
  }

  for (final surface in [
    FlareMessageSurface.card,
    FlareMessageSurface.bareMedia,
  ]) {
    for (final self in [false, true]) {
      testWidgets(
        'a 420px pane preserves a fitting 240px ${surface.name} ${self ? 'outgoing' : 'incoming'} frame',
        variant: desktop,
        (tester) async {
          const type = 'desktop-fitting-frame';
          const frameKey = ValueKey('desktop-fitting-frame');
          FlareContentRegistry.register(
            type,
            (_, _, _) => const SizedBox(key: frameKey, width: 240, height: 96),
          );
          addTearDown(() => FlareContentRegistry.unregister(type));
          await tester.pumpWidget(
            _host(
              [
                FlareMessageData(
                  id: 'fitting',
                  senderId: self ? 'me' : 'bob',
                  senderName: 'Bob',
                  content: const FlareGenericContent(
                    contentType: type,
                    label: 'frame',
                  ),
                  timeLabel: '14:32',
                ),
              ],
              width: 420,
              surface: surface,
            ),
          );
          expect(tester.getSize(find.byKey(frameKey)).width, 240);
          await _hover(tester, find.byKey(frameKey));
          final frame = tester.getRect(find.byKey(frameKey));
          final bar = tester.getRect(_toolbar);
          expect(
            frame.width,
            240,
            reason: 'a fitting frame does not lose content cap to its toolbar',
          );
          expect(
            self ? frame.left - bar.right : bar.left - frame.right,
            closeTo(8, 0.1),
          );
          expect(bar.center.dy, closeTo(frame.center.dy, 0.1));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'only the hovered message owns the toolbar and actions',
    variant: desktop,
    (tester) async {
      final replies = <String>[];
      final menus = <String>[];
      await tester.pumpWidget(
        _host(
          [_message('first'), _message('second', self: true)],
          reply: replies.add,
          more: menus.add,
        ),
      );
      final mouse = await _hover(tester, _surface('first'));
      expect(
        find.descendant(of: _row('first'), matching: _toolbar),
        findsOneWidget,
      );
      await mouse.moveTo(tester.getCenter(_surface('second')));
      await tester.pump();
      expect(_toolbar, findsOneWidget);
      expect(
        find.descendant(of: _row('first'), matching: _toolbar),
        findsNothing,
      );
      expect(
        find.descendant(of: _row('second'), matching: _toolbar),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: _toolbar,
          matching: find.bySemanticsLabel(
            const FlareStrings().messageActionReply,
          ),
        ),
      );
      expect(replies, ['second']);
      await tester.tap(
        find.descendant(
          of: _toolbar,
          matching: find.bySemanticsLabel(const FlareStrings().more),
        ),
      );
      expect(menus, ['second']);
    },
  );

  for (final self in [false, true]) {
    testWidgets(
      'long ${self ? 'outgoing' : 'incoming'} message keeps controls inside a narrow pane',
      variant: desktop,
      (tester) async {
        await tester.pumpWidget(
          _host([_message('long', self: self, long: true)], width: 360),
        );
        final before = tester.getRect(_surface('long'));
        await _hover(tester, _surface('long'));
        final bar = tester.getRect(_toolbar);
        final row = tester.getRect(_row('long'));
        expect(tester.getRect(_surface('long')), before);
        expect(bar.left, greaterThanOrEqualTo(row.left));
        expect(bar.right, lessThanOrEqualTo(row.right));
        expect(bar.overlaps(tester.getRect(_surface('long'))), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  Finder action(String icon) => find.descendant(
    of: _toolbar,
    matching: find.byWidgetPredicate(
      (w) => w is FlareIconButton && w.icon == icon,
    ),
  );

  Future<void> tabToAction(WidgetTester tester, String icon) async {
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      if (action(icon).evaluate().isNotEmpty &&
          Focus.of(tester.element(action(icon))).hasPrimaryFocus)
        return;
    }
    fail('Tab did not reach $icon');
  }

  testWidgets(
    'Tab reaches reply and more; Enter and Space activate the focused action',
    variant: desktop,
    (tester) async {
      final replies = <String>[];
      final menus = <String>[];
      await tester.pumpWidget(
        _host([_message('keyboard')], reply: replies.add, more: menus.add),
      );
      await tabToAction(tester, 'reply');
      expect(_toolbar, findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 500));
      addTearDown(mouse.removePointer);
      await tester.pump();
      expect(
        _toolbar,
        findsOneWidget,
        reason: 'keyboard focus keeps actions available off hover',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(replies, ['keyboard']);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(replies, ['keyboard', 'keyboard']);
      await tabToAction(tester, 'more');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(menus, ['keyboard']);
    },
  );

  testWidgets(
    'keyboard activation opens react choices and selects a quick reaction',
    variant: desktop,
    (tester) async {
      final reactions = <String>[];
      await tester.pumpWidget(
        _host([
          _message('keyboard'),
        ], react: (id, emoji) => reactions.add('$id $emoji')),
      );
      await tabToAction(tester, 'emoji');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text(flareQuickReactions.first), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reactions, ['keyboard ${flareQuickReactions.first}']);
    },
  );
}
