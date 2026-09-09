import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  test('shared device layout vectors', () {
    final vectors =
        jsonDecode(
              File('../spec/device-layout-vectors.json').readAsStringSync(),
            )
            as List;
    for (final v in vectors) {
      expect(
        FlareLayoutPolicy.paneCount(
          (v['width'] as num).toDouble(),
          hasDetail: v['detail'],
          textScale: (v['scale'] as num).toDouble(),
        ),
        v['expected'],
        reason: '$v',
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
          if (FlareLayoutPolicy.paneCount(
                width,
                hasDetail: true,
                textScale: scale,
              ) ==
              1) {
            final button = find.byType(TextButton);
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
            await tester.tap(button);
            expect(back, FlarePane.chat);
          }
        });
      }
    }
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
      expect(find.text('99+'), findsOneWidget);
    });
  }
}
