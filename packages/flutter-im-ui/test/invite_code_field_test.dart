import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('off mode renders nothing at all', (tester) async {
    await tester.pumpWidget(_host(const FlareInviteCodeField(mode: FlareInviteCodeMode.off)));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('邀请码'), findsNothing);
  });

  testWidgets('optional shows the hint, required the mark', (tester) async {
    await tester.pumpWidget(_host(const FlareInviteCodeField()));
    expect(find.text('邀请码'), findsOneWidget);
    expect(find.text('选填'), findsOneWidget);
    await tester.pumpWidget(_host(const FlareInviteCodeField(mode: FlareInviteCodeMode.required)));
    expect(find.textContaining('*'), findsOneWidget);
    expect(find.text('选填'), findsNothing);
  });

  testWidgets('normalizes typing the way the server reads it and caps at the length', (tester) async {
    final controller = TextEditingController();
    final changes = <String>[];
    await tester.pumpWidget(_host(FlareInviteCodeField(controller: controller, onChanged: changes.add)));
    await tester.enterText(find.byType(TextField), ' ab-o1 li9z ');
    await tester.pump();
    expect(controller.text, 'AB0111');
    expect(changes.last, 'AB0111');
    await tester.enterText(find.byType(TextField), 'AB01117');
    await tester.pump();
    expect(controller.text, 'AB0111');
  });

  testWidgets('asks for one check 400 ms after a complete code, never for a partial one', (tester) async {
    final checks = <String>[];
    await tester.pumpWidget(_host(FlareInviteCodeField(onCheck: checks.add)));
    await tester.enterText(find.byType(TextField), 'AB1');
    await tester.pump(const Duration(seconds: 1));
    expect(checks, isEmpty);
    await tester.enterText(find.byType(TextField), 'AB12C');
    await tester.enterText(find.byType(TextField), 'AB12CD');
    await tester.pump(const Duration(milliseconds: 399));
    expect(checks, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(checks, ['AB12CD']);
    await tester.enterText(find.byType(TextField), 'AB12CE');
    await tester.pump(const Duration(milliseconds: 400));
    expect(checks, ['AB12CD', 'AB12CE']);
  });

  testWidgets('applies a deep-link prefill once and checks it like a paste', (tester) async {
    final controller = TextEditingController();
    final checks = <String>[];
    await tester.pumpWidget(_host(FlareInviteCodeField(controller: controller, prefill: 'ab12cd', onCheck: checks.add)));
    await tester.pump();
    expect(controller.text, 'AB12CD');
    await tester.pump(const Duration(milliseconds: 400));
    expect(checks, ['AB12CD']);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpWidget(_host(FlareInviteCodeField(controller: controller, prefill: 'zz99zz', onCheck: checks.add)));
    await tester.pump();
    expect(controller.text, '');
  });

  testWidgets('walks the state vector: checking, inviter on valid, kit text on invalid, host error wins', (tester) async {
    final controller = TextEditingController(text: 'AB12CD');
    await tester.pumpWidget(_host(FlareInviteCodeField(controller: controller, checking: true)));
    expect(find.text('正在校验邀请码…'), findsOneWidget);

    await tester.pumpWidget(_host(FlareInviteCodeField(
      controller: controller,
      checkResult: const FlareInviteCodeCheckResult(valid: true, inviterDisplayName: 'A**n'),
    )));
    expect(find.text('邀请人：A**n'), findsOneWidget);

    await tester.pumpWidget(_host(FlareInviteCodeField(
      controller: controller,
      checkResult: const FlareInviteCodeCheckResult(valid: false),
    )));
    expect(find.text('邀请码无效'), findsOneWidget);

    await tester.pumpWidget(_host(FlareInviteCodeField(
      controller: controller,
      error: '请填写邀请码后再提交',
      checkResult: const FlareInviteCodeCheckResult(valid: true, inviterDisplayName: 'Ann'),
    )));
    expect(find.text('请填写邀请码后再提交'), findsOneWidget);
    expect(find.text('邀请人：Ann'), findsNothing);
  });

  testWidgets('a verdict for another code is not shown', (tester) async {
    final controller = TextEditingController(text: 'AB1');
    await tester.pumpWidget(_host(FlareInviteCodeField(
      controller: controller,
      checkResult: const FlareInviteCodeCheckResult(valid: true, inviterDisplayName: 'Ann'),
    )));
    expect(find.text('邀请人：Ann'), findsNothing);
  });

  testWidgets('a host override changes the copy', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareStringsScope(
          strings: const FlareStrings().copyWith(inviteCodeLabel: 'Invite code'),
          child: const FlareInviteCodeField(mode: FlareInviteCodeMode.required),
        ),
      ),
    ));
    expect(find.textContaining('Invite code'), findsOneWidget);
  });
}
