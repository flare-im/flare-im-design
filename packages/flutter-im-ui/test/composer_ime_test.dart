import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

// DoD 20 —— 发送路径上的输入法证明：组字中按 Enter 绝不能把半个词发出去。
// 这条是真渲染 + 真按键，不是只验纯函数。
void main() {
  testWidgets('touch switches between the keyboard and composer panels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    final draft = TextEditingController();
    final focus = FocusNode();
    addTearDown(tester.view.reset);
    addTearDown(draft.dispose);
    addTearDown(focus.dispose);
    var outsideTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => outsideTaps++,
                  child: const Center(child: Text('Timeline')),
                ),
              ),
              FlareComposer(
                controller: draft,
                focusNode: focus,
                actions: const [
                  FlareComposerAction(id: 'file', label: 'File', icon: 'file'),
                ],
                onSend: (_) => true,
              ),
            ],
          ),
        ),
      ),
    );
    final input = find.byKey(const ValueKey('composer-input'));
    final picker = find.byType(FlareEmojiStickerPicker);
    await tester.tap(input);
    await tester.pump();
    tester.testTextInput.enterText('draft');
    tester.view.viewInsets = const FakeViewPadding(bottom: 270);
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(tester.getBottomLeft(find.byType(FlareComposer)).dy, 530);

    await tester.tap(find.byIcon(flareIconMap['emoji']!));
    await tester.pump();
    tester.view.resetViewInsets();
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(picker, findsOneWidget);
    tester.widget<FlareEmojiStickerPicker>(picker).onInsertEmoji!('alien');
    await tester.pump();
    expect(draft.text, 'draft[alien]');
    expect(focus.hasFocus, isFalse);
    expect(picker, findsOneWidget);

    await tester.tap(input);
    await tester.pump();
    expect(picker, findsNothing);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byIcon(flareIconMap['add']!));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    expect(find.byType(FlareComposerActionPanel), findsOneWidget);
    await tester.tap(input);
    await tester.pump();
    expect(find.byType(FlareComposerActionPanel), findsNothing);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('Timeline'));
    await tester.pump();
    expect(outsideTaps, 1);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(draft.text, 'draft[alien]');
  });

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
