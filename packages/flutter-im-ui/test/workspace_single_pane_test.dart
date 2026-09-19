import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// B5.4 (FR-083 / FR-095): a workspace keeps the list beside the chat only while
// the chat keeps its minimum width. On its own (no shell) the frame resolves the
// mode from its own box.
//
// the chat keeps its minimum width. Below navigation + list + chat (72 + 320 +
// 360 = 752) it shows one pane at a time, keeps the rail, and a detail becomes a
// page the host routes to rather than an overlay over a screen-wide pane.

Widget _layout({
  required double width,
  double textScale = 1,
  bool hasDetail = false,
  FlareWorkspacePane activePane = FlareWorkspacePane.content,
  ValueChanged<FlareWorkspacePresentation>? onLayoutChange,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: 800,
          child: FlareAppLayout(
            navigation: const SizedBox(
              width: FlareSizes.navigationRailWidth,
              child: Text('rail'),
            ),
            primary: const Text('list'),
            content: const Text('chat'),
            detail: hasDetail ? const Text('detail') : null,
            hasDetail: hasDetail,
            activePane: activePane,
            onLayoutChange: onLayoutChange,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a tablet below 752 shows one pane and keeps the rail', (
    tester,
  ) async {
    await tester.pumpWidget(_layout(width: 700));
    await tester.pumpAndSettle();
    expect(find.text('rail'), findsOneWidget);
    expect(find.text('chat'), findsOneWidget, reason: 'the active pane');
    expect(find.text('list'), findsNothing, reason: 'no second pane');
  });

  testWidgets('the pane that shows is the host active pane', (tester) async {
    await tester.pumpWidget(
      _layout(width: 700, activePane: FlareWorkspacePane.primary),
    );
    await tester.pumpAndSettle();
    expect(find.text('list'), findsOneWidget);
    expect(find.text('chat'), findsNothing);
  });

  testWidgets('at 752 and above the list sits beside the chat again', (
    tester,
  ) async {
    await tester.pumpWidget(_layout(width: 752));
    await tester.pumpAndSettle();
    expect(find.text('rail'), findsOneWidget);
    expect(find.text('list'), findsOneWidget);
    expect(find.text('chat'), findsOneWidget);
  });

  testWidgets('the width the layout reads is its own box, not the window', (
    tester,
  ) async {
    // A 700-wide frame inside a 1400-wide window is still one pane.
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_layout(width: 700));
    await tester.pumpAndSettle();
    expect(find.text('list'), findsNothing);
  });

  // FR-110: only the chat's minimum grows with the text (360 x 1.5 = 540); the
  // rail and the list keep the widths they are drawn at. 72 + 320 + 540 = 932.
  testWidgets('text scale grows only the chat: 932 at 1.5 fits two panes', (
    tester,
  ) async {
    _roomFor(tester, 1000);
    await tester.pumpWidget(_layout(width: 931, textScale: 1.5));
    await tester.pumpAndSettle();
    expect(find.text('list'), findsNothing);
    await tester.pumpWidget(_layout(width: 932, textScale: 1.5));
    await tester.pumpAndSettle();
    expect(find.text('list'), findsOneWidget);
  });

  testWidgets('the host is told the presentation, once per change', (
    tester,
  ) async {
    final reports = <FlareWorkspacePresentation>[];
    await tester.pumpWidget(
      _layout(width: 700, hasDetail: true, onLayoutChange: reports.add),
    );
    await tester.pumpAndSettle();
    expect(reports, hasLength(1), reason: 'the first resolution');
    expect(reports.single.paneMode, FlareWorkspacePaneMode.singlePane);
    expect(reports.single.detail, FlareWorkspaceDetailPresentation.route);

    // A rebuild with the same width says nothing new.
    await tester.pumpWidget(
      _layout(width: 700, hasDetail: true, onLayoutChange: reports.add),
    );
    await tester.pumpAndSettle();
    expect(reports, hasLength(1));

    // Growing past the two-pane width is a change.
    await tester.pumpWidget(
      _layout(width: 800, hasDetail: true, onLayoutChange: reports.add),
    );
    await tester.pumpAndSettle();
    expect(reports, hasLength(2));
    expect(reports.last.paneMode, FlareWorkspacePaneMode.dualPane);
    expect(reports.last.detail, FlareWorkspaceDetailPresentation.overlay);
  });

  testWidgets('a detail in one-pane mode is a page, not an overlay', (
    tester,
  ) async {
    final reports = <FlareWorkspacePresentation>[];
    await tester.pumpWidget(
      _layout(
        width: 700,
        hasDetail: true,
        activePane: FlareWorkspacePane.detail,
        onLayoutChange: reports.add,
      ),
    );
    await tester.pumpAndSettle();
    expect(reports.single.detail, FlareWorkspaceDetailPresentation.route);
    // The host routes to it; the kit shows it as the one pane, with no overlay
    // surface over a screen-wide pane.
    expect(find.text('detail'), findsOneWidget);
    expect(find.text('chat'), findsNothing);
    expect(find.byType(Material).evaluate().length, lessThan(4));

    // Wide enough for two panes, the same detail is an overlay again.
    await tester.pumpWidget(
      _layout(
        width: 800,
        hasDetail: true,
        activePane: FlareWorkspacePane.detail,
        onLayoutChange: reports.add,
      ),
    );
    await tester.pumpAndSettle();
    expect(reports.last.detail, FlareWorkspaceDetailPresentation.overlay);
    expect(find.text('chat'), findsOneWidget);
    expect(find.text('detail'), findsOneWidget);
  });

  testWidgets('a phone reports one pane too', (tester) async {
    final reports = <FlareWorkspacePresentation>[];
    await tester.pumpWidget(
      _layout(width: 390, hasDetail: true, onLayoutChange: reports.add),
    );
    await tester.pumpAndSettle();
    expect(reports.single.paneMode, FlareWorkspacePaneMode.singlePane);
    expect(reports.single.detail, FlareWorkspaceDetailPresentation.route);
  });

  // FR-110: a desktop draws a 280 sidebar, and the rule counts it: 280 + 320 +
  // 360 = 960. The old rule never checked two panes on a desktop, so a 900 wide
  // desktop squeezed the chat to 300.
  testWidgets('a desktop keeps two panes only with room for its sidebar', (
    tester,
  ) async {
    _roomFor(tester, 1100);
    await tester.pumpWidget(_layout(width: 959, hasDetail: true));
    await tester.pumpAndSettle();
    expect(find.text('list'), findsNothing);
    await tester.pumpWidget(_layout(width: 1000, hasDetail: true));
    await tester.pumpAndSettle();
    expect(find.text('list'), findsOneWidget);
    expect(find.text('chat'), findsOneWidget);
  });
}

/// The default test surface is 800 wide, and a wider SizedBox inside it is
/// quietly clamped to 800: give the layout the room its width names.
void _roomFor(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
