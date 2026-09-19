import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

// DoD 20 —— 发送路径上的输入法证明：组字中按 Enter 绝不能把半个词发出去。
// 这条是真渲染 + 真按键，不是只验纯函数。
void main() {
  Future<void> pumpComposer(
    WidgetTester tester, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> sent,
    FlareComposerSubmitMode mode = FlareComposerSubmitMode.enter,
  }) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareComposer(
            controller: controller,
            focusNode: focusNode,
            desktopSubmitMode: mode,
            onSend: (text) {
              sent.add(text);
              return true;
            },
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
  }

  testWidgets('Enter 在没有组字时发送', (tester) async {
    final controller = TextEditingController(text: '晚点同步');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final sent = <String>[];
    await pumpComposer(
      tester,
      controller: controller,
      focusNode: focusNode,
      sent: sent,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sent, ['晚点同步']);
  });

  testWidgets('组字中按 Enter 不发送，提交后同一个键才发送', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final sent = <String>[];
    await pumpComposer(
      tester,
      controller: controller,
      focusNode: focusNode,
      sent: sent,
    );

    // 输入法把「晚点同步」挂在 composing 区间上，还没上屏。
    controller.value = const TextEditingValue(
      text: '晚点同步',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 0, end: 4),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sent, isEmpty, reason: '这一下 Enter 属于输入法，不是发送');
    expect(controller.text, '晚点同步', reason: '草稿不能被清掉');

    // 输入法提交后 composing 区间清空，同一个 Enter 才是发送。
    controller.value = controller.value.copyWith(composing: TextRange.empty);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sent, ['晚点同步']);
  });

  testWidgets('组字中的 Ctrl+Enter 同样不发送', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final sent = <String>[];
    await pumpComposer(
      tester,
      controller: controller,
      focusNode: focusNode,
      sent: sent,
      mode: FlareComposerSubmitMode.modifierEnter,
    );

    controller.value = const TextEditingValue(
      text: '晚点同步',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 0, end: 4),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(sent, isEmpty);
  });
}
