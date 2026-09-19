import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  test('the one pane rule follows the shared table', () {
    final fixture =
        jsonDecode(
              File(
                '../../spec/application-layout-vectors.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final panes = fixture['panes'] as List;
    expect(panes.length, greaterThanOrEqualTo(20));
    for (final v in panes) {
      expect(
        flarePaneModeForWidth(
          (v['width'] as num).toDouble(),
          hasDetail: v['hasDetail'] as bool,
          textScale: (v['scale'] as num).toDouble(),
          navigationWidth: (v['navigationWidth'] as num).toDouble(),
          primaryWidth:
              (v['primaryWidth'] as num?)?.toDouble() ??
              FlareSizes.primaryPaneDefaultWidth,
          detailWidth:
              (v['detailWidth'] as num?)?.toDouble() ??
              FlareSizes.detailPaneDefaultWidth,
        ).name,
        v['expected'],
        reason: '${v['id']}: ${v['why']}',
      );
    }
    // The rule, not a magic number: rail + list + the chat minimum.
    expect(
      flarePaneModeMinWidth(
        FlareWorkspacePaneMode.dualPane,
        navigationWidth: flareNavigationWidthForMode(
          FlareApplicationResponsiveMode.tablet,
        ),
      ),
      752,
    );
    expect(flarePaneModeMinWidth(FlareWorkspacePaneMode.triplePane), 980);
    expect(flarePaneModeMinWidth(FlareWorkspacePaneMode.singlePane), 0);
  });
  test('shared application layout vectors', () {
    final fixture =
        jsonDecode(
              File(
                '../../spec/application-layout-vectors.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    for (final v in fixture['cases'] as List) {
      final width = (v['width'] as num).toDouble();
      final scale = (v['scale'] as num).toDouble();
      final mode = flareApplicationResponsiveModeForWidth(
        width,
        textScale: scale,
      );
      expect(mode.name, v['expected']['mode'], reason: v['id']);
      final presentation = flareWorkspacePresentation(
        mode,
        hasDetail: v['hasDetail'] as bool,
        width: width,
        textScale: scale,
        navigationWidth: (v['navigation'] as bool) ? null : 0,
      );
      expect(
        presentation.paneMode.name,
        v['expected']['paneMode'],
        reason: v['id'],
      );
      expect(
        presentation.detail.name,
        v['expected']['detail'],
        reason: v['id'],
      );
    }
  });

  for (final width in [320.0, 390.0, 720.0, 1100.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('detail visible width=$width scale=$scale dark=$dark', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = Size(width * 3, 2400);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          FlarePane? back;
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 59, bottom: 34),
                ),
                child: child!,
              ),
              home: Scaffold(
                body: SafeArea(
                  child: FlareResponsiveLayout(
                    activePane: FlarePane.detail,
                    onPaneChange: (pane) => back = pane,
                    list: const Text('list'),
                    chat: const Text('chat'),
                    detail: const Text('detail'),
                  ),
                ),
              ),
            ),
          );
          expect(find.text('detail'), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(
            tester.getTopLeft(find.text('detail')).dy,
            greaterThanOrEqualTo(59),
          );
          if (flarePaneModeForWidth(width, hasDetail: true, textScale: scale) ==
              FlareWorkspacePaneMode.singlePane) {
            final button = find.byType(TextButton);
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
            await tester.tap(button);
            expect(back, FlarePane.chat);
          }
        });
      }
    }
  }
  // FR-110: the conversation layout answers with the same rule, and says so in
  // the words the application frames use.
  for (final (width, paneMode, list) in [
    (679.0, FlareWorkspacePaneMode.singlePane, false),
    (680.0, FlareWorkspacePaneMode.dualPane, true),
  ]) {
    testWidgets('conversation layout at $width reports ${paneMode.name}', (
      tester,
    ) async {
      final reports = <FlareWorkspacePresentation>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: FlareResponsiveLayout(
                  activePane: FlarePane.chat,
                  onLayoutChange: reports.add,
                  list: const Text('list'),
                  chat: const Text('chat'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('list'), list ? findsOneWidget : findsNothing);
      expect(find.text('chat'), findsOneWidget);
      expect(reports, [
        FlareWorkspacePresentation(
          paneMode,
          FlareWorkspaceDetailPresentation.hidden,
        ),
      ]);
    });
  }
  testWidgets('nested narrow container does not use window width', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: FlareResponsiveLayout(
                list: Text('list'),
                chat: Text('chat'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('list'), findsOneWidget);
    expect(find.text('chat'), findsNothing);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('conversation at large text width=$width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: FlareConversationRow(
              item: ConversationRowData(
                id: 'test',
                title: '很长的会话名称 Long conversation',
                preview: '长消息与 emoji 👋',
                timestampLabel: '23:59',
                unreadCount: 120,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('120'), findsOneWidget);
    });
  }
}
