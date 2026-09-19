import 'package:extended_text_field/extended_text_field.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// Every icon-only control is announced by what it does, exposes the state its
// glyph shows, and is at least the kit's touch target — a screen reader must
// never land on an unnamed glyph, and a finger must not have to hunt for one.

const _strings = FlareStrings();

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// The semantics node a screen reader announces as [name] — named by its label
/// (kit controls) or by its tooltip (Material icon buttons).
SemanticsNode _node(WidgetTester tester, String name) {
  final byLabel = find.bySemanticsLabel(name);
  if (byLabel.evaluate().isNotEmpty) {
    expect(byLabel, findsOneWidget, reason: name);
    return tester.getSemantics(byLabel);
  }
  final byTooltip = find.byTooltip(name);
  expect(byTooltip, findsOneWidget, reason: 'no control is named "$name"');
  return tester.getSemantics(byTooltip);
}

/// [name] is a button with a tap action and a full touch target.
void _expectNamedButton(WidgetTester tester, String name) {
  final node = _node(tester, name);
  expect(node, isSemantics(isButton: true, hasTapAction: true), reason: name);
  _expectTouchTarget(node, name);
}

void _expectTouchTarget(SemanticsNode node, String name) {
  expect(
    node.rect.width,
    greaterThanOrEqualTo(FlareSizes.touchTarget),
    reason: '$name width',
  );
  expect(
    node.rect.height,
    greaterThanOrEqualTo(FlareSizes.touchTarget),
    reason: '$name height',
  );
}

void main() {
  group('composer toolbar', () {
    testWidgets('every key is a named button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          FlareComposer(
            enableVoice: true,
            onVoiceSend: (_, _) async => true,
            onSend: (_) => true,
            onImage: () {},
            actions: FlareComposerActionPanel.defaultActions,
          ),
        ),
      );
      for (final name in [
        _strings.composerEmoji,
        _strings.composerMention,
        _strings.composerVoiceInput,
        _strings.actionImage,
        _strings.composerRichText,
        _strings.more,
        _strings.send,
      ]) {
        expect(_node(tester, name), isSemantics(isButton: true), reason: name);
      }
      handle.dispose();
    });

    testWidgets('the icon-button part requires and announces its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          FlareComposerIconButton(
            icon: 'mic',
            label: _strings.composerVoiceInput,
            onTap: () => taps++,
          ),
        ),
      );
      _expectNamedButton(tester, _strings.composerVoiceInput);
      await tester.tap(find.byTooltip(_strings.composerVoiceInput));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('the reply strip cancel is named', (tester) async {
      final handle = tester.ensureSemantics();
      var cancelled = 0;
      await tester.pumpWidget(
        _host(
          FlareComposerReplyStrip(
            senderName: 'Bob',
            summary: 'hey',
            onCancel: () => cancelled++,
          ),
        ),
      );
      _expectNamedButton(tester, _strings.cancelReply);
      await tester.tap(find.bySemanticsLabel(_strings.cancelReply));
      expect(cancelled, 1);
      handle.dispose();
    });
  });

  testWidgets('image preview close and download are named buttons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var closed = 0, downloads = 0;
    await tester.pumpWidget(
      _host(
        FlareImagePreview(
          show: true,
          imageSrc: 'x',
          imageBuilder: (_, _) => const SizedBox.square(dimension: 100),
          onClose: () => closed++,
          onDownload: () => downloads++,
        ),
      ),
    );
    _expectNamedButton(tester, _strings.closePreview);
    _expectNamedButton(tester, _strings.download);
    await tester.tap(find.bySemanticsLabel(_strings.closePreview));
    await tester.tap(find.bySemanticsLabel(_strings.download));
    expect((closed, downloads), (1, 1));
    handle.dispose();
  });

  testWidgets('voice recording bar cancel and send are named buttons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var cancelled = 0, sent = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          child: FlareVoiceRecordingBar(
            durationLabel: '0:07',
            onCancel: () => cancelled++,
            onSend: () => sent++,
          ),
        ),
      ),
    );
    _expectNamedButton(tester, _strings.voiceRecordingCancel);
    _expectNamedButton(tester, _strings.voiceRecordingSend);
    await tester.tap(find.bySemanticsLabel(_strings.voiceRecordingCancel));
    await tester.tap(find.bySemanticsLabel(_strings.voiceRecordingSend));
    expect((cancelled, sent), (1, 1));
    handle.dispose();
  });

  testWidgets('message batch toolbar exit is a named button', (tester) async {
    final handle = tester.ensureSemantics();
    var exits = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 600,
          child: FlareMessageBatchToolbar(
            selectedIds: const ['a', 'b'],
            total: 5,
            capabilities: const FlareMessageBatchCapabilities(delete: true),
            onExit: () => exits++,
          ),
        ),
      ),
    );
    _expectNamedButton(tester, _strings.messageBatchExit);
    await tester.tap(find.bySemanticsLabel(_strings.messageBatchExit));
    expect(exits, 1);
    handle.dispose();
  });

  group('call controls', () {
    testWidgets('toggles expose their state and hang up is named', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          FlareCallControls(
            muted: true,
            cameraOn: false,
            onToggleMute: () {},
            onToggleCamera: () {},
            onSwitchCamera: () {},
            onHangup: () {},
          ),
        ),
      );
      // Muted with the camera off: both devices are off.
      expect(
        _node(tester, _strings.microphone),
        isSemantics(hasToggledState: true, isToggled: false),
      );
      expect(
        _node(tester, _strings.camera),
        isSemantics(hasToggledState: true, isToggled: false),
      );
      expect(_node(tester, _strings.flipCamera), isSemantics(isButton: true));
      _expectNamedButton(tester, _strings.hangUp);
      expect(find.byIcon(flareIconMap['mic-off']!), findsOneWidget);
      expect(find.byIcon(flareIconMap['camera-off']!), findsOneWidget);
      expect(find.byIcon(flareIconMap['end-call']!), findsOneWidget);

      await tester.pumpWidget(
        _host(
          FlareCallControls(
            mode: FlareCallMode.audio,
            speakerOn: true,
            onToggleSpeaker: () {},
          ),
        ),
      );
      expect(
        _node(tester, _strings.speaker),
        isSemantics(hasToggledState: true, isToggled: true),
      );
      expect(find.byIcon(flareIconMap['speaker']!), findsOneWidget);
      handle.dispose();
    });

    testWidgets('call dock microphone and hang up are named, the microphone '
        'shows whether it is on', (tester) async {
      final handle = tester.ensureSemantics();
      var toggles = 0, hangups = 0;
      await tester.pumpWidget(
        _host(
          FlareCallDock(
            title: 'Ivy',
            muted: true,
            onToggleMute: () => toggles++,
            onHangup: () => hangups++,
          ),
        ),
      );
      _expectNamedButton(tester, _strings.microphone);
      expect(
        _node(tester, _strings.microphone),
        isSemantics(hasToggledState: true, isToggled: false),
      );
      _expectNamedButton(tester, _strings.hangUp);
      // Hang up is its own glyph, not a rotated handset.
      expect(find.byIcon(flareIconMap['end-call']!), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byIcon(flareIconMap['end-call']!),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
      await tester.tap(find.bySemanticsLabel(_strings.microphone));
      await tester.tap(find.bySemanticsLabel(_strings.hangUp));
      expect((toggles, hangups), (1, 1));
      handle.dispose();
    });

    testWidgets('group call minimize is a named button', (tester) async {
      final handle = tester.ensureSemantics();
      var minimized = 0;
      await tester.pumpWidget(
        _host(
          FlareGroupCallView(
            participants: const [],
            mode: FlareCallMode.audio,
            state: 'connected',
            onMinimize: () => minimized++,
          ),
        ),
      );
      _expectNamedButton(tester, _strings.callMinimize);
      await tester.tap(find.bySemanticsLabel(_strings.callMinimize));
      expect(minimized, 1);
      handle.dispose();
    });
  });

  group('the other icon-only controls', () {
    testWidgets(
      'announcement dismiss, forward picker and receipt sheet close',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            FlareAnnouncementBanner(
              text: 'Standup moves to 10:00',
              dismissible: true,
              onClose: () {},
            ),
          ),
        );
        _expectNamedButton(tester, _strings.close);

        await tester.pumpWidget(
          _host(
            FlareForwardPicker(
              targets: const [FlareForwardTarget(id: 'a', name: 'Ann')],
              onClose: () {},
            ),
          ),
        );
        _expectNamedButton(tester, _strings.close);

        await tester.pumpWidget(
          _host(
            FlareReadReceiptSheet(
              readers: const [],
              unread: const [],
              dismissible: true,
              onClose: () {},
            ),
          ),
        );
        _expectNamedButton(tester, _strings.close);
        handle.dispose();
      },
    );

    testWidgets('date picker month navigation', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(FlareDatePicker(value: '2026-09-15', onChanged: (_) {})),
      );
      await tester.tap(find.text('2026-09-15'));
      await tester.pumpAndSettle();
      _expectNamedButton(tester, _strings.previousMonth);
      _expectNamedButton(tester, _strings.nextMonth);
      handle.dispose();
    });

    testWidgets('emoji picker tabs are named by category and show selection', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const FlareEmojiPicker(
            recents: ['😀'],
            categories: [
              FlareEmojiCategory(
                key: 'smileys',
                label: 'Smileys',
                emojis: ['😀'],
              ),
              FlareEmojiCategory(
                key: 'animals',
                label: 'Animals',
                emojis: ['🐱'],
              ),
            ],
          ),
        ),
      );
      expect(
        _node(tester, _strings.recent),
        isSemantics(isButton: true, isSelected: true),
      );
      expect(
        _node(tester, 'Animals'),
        isSemantics(isButton: true, isSelected: false),
      );
      _expectTouchTarget(_node(tester, 'Smileys'), 'Smileys');
      await tester.tap(find.bySemanticsLabel('Animals'));
      await tester.pump();
      expect(_node(tester, 'Animals'), isSemantics(isSelected: true));
      handle.dispose();
    });

    testWidgets('input clear is named and the field keeps its height', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: FlareInput(controller: controller, clearable: true),
          ),
        ),
      );
      final empty = tester.getSize(find.byType(FlareInput));
      controller.text = 'draft';
      await tester.pump();
      _expectNamedButton(tester, _strings.clear);
      expect(tester.getSize(find.byType(FlareInput)), empty);
      await tester.tap(find.bySemanticsLabel(_strings.clear));
      await tester.pump();
      expect(controller.text, isEmpty);
      handle.dispose();
    });

    testWidgets('file download and the task checkbox', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(FlareFileMessage(name: 'spec.pdf', onDownload: () {})),
      );
      _expectNamedButton(tester, _strings.download);

      var toggles = 0;
      await tester.pumpWidget(
        _host(
          FlareTaskMessage(
            title: 'Sync notes',
            done: true,
            onToggle: () => toggles++,
          ),
        ),
      );
      final task = _node(tester, 'Sync notes');
      expect(
        task,
        isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
      );
      _expectTouchTarget(task, 'task');
      await tester.tap(find.bySemanticsLabel('Sync notes'));
      expect(toggles, 1);
      handle.dispose();
    });

    testWidgets('moment card actions, composer images and visibility add', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 360,
            child: FlareMomentCard(
              moment: FlareMoment(
                id: 'm',
                author: FlareMomentAuthor(id: 'u', name: 'Ann'),
                text: 'Hello',
                time: '1m',
              ),
            ),
          ),
        ),
      );
      expect(
        _node(tester, _strings.momentActions),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: false),
      );
      await tester.tap(find.bySemanticsLabel(_strings.momentActions));
      await tester.pump();
      expect(
        _node(tester, _strings.momentActions),
        isSemantics(isExpanded: true),
      );

      var removed = -1, added = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: FlareMomentComposer(
              images: const ['a.png'],
              onRemoveImage: (i) => removed = i,
              onAddImage: () => added++,
            ),
          ),
        ),
      );
      _expectNamedButton(tester, _strings.removeImage);
      _expectNamedButton(tester, _strings.addImage);
      await tester.tap(find.bySemanticsLabel(_strings.removeImage));
      await tester.tap(find.bySemanticsLabel(_strings.addImage));
      expect((removed, added), (0, 1));

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: FlareMomentsVisibilityRuleList(
              kind: FlareMomentsVisibilityRuleKind.hideFrom,
              members: const [],
              onAdd: () {},
            ),
          ),
        ),
      );
      _expectNamedButton(tester, _strings.momentsVisibilityAdd);
      handle.dispose();
    });

    testWidgets('poll composer cancel and remove option', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(SizedBox(width: 360, child: FlarePollComposer(onCancel: () {}))),
      );
      _expectNamedButton(tester, _strings.cancel);
      expect(find.bySemanticsLabel(_strings.removeOption), findsNothing);
      await tester.tap(find.text(_strings.addOption));
      await tester.pump();
      expect(find.bySemanticsLabel(_strings.removeOption), findsNWidgets(3));
      handle.dispose();
    });

    testWidgets('profile panel QR code', (tester) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: FlareProfilePanel(
              user: const FlareUserProfile(id: 'u', name: 'Ann'),
              onQr: () => opened++,
            ),
          ),
        ),
      );
      _expectNamedButton(tester, _strings.myQrCode);
      await tester.tap(find.bySemanticsLabel(_strings.myQrCode));
      expect(opened, 1);
      handle.dispose();
    });

    testWidgets('rating stars are a radio group checked at the value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      int? picked;
      await tester.pumpWidget(
        _host(FlareRating(value: 3, onChanged: (v) => picked = v)),
      );
      for (var n = 1; n <= 5; n++) {
        final star = _node(tester, _strings.ratingStars(n));
        expect(
          star,
          isSemantics(
            hasCheckedState: true,
            isChecked: n == 3,
            isInMutuallyExclusiveGroup: true,
            hasTapAction: true,
          ),
          reason: '$n',
        );
        _expectTouchTarget(star, 'star $n');
      }
      await tester.tap(find.bySemanticsLabel(_strings.ratingStars(5)));
      expect(picked, 5);

      await tester.pumpWidget(
        _host(const FlareRating(value: 4, readonly: true)),
      );
      expect(find.bySemanticsLabel(_strings.ratingStars(4)), findsOneWidget);
      expect(find.bySemanticsLabel(_strings.ratingStars(1)), findsNothing);
      handle.dispose();
    });

    testWidgets('stepper keys are named touch targets over a compact pill', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      num? value;
      await tester.pumpWidget(
        _host(
          FlareStepper(
            value: 2,
            size: FlareControlSize.sm,
            onChanged: (v) => value = v,
          ),
        ),
      );
      _expectNamedButton(tester, _strings.decrease);
      _expectNamedButton(tester, _strings.increase);
      await tester.tap(find.bySemanticsLabel(_strings.increase));
      expect(value, 3);
      handle.dispose();
    });

    testWidgets('video and voice play controls', (tester) async {
      final handle = tester.ensureSemantics();
      var plays = 0;
      await tester.pumpWidget(
        _host(
          FlareVideoPlayer(
            show: true,
            videoSrc: 'x.mp4',
            onPlay: () => plays++,
            onClose: () {},
          ),
        ),
      );
      _expectNamedButton(tester, _strings.play);
      _expectNamedButton(tester, _strings.close);
      await tester.tap(find.bySemanticsLabel(_strings.play));
      expect(plays, 1);

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: FlareVoicePlayer(
              durationLabel: '0:07',
              playing: true,
              onToggle: () {},
            ),
          ),
        ),
      );
      _expectNamedButton(tester, _strings.pause);
      expect(find.byIcon(flareIconMap['pause']!), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets('the kit composer still sends through its named send key', (
    tester,
  ) async {
    String? sent;
    await tester.pumpWidget(
      _host(
        FlareComposer(
          onSend: (text) {
            sent = text;
            return true;
          },
        ),
      ),
    );
    await tester.tap(find.byType(ExtendedTextField));
    tester.testTextInput.enterText('hi');
    await tester.pump();
    await tester.tap(find.byTooltip(_strings.send));
    expect(sent, 'hi');
  });
}
