import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mark a located row wears: the reader has to be able to see which row the
/// jump landed on. The numbers are the shared table
/// (`locate_highlight_vectors_test.dart`); this is the mark reaching the right
/// row, only one row, and leaving when the window closes.
Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(body: child),
    ),
  ),
);

FlareMessageData _message(String id) => FlareMessageData(
  id: id,
  senderId: 'ann',
  senderName: 'Ann',
  content: FlareTextContent('message $id'),
);

/// Every ring drawn anywhere in the tree. A plain thread of text draws no other
/// shadow, so this is the mark and nothing else.
List<BoxShadow> _marks(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .expand((decoration) => decoration.boxShadow ?? const <BoxShadow>[])
    .toList();

bool _marksRow(WidgetTester tester, String text) => tester
    .widgetList<DecoratedBox>(
      find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .any((decoration) => (decoration.boxShadow ?? const []).isNotEmpty);

/// Pumps frames — without advancing the clock, so the window does not run down —
/// until the mark appears. The mark is drawn by the row itself, so it can only
/// appear once that row is built.
Future<void> _untilMarked(WidgetTester tester) async {
  for (var frame = 0; frame < 12 && _marks(tester).isEmpty; frame++) {
    await tester.pump();
  }
}

Future<FlareMessageListController> _pump(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(400, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = FlareMessageListController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    _host(
      FlareMessageList(
        messages: [for (var i = 0; i < 40; i++) _message('m$i')],
        currentUserId: 'me',
        controller: controller,
      ),
      reduceMotion: reduceMotion,
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('the row a jump landed on is marked, and fades out of it', (
    tester,
  ) async {
    final controller = await _pump(tester);
    expect(_marks(tester), isEmpty);

    expect(controller.scrollToMessage('m35'), isTrue);
    await _untilMarked(tester);
    expect(_marksRow(tester, 'message m35'), isTrue);
    final arrival = _marks(tester).single;

    await tester.pump(const Duration(milliseconds: 900));
    final later = _marks(tester).single;
    // It fades and reaches further out as it goes.
    expect(later.color.a, lessThan(arrival.color.a));
    expect(later.spreadRadius, greaterThan(arrival.spreadRadius));

    await tester.pumpAndSettle();
    expect(_marks(tester), isEmpty);
  });

  testWidgets('a landed jump is announced, so a reader who cannot see the ring '
      'is told the same thing', (tester) async {
    final announcements = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (message) async {
        final map = message as Map<Object?, Object?>;
        if (map['type'] == 'announce') {
          announcements.add(
            (map['data'] as Map<Object?, Object?>)['message'] as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(
            SystemChannels.accessibility,
            null,
          ),
    );

    final controller = await _pump(tester);
    expect(controller.scrollToMessage('m35'), isTrue);
    await _untilMarked(tester);
    await tester.pumpAndSettle();

    // The same one line a reply strip would show, named by its sender: the ring says this to everyone
    // who can see it.
    expect(announcements, ['已跳转到 Ann 的消息：message m35']);
  });

  testWidgets('only one row is marked: a second jump moves the mark', (
    tester,
  ) async {
    final controller = await _pump(tester);
    controller.scrollToMessage('m35');
    await _untilMarked(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_marksRow(tester, 'message m35'), isTrue);

    controller.scrollToMessage('m32');
    await tester.pump();
    await tester.pump();
    // Two marked rows would say the jump landed twice.
    expect(_marks(tester), hasLength(1));
    expect(_marksRow(tester, 'message m32'), isTrue);
    expect(_marksRow(tester, 'message m35'), isFalse);

    // The first row's window closing must not take the second row's mark.
    await tester.pump(const Duration(milliseconds: 1250));
    expect(_marksRow(tester, 'message m32'), isTrue);
    await tester.pumpAndSettle();
    expect(_marks(tester), isEmpty);
  });

  testWidgets('a reader who asked for less motion still gets the mark, held '
      'still', (tester) async {
    final controller = await _pump(tester, reduceMotion: true);
    controller.scrollToMessage('m35');
    await _untilMarked(tester);
    final arrival = _marks(tester).single;
    expect(_marksRow(tester, 'message m35'), isTrue);

    await tester.pump(const Duration(milliseconds: 900));
    final later = _marks(tester).single;
    // Less motion is not no answer: the same ring, not moving.
    expect(later.color, arrival.color);
    expect(later.spreadRadius, arrival.spreadRadius);

    await tester.pumpAndSettle();
    expect(_marks(tester), isEmpty);
  });
}
