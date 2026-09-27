import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _phone = Size(402, 874);
const _desktop = Size(1280, 800);

Future<BuildContext> _pumpHost(WidgetTester tester, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
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

Finder get _materialSheet => find.byType(BottomSheet);

void main() {
  group('FlareBottomSheet.show', () {
    testWidgets('frames the content under a title and returns the pop value', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final context = await _pumpHost(tester, size: _phone);
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
      expect(_materialSheet, findsOneWidget);
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

    testWidgets('auto is a sheet on a phone and a Modal on a wide window', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var context = await _pumpHost(tester, size: _phone);
      FlareBottomSheet.show<void>(
        context,
        title: '选择',
        builder: (_) => const Text('Body'),
      );
      await tester.pumpAndSettle();
      expect(_materialSheet, findsOneWidget);
      expect(find.byType(FlareModal), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);

      context = await _pumpHost(tester, size: _desktop);
      final result = FlareBottomSheet.show<String>(
        context,
        title: '选择',
        builder: (_) => const Text('Body'),
      );
      await tester.pumpAndSettle();
      expect(_materialSheet, findsNothing);
      // The same FlareBottomSheet hands its content to a Modal: the title
      // leads and still names the route, and there is no close control.
      expect(find.byType(FlareBottomSheet), findsOneWidget);
      expect(
        find.ancestor(of: find.text('Body'), matching: find.byType(FlareModal)),
        findsOneWidget,
      );
      expect(
        tester.widget<FlareModal>(find.byType(FlareModal)).showClose,
        isFalse,
      );
      expect(
        tester.getSemantics(find.text('选择')),
        isSemantics(isHeader: true, namesRoute: true),
      );
      final box = tester.getRect(find.byType(FlareModal));
      expect(box.center.dx, closeTo(_desktop.width / 2, 1));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
      expect(await result, isNull);
      semantics.dispose();
    });

    testWidgets('presentation sheet stays a sheet on a wide window', (
      tester,
    ) async {
      final context = await _pumpHost(tester, size: _desktop);
      FlareBottomSheet.show<void>(
        context,
        presentation: FlareSheetPresentation.sheet,
        builder: (_) => const Text('Body'),
      );
      await tester.pumpAndSettle();
      expect(_materialSheet, findsOneWidget);
      expect(find.byType(FlareModal), findsNothing);
    });

    testWidgets('auto is resolved once, when the sheet opens', (tester) async {
      final context = await _pumpHost(tester, size: _phone);
      FlareBottomSheet.show<void>(context, builder: (_) => const Text('Body'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = _desktop;
      await tester.pumpAndSettle();
      expect(_materialSheet, findsOneWidget);
      expect(find.byType(FlareModal), findsNothing);
    });

    testWidgets('the scrim closes a dismissible sheet with null', (
      tester,
    ) async {
      final context = await _pumpHost(tester, size: _phone);
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

    testWidgets('the scrim is the kit scrim token', (tester) async {
      for (final size in [_phone, _desktop]) {
        final context = await _pumpHost(tester, size: size);
        FlareBottomSheet.show<void>(
          context,
          builder: (_) => const Text('Body'),
        );
        await tester.pumpAndSettle();
        final scrim = FlareColors.of(context).scrim;
        expect(
          tester
              .widgetList<ModalBarrier>(find.byType(ModalBarrier))
              .map((barrier) => barrier.color),
          contains(scrim),
          reason: '$size',
        );
        Navigator.of(tester.element(find.text('Body'))).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('a sheet that is not dismissible ignores scrim and back', (
      tester,
    ) async {
      for (final size in [_phone, _desktop]) {
        final context = await _pumpHost(tester, size: size);
        FlareBottomSheet.show<void>(
          context,
          dismissible: false,
          builder: (_) => const Text('Busy'),
        );
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.text('Busy'), findsOneWidget, reason: '$size scrim');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Busy'), findsOneWidget, reason: '$size back');
        Navigator.of(tester.element(find.text('Busy'))).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('busy locks drag, scrim and back while it is up', (
      tester,
    ) async {
      final context = await _pumpHost(tester, size: _phone);
      final busy = ValueNotifier<bool>(true);
      addTearDown(busy.dispose);
      final result = FlareBottomSheet.show<String>(
        context,
        title: '举报',
        busy: busy,
        builder: (_) => const SizedBox(height: 300, child: Text('Form')),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.text('Form'), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsOneWidget, reason: 'drag');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsOneWidget, reason: 'scrim');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsOneWidget, reason: 'back');

      busy.value = false;
      await tester.pump();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('busy locks the Modal form too', (tester) async {
      final context = await _pumpHost(tester, size: _desktop);
      final busy = ValueNotifier<bool>(true);
      addTearDown(busy.dispose);
      FlareBottomSheet.show<void>(
        context,
        title: '举报',
        busy: busy,
        builder: (_) => const Text('Form'),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FlareModal>(find.byType(FlareModal)).busy, isTrue);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsOneWidget);
      busy.value = false;
      await tester.pump();
      expect(tester.widget<FlareModal>(find.byType(FlareModal)).busy, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsNothing);
    });

    testWidgets('caps its height and hands the content bounded constraints', (
      tester,
    ) async {
      for (final size in [_phone, _desktop]) {
        final context = await _pumpHost(tester, size: size);
        FlareBottomSheet.show<void>(
          context,
          title: '成员',
          maxHeight: 300,
          builder: (_) => ListView(
            children: [
              for (var i = 0; i < 60; i++)
                SizedBox(height: 40, child: Text('row $i')),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final list = tester.getRect(find.byType(ListView));
        expect(list.height, lessThanOrEqualTo(300), reason: '$size');
        Navigator.of(tester.element(find.byType(ListView))).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the default cap is 72% of the height the keyboard leaves', (
      tester,
    ) async {
      final context = await _pumpHost(tester, size: _phone);
      FlareBottomSheet.show<void>(
        context,
        builder: (_) =>
            const SingleChildScrollView(child: SizedBox(height: 2000)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sheet = tester.getRect(_materialSheet);
      expect(sheet.height, lessThanOrEqualTo(_phone.height * 0.72 + 1));
    });

    testWidgets('titleHidden names the surface without drawing the title', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final context = await _pumpHost(tester, size: _phone);
      FlareBottomSheet.show<void>(
        context,
        title: '消息操作',
        titleHidden: true,
        builder: (_) => const Text('Reply'),
      );
      await tester.pumpAndSettle();
      expect(find.text('消息操作'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('消息操作')),
        isSemantics(label: '消息操作', namesRoute: true),
      );
      semantics.dispose();
    });

    testWidgets('a sheet opened inside a nested navigator covers the window', (
      tester,
    ) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late BuildContext inner;
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              const Expanded(child: SizedBox.expand()),
              SizedBox(
                width: 200,
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (context) {
                      inner = context;
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      FlareBottomSheet.show<void>(inner, builder: (_) => const Text('Body'));
      await tester.pumpAndSettle();
      expect(tester.getRect(_materialSheet).width, _phone.width);
    });

    testWidgets('appears without motion when motion is reduced', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final size in [_phone, _desktop]) {
        final context = await _pumpHost(tester, size: size);
        FlareBottomSheet.show<void>(context, builder: (_) => const Text('Now'));
        await tester.pump();
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse, reason: '$size');
        expect(find.text('Now'), findsOneWidget);
        Navigator.of(tester.element(find.text('Now'))).pop();
        await tester.pumpAndSettle();
      }
    });
  });

  group('FlareModal.show', () {
    testWidgets('returns the value its modal pops', (tester) async {
      final context = await _pumpHost(tester);
      final result = FlareModal.show<bool>(
        context,
        builder: (dialogContext) => FlareModal(
          title: 'Leave?',
          footer: [
            FlareButton(
              label: 'Leave',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
          child: const Text('You can come back later.'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Leave?'), findsOneWidget);
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });

    testWidgets('frames plain content with the header it is given', (
      tester,
    ) async {
      final context = await _pumpHost(tester, size: _desktop);
      final result = FlareModal.show<String>(
        context,
        title: '说明',
        builder: (_) => const Text('正文'),
      );
      await tester.pumpAndSettle();
      expect(
        find.ancestor(of: find.text('正文'), matching: find.byType(FlareModal)),
        findsOneWidget,
      );
      await tester.tap(find.byType(FlareIconButton));
      await tester.pumpAndSettle();
      expect(find.text('正文'), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('gives a bare kit card the Material its field needs', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      FlareModal.show<void>(
        context,
        framed: false,
        builder: (_) => const Center(child: FlareMomentComposer()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(FlareMomentComposer), findsOneWidget);
      expect(find.byType(FlareModal), findsNothing);
    });

    testWidgets('a modal that is not dismissible ignores barrier and back', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      FlareModal.show<void>(
        context,
        dismissible: false,
        title: 'Saving',
        builder: (_) => const Text('Wait'),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Saving'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Saving'), findsOneWidget);
      final close = find.byType(FlareIconButton);
      expect(tester.widget<FlareIconButton>(close).disabled, isTrue);
    });
  });
}
