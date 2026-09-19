import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page whose context the toasts are shown from; they land in the root
/// overlay above it.
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('shows with a close button and leaves after 4 s', (tester) async {
    final semantics = tester.ensureSemantics();
    final context = await _pumpHost(tester);
    FlareToast.show(context, message: 'Saved');
    await tester.pump();
    expect(find.text('Saved'), findsOneWidget);
    expect(find.bySemanticsLabel(const FlareStrings().close), findsOneWidget);
    semantics.dispose();
    await tester.pump(const Duration(milliseconds: 3900));
    expect(find.text('Saved'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('error and danger toasts stay 6 s', (tester) async {
    final context = await _pumpHost(tester);
    FlareToast.show(
      context,
      message: 'Failed',
      variant: FlareToastVariant.error,
    );
    FlareToast.show(context, message: 'Blocked', tone: FlareStatusTone.danger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5900));
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Failed'), findsNothing);
    expect(find.text('Blocked'), findsNothing);
  });

  testWidgets('duration zero stays until closed; close dismisses', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    FlareToast.show(context, message: 'Pinned', duration: Duration.zero);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('Pinned'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('Pinned'), findsNothing);
  });

  testWidgets('running the action dismisses the toast', (tester) async {
    final context = await _pumpHost(tester);
    var undone = 0;
    FlareToast.show(
      context,
      message: 'Deleted',
      actionLabel: 'Undo',
      onAction: () => undone++,
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, 1);
    expect(find.text('Deleted'), findsNothing);
  });

  testWidgets('an action label without a handler is not shown', (tester) async {
    final context = await _pumpHost(tester);
    FlareToast.show(context, message: 'Heads up', actionLabel: 'Open');
    await tester.pump();
    expect(find.text('Heads up'), findsOneWidget);
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('keeps at most three, removing the oldest', (tester) async {
    final context = await _pumpHost(tester);
    for (final message in ['one', 'two', 'three', 'four']) {
      FlareToast.show(context, message: message, duration: Duration.zero);
    }
    await tester.pump();
    expect(find.text('one'), findsNothing);
    for (final message in ['two', 'three', 'four']) {
      expect(find.text(message), findsOneWidget);
    }
    // Oldest on top, below the safe area.
    expect(
      tester.getTopLeft(find.text('two')).dy,
      lessThan(tester.getTopLeft(find.text('four')).dy),
    );
  });

  testWidgets('show returns an early dismiss', (tester) async {
    final context = await _pumpHost(tester);
    final dismiss = FlareToast.show(context, message: 'Uploading');
    FlareToast.show(context, message: 'Other');
    await tester.pump();
    dismiss();
    await tester.pump();
    expect(find.text('Uploading'), findsNothing);
    expect(find.text('Other'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Other'), findsNothing);
  });

  testWidgets('announces the message politely where announcements work', (
    tester,
  ) async {
    final announced = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async => announced.add(message),
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    final context = await _pumpHost(tester);
    FlareToast.show(context, message: 'Copied', duration: Duration.zero);
    await tester.pump();
    await tester.pump();
    final data = announced
        .whereType<Map<Object?, Object?>>()
        .where((event) => event['type'] == 'announce')
        .map((event) => event['data'] as Map<Object?, Object?>)
        .toList();
    expect(data.map((event) => event['message']), ['Copied']);
    // Polite is the default and travels without an assertiveness entry.
    expect(data.single.containsKey('assertiveness'), isFalse);
  });

  testWidgets('is a live region where announcements are not supported', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final semantics = tester.ensureSemantics();
    final context = await _pumpHost(tester);
    FlareToast.show(context, message: 'Copied', duration: Duration.zero);
    await tester.pump();
    final region = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.liveRegion == true,
    );
    expect(tester.getSemantics(region), isSemantics(isLiveRegion: true));
    expect(
      find.descendant(of: region, matching: find.text('Copied')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('outlives the route that showed it', (tester) async {
    final context = await _pumpHost(tester);
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (pageContext) => Scaffold(
          body: TextButton(
            onPressed: () {
              FlareToast.show(pageContext, message: 'Sent');
              Navigator.of(pageContext).pop();
            },
            child: const Text('send'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('send'));
    await tester.pumpAndSettle();
    expect(find.text('send'), findsNothing);
    expect(find.text('Sent'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Sent'), findsNothing);
  });

  group('FlareToast controls', () {
    testWidgets('close and action are named buttons with full touch targets', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var undone = 0;
      var closed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FlareToast(
                message: 'Deleted',
                actionLabel: 'Undo',
                onAction: () => undone++,
                onClose: () => closed++,
              ),
            ),
          ),
        ),
      );
      final close = find.bySemanticsLabel(const FlareStrings().close);
      final undo = find.bySemanticsLabel('Undo');
      for (final control in [close, undo]) {
        expect(
          tester.getSemantics(control),
          isSemantics(isButton: true, hasTapAction: true, isFocusable: true),
        );
        final size = tester.getSize(control);
        expect(size.width, greaterThanOrEqualTo(FlareSizes.touchTarget));
        expect(size.height, greaterThanOrEqualTo(FlareSizes.touchTarget));
      }
      // The whole target takes the tap, not only the glyph or the word.
      await tester.tapAt(tester.getRect(close).topLeft + const Offset(2, 2));
      expect(closed, 1);
      await tester.tapAt(tester.getRect(undo).bottomRight - const Offset(2, 2));
      expect(undone, 1);
      semantics.dispose();
    });

    testWidgets('an action label without a handler shows no control', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FlareToast(message: 'Heads up', actionLabel: 'Open'),
            ),
          ),
        ),
      );
      expect(find.text('Open'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('a toast without controls keeps its compact height', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: FlareToast(message: 'Saved')),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(FlareToast)).height,
        lessThan(FlareSizes.touchTarget),
      );
    });

    testWidgets('controls activate from the keyboard', (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FlareToast(message: 'Saved', onClose: () => closed++),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(closed, 1);
    });
  });
}
