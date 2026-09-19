import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('message action sheet emits action and reaction intents', (
    tester,
  ) async {
    String? action;
    String? reaction;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareMessageActionSheet(
            availability: const FlareMessageActionAvailability(canReact: true),
            actions: const [
              FlareMessageMenuEntry(
                id: 'reply',
                label: 'Reply',
                icon: 'reply',
                group: FlareMessageMenuGroup.primary,
              ),
            ],
            reactions: const ['OK'],
            onAction: (value) => action = value,
            onReact: (value) => reaction = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reply'));
    expect(action, 'reply');
    await tester.tap(find.text('OK'));
    expect(reaction, 'OK');
    expect(
      find.bySemanticsLabel(const FlareStrings().messageActionSheetLabel),
      findsOneWidget,
    );
  });

  testWidgets('a host reaction list still needs canReact', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FlareMessageActionSheet(reactions: ['OK'])),
      ),
    );
    expect(find.text('OK'), findsNothing);
  });

  const everything = FlareMessageActionAvailability(
    canReply: true,
    canForward: true,
    canCopy: true,
    canEdit: true,
    canDelete: true,
    canRecall: true,
    canPin: true,
    canUnpin: true,
    canReact: true,
    canMultiSelect: true,
    canSave: true,
    canResend: true,
  );

  List<String> ids(
    FlareMessageActionAvailability availability, {
    Set<String> hidden = const {},
    FlareMessageContent? content = const FlareTextContent('hello'),
  }) => messageMenuActions(
    availability,
    const FlareStrings(),
    hidden: hidden,
    content: content,
  ).map((entry) => entry.id).toList();

  test('standard actions follow the core flags in contract order', () {
    expect(ids(everything), [
      'reply', 'forward', 'recall', 'resend', 'multiSelect', 'mark', 'pin', //
      'pinSelf', 'unpin', 'copy', 'preview', 'save', 'edit', 'delete',
    ]);
    expect(ids(const FlareMessageActionAvailability()), isEmpty);
    expect(ids(const FlareMessageActionAvailability(canDelete: true)), [
      'mark',
      'delete',
    ]);
    expect(ids(const FlareMessageActionAvailability(canPin: true)), [
      'pin',
      'pinSelf',
    ]);
    expect(ids(const FlareMessageActionAvailability(canMultiSelect: true)), [
      'multiSelect',
      'preview',
    ]);
    expect(ids(const FlareMessageActionAvailability(canUnpin: true)), [
      'unpin',
    ]);
    expect(ids(const FlareMessageActionAvailability(canResend: true)), [
      'resend',
    ]);
    expect(ids(const FlareMessageActionAvailability(canReact: true)), isEmpty);
    expect(ids(everything, hidden: {'multiSelect', 'preview'}), hasLength(12));
  });

  test('copy needs text to copy, whatever the core allows', () {
    // The core's canCopy comes from `text_for_storage()`, which hands back a
    // preview token ("[图片]") for media: it would offer a Copy that copies
    // nothing. The kit asks the content instead.
    for (final content in const <FlareMessageContent>[
      FlareImageContent(url: 'https://media.example/a.jpg'),
      FlareVideoContent(url: 'https://media.example/a.mp4'),
      FlareAudioContent(url: 'https://media.example/a.m4a', durationSec: 3),
      FlareFileContent(name: 'a.pdf', url: 'https://media.example/a.pdf'),
      FlareStickerContent(url: 'https://media.example/s.png'),
      FlareTextContent('   '),
    ]) {
      expect(
        ids(everything, content: content),
        isNot(contains('copy')),
        reason: content.type,
      );
    }
    // Unknown content claims nothing either.
    expect(ids(everything, content: null), isNot(contains('copy')));
    // Text, and the cards that carry a title, do copy.
    expect(
      ids(everything, content: const FlareTextContent('hi')),
      contains('copy'),
    );
    expect(
      ids(
        everything,
        content: const FlareLinkCardContent(url: 'https://e.co', title: 'Docs'),
      ),
      contains('copy'),
    );
    expect(flareCopyableText(const FlareTextContent('hi')), 'hi');
    expect(
      flareCopyableText(const FlareImageContent(url: 'https://e.co/a.jpg')),
      isNull,
    );
  });

  testWidgets('an image message has no Copy in the sheet', (tester) async {
    const strings = FlareStrings();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlareMessageActionSheet(
            availability: FlareMessageActionAvailability(canCopy: true),
            content: FlareImageContent(url: 'https://media.example/a.jpg'),
          ),
        ),
      ),
    );
    expect(find.text(strings.messageActionCopy), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlareMessageActionSheet(
            availability: FlareMessageActionAvailability(canCopy: true),
            content: FlareTextContent('ship it'),
          ),
        ),
      ),
    );
    expect(find.text(strings.messageActionCopy), findsOneWidget);
  });

  test('groups and labels belong to the kit', () {
    final entries = messageMenuActions(
      everything,
      const FlareStrings(),
      content: const FlareTextContent('hello'),
    );
    expect(
      entries
          .where((e) => e.group == FlareMessageMenuGroup.primary)
          .map((e) => e.id),
      ['reply', 'forward', 'recall', 'resend'],
    );
    expect(
      entries
          .where((e) => e.group == FlareMessageMenuGroup.destructive)
          .map((e) => e.id),
      ['delete'],
    );
    expect(entries.firstWhere((e) => e.id == 'recall').label, '撤回');
    final english = const FlareStrings().copyWith(
      messageActionRecall: 'Recall',
    );
    expect(
      messageMenuActions(
        everything,
        english,
      ).firstWhere((e) => e.id == 'recall').label,
      'Recall',
    );
  });

  test('availability reads the core json', () {
    final parsed = FlareMessageActionAvailability.fromJson({
      'canReply': true,
      'canPin': false,
      'canCopy': 'true',
      'canDelete': 1,
      'unknown': true,
    });
    expect(parsed.canReply, isTrue);
    expect(parsed.canPin || parsed.canCopy || parsed.canDelete, isFalse);
  });

  testWidgets(
    'availability drives the sheet: standard actions, hidden ones out, default reactions',
    (tester) async {
      String? action;
      String? reaction;
      const strings = FlareStrings();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageActionSheet(
              availability: const FlareMessageActionAvailability(
                canReply: true,
                canMultiSelect: true,
                canReact: true,
              ),
              hiddenActions: const {'preview'},
              onAction: (value) => action = value,
              onReact: (value) => reaction = value,
            ),
          ),
        ),
      );

      expect(find.text(strings.messageActionReply), findsOneWidget);
      expect(find.text(strings.messageActionMultiSelect), findsOneWidget);
      expect(find.text(strings.messageActionPreview), findsNothing);
      await tester.tap(find.text(strings.messageActionReply));
      expect(action, 'reply');
      await tester.tap(find.text(flareQuickReactions.first));
      expect(reaction, flareQuickReactions.first);
    },
  );
}
