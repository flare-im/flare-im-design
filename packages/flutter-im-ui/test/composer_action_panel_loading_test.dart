import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// §4.1: the "+" panel opens at once; while the plugin items load, a row of
// skeleton squares holds their place.
Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.topCenter, child: child),
  ),
);

void main() {
  testWidgets('loading adds one row of skeleton squares after the tiles', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const FlareComposerActionPanel(
          formFactor: FlareComposerPanelFormFactor.desktop,
          loading: true,
        ),
      ),
    );
    expect(find.byKey(FlareComposerActionPanel.skeletonKey), findsNWidgets(4));
    expect(
      find.byWidgetPredicate(
        (w) => w is FlareSkeleton && w.variant == FlareSkeletonVariant.tile,
      ),
      findsNWidgets(4),
    );
    expect(
      tester.getSize(find.byKey(FlareComposerActionPanel.skeletonKey).first),
      const Size.square(52),
    );
    expect(
      find.descendant(
        of: find.byType(FlareComposerActionPanel),
        matching: find.byType(InkWell),
      ),
      findsNWidgets(FlareComposerActionPanel.defaultActions.length),
    );
    expect(find.bySemanticsLabel('加载中'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the squares go once the items arrive', (tester) async {
    await tester.pumpWidget(
      _host(
        const FlareComposerActionPanel(
          formFactor: FlareComposerPanelFormFactor.desktop,
        ),
      ),
    );
    expect(find.byKey(FlareComposerActionPanel.skeletonKey), findsNothing);
  });
}
