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
