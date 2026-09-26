import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归:同一个 FlareInput 元素被重建时换了 controller,输入必须落到新 controller,
/// 旧 controller 不能再被驱动(曾让注册页的昵称与密码两个框内容互相镜像)。
void main() {
  testWidgets('FlareInput follows a swapped controller', (tester) async {
    final first = TextEditingController();
    final second = TextEditingController();
    Widget build(TextEditingController controller) => MaterialApp(
      home: Scaffold(body: FlareInput(controller: controller)),
    );

    await tester.pumpWidget(build(first));
    await tester.enterText(find.byType(TextField), 'one');
    expect(first.text, 'one');

    await tester.pumpWidget(build(second));
    await tester.enterText(find.byType(TextField), 'two');
    expect(second.text, 'two');
    expect(first.text, 'one');
  });
}
