import 'package:extended_text_field/extended_text_field.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('FlareComposer', () {
    testWidgets('send is disabled until there is text, then sends and clears', (
      tester,
    ) async {
      String? sent;
      await tester.pumpWidget(
        _host(
          FlareComposer(
            onSend: (t) {
              sent = t;
              return true;
            },
          ),
        ),
      );

      // empty → tapping send does nothing
      await tester.tap(find.byIcon(Icons.send_outlined));
      expect(sent, isNull);

      await tester.tap(find.byType(ExtendedTextField));
      await tester.pump();
      tester.testTextInput.enterText('hello world');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_outlined));
      expect(sent, 'hello world');

      // cleared after send
      expect(find.text('hello world'), findsNothing);
    });

    testWidgets('attach button fires onAttach', (tester) async {
      var attached = false;
      await tester.pumpWidget(
        _host(FlareComposer(onAttach: () => attached = true)),
      );
      await tester.tap(find.byIcon(Icons.add));
      expect(attached, isTrue);
    });

    testWidgets('reply strip shows the target and cancels', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        _host(
          FlareComposer(
            replyTo: const FlareReplyTarget(senderName: 'Bob', summary: 'hey'),
            replyLabel: 'Reply',
            onCancelReply: () => cancelled = true,
          ),
        ),
      );
      expect(find.text('Reply Bob'), findsOneWidget);
      await tester.tap(find.byTooltip(const FlareStrings().cancelReply));
      expect(cancelled, isTrue);
    });

    testWidgets('voice toggle swaps the input for inline capture', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareComposer(enableVoice: true, onVoiceSend: (_, _) async => true),
        ),
      );
      expect(find.byType(ExtendedTextField), findsOneWidget);
      await tester.tap(find.byIcon(flareIconMap['mic']!));
      await tester.pump();
      expect(find.byType(FlareInlineVoice), findsOneWidget);
      expect(find.byType(ExtendedTextField), findsNothing);
    });

    testWidgets('+ opens the inline action panel and reports selection', (
      tester,
    ) async {
      FlareComposerAction? picked;
      await tester.pumpWidget(
        _host(
          FlareComposer(
            actions: FlareComposerActionPanel.defaultActions,
            onAction: (a) => picked = a,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      const strings = FlareStrings();
      expect(find.text(strings.actionImage), findsWidgets);
      await tester.tap(find.text(strings.actionFile).first);
      expect(picked?.id, 'file');
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
      await tester.pumpWidget(
        _host(
          const FlareMarkdownPreview(
            content: '# Title\n\n- item one\n\nsome **bold** text',
            showStats: true,
          ),
        ),
      );
      expect(find.textContaining('Title'), findsOneWidget);
      expect(find.textContaining('item one'), findsOneWidget);
      expect(find.textContaining('words'), findsOneWidget); // stats footer
    });
  });

  group('FlareComposerActionPanel', () {
    testWidgets('renders default actions and reports selection', (
      tester,
    ) async {
      FlareComposerAction? picked;
      await tester.pumpWidget(
        _host(FlareComposerActionPanel(onAction: (a) => picked = a)),
      );
      const strings = FlareStrings();
      expect(find.text(strings.actionImage), findsOneWidget);
      expect(find.text(strings.actionFile), findsOneWidget);
      await tester.tap(find.text(strings.actionFile));
      expect(picked?.id, 'file');
    });

    test('default set stays useful and restrained', () {
      final ids = FlareComposerActionPanel.defaultActions
          .map((a) => a.id)
          .toList();
      expect(ids, ['image', 'video', 'file', 'voice', 'location', 'contact']);
      // Default tiles carry no baked-in label; it is resolved from strings.
      for (final a in FlareComposerActionPanel.defaultActions) {
        expect(a.label, isNull);
      }
    });

    testWidgets('default labels follow the FlareStringsScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlareStringsScope(
            strings: const FlareStrings().copyWith(
              actionCard: 'Contact',
              composerVoiceInput: 'Voice',
            ),
            child: const Scaffold(body: FlareComposerActionPanel()),
          ),
        ),
      );
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
      // fields the host did not override keep the kit default
      expect(find.text(const FlareStrings().actionImage), findsOneWidget);
    });

    test(
      'resolver supports hide, disable, reorder, custom and capability filtering',
      () {
        const actions = [
          FlareComposerAction(
            id: 'file',
            label: 'File',
            icon: 'folder',
            order: 30,
          ),
          FlareComposerAction(
            id: 'voice',
            label: 'Voice',
            icon: 'mic',
            visible: false,
          ),
          FlareComposerAction(
            id: 'order',
            label: 'Order',
            icon: 'file',
            order: 20,
            intent: 'open-order',
          ),
          FlareComposerAction(
            id: 'image',
            label: 'Image',
            icon: 'image',
            order: 10,
            enabled: false,
          ),
        ];
        final resolved = resolveFlareComposerActions(
          actions: actions,
          capabilities: const FlareComposerCapabilities(
            availableActionIds: {'image', 'order', 'file'},
          ),
        );
        expect(resolved.map((action) => action.id), ['image', 'order', 'file']);
        expect(resolved.first.enabled, isFalse);
        expect(resolved[1].intent, 'open-order');
      },
    );

    testWidgets('an explicit label overrides the strings default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FlareComposerActionPanel(
            actions: [
              FlareComposerAction(id: 'image', label: 'Photo', icon: 'image'),
              FlareComposerAction(id: 'translate', icon: 'translate'),
              FlareComposerAction(id: 'custom', icon: 'mini-app'),
            ],
          ),
        ),
      );
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text(const FlareStrings().actionImage), findsNothing);
      expect(find.text(const FlareStrings().actionTranslate), findsOneWidget);
      // unknown ids fall back to the id itself rather than rendering blank
      expect(find.text('custom'), findsOneWidget);
    });
  });

  group('media viewers', () {
    testWidgets('ImagePreview renders nothing when show=false', (tester) async {
      await tester.pumpWidget(
        _host(const FlareImagePreview(show: false, imageSrc: 'x')),
      );
      expect(find.byIcon(flareIconMap['close']!), findsNothing);
    });

    testWidgets('ImagePreview shows close and fires onClose', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        _host(
          FlareImagePreview(
            show: true,
            imageSrc: 'https://example.com/x.png',
            onClose: () => closed = true,
          ),
        ),
      );
      await tester.tap(find.byIcon(flareIconMap['close']!));
      expect(closed, isTrue);
    });

    testWidgets('ImagePreview delegates media loading to the host builder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareImagePreview(
            show: true,
            imageSrc: 'file:///tmp/preview.png',
            imageBuilder: (context, source) =>
                Text(source, key: const ValueKey('host-image-loader')),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('host-image-loader')), findsOneWidget);
      expect(find.text('file:///tmp/preview.png'), findsOneWidget);
    });

    testWidgets('VideoPlayer shows title and the host play affordance', (
      tester,
    ) async {
      // A host that starts playback itself keeps the poster and play key; the
      // kit's own playback is covered in media_defaults_test.dart.
      var plays = 0;
      await tester.pumpWidget(
        _host(
          FlareVideoPlayer(
            show: true,
            videoSrc: 'https://example.com/x.mp4',
            title: 'Clip',
            onPlay: () => plays++,
          ),
        ),
      );
      expect(find.text('Clip'), findsOneWidget);
      expect(find.byIcon(flareIconMap['play']!), findsOneWidget);
      await tester.tap(find.byIcon(flareIconMap['play']!));
      expect(plays, 1);
    });
  });

  group('FlareConversationDetails', () {
    testWidgets('shows title, connection and toggles mute', (tester) async {
      bool? muted;
      await tester.pumpWidget(
        _host(
          FlareConversationDetails(
            conversation: const FlareConversationSummary(
              id: 'c1',
              title: 'Team',
            ),
            connectionText: '已连接',
            labels: const FlareConversationDetailsLabels(mute: 'Mute'),
            onMute: (v) => muted = v,
          ),
        ),
      );
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('已连接'), findsOneWidget);
      await tester.tap(find.text('Mute'));
      expect(muted, isTrue);
    });

    testWidgets('delete action fires onDelete', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        _host(
          FlareConversationDetails(
            conversation: const FlareConversationSummary(
              id: 'c1',
              title: 'Team',
            ),
            labels: const FlareConversationDetailsLabels(
              delete: 'Delete conversation',
            ),
            onDelete: () => deleted = true,
          ),
        ),
      );
      await tester.tap(find.text('Delete conversation'));
      expect(deleted, isTrue);
    });
  });

  group('FlareStartConversationSheet', () {
    testWidgets('selects contacts and confirms with ids', (tester) async {
      List<String>? ids;
      await tester.pumpWidget(
        _host(
          FlareStartConversationSheet(
            contacts: const [
              FlareContactOption(id: 'u1', name: 'Ann'),
              FlareContactOption(id: 'u2', name: 'Bob'),
            ],
            confirmLabel: 'OK',
            onConfirm: (v) => ids = v,
          ),
        ),
      );
      await tester.tap(find.text('Ann'));
      await tester.pump();
      await tester.tap(find.textContaining('OK'));
      expect(ids, ['u1']);
    });

    testWidgets('search filters the list', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareStartConversationSheet(
            contacts: const [
              FlareContactOption(id: 'u1', name: 'Ann'),
              FlareContactOption(id: 'u2', name: 'Bob'),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Bob');
      await tester.pump();
      // scope to the ListTile — the search field itself now shows "Bob" too
      expect(find.widgetWithText(ListTile, 'Ann'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Bob'), findsOneWidget);
    });
  });
}
