import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('FlareBottomSheet.show', () {
    testWidgets('frames the content under a title and returns the pop value', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final context = await _pumpHost(tester);
      final result = FlareBottomSheet.show<String>(
        context,
        title: 'Pick one',
        builder: (sheetContext) => TextButton(
          onPressed: () => Navigator.of(sheetContext).pop('picked'),
          child: const Text('Option'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlareBottomSheet), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Pick one')),
        isSemantics(isHeader: true, namesRoute: true),
      );
      await tester.tap(find.text('Option'));
      await tester.pumpAndSettle();
      expect(await result, 'picked');
      expect(find.byType(FlareBottomSheet), findsNothing);
      semantics.dispose();
    });

    testWidgets('the scrim closes a dismissible sheet with null', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      final result = FlareBottomSheet.show<String>(
        context,
        builder: (_) => const Text('Body'),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('a sheet that is not dismissible ignores scrim and back', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      FlareBottomSheet.show<void>(
        context,
        dismissible: false,
        builder: (_) => const Text('Busy'),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Busy'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Busy'), findsOneWidget);
    });

    testWidgets('appears without motion when motion is reduced', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final context = await _pumpHost(tester);
      FlareBottomSheet.show<void>(context, builder: (_) => const Text('Now'));
      await tester.pump();
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Now'), findsOneWidget);
    });
  });

  group('FlareDialog.show', () {
    testWidgets('returns the value its dialog pops', (tester) async {
      final context = await _pumpHost(tester);
      final result = FlareDialog.show<bool>(
        context,
        builder: (dialogContext) => FlareDialog(
          title: const Text('Leave?'),
          content: const Text('You can come back later.'),
          actions: [
            FlareButton(
              label: 'Leave',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Leave?'), findsOneWidget);
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });

    testWidgets('gives a bare kit card the Material its field needs', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      FlareDialog.show<void>(
        context,
        builder: (_) => const Center(child: FlareMomentComposer()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(FlareMomentComposer), findsOneWidget);
    });

    testWidgets('a dialog that is not dismissible ignores barrier and back', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      FlareDialog.show<void>(
        context,
        dismissible: false,
        builder: (_) =>
            const FlareDialog(title: Text('Saving'), content: Text('Wait')),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Saving'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Saving'), findsOneWidget);
    });
  });
}
