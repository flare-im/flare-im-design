import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('FlareComposer', () {
    testWidgets('send is disabled until there is text, then sends and clears',
        (tester) async {
      String? sent;
      await tester.pumpWidget(_host(FlareComposer(onSend: (t) => sent = t)));

      // empty → tapping send does nothing
      await tester.tap(find.byIcon(Icons.send_rounded));
      expect(sent, isNull);

      await tester.enterText(find.byType(TextField), 'hello world');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      expect(sent, 'hello world');

      // cleared after send
      expect(find.text('hello world'), findsNothing);
    });

    testWidgets('attach button fires onAttach', (tester) async {
      var attached = false;
      await tester.pumpWidget(
        _host(FlareComposer(onAttach: () => attached = true)),
      );
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      expect(attached, isTrue);
    });

    testWidgets('reply strip shows the target and cancels', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(_host(FlareComposer(
        replyTo: const FlareReplyTarget(senderName: 'Bob', summary: 'hey'),
        onCancelReply: () => cancelled = true,
      )));
      expect(find.text('Reply Bob'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(cancelled, isTrue);
    });

    testWidgets('voice toggle swaps the input for hold-to-talk', (tester) async {
      await tester.pumpWidget(_host(const FlareComposer(enableVoice: true)));
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pump();
      expect(find.text('Hold to talk'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('+ opens the inline action panel and reports selection',
        (tester) async {
      FlareComposerAction? picked;
      await tester.pumpWidget(_host(FlareComposer(
        actions: FlareMessageActionSheet.defaultActions,
        onAction: (a) => picked = a,
      )));
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Image'), findsWidgets);
      await tester.tap(find.text('File').first);
      expect(picked?.key, 'file');
    });
  });

  group('FlareRichMarkdownInput', () {
    testWidgets('bold button wraps input with **', (tester) async {
      final controller = TextEditingController(text: 'hi');
      await tester.pumpWidget(
        _host(FlareRichMarkdownInput(controller: controller)),
      );
      await tester.tap(find.byIcon(Icons.format_bold_rounded));
      await tester.pump();
      expect(controller.text, contains('**'));
    });

    testWidgets('shows counter at maxLength', (tester) async {
      final controller = TextEditingController(text: 'abc');
      await tester.pumpWidget(
        _host(FlareRichMarkdownInput(controller: controller, maxLength: 10)),
      );
      expect(find.text('3/10'), findsOneWidget);
    });
  });

  group('FlareMarkdownPreview', () {
    testWidgets('renders heading, bullet and bold', (tester) async {
      await tester.pumpWidget(_host(const FlareMarkdownPreview(
        content: '# Title\n\n- item one\n\nsome **bold** text',
        showStats: true,
      )));
      expect(find.textContaining('Title'), findsOneWidget);
      expect(find.textContaining('item one'), findsOneWidget);
      expect(find.textContaining('words'), findsOneWidget); // stats footer
    });
  });

  group('FlareMessageActionSheet', () {
    testWidgets('renders default actions and reports selection', (tester) async {
      FlareComposerAction? picked;
      await tester.pumpWidget(_host(FlareMessageActionSheet(
        onAction: (a) => picked = a,
      )));
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
      await tester.tap(find.text('File'));
      expect(picked?.key, 'file');
    });
  });

  group('media viewers', () {
    testWidgets('ImagePreview renders nothing when show=false', (tester) async {
      await tester.pumpWidget(_host(
        const FlareImagePreview(show: false, imageSrc: 'x'),
      ));
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('ImagePreview shows close and fires onClose', (tester) async {
      var closed = false;
      await tester.pumpWidget(_host(FlareImagePreview(
        show: true,
        imageSrc: 'https://example.com/x.png',
        onClose: () => closed = true,
      )));
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);
    });

    testWidgets('VideoPlayer shows title and play affordance', (tester) async {
      await tester.pumpWidget(_host(const FlareVideoPlayer(
        show: true,
        videoSrc: 'https://example.com/x.mp4',
        title: 'Clip',
      )));
      expect(find.text('Clip'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });

  group('FlareConversationDetails', () {
    testWidgets('shows title, connection and toggles mute', (tester) async {
      bool? muted;
      await tester.pumpWidget(_host(FlareConversationDetails(
        conversation: const FlareConversationSummary(id: 'c1', title: 'Team'),
        connectionText: '已连接',
        onMute: (v) => muted = v,
      )));
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('已连接'), findsOneWidget);
      await tester.tap(find.text('Mute'));
      expect(muted, isTrue);
    });

    testWidgets('delete action fires onDelete', (tester) async {
      var deleted = false;
      await tester.pumpWidget(_host(FlareConversationDetails(
        conversation: const FlareConversationSummary(id: 'c1', title: 'Team'),
        onDelete: () => deleted = true,
      )));
      await tester.tap(find.text('Delete conversation'));
      expect(deleted, isTrue);
    });
  });

  group('FlareStartConversationSheet', () {
    testWidgets('selects contacts and confirms with ids', (tester) async {
      List<String>? ids;
      await tester.pumpWidget(_host(FlareStartConversationSheet(
        contacts: const [
          FlareContactOption(id: 'u1', name: 'Ann'),
          FlareContactOption(id: 'u2', name: 'Bob'),
        ],
        onConfirm: (v) => ids = v,
      )));
      await tester.tap(find.text('Ann'));
      await tester.pump();
      await tester.tap(find.textContaining('OK'));
      expect(ids, ['u1']);
    });

    testWidgets('search filters the list', (tester) async {
      await tester.pumpWidget(_host(FlareStartConversationSheet(
        contacts: const [
          FlareContactOption(id: 'u1', name: 'Ann'),
          FlareContactOption(id: 'u2', name: 'Bob'),
        ],
      )));
      await tester.enterText(find.byType(TextField), 'Bob');
      await tester.pump();
      // scope to the ListTile — the search field itself now shows "Bob" too
      expect(find.widgetWithText(ListTile, 'Ann'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Bob'), findsOneWidget);
    });
  });
}
