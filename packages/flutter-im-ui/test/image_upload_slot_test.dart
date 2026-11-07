import 'dart:ui' show SemanticsAction;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
  theme: dark ? ThemeData.dark() : ThemeData.light(),
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 180, child: child),
      ),
    ),
  ),
);

void main() {
  testWidgets('the labelled native accessibility button forwards choose', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var choices = 0;
    await tester.pumpWidget(
      host(
        FlareImageUploadSlot(
          title: 'Document front',
          statusText: 'Not uploaded',
          pickLabel: 'Choose photo',
          onChoose: () => choices++,
        ),
      ),
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel('Document front, Not uploaded, Choose photo'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    expect(choices, 1);
    semantics.dispose();
  });

  testWidgets(
    'a completed private material needs no readable image or actions',
    (tester) async {
      var actions = 0;
      await tester.pumpWidget(
        host(
          FlareImageUploadSlot(
            title: 'Document front',
            statusText: 'Uploaded',
            state: FlareImageUploadState.uploaded,
            pickLabel: 'Choose photo',
            actionLabel: 'Retry',
            onChoose: () => actions++,
            onAction: () => actions++,
          ),
        ),
      );
      expect(find.text('Uploaded'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Retry'), findsNothing);
      await tester.tap(find.byType(AspectRatio));
      await tester.pump();
      expect(actions, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed selection and retry remain distinct controlled intents', (
    tester,
  ) async {
    var choices = 0;
    var retries = 0;
    await tester.pumpWidget(
      host(
        FlareImageUploadSlot(
          title: 'Document back',
          statusText: 'Upload incomplete',
          state: FlareImageUploadState.failed,
          pickLabel: 'Choose again',
          actionLabel: 'Retry',
          preview: const ColoredBox(color: Colors.transparent),
          onChoose: () => choices++,
          onAction: () => retries++,
        ),
      ),
    );
    await tester.tap(find.byType(AspectRatio));
    await tester.pump();
    expect(choices, 1);
    expect(retries, 0);
    expect(find.text('Choose again'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retries, 1);
    expect(find.text('Upload incomplete'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AspectRatio)).height,
      greaterThanOrEqualTo(FlareSizes.touchTargetMin),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uploading is indeterminate, inert and fits enlarged dark text', (
    tester,
  ) async {
    var actions = 0;
    await tester.pumpWidget(
      host(
        FlareImageUploadSlot(
          title: 'Holding document',
          statusText: 'Uploading',
          state: FlareImageUploadState.uploading,
          pickLabel: 'Choose photo',
          actionLabel: 'Retry',
          onChoose: () => actions++,
          onAction: () => actions++,
        ),
        dark: true,
        scale: 1.5,
      ),
    );
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, isNull);
    await tester.tap(find.byType(AspectRatio));
    await tester.pump();
    expect(actions, 0);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing an empty slot is keyboard accessible', (tester) async {
    var choices = 0;
    await tester.pumpWidget(
      host(
        FlareImageUploadSlot(
          title: 'Document front',
          statusText: 'Not uploaded',
          pickLabel: 'Choose photo',
          onChoose: () => choices++,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(choices, 1);
    expect(find.text('Not uploaded'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uploaded viewing is independent from upload disablement', (
    tester,
  ) async {
    var choices = 0;
    var views = 0;
    await tester.pumpWidget(
      host(
        FlareImageUploadSlot(
          title: 'Document front',
          statusText: 'Uploaded',
          state: FlareImageUploadState.uploaded,
          disabled: true,
          pickLabel: 'Choose again',
          previewLabel: 'View photo',
          onChoose: () => choices++,
          onPreview: () => views++,
        ),
      ),
    );
    await tester.tap(find.byType(AspectRatio));
    await tester.pump();
    expect(views, 1);
    expect(choices, 0);
    expect(find.text('View photo'), findsOneWidget);
    expect(find.text('Choose again'), findsNothing);
  });

  testWidgets('loading or unavailable private preview cannot dispatch twice', (
    tester,
  ) async {
    var views = 0;
    for (final loading in [true, false]) {
      await tester.pumpWidget(
        host(
          FlareImageUploadSlot(
            title: 'Document back',
            statusText: 'Uploaded',
            state: FlareImageUploadState.uploaded,
            previewLabel: 'View photo',
            previewLoading: loading,
            previewDisabled: !loading,
            onPreview: () => views++,
          ),
        ),
      );
      await tester.tap(find.byType(AspectRatio));
      await tester.pump();
      expect(views, 0);
      expect(
        find.byType(LinearProgressIndicator),
        loading ? findsOneWidget : findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
