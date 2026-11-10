import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _rootKey = ValueKey('desktop-fixture-boundary');
const _messages = [
  FlareMessageData(id: 'incoming-video', senderId: 'alice', senderName: 'Lab Alice', content: FlareGenericContent(contentType: 'fixture-call', label: 'video-5'), timeLabel: '11:58 PM'),
  FlareMessageData(id: 'incoming-voice', senderId: 'alice', senderName: 'Lab Alice', content: FlareGenericContent(contentType: 'fixture-call', label: 'voice-88'), timeLabel: '12:15 AM'),
  FlareMessageData(id: 'outgoing-voice', senderId: 'me', senderName: 'Lab Bob', content: FlareGenericContent(contentType: 'fixture-call', label: 'voice-102'), timeLabel: '12:17 AM'),
  FlareMessageData(id: 'incoming-video-2', senderId: 'alice', senderName: 'Lab Alice', content: FlareGenericContent(contentType: 'fixture-call', label: 'video-223'), timeLabel: '12:19 AM'),
  FlareMessageData(id: 'outgoing-video', senderId: 'me', senderName: 'Lab Bob', content: FlareGenericContent(contentType: 'fixture-call', label: 'video-265'), timeLabel: '12:23 AM'),
];

Finder row(String id) => find.byWidgetPredicate((w) => w is FlareMessageBubble && w.message.id == id);
Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_rootKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('/Users/hg/workspace/flare/flare-im/docs/reports/evidence/2026-11-03-flutter-composer-menu/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets('capture actual shared Flutter desktop message rows', variant: TargetPlatformVariant.only(TargetPlatform.macOS), (tester) async {
    tester.view.physicalSize = const Size(1360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final font = FontLoader('FixtureSans')..addFont(Future.value(ByteData.sublistView(await File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytes())));
      await font.load();
      final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(await File('/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytes())));
      await icons.load();
    });
    FlareContentRegistry.register('fixture-call', (context, content, ctx) {
      final fields = (content as FlareGenericContent).label.split('-');
      return FlareCallRecordCard(media: fields.first == 'voice' ? FlareCallMode.audio : FlareCallMode.video, scope: FlareCallRecordScope.group, state: FlareCallRecordState.ended, durationSeconds: int.parse(fields.last), viewerIsInitiator: false, canJoin: false, canCallBack: false);
    });
    addTearDown(() => FlareContentRegistry.unregister('fixture-call'));
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, fontFamily: 'FixtureSans'),
      home: FlareStringsScope(strings: flareStringsEnglish,
        child: FlareTheme(mode: FlareThemeMode.dark,
          child: Builder(builder: (context) {
            final colors = FlareColors.of(context);
            return RepaintBoundary(key: _rootKey,
              child: Scaffold(backgroundColor: colors.bgSecondary,
                body: Column(children: [
                  FlareConversationHeader(identity: const FlareConversationIdentity(id:'fixture-group', title:'Flutter desktop message actions', subtitle:'Shared component fixture · not server data'), capabilities: const FlareConversationHeaderCapabilities(availableActionIds: {'search'}), onAction: (_) {}),
                  Divider(height:1, color:colors.borderSecondary),
                  Padding(padding: const EdgeInsets.all(16), child: Text('Incoming controls on the right · outgoing controls on the left', style: TextStyle(color:colors.textTertiary, fontSize:13))),
                  Expanded(child: ListView(children: [
                    for(final message in _messages)
                      Padding(padding: const EdgeInsets.symmetric(vertical:8, horizontal:16),
                        child: FlareMessageBubble(message:message, currentUserId:'me', surface:FlareMessageSurface.card, conversationKind:FlareConversationKind.group,
                          rowPresentation:FlareMessageRowPresentation(showAvatar: message.senderId != 'me', reserveAvatarSpace: message.senderId != 'me', showSenderName: message.senderId != 'me'),
                          onReact:(_,_) {}, onReply:(_) {}, onContextMenu:(_,_) {})),
                  ])),
                  Divider(height:1, color:colors.borderSecondary),
                  const Padding(padding:EdgeInsets.all(16), child: Text('Deterministic Flutter widget rendering · sample call records')),
                ]),
              ),
            );
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind:PointerDeviceKind.mouse);
    await mouse.addPointer(location:const Offset(700,110));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(row('incoming-voice')));
    await tester.pump();
    expect(find.byKey(FlareMessageBubble.hoverToolbarKey),findsOneWidget);
    final incomingCard = tester.getRect(find.descendant(of: row('incoming-voice'), matching: find.byKey(FlareMessageCardShell.surfaceKey)));
    final incomingToolbar = tester.getRect(find.byKey(FlareMessageBubble.hoverToolbarKey));
    expect(incomingToolbar.center.dy, closeTo(incomingCard.center.dy,0.1));
    expect(incomingToolbar.left-incomingCard.right,closeTo(8,0.1));
    await capture(tester,'flutter-desktop-menu-incoming-fixture');
    await mouse.moveTo(tester.getCenter(row('outgoing-video')));
    await tester.pump();
    expect(find.byKey(FlareMessageBubble.hoverToolbarKey),findsOneWidget);
    final outgoingCard = tester.getRect(find.descendant(of: row('outgoing-video'), matching: find.byKey(FlareMessageCardShell.surfaceKey)));
    final outgoingToolbar = tester.getRect(find.byKey(FlareMessageBubble.hoverToolbarKey));
    expect(outgoingToolbar.center.dy,closeTo(outgoingCard.center.dy,0.1));
    expect(outgoingCard.left-outgoingToolbar.right,closeTo(8,0.1));
    await capture(tester,'flutter-desktop-menu-outgoing-fixture');
    await tester.runAsync(() => File('/Users/hg/workspace/flare/flare-im/docs/reports/evidence/2026-11-03-flutter-composer-menu/fixture-menu-geometry.json').writeAsString(jsonEncode({
      'incoming': {'cardCentreY':incomingCard.center.dy,'toolbarCentreY':incomingToolbar.center.dy,'gap':incomingToolbar.left-incomingCard.right},
      'outgoing': {'cardCentreY':outgoingCard.center.dy,'toolbarCentreY':outgoingToolbar.center.dy,'gap':outgoingCard.left-outgoingToolbar.right},
      'source':'actual Flutter test RenderBox geometry, sample data, not server data',
    })));
  });
}
