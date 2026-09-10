import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('contact actions fit narrow layouts and expose unavailable calls', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final handle = tester.ensureSemantics();
    try {
    var opens = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FlareContactDetail(
      contact: const FlareContact(id: 'qa', name: 'QA Contact'),
      onMessage: () => opens++,
    ))));
    expect(tester.takeException(), isNull);
    final voice = find.widgetWithText(FlareButton, '语音通话');
    expect(tester.getSemantics(voice).hasFlag(SemanticsFlag.isButton), isTrue);
    expect(tester.getSemantics(voice).hasFlag(SemanticsFlag.isEnabled), isFalse);
    await tester.tap(find.widgetWithText(FlareButton, '发消息'));
    expect(opens, 1);
    await tester.tap(voice);
    expect(opens, 1);
    expect(tester.takeException(), isNull);
    } finally { handle.dispose(); }
  });
}
