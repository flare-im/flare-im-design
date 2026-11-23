import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/action_icon.dart';
import 'package:flare_im_ui/src/components/call_stage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// docs/plugin-experience.md §3: the dark call stage, the PC incoming banner,
// the ended and failed call states, disabled keys, the phone hang-up row, the
// group grid's centred last row and selection, and the dock's states.

const _strings = FlareStrings();

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme,
  home: Scaffold(body: child),
);

List<IconButton> _keys(WidgetTester tester) =>
    tester.widgetList<IconButton>(find.byType(IconButton)).toList();

void main() {
  group('incoming call banner', () {
    testWidgets('sits top trailing, 360 wide, and leaves the page usable', (
      tester,
    ) async {
      await _size(tester, const Size(1280, 800));
      var behind = 0;
      await tester.pumpWidget(
        _host(
          Stack(
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: TextButton(
                  onPressed: () => behind++,
                  child: const Text('behind'),
                ),
              ),
              FlareIncomingCall(
                callerName: '周屿',
                mode: FlareCallMode.video,
                presentation: FlareIncomingCallPresentation.banner,
                onAccept: () {},
                onReject: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final banner = tester.getRect(
        find.ancestor(
          of: find.byType(FlareAvatar),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth ==
                    FlareSizes.componentCallIncomingBannerWidth,
          ),
        ),
      );
      expect(banner.width, FlareSizes.componentCallIncomingBannerWidth);
      expect(banner.right, 1280 - FlareSizes.spacingLg);
      expect(banner.top, FlareSizes.spacingLg);
      // The stage with its stageTint wash, like the 1:1 stage (C1).
      final card = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.maxWidth ==
                  FlareSizes.componentCallIncomingBannerWidth,
        ),
      );
      final colors = FlareColors.of(tester.element(find.byType(FlareAvatar)));
      expect(
        (card.decoration! as BoxDecoration).gradient,
        callStageDecoration(colors).gradient,
      );
      expect(find.text(_strings.incomingVideoCall), findsOneWidget);
      // Non-modal: the page behind still takes taps.
      await tester.tap(find.text('behind'));
      expect(behind, 1);
    });

    testWidgets('never takes focus; a key the user tabs to takes Enter', (
      tester,
    ) async {
      await _size(tester, const Size(1280, 800));
      final handle = tester.ensureSemantics();
      var accepted = 0, rejected = 0;
      Widget banner({Widget? page}) => _host(
        Stack(
          children: [
            ?page,
            FlareIncomingCall(
              callerName: '周屿',
              mode: FlareCallMode.audio,
              presentation: FlareIncomingCallPresentation.banner,
              onAccept: () => accepted++,
              onReject: () => rejected++,
            ),
          ],
        ),
      );
      // Typing in the page: Enter stays the page's.
      await tester.pumpWidget(
        banner(page: const Align(child: TextField(autofocus: true))),
      );
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel(_strings.accept)),
        isSemantics(isButton: true, isFocusable: true, isFocused: false),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(accepted, 0, reason: 'a global Enter never answers');

      // Tab reaches decline, then accept; a focused key takes Space and Enter.
      await tester.pumpWidget(banner());
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(rejected, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(accepted, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(accepted, 2);
      handle.dispose();
    });

    testWidgets('a video invitation can be answered with audio', (
      tester,
    ) async {
      var audio = 0;
      for (final presentation in FlareIncomingCallPresentation.values) {
        await tester.pumpWidget(
          _host(
            FlareIncomingCall(
              callerName: '周屿',
              mode: FlareCallMode.video,
              presentation: presentation,
              onAccept: () {},
              onReject: () {},
              onAcceptAudio: () => audio++,
            ),
          ),
        );
        // An IconButton md disc (§3.2), not a 40 control.
        expect(
          tester.getSize(
            find
                .descendant(
                  of: find.byTooltip(_strings.callAnswerAudio),
                  matching: find.byType(Container),
                )
                .first,
          ),
          const Size.square(FlareSizes.componentIconButtonSideMd),
        );
        await tester.tap(find.byTooltip(_strings.callAnswerAudio));
      }
      expect(audio, 2);
      // Not offered for a voice invitation.
      await tester.pumpWidget(
        _host(
          FlareIncomingCall(
            callerName: '周屿',
            mode: FlareCallMode.audio,
            onAcceptAudio: () {},
          ),
        ),
      );
      expect(find.byTooltip(_strings.callAnswerAudio), findsNothing);
    });

    testWidgets('full screen keys sit at a quarter and three quarters', (
      tester,
    ) async {
      await _size(tester, const Size(390, 844));
      await tester.pumpWidget(
        _host(
          FlareIncomingCall(
            callerName: '周屿',
            mode: FlareCallMode.audio,
            onAccept: () {},
            onReject: () {},
          ),
        ),
      );
      expect(
        tester.getCenter(find.byTooltip(_strings.callDecline)).dx,
        390 / 4,
      );
      expect(tester.getCenter(find.byTooltip(_strings.accept)).dx, 390 * 3 / 4);
    });
  });

  group('call view', () {
    testWidgets('the voice call stands on the dark stage in a light theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.audio,
            state: FlareCallState.connected,
            encrypted: true,
          ),
          theme: ThemeData(brightness: Brightness.light),
        ),
      );
      final stage = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(FlareCallView),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (stage.decoration as BoxDecoration).color,
        FlareColors.light.callStage,
      );
      expect(find.text(_strings.callEncrypted), findsOneWidget);
      expect(find.byIcon(flareIconGlyph('lock')), findsOneWidget);
    });

    testWidgets('ended shows the duration with every key disabled', (
      tester,
    ) async {
      var hung = 0;
      await tester.pumpWidget(
        _host(
          FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.video,
            state: FlareCallState.ended,
            durationLabel: '03:24',
            onHangup: () => hung++,
            onToggleMute: () {},
            onToggleCamera: () {},
          ),
        ),
      );
      expect(find.text('通话已结束 · 03:24'), findsOneWidget);
      expect(_keys(tester).every((k) => k.onPressed == null), isTrue);
      await tester.tap(find.byTooltip(_strings.hangUp), warnIfMissed: false);
      expect(hung, 0);

      await tester.pumpWidget(
        _host(
          const FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.audio,
            state: FlareCallState.ended,
          ),
        ),
      );
      expect(find.text('通话已结束'), findsOneWidget);
    });

    testWidgets('failed shows the host reason and Call again by default', (
      tester,
    ) async {
      var redialled = 0;
      await tester.pumpWidget(
        _host(
          FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.video,
            state: FlareCallState.failed,
            statusDetail: '对方暂时无法接听',
            onRecover: () => redialled++,
            onHangup: () {},
          ),
        ),
      );
      expect(find.text('对方暂时无法接听'), findsOneWidget);
      expect(find.byType(FlareCallControls), findsNothing);
      await tester.tap(find.text(_strings.callRedial));
      expect(redialled, 1);
    });

    testWidgets('reconnecting puts the warning dot before the status', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.audio,
            state: FlareCallState.reconnecting,
          ),
        ),
      );
      expect(find.byType(CallPulseDot), findsOneWidget);
      expect(find.text(_strings.callReconnecting), findsOneWidget);
    });
  });

  group('call controls', () {
    testWidgets('disabled leaves only hang-up live', (tester) async {
      var hung = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: FlareCallControls(
              disabled: true,
              onToggleMute: () {},
              onToggleCamera: () {},
              onSwitchCamera: () {},
              onToggleSpeaker: () {},
              onHangup: () => hung++,
            ),
          ),
        ),
      );
      for (final key in _keys(tester)) {
        expect(
          key.onPressed == null,
          key.tooltip != _strings.hangUp,
          reason: key.tooltip,
        );
      }
      await tester.tap(find.byTooltip(_strings.hangUp));
      expect(hung, 1);
    });

    testWidgets('phones give hang-up its own row past four keys', (
      tester,
    ) async {
      Widget controls() => _host(
        Center(
          child: FlareCallControls(
            onToggleMute: () {},
            onToggleCamera: () {},
            onSwitchCamera: () {},
            onToggleSpeaker: () {},
            onAddMember: () {},
            onHangup: () {},
          ),
        ),
      );
      await _size(tester, const Size(390, 844));
      await tester.pumpWidget(controls());
      final mic = tester.getRect(find.byTooltip(_strings.microphone));
      var hangup = tester.getRect(find.byTooltip(_strings.hangUp));
      expect(hangup.top, greaterThan(mic.bottom));
      expect(hangup.center.dx, closeTo(195, 0.5));
      expect(hangup.width, FlareSizes.componentCallHangupSize);

      // PC: one row, hang-up last.
      await _size(tester, const Size(1280, 800));
      await tester.pumpWidget(controls());
      hangup = tester.getRect(find.byTooltip(_strings.hangUp));
      expect(
        hangup.top,
        tester.getRect(find.byTooltip(_strings.microphone)).top,
      );
      expect(hangup.width, FlareSizes.componentCallControlSize);
    });

    testWidgets('hang-up has its caption; phone keys stand spacingLg apart', (
      tester,
    ) async {
      await _size(tester, const Size(390, 844));
      await tester.pumpWidget(
        _host(
          Center(
            child: FlareCallControls(
              onToggleMute: () {},
              onToggleCamera: () {},
              onSwitchCamera: () {},
              onToggleSpeaker: () {},
              onHangup: () {},
            ),
          ),
        ),
      );
      final hangup = tester.getRect(find.byTooltip(_strings.hangUp));
      final caption = tester.getRect(find.text(_strings.hangUp));
      expect(caption.top, hangup.bottom + FlareSizes.spacingXs);
      expect(caption.center.dx, closeTo(hangup.center.dx, 0.5));
      final mic = tester.getRect(find.byTooltip(_strings.microphone));
      final speaker = tester.getRect(find.byTooltip(_strings.speaker));
      final flip = tester.getRect(find.byTooltip(_strings.flipCamera));
      expect(speaker.left - mic.right, FlareSizes.spacingLg);
      expect(hangup.left - flip.right, FlareSizes.spacingLg);
      // Centred as a group, not spread over the width.
      expect(mic.left, closeTo(390 - hangup.right, 0.5));
    });
  });

  testWidgets('desktop keys: M, V and Cmd/Ctrl+Shift+H, named in tooltips', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    var mic = 0, camera = 0, hung = 0;
    await tester.pumpWidget(
      _host(
        Center(
          child: FlareCallControls(
            onToggleMute: () => mic++,
            onToggleCamera: () => camera++,
            onHangup: () => hung++,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byTooltip('${_strings.microphone} (M)'), findsOneWidget);
    expect(find.byTooltip('${_strings.hangUp} (⌘⇧H)'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    expect((mic, camera, hung), (1, 1, 0), reason: 'H alone never hangs up');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    expect(hung, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  group('group call grid', () {
    List<FlareCallParticipant> people(int n) => [
      for (var i = 0; i < n; i++) FlareCallParticipant(id: 'p$i', name: 'P$i'),
    ];

    /// The avatars' rects, top row first.
    List<Rect> tiles(WidgetTester tester) =>
        tester.widgetList(find.byType(FlareAvatar)).map((w) {
          return tester.getRect(find.byWidget(w));
        }).toList()..sort((a, b) {
          final dy = a.top.compareTo(b.top);
          return dy != 0 ? dy : a.left.compareTo(b.left);
        });

    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      testWidgets('three people: two over one, centred (w${size.width})', (
        tester,
      ) async {
        await _size(tester, size);
        await tester.pumpWidget(
          _host(
            FlareGroupCallView(
              participants: people(3),
              mode: FlareCallMode.video,
              state: FlareCallState.connected,
            ),
          ),
        );
        final r = tiles(tester);
        expect(r[0].top, r[1].top);
        expect(r[2].top, greaterThan(r[0].bottom));
        expect(
          r[2].center.dx,
          closeTo((r[0].center.dx + r[1].center.dx) / 2, 0.5),
        );
      });
    }

    testWidgets('five or six: 2×3 on phones, 3×2 on PC', (tester) async {
      Future<int> firstRow(Size size, int n) async {
        await _size(tester, size);
        await tester.pumpWidget(
          _host(
            FlareGroupCallView(
              participants: people(n),
              mode: FlareCallMode.video,
              state: FlareCallState.connected,
            ),
          ),
        );
        final r = tiles(tester);
        return r.where((t) => t.top == r.first.top).length;
      }

      expect(await firstRow(const Size(390, 844), 6), 2);
      expect(await firstRow(const Size(1280, 800), 6), 3);
      expect(await firstRow(const Size(1280, 800), 5), 3);
      // §12.16: up to 12 — 7–9 3×3, 10–12 4×3 on PC and 3×4 on phones.
      expect(await firstRow(const Size(1280, 800), 9), 3);
      expect(await firstRow(const Size(390, 844), 9), 3);
      expect(await firstRow(const Size(1280, 800), 12), 4);
      expect(await firstRow(const Size(1280, 800), 10), 4);
      expect(await firstRow(const Size(390, 844), 12), 3);
    });

    testWidgets('the kit enlarges a tapped tile without a host callback', (
      tester,
    ) async {
      await _size(tester, const Size(390, 844));
      await tester.pumpWidget(
        _host(
          FlareGroupCallView(
            participants: people(3),
            mode: FlareCallMode.video,
            state: FlareCallState.connected,
          ),
        ),
      );
      await tester.tap(find.text('P1'));
      await tester.pump();
      expect(find.byType(ListView), findsOneWidget, reason: 'the strip');
      await tester.tap(find.text('P1'));
      await tester.pump();
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('the header counts only those who joined', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareGroupCallView(
            participants: [
              ...people(2),
              const FlareCallParticipant(id: 'c', name: 'C', calling: true),
            ],
            mode: FlareCallMode.audio,
            state: FlareCallState.connected,
            durationLabel: '08:41',
            joinedText: (count, status) => '$count · $status',
          ),
        ),
      );
      expect(find.text('2 · 08:41'), findsOneWidget);
    });

    testWidgets('a tapped tile becomes the main view; again restores', (
      tester,
    ) async {
      await _size(tester, const Size(390, 844));
      final picked = <String>[];
      await tester.pumpWidget(
        _host(
          FlareGroupCallView(
            participants: people(3),
            mode: FlareCallMode.video,
            state: FlareCallState.connected,
            onSelectParticipant: picked.add,
          ),
        ),
      );
      Size tile(String name) => tester.getSize(
        find.ancestor(of: find.text(name), matching: find.byType(InkWell)),
      );
      await tester.tap(find.text('P1'));
      await tester.pump();
      expect(picked, ['p1']);
      expect(tile('P1').height, greaterThan(tile('P0').height));
      expect(tile('P0').height, 96);
      await tester.tap(find.text('P1'));
      await tester.pump();
      expect(picked, ['p1', 'p1']);
      expect(tile('P1').height, tile('P0').height);
    });

    testWidgets('status detail, encryption, disabled keys and recovery', (
      tester,
    ) async {
      var redialled = 0;
      await tester.pumpWidget(
        _host(
          FlareGroupCallView(
            participants: people(2),
            mode: FlareCallMode.audio,
            state: FlareCallState.connected,
            statusDetail: '网络较差',
            encrypted: true,
            controlsDisabled: true,
            onToggleMute: () {},
            onHangup: () {},
          ),
        ),
      );
      expect(find.text('网络较差'), findsOneWidget);
      expect(find.text(_strings.callEncrypted), findsOneWidget);
      expect(
        _keys(
          tester,
        ).firstWhere((k) => k.tooltip == _strings.microphone).onPressed,
        isNull,
      );

      await tester.pumpWidget(
        _host(
          FlareGroupCallView(
            participants: people(2),
            mode: FlareCallMode.audio,
            state: FlareCallState.failed,
            onRecover: () => redialled++,
            onHangup: () {},
          ),
        ),
      );
      await tester.tap(find.text(_strings.callRedial));
      expect(redialled, 1);
    });
  });

  testWidgets('dock status follows the call state', (tester) async {
    Future<void> dock(FlareCallState state, {String? detail}) =>
        tester.pumpWidget(
          _host(
            Center(
              child: FlareCallDock(
                title: 'Ivy',
                durationLabel: '02:14',
                state: state,
                statusDetail: detail,
              ),
            ),
          ),
        );
    await dock(FlareCallState.connected);
    expect(find.text('02:14'), findsOneWidget);
    // The stage with its stageTint wash, like the 1:1 stage (C1).
    final colors = FlareColors.of(tester.element(find.byType(FlareCallDock)));
    final pill = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(FlareCallDock),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (pill.decoration! as BoxDecoration).gradient,
      callStageDecoration(colors).gradient,
    );
    // §12.17: short phrases; the failure in call.errorText.
    await dock(FlareCallState.ringing);
    expect(find.text(_strings.callDockWaiting), findsOneWidget);
    await dock(FlareCallState.calling);
    expect(find.text(_strings.callDockWaiting), findsOneWidget);
    await dock(FlareCallState.reconnecting);
    expect(find.text(_strings.callReconnectingShort), findsOneWidget);
    expect(find.byType(CallPulseDot), findsOneWidget);
    await dock(FlareCallState.failed);
    expect(
      tester.widget<Text>(find.text(_strings.callInterrupted)).style?.color,
      colors.callErrorText,
    );
    await dock(FlareCallState.connected, detail: 'Weak network');
    expect(find.text('Weak network'), findsOneWidget);
    expect(find.text('02:14'), findsNothing);
    // The mode glyph comes from the registry.
    expect(find.byIcon(flareIconGlyph('phone')), findsOneWidget);
  });

  testWidgets('screen share copy comes from the strings table', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlareStringsScope(
          strings: flareStringsEnglish,
          child: Scaffold(
            body: FlareScreenShare(
              state: FlareScreenShareState.sharing,
              onStop: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text(flareStringsEnglish.screenShareStop), findsOneWidget);
    expect(find.text(flareStringsEnglish.screenShareTitle), findsOneWidget);
    // The stop key wears the screen-share glyph (the state row shows video).
    expect(find.byIcon(Icons.block), findsNothing);
    expect(find.byIcon(flareIconGlyph('screen-share')), findsOneWidget);
  });

  group('follow-up: close, preview, fade, halos, calling tiles, window', () {
    testWidgets('Close emits onClose, falling back to onHangup', (
      tester,
    ) async {
      var closed = 0, hung = 0;
      for (final view in <Widget>[
        FlareCallView(
          peerName: '周屿',
          mode: FlareCallMode.audio,
          state: FlareCallState.failed,
          onClose: () => closed++,
          onHangup: () => hung++,
        ),
        FlareGroupCallView(
          participants: const [FlareCallParticipant(id: 'a', name: 'A')],
          mode: FlareCallMode.audio,
          state: FlareCallState.failed,
          onClose: () => closed++,
          onHangup: () => hung++,
        ),
      ]) {
        await tester.pumpWidget(_host(view));
        await tester.tap(find.text(_strings.close));
      }
      expect((closed, hung), (2, 0));
      await tester.pumpWidget(
        _host(
          FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.audio,
            state: FlareCallState.failed,
            onHangup: () => hung++,
          ),
        ),
      );
      await tester.tap(find.text(_strings.close));
      expect(hung, 1);
    });

    Widget video({bool still = false, VoidCallback? onMinimize}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: still,
        ),
        child: Scaffold(
          body: FlareCallView(
            peerName: 'Peer',
            mode: FlareCallMode.video,
            state: FlareCallState.connected,
            durationLabel: '01:02',
            videoContent: const ColoredBox(
              key: Key('remote'),
              color: Colors.black,
            ),
            localVideoContent: const ColoredBox(
              key: Key('mine'),
              color: Colors.blue,
            ),
            onMinimize: onMinimize,
          ),
        ),
      ),
    );

    testWidgets('tapping the preview swaps the pictures', (tester) async {
      await _size(tester, const Size(390, 844));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(video());
      expect(find.bySemanticsLabel(_strings.callSwapVideo), findsOneWidget);
      handle.dispose();
      const preview = Size(
        FlareSizes.componentCallPreviewWidth,
        FlareSizes.componentCallPreviewWidth * 16 / 9,
      );
      expect(tester.getSize(find.byKey(const Key('mine'))), preview);
      await tester.tap(find.byKey(const Key('mine')));
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('remote'))), preview);
      expect(
        tester.getSize(find.byKey(const Key('mine'))).width,
        greaterThan(preview.width),
      );
      await tester.tap(find.byKey(const Key('remote')));
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('mine'))), preview);
    });

    testWidgets('a dragged preview snaps to the nearest corner', (
      tester,
    ) async {
      await _size(tester, const Size(390, 844));
      await tester.pumpWidget(video());
      final start = tester.getRect(find.byKey(const Key('mine')));
      expect(start.right, 390 - FlareSizes.spacingLg);
      await tester.drag(find.byKey(const Key('mine')), const Offset(-250, 380));
      await tester.pump();
      await tester.pump(FlareMotion.normal);
      final end = tester.getRect(find.byKey(const Key('mine')));
      expect(end.left, FlareSizes.spacingLg);
      expect(end.top, greaterThan(start.bottom));
    });

    testWidgets('the video top bar fades after 4 s and a tap brings it back', (
      tester,
    ) async {
      await _size(tester, const Size(390, 844));
      double opacity() => tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(
                  of: find.text('Peer'),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity;
      await tester.pumpWidget(video(onMinimize: () {}));
      expect(opacity(), 1);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(FlareMotion.slow);
      expect(opacity(), 0);
      await tester.tapAt(const Offset(195, 400));
      await tester.pump();
      expect(opacity(), 1);

      // Reduced motion: the bar stays.
      await tester.pumpWidget(video(still: true, onMinimize: () {}));
      await tester.pump(const Duration(seconds: 5));
      expect(opacity(), 1);
    });

    testWidgets('calling breathes a halo, still under reduced motion', (
      tester,
    ) async {
      double scale() => tester
          .widget<ScaleTransition>(
            find.descendant(
              of: find.byType(CallHalo),
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value;
      Widget calling({bool still = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: const Scaffold(
            body: FlareCallView(
              peerName: '周屿',
              mode: FlareCallMode.audio,
              state: FlareCallState.calling,
            ),
          ),
        ),
      );
      await tester.pumpWidget(calling());
      await tester.pump(const Duration(milliseconds: 400));
      expect(scale(), greaterThan(1));
      await tester.pumpWidget(calling(still: true));
      await tester.pump(const Duration(milliseconds: 400));
      expect(scale(), 1);

      await tester.pumpWidget(
        _host(
          const FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.audio,
            state: FlareCallState.connected,
          ),
        ),
      );
      expect(tester.widget<CallHalo>(find.byType(CallHalo)).breathing, isFalse);
    });

    testWidgets('the dock ring breathes only once connected', (tester) async {
      for (final state in [FlareCallState.connected, FlareCallState.ringing]) {
        await tester.pumpWidget(
          _host(
            Center(
              child: FlareCallDock(title: 'Ivy', state: state),
            ),
          ),
        );
        expect(
          tester.widget<CallHalo>(find.byType(CallHalo)).breathing,
          state == FlareCallState.connected,
        );
      }
    });

    testWidgets('a participant still being called: faded avatar, no video', (
      tester,
    ) async {
      final asked = <String>[];
      await tester.pumpWidget(
        _host(
          FlareGroupCallView(
            participants: const [
              FlareCallParticipant(id: 'a', name: 'A'),
              FlareCallParticipant(id: 'b', name: 'B', calling: true),
            ],
            mode: FlareCallMode.video,
            state: FlareCallState.connected,
            tileBuilder: (p) {
              asked.add(p.id);
              return null;
            },
          ),
        ),
      );
      expect(asked, ['a']);
      expect(find.text(_strings.callCalling), findsOneWidget);
      final faded = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byType(FlareAvatar).last,
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(faded.opacity, FlareOpacity.disabled);
    });

    testWidgets('the window drags by its top, inside the viewport', (
      tester,
    ) async {
      await _size(tester, const Size(1280, 800));
      Widget surface({bool expanded = false}) => _host(
        FlareCallSurface(
          mode: FlareCallMode.audio,
          expanded: expanded,
          child: const FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.audio,
            state: FlareCallState.connected,
          ),
        ),
      );
      await tester.pumpWidget(surface());
      final before = tester.getRect(find.byType(FlareCallView));
      await tester.dragFrom(
        before.topCenter + const Offset(0, 10),
        const Offset(200, 50),
      );
      await tester.pump();
      final moved = tester.getRect(find.byType(FlareCallView));
      expect(moved.topLeft - before.topLeft, const Offset(200, 50));
      // However far it goes, it stays on screen.
      await tester.dragFrom(
        moved.topCenter + const Offset(0, 10),
        const Offset(5000, 5000),
      );
      await tester.pump();
      final edge = tester.getRect(find.byType(FlareCallView));
      expect(edge.right, lessThanOrEqualTo(1280));
      expect(edge.bottom, lessThanOrEqualTo(800));
      // A drag lower down is the stage's, not the window's.
      await tester.dragFrom(edge.center, const Offset(-100, 0));
      await tester.pump();
      expect(tester.getRect(find.byType(FlareCallView)), edge);
    });
  });

  group('round 3: Escape leaves expanded, group ended', () {
    testWidgets('Escape asks to leave expanded and nothing else', (
      tester,
    ) async {
      await _size(tester, const Size(1280, 800));
      final asked = <bool>[];
      Widget surface(bool expanded) => _host(
        FlareCallSurface(
          mode: FlareCallMode.video,
          expanded: expanded,
          onExpandedChange: asked.add,
          child: const Focus(autofocus: true, child: SizedBox.expand()),
        ),
      );
      await tester.pumpWidget(surface(true));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(asked, [false]);
      await tester.pumpWidget(surface(false));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(asked, [
        false,
      ], reason: 'a window that is not expanded ignores it');
    });

    testWidgets('an ended group call reads call.ended with every key off', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareGroupCallView(
            participants: const [
              FlareCallParticipant(id: 'a', name: 'A'),
              FlareCallParticipant(id: 'b', name: 'B'),
            ],
            mode: FlareCallMode.audio,
            state: FlareCallState.ended,
            durationLabel: '08:41',
            onToggleMute: () {},
            onHangup: () {},
          ),
        ),
      );
      expect(find.textContaining('通话已结束 · 08:41'), findsOneWidget);
      expect(_keys(tester).every((k) => k.onPressed == null), isTrue);
      expect(find.byType(FlareCallControls), findsOneWidget);
    });
  });

  group('round 4: parity', () {
    List<FlareCallParticipant> people(Iterable<int> ids) => [
      for (final i in ids) FlareCallParticipant(id: 'p$i', name: 'P$i'),
    ];

    testWidgets('the enlarged participant leaving brings the grid back', (
      tester,
    ) async {
      await _size(tester, const Size(390, 844));
      Widget group(Iterable<int> ids) => _host(
        FlareGroupCallView(
          participants: people(ids),
          mode: FlareCallMode.video,
          state: FlareCallState.connected,
          onSelectParticipant: (_) {},
        ),
      );
      await tester.pumpWidget(group([0, 1, 2]));
      await tester.tap(find.text('P1'));
      await tester.pump();
      expect(find.byType(ListView), findsOneWidget, reason: 'the strip');
      await tester.pumpWidget(group([0, 2]));
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsOneWidget);
      // Coming back does not enlarge them again.
      await tester.pumpWidget(group([0, 1, 2]));
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('the local tile reads callYou', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareGroupCallView(
            participants: const [
              FlareCallParticipant(id: 'me', name: 'Ada', isSelf: true),
              FlareCallParticipant(id: 'b', name: 'Bo'),
            ],
            mode: FlareCallMode.audio,
            state: FlareCallState.connected,
          ),
        ),
      );
      expect(find.text(_strings.callYou), findsOneWidget);
      expect(find.text('Ada'), findsNothing);
    });

    testWidgets('a switching device group spins after its title', (
      tester,
    ) async {
      Widget picker(bool busy) => _host(
        FlareCallDevicePicker(
          permission: FlareCapabilityState.available,
          permissionText: '',
          groups: [
            FlareCallDeviceGroup(
              kind: FlareCallDeviceKind.microphone,
              label: 'Microphone',
              selectedId: 'a',
              busy: busy,
              devices: const [FlareCallDevice(id: 'a', label: 'Built-in')],
            ),
          ],
          onSelect: (_, _) {},
        ),
      );
      await tester.pumpWidget(picker(true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(flareIconGlyph('check')), findsOneWidget);
      await tester.pumpWidget(picker(false));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the window wears shadows.xl; full screen wears none', (
      tester,
    ) async {
      final shadowed = find.ancestor(
        of: find.byType(FlareCallView),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).boxShadow != null,
        ),
      );
      Widget surface() => _host(
        const FlareCallSurface(
          mode: FlareCallMode.audio,
          child: FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.audio,
            state: FlareCallState.connected,
          ),
        ),
      );
      await _size(tester, const Size(1280, 800));
      await tester.pumpWidget(surface());
      final window = tester.widget<Container>(shadowed);
      final box = window.decoration! as BoxDecoration;
      expect(box.boxShadow, FlareShadows.light.xl);
      expect(box.borderRadius, BorderRadius.circular(FlareSizes.radiusXl));

      await _size(tester, const Size(390, 844));
      await tester.pumpWidget(surface());
      expect(shadowed, findsNothing);
      expect(
        tester.getRect(find.byType(FlareCallView)),
        const Rect.fromLTWH(0, 0, 390, 844),
      );
    });
  });

  group('round 5: review fixes', () {
    List<String> order(WidgetTester tester) =>
        _keys(tester).map((k) => k.tooltip ?? '').toList();

    testWidgets('phone keys: §3.3 order, flip on phones only, one row', (
      tester,
    ) async {
      Widget controls() => _host(
        FlareCallControls(
          onToggleMute: () {},
          onToggleCamera: () {},
          onSwitchCamera: () {},
          onToggleSpeaker: () {},
          onHangup: () {},
        ),
      );
      for (final width in [320.0, 375.0]) {
        await _size(tester, Size(width, 800));
        await tester.pumpWidget(controls());
        expect(order(tester), [
          _strings.microphone,
          _strings.speaker,
          _strings.camera,
          _strings.flipCamera,
          _strings.hangUp,
        ]);
        final mic = tester.getRect(find.byTooltip(_strings.microphone));
        final hangup = tester.getRect(find.byTooltip(_strings.hangUp));
        expect(hangup.top, mic.top, reason: 'never wraps at $width');
        expect(hangup.right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
      }
      // PC: no flip.
      await _size(tester, const Size(1280, 800));
      await tester.pumpWidget(controls());
      expect(find.byTooltip(_strings.flipCamera), findsNothing);
    });

    testWidgets('the status line is not a live region; peer muted reads', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FlareCallView(
            peerName: '周屿',
            mode: FlareCallMode.audio,
            state: FlareCallState.connected,
            durationLabel: '03:24',
            peerMuted: true,
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.liveRegion ?? false),
        ),
        findsNothing,
      );
      expect(find.text(_strings.callPeerMuted), findsOneWidget);
      expect(find.byIcon(flareIconGlyph('mic-off')), findsWidgets);
    });

    testWidgets('group: no minimize key without onMinimize; failed reason', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const FlareGroupCallView(
            participants: [FlareCallParticipant(id: 'a', name: 'A')],
            mode: FlareCallMode.audio,
            state: FlareCallState.failed,
            statusDetail: '网络断开',
          ),
        ),
      );
      expect(find.bySemanticsLabel(_strings.callMinimize), findsNothing);
      expect(find.textContaining('网络断开'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the window: inert scrim, Tab stays inside, expand key', (
      tester,
    ) async {
      await _size(tester, const Size(1280, 800));
      var minimized = 0;
      final asked = <bool>[];
      Widget window(bool expanded) => _host(
        Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(onPressed: () {}, child: const Text('behind')),
            ),
            FlareCallSurface(
              mode: FlareCallMode.audio,
              expanded: expanded,
              onMinimize: () => minimized++,
              onExpandedChange: asked.add,
              child: Column(
                children: [
                  TextButton(onPressed: () {}, child: const Text('a')),
                  TextButton(onPressed: () {}, child: const Text('b')),
                ],
              ),
            ),
          ],
        ),
      );
      await tester.pumpWidget(window(false));
      await tester.pump();
      await tester.tapAt(const Offset(8, 8));
      expect(minimized, 0, reason: 'the scrim never minimizes');
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        final focused = FocusManager.instance.primaryFocus!.context!;
        expect(
          focused.findAncestorWidgetOfExactType<FlareCallSurface>(),
          isNotNull,
          reason: 'Tab $i stays in the window',
        );
      }
      await tester.tap(find.bySemanticsLabel(_strings.expand));
      expect(asked, [true]);
      await tester.pumpWidget(window(true));
      await tester.tap(find.bySemanticsLabel(_strings.collapse));
      expect(asked, [true, false]);
    });

    testWidgets('dock avatar is 40 with the ring outside', (tester) async {
      await tester.pumpWidget(
        _host(const Center(child: FlareCallDock(title: 'Ivy'))),
      );
      expect(tester.getSize(find.byType(FlareAvatar)), const Size(40, 40));
    });

    testWidgets('screen share: a still half bar under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: FlareScreenShare(
                state: FlareScreenShareState.requesting,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .5,
      );
      expect(find.byType(FlareButton), findsOneWidget);
    });

    testWidgets('device rows: Up and Down stop at the group ends', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareCallDevicePicker(
            permission: FlareCapabilityState.available,
            permissionText: '',
            groups: const [
              FlareCallDeviceGroup(
                kind: FlareCallDeviceKind.microphone,
                label: 'Microphone',
                selectedId: 'a',
                devices: [
                  FlareCallDevice(id: 'a', label: 'Mic A'),
                  FlareCallDevice(id: 'b', label: 'Mic B'),
                ],
              ),
              FlareCallDeviceGroup(
                kind: FlareCallDeviceKind.speaker,
                label: 'Speaker',
                selectedId: 'c',
                devices: [FlareCallDevice(id: 'c', label: 'Desk')],
              ),
            ],
            onSelect: (_, _) {},
          ),
        ),
      );
      String focused() {
        final tile = FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<ListTile>()!;
        return (tile.title! as Text).data!;
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focused(), 'Mic A');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focused(), 'Mic B');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focused(), 'Mic B', reason: 'Down stops at the group end');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focused(), 'Desk', reason: 'Tab moves on to the next group');
    });
  });
}
