import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// FlareMessageList.menu: the long-press sheet and the pointer menu are drawn
/// from one entry list (messageMenuEntries), the host's snapshot is read
/// synchronously, rows coming on screen are prefetched, and both menus hand
/// the chosen entry to perform.
FlareMessageData _msg(String id, String text) => FlareMessageData(
  id: id,
  senderId: 'bob',
  senderName: 'Bob',
  content: FlareTextContent(text),
  timeLabel: '14:32',
);

const _snapshot = FlareMessageActionAvailability(
  canReply: true,
  canForward: true,
  canCopy: true,
  canDelete: true,
  canReact: true,
);

const _report = FlareMessageMenuEntry(
  id: 'report',
  label: '举报',
  icon: 'report',
  group: FlareMessageMenuGroup.destructive,
);

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    required this.log,
    this.snapshots = const {},
    this.observers = const [],
  });

  final List<String> log;
  final Map<String, FlareMessageActionAvailability> snapshots;
  final List<NavigatorObserver> observers;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late final Map<String, FlareMessageActionAvailability> snapshots = {
    ...widget.snapshots,
  };

  void arrive(String id) => setState(() => snapshots[id] = _snapshot);

  void change(String id, FlareMessageActionAvailability snapshot) =>
      setState(() => snapshots[id] = snapshot);

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorObservers: widget.observers,
    home: Scaffold(
      body: FlareMessageList(
        currentUserId: 'me',
        messages: [_msg('m1', 'one'), _msg('m2', 'two')],
        onReact: (m, emoji) => widget.log.add('react ${m.id} $emoji'),
        menu: FlareMessageMenuSource(
          availability: (m) => snapshots[m.id],
          prefetch: (ids) => widget.log.add('prefetch ${ids.join(',')}'),
          hiddenActions: const {'forward'},
          extraActions: (_) => const [_report],
          perform: (m, id) => widget.log.add('perform ${m.id} $id'),
        ),
      ),
    ),
  );
}

/// Counts the routes that leave: an open menu that follows its snapshot never
/// closes to do it.
class _Pops extends NavigatorObserver {
  int count = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => count++;
}

Finder get _pointerMenu => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ActionMenuPanel',
);

void main() {
  const strings = FlareStrings();
  final message = _msg('m1', 'one');
  final source = FlareMessageMenuSource(
    availability: (m) => m.id == 'm1' ? _snapshot : null,
    hiddenActions: const {'forward'},
    extraActions: (m) => m.senderId == 'me' ? const [] : const [_report],
    perform: (_, _) {},
  );

  test('the host entries follow the message', () {
    final mine = FlareMessageData(
      id: 'm1',
      senderId: 'me',
      senderName: 'Me',
      content: const FlareTextContent('one'),
    );
    expect(
      source.entriesFor(mine, strings)!.map((e) => e.id),
      isNot(contains('report')),
    );
    expect(
      source.entriesFor(message, strings)!.map((e) => e.id),
      contains('report'),
    );
    expect(source.extraActionsFor(mine), isEmpty);
    expect(
      FlareMessageMenuSource(
        availability: (_) => null,
        perform: (_, _) {},
      ).extraActionsFor(message),
      isEmpty,
    );
  });

  test('one entry list behind both menus', () {
    final entries = source.entriesFor(message, strings)!;
    expect(
      entries.map((e) => e.id),
      messageMenuEntries(
        _snapshot,
        strings,
        hidden: const {'forward'},
        extra: const [_report],
        content: message.content,
      ).map((e) => e.id),
    );
    expect(entries.map((e) => e.id), [
      'reply',
      'mark',
      'copy',
      'delete',
      'report',
    ]);
    final items = flareMessagePointerMenuItems(entries, strings);
    expect(items.map((i) => i.id), entries.map((e) => e.id));
    expect(items.map((i) => i.label), entries.map((e) => e.label));
    expect(items.last.danger, isTrue);
  });

  test('without a snapshot the pointer menu is one disabled loading entry', () {
    expect(source.entriesFor(_msg('m2', 'two'), strings), isNull);
    final items = flareMessagePointerMenuItems(null, strings);
    expect(items, hasLength(1));
    expect(items.single.label, strings.messageMenuLoading);
    expect(items.single.enabled, isFalse);
  });

  testWidgets('rows on screen are prefetched once, in one call', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(_Host(log: log));
    await tester.pump();
    expect(log, hasLength(1));
    expect(log.single.startsWith('prefetch '), isTrue);
    expect(log.single.substring(9).split(',').toSet(), {'m1', 'm2'});
    // A rebuild of rows already on screen asks again for nothing.
    tester.state<_HostState>(find.byType(_Host)).arrive('m1');
    await tester.pump();
    await tester.pump();
    expect(log, hasLength(1));
  });

  testWidgets('a long press opens the sheet from the same entries', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(
      _Host(log: log, snapshots: const {'m1': _snapshot}),
    );
    await tester.pump();
    log.clear();
    await tester.longPress(find.text('one'));
    await tester.pumpAndSettle();
    expect(find.byType(FlareMessageActionSheet), findsOneWidget);
    for (final entry in source.entriesFor(message, strings)!) {
      expect(find.text(entry.label), findsOneWidget, reason: entry.id);
    }
    expect(find.text(strings.messageActionForward), findsNothing);
    await tester.tap(find.text('举报'));
    await tester.pumpAndSettle();
    expect(log, ['perform m1 report']);
  });

  testWidgets('a reaction from the sheet goes to onReact', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(
      _Host(log: log, snapshots: const {'m1': _snapshot}),
    );
    await tester.pump();
    log.clear();
    await tester.longPress(find.text('one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(flareQuickReactions.first));
    await tester.pumpAndSettle();
    expect(log, ['react m1 ${flareQuickReactions.first}']);
  });

  testWidgets('a long press without a snapshot prefetches, then opens once '
      'the host has read', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(_Host(log: log));
    await tester.pump();
    log.clear();
    await tester.longPress(find.text('two'));
    await tester.pumpAndSettle();
    expect(log, ['prefetch m2']);
    expect(find.byType(FlareMessageActionSheet), findsNothing);
    tester.state<_HostState>(find.byType(_Host)).arrive('m2');
    await tester.pumpAndSettle();
    expect(find.byType(FlareMessageActionSheet), findsOneWidget);
    expect(find.text(strings.messageActionReply), findsOneWidget);
  });

  group('pointer', () {
    final desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgets(
      'a secondary click opens the same entries where it landed',
      variant: desktop,
      (tester) async {
        final log = <String>[];
        await tester.pumpWidget(
          _Host(log: log, snapshots: const {'m1': _snapshot}),
        );
        await tester.pump();
        log.clear();
        await tester.tapAt(
          tester.getCenter(find.text('one')),
          buttons: kSecondaryButton,
        );
        await tester.pumpAndSettle();
        expect(find.byType(FlareMessageActionSheet), findsNothing);
        for (final entry in source.entriesFor(message, strings)!) {
          expect(find.text(entry.label), findsOneWidget, reason: entry.id);
        }
        await tester.tap(find.text(strings.messageActionReply));
        await tester.pumpAndSettle();
        expect(log, ['perform m1 reply']);
      },
    );

    testWidgets(
      'without a snapshot: one disabled loading entry, and a prefetch',
      variant: desktop,
      (tester) async {
        final log = <String>[];
        await tester.pumpWidget(_Host(log: log));
        await tester.pump();
        log.clear();
        await tester.tapAt(
          tester.getCenter(find.text('two')),
          buttons: kSecondaryButton,
        );
        await tester.pumpAndSettle();
        expect(log, ['prefetch m2']);
        expect(find.text(strings.messageMenuLoading), findsOneWidget);
        expect(find.text(strings.messageActionReply), findsNothing);
        await tester.tap(
          find.text(strings.messageMenuLoading),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(log, ['prefetch m2']);
      },
    );

    testWidgets(
      'an open menu turns into the entries when the snapshot arrives, in place',
      variant: desktop,
      (tester) async {
        final log = <String>[];
        final host = GlobalKey<_HostState>();
        final pops = _Pops();
        await tester.pumpWidget(_Host(key: host, log: log, observers: [pops]));
        await tester.pump();
        log.clear();
        await tester.tapAt(
          tester.getCenter(find.text('two')),
          buttons: kSecondaryButton,
        );
        await tester.pumpAndSettle();
        expect(find.text(strings.messageMenuLoading), findsOneWidget);
        final route = ModalRoute.of(tester.element(_pointerMenu));
        final edge = tester.getTopRight(_pointerMenu).dx;

        host.currentState!.arrive('m2');
        // The list rebuilds with the snapshot, then the open menu.
        await tester.pump();
        await tester.pump();
        expect(find.text(strings.messageMenuLoading), findsNothing);
        expect(find.text(strings.messageActionReply), findsOneWidget);
        expect(find.text(strings.messageActionDelete), findsOneWidget);
        expect(find.text('举报'), findsOneWidget, reason: 'the host entry');
        expect(
          find.text(strings.messageActionForward),
          findsNothing,
          reason: 'hidden by the host',
        );
        expect(pops.count, 0, reason: 'the menu did not close to refresh');
        expect(ModalRoute.of(tester.element(_pointerMenu)), same(route));
        // Still where the click landed: its end edge stays at the anchor (it may
        // open upwards now that it is taller).
        expect(tester.getTopRight(_pointerMenu).dx, edge);

        await tester.tap(find.text(strings.messageActionReply));
        await tester.pumpAndSettle();
        expect(log, ['prefetch m2', 'perform m2 reply']);
      },
    );

    testWidgets(
      'a snapshot that changes while the menu is open narrows it in place',
      variant: desktop,
      (tester) async {
        final log = <String>[];
        final host = GlobalKey<_HostState>();
        final pops = _Pops();
        await tester.pumpWidget(
          _Host(
            key: host,
            log: log,
            snapshots: const {'m1': _snapshot},
            observers: [pops],
          ),
        );
        await tester.pump();
        await tester.tapAt(
          tester.getCenter(find.text('one')),
          buttons: kSecondaryButton,
        );
        await tester.pumpAndSettle();
        expect(find.text(strings.messageActionDelete), findsOneWidget);
        expect(find.text(strings.messageActionCopy), findsOneWidget);

        host.currentState!.change(
          'm1',
          const FlareMessageActionAvailability(
            canReply: true,
            canForward: true,
            canCopy: true,
            canReact: true,
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(
          find.text(strings.messageActionDelete),
          findsNothing,
          reason: 'an action the core no longer allows leaves the menu',
        );
        expect(find.text(strings.messageActionCopy), findsOneWidget);
        expect(find.text(strings.messageActionReply), findsOneWidget);
        expect(pops.count, 0);
        expect(_pointerMenu, findsOneWidget);
      },
    );

    testWidgets('pointerIdiom follows the fine pointer', variant: desktop, (
      tester,
    ) async {
      late bool idiom;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              idiom = FlareMessageMenuSource.pointerIdiom(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(idiom, isTrue);
    });
  });

  testWidgets('pointerIdiom is off on a phone', (tester) async {
    late bool idiom;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            idiom = FlareMessageMenuSource.pointerIdiom(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(idiom, isFalse);
  });
}
