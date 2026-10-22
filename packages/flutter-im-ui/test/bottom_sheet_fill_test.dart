import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/flare_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FlareBottomSheet fill (spec BottomSheet `fill`): the surface takes its whole
// cap, the content fills the rest, and content that brings its own header
// (FlareSheetOwnHeader) keeps the title as the accessible name only.

const _phone = Size(402, 874);
const _desktop = Size(1280, 800);

Future<BuildContext> _pumpHost(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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

/// Sheet content with its own header row, like the kit pickers.
class _OwnHeader extends StatelessWidget implements FlareSheetOwnHeader {
  const _OwnHeader();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    key: ValueKey('own-header-content'),
    color: Colors.transparent,
    child: Column(
      children: [
        Text('Own header'),
        Expanded(child: SizedBox()),
      ],
    ),
  );
}

/// Own-header content that shows a host flag, like a picker's `sending`.
class _Sending extends StatelessWidget implements FlareSheetOwnHeader {
  const _Sending({required this.sending});

  final bool sending;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(sending ? 'sending' : 'idle'),
      const Expanded(child: SizedBox()),
    ],
  );
}

void main() {
  testWidgets('fill takes the whole cap and hands the content the rest', (
    tester,
  ) async {
    final context = await _pumpHost(tester, _phone);
    FlareBottomSheet.show<void>(
      context,
      title: 'Location',
      fill: true,
      maxHeight: 600,
      builder: (_) => const SizedBox.expand(key: ValueKey('plain-content')),
    );
    await tester.pumpAndSettle();
    final sheet = tester.getSize(find.byType(FlareOverlaySurface));
    expect(sheet.height, 600);
    // A plain child keeps the visible title, and fills what is left under it.
    expect(find.text('Location'), findsOneWidget);
    final content = tester.getSize(find.byKey(const ValueKey('plain-content')));
    expect(content.height, greaterThan(500));
    expect(content.height, lessThan(600));
  });

  testWidgets(
    'own-header content keeps the title as the accessible name only',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final context = await _pumpHost(tester, _phone);
      FlareBottomSheet.show<void>(
        context,
        title: 'Location',
        fill: true,
        builder: (_) => const _OwnHeader(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Location'), findsNothing);
      expect(find.bySemanticsLabel('Location'), findsOneWidget);
      expect(find.text('Own header'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('without fill nothing changes, even for own-header content', (
    tester,
  ) async {
    final context = await _pumpHost(tester, _phone);
    FlareBottomSheet.show<void>(
      context,
      title: 'Location',
      builder: (_) => const SizedBox(height: 120, child: _OwnHeader()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Location'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FlareOverlaySurface)).height,
      lessThan(300),
    );
  });

  testWidgets(
    'off the phone fill is the modal fill, heading hidden for own-header content',
    (tester) async {
      final context = await _pumpHost(tester, _desktop);
      FlareBottomSheet.show<void>(
        context,
        title: 'Location',
        fill: true,
        maxHeight: 560,
        builder: (_) => const _OwnHeader(),
      );
      await tester.pumpAndSettle();
      final modal = tester.widget<FlareModal>(find.byType(FlareModal));
      expect(modal.fill, isTrue);
      expect(modal.titleHidden, isTrue);
      expect(find.text('Location'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('own-header-content'))).height,
        greaterThan(400),
      );
    },
  );

  testWidgets(
    'listenable runs the builder again, and fill keeps the own header after each rebuild',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final sending = ValueNotifier<bool>(false);
      addTearDown(sending.dispose);
      var builds = 0;
      final context = await _pumpHost(tester, _phone);
      FlareBottomSheet.show<void>(
        context,
        title: 'Location',
        fill: true,
        busy: sending,
        listenable: sending,
        builder: (_) {
          builds++;
          return _Sending(sending: sending.value);
        },
      );
      await tester.pumpAndSettle();
      expect(find.text('idle'), findsOneWidget);
      final first = builds;

      sending.value = true;
      await tester.pump();
      expect(find.text('sending'), findsOneWidget);
      expect(builds, greaterThan(first));
      // Still the content's own header: the sheet draws no second title.
      expect(find.text('Location'), findsNothing);
      expect(find.bySemanticsLabel('Location'), findsOneWidget);
      // busy is the same notifier: the scrim does not close the sheet now.
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.text('sending'), findsOneWidget);

      sending.value = false;
      await tester.pump();
      expect(find.text('idle'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('without listenable the builder runs once; with it a plain sheet rebuilds too', (
    tester,
  ) async {
    final label = ValueNotifier<String>('one');
    addTearDown(label.dispose);
    final context = await _pumpHost(tester, _phone);
    FlareBottomSheet.show<void>(
      context,
      title: 'Plain',
      builder: (_) => Text('once ${label.value}'),
    );
    await tester.pumpAndSettle();
    label.value = 'two';
    await tester.pump();
    expect(find.text('once one'), findsOneWidget);
    Navigator.of(context, rootNavigator: true).pop();
    await tester.pumpAndSettle();

    FlareBottomSheet.show<void>(
      context,
      title: 'Plain',
      listenable: label,
      builder: (_) => Text('live ${label.value}'),
    );
    await tester.pumpAndSettle();
    expect(find.text('live two'), findsOneWidget);
    label.value = 'three';
    await tester.pump();
    expect(find.text('live three'), findsOneWidget);
    expect(find.text('Plain'), findsOneWidget);
  });

  testWidgets('off the phone the modal rebuilds from listenable as well', (tester) async {
    final sending = ValueNotifier<bool>(false);
    addTearDown(sending.dispose);
    final context = await _pumpHost(tester, _desktop);
    FlareBottomSheet.show<void>(
      context,
      title: 'Location',
      fill: true,
      listenable: sending,
      builder: (_) => _Sending(sending: sending.value),
    );
    await tester.pumpAndSettle();
    expect(find.text('idle'), findsOneWidget);
    sending.value = true;
    await tester.pump();
    expect(find.text('sending'), findsOneWidget);
    expect(tester.widget<FlareModal>(find.byType(FlareModal)).titleHidden, isTrue);
  });

  testWidgets('the kit pickers declare their own header', (tester) async {
    expect(const FlareContactPicker(groups: []), isA<FlareSheetOwnHeader>());
    expect(
      FlareLocationPicker(
        requestCurrentLocation: () async =>
            const FlareLocationCoordinate(latitude: 0, longitude: 0),
        searchNearby: (lat, lng, query) async => const [],
      ),
      isA<FlareSheetOwnHeader>(),
    );
  });
}
