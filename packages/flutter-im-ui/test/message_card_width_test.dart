import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FlarePluginViewModel _packet() => FlarePluginViewModel.fromJson(
  (jsonDecode(
            File(
              '../../spec/financial-presentation-vectors.json',
            ).readAsStringSync(),
          )['card']
          as Map)
      .cast<String, Object?>(),
);

Finder _packetFace() => find
    .descendant(
      of: find.byType(FlareRedPacketCard),
      matching: find.byType(InkWell),
    )
    .last;

void main() {
  testWidgets(
    'a quoted envelope exposes and activates its quote independently',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var located = 0;
      var opened = 0;
      Widget packet(bool disabled) => MaterialApp(
        home: Scaffold(
          body: FlareCardQuote(
            quote: TextButton(
              onPressed: () => located++,
              child: const Text('Quoted message'),
            ),
            child: FlareRedPacketCard(
              blessing: 'Hello',
              disabled: disabled,
              onOpen: () => opened++,
            ),
          ),
        ),
      );
      await tester.pumpWidget(packet(false));
      expect(find.bySemanticsLabel('Quoted message'), findsOneWidget);
      await tester.tap(find.text('Quoted message'));
      expect((located, opened), (1, 0));
      await tester.tap(_packetFace());
      expect((located, opened), (1, 1));
      await tester.pumpWidget(packet(true));
      expect(find.bySemanticsLabel('Quoted message'), findsOneWidget);
      await tester.tap(find.text('Quoted message'));
      expect((located, opened), (2, 1));
      semantics.dispose();
    },
  );

  testWidgets('all packet footers fit narrow English layouts with large text', (
    tester,
  ) async {
    for (final kind in FlareRedPacketKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: FlareStringsScope(
            strings: flareStringsEnglish,
            child: Scaffold(
              body: Center(
                child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: SizedBox(
                    width: 180,
                    child: FlareRedPacketCard(
                      blessing: 'Congratulations and best wishes',
                      kind: kind,
                      recipientName: 'A recipient with a long name',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: kind.name);
      expect(tester.getSize(_packetFace()).width, 180);
    }
  });

  for (final width in [180.0, 390.0, 1360.0]) {
    for (final self in [false, true]) {
      testWidgets(
        'resolved packet keeps its width in a $width timeline, self $self',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              home: FlareContentScope(
                builders: {
                  'width-fixture': (context, content, ctx) =>
                      FlarePluginView(view: _packet(), onAction: (_, _) {}),
                },
                child: Scaffold(
                  body: FlareMessageBubble(
                    message: FlareMessageData(
                      id: 'packet',
                      senderId: self ? 'me' : 'alice',
                      senderName: 'Alice',
                      content: const FlareGenericContent(
                        contentType: 'width-fixture',
                        label: 'Packet',
                      ),
                      timeLabel: '18:30',
                    ),
                    currentUserId: 'me',
                    surface: FlareMessageSurface.card,
                  ),
                ),
              ),
            ),
          );
          final face = tester.getRect(_packetFace());
          expect(
            face.width,
            lessThanOrEqualTo(FlareSizes.componentRedPacketCardWidth),
          );
          if (width >= 390) {
            expect(face.width, FlareSizes.componentRedPacketCardWidth);
          }
          final meta = tester.getRect(find.text('18:30'));
          expect(
            meta.right,
            lessThanOrEqualTo(face.right + 1),
            reason: 'metadata must stay beneath its envelope, not the pane cap',
          );
          expect(meta.left, greaterThanOrEqualTo(face.left - 1));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('a tight $width parent preserves packet and rich-card caps', (
      tester,
    ) async {
      tester.view.physicalSize = Size(math.max(width, 390), 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlareRedPacketCard(blessing: '恭喜发财'),
                    FlareMessageCardShell(
                      child: SizedBox(
                        width: double.infinity,
                        child: Text('Contact card'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(_packetFace()).width,
        math.min(width, FlareSizes.componentRedPacketCardWidth),
      );
      expect(
        tester.getSize(find.byKey(FlareMessageCardShell.surfaceKey)).width,
        math.min(width, FlareSizes.componentRichCardWidth),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
