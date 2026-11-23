import 'dart:ui' show SemanticsValidationResult;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// R6 / §12.9 (docs/plugin-experience.md): a plugin form's fields.

FlarePluginInput _input(Map<String, Object?> json) =>
    FlarePluginInput.fromJson(json)!;

final _name = _input({
  'id': 'name',
  'kind': 'text',
  'label': '姓名',
  'required': true,
  'maxLength': 20,
});

Widget _host(Widget form, {TargetPlatform platform = TargetPlatform.android}) =>
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: Scaffold(body: form),
    );

void _surface(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _submitKey = find.byKey(const ValueKey('flare-plugin-form-submit'));

void main() {
  testWidgets('the label is primary text; a required one draws * in error '
      'and reads 必填', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(FlarePluginForm(inputs: [_name])));
    final colors = FlareColors.of(tester.element(find.byType(FlarePluginForm)));
    final label = tester.widget<Text>(find.text('姓名 *')).textSpan! as TextSpan;
    expect(label.style!.color, colors.textPrimary);
    expect(label.style!.fontSize, FlareSizes.fontSizeMd);
    expect((label.children!.single as TextSpan).style!.color, colors.error);
    expect(find.bySemanticsLabel('姓名 必填'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an error borders the input, rides on its semantics and draws '
      'the error line', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(FlarePluginForm(inputs: [_name], onSubmit: (_) {})),
    );
    await tester.tap(_submitKey);
    await tester.pump();
    expect(tester.widget<FlareInput>(find.byType(FlareInput)).error, '必填');
    expect(
      tester.getSemantics(find.byType(TextField)),
      isSemantics(
        hint: '必填',
        validationResult: SemanticsValidationResult.invalid,
      ),
    );
    expect(
      find.descendant(
        of: find.byType(FlareFormField),
        matching: find.byWidgetPredicate(
          (w) =>
              w is FlareIcon &&
              w.name == 'error' &&
              w.size == FlareSizes.iconSizeSm,
        ),
      ),
      findsOneWidget,
    );
    final colors = FlareColors.of(tester.element(find.byType(FlarePluginForm)));
    final text = tester.widget<Text>(find.text('必填'));
    expect(text.style!.color, colors.errorText);
    expect(text.style!.fontSize, FlareTextRoles.caption.fontSize);
    handle.dispose();
  });

  testWidgets('the counter sits under the input at its end once typed', (
    tester,
  ) async {
    await tester.pumpWidget(_host(FlarePluginForm(inputs: [_name])));
    expect(
      tester.widget<FlareFormField>(find.byType(FlareFormField)).counter,
      isNull,
    );
    await tester.enterText(find.byType(EditableText), 'Ann');
    await tester.pump();
    final field = tester.widget<FlareFormField>(find.byType(FlareFormField));
    expect(field.counter, '3/20');
    expect(field.hint, isNull);
    final counter = tester.getRect(find.text('3/20'));
    expect(
      counter.top,
      greaterThan(tester.getRect(find.byType(FlareInput)).bottom),
    );
    expect(counter.right, tester.getRect(find.byType(FlareFormField)).right);
    final colors = FlareColors.of(tester.element(find.byType(FlarePluginForm)));
    expect(
      tester.widget<Text>(find.text('3/20')).style!.color,
      colors.textSecondary,
    );
  });

  testWidgets('help sits under the input as a secondary caption; none '
      'without it', (tester) async {
    const help = '英文、数字或 _ : - .，最多 128 个字符';
    final walletId = _input({
      'id': 'walletId',
      'kind': 'text',
      'label': '钱包标识',
      'help': help,
    });
    await tester.pumpWidget(_host(FlarePluginForm(inputs: [walletId])));
    expect(walletId.help, help);
    final text = tester.widget<Text>(find.text(help));
    final colors = FlareColors.of(tester.element(find.byType(FlarePluginForm)));
    expect(text.style!.color, colors.textSecondary);
    expect(text.style!.fontSize, FlareTextRoles.caption.fontSize);
    expect(
      tester.getRect(find.text(help)).top,
      greaterThan(tester.getRect(find.byType(FlareInput)).bottom),
    );
    await tester.pumpWidget(_host(FlarePluginForm(inputs: [_name])));
    expect(_name.help, isNull);
    expect(
      tester.widget<FlareFormField>(find.byType(FlareFormField)).hint,
      isNull,
    );
  });

  testWidgets('inputs are 48 on a phone and 40 from the PC breakpoint', (
    tester,
  ) async {
    _surface(tester, 390);
    await tester.pumpWidget(_host(FlarePluginForm(inputs: [_name])));
    expect(
      tester.getSize(find.byType(FlareInput)).height,
      FlareSizes.controlHeightLg,
    );
    _surface(tester, FlareSizes.appShellCompactMinWidth);
    await tester.pumpWidget(
      _host(FlarePluginForm(inputs: [_name]), platform: TargetPlatform.macOS),
    );
    // The theme animates to the new platform; read it once it has settled.
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(FlareInput)).height,
      FlareSizes.controlHeightMd,
    );
  });

  testWidgets('Enter in a single-line input runs the submit key\'s path', (
    tester,
  ) async {
    final submitted = <Map<String, Object?>>[];
    await tester.pumpWidget(
      _host(FlarePluginForm(inputs: [_name], onSubmit: submitted.add)),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    // The local check runs first: nothing goes out, the field says why.
    expect(submitted, isEmpty);
    expect(
      tester.widget<FlareFormField>(find.byType(FlareFormField)).error,
      '必填',
    );
    await tester.enterText(find.byType(EditableText), 'Ann');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submitted.single['name'], 'Ann');
  });

  testWidgets('a form-level failure is a danger banner above the submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(FlarePluginForm(inputs: [_name], error: '余额不足')),
    );
    final banner = find.byKey(const ValueKey('flare-plugin-form-error'));
    expect(tester.widget<FlareStatusBanner>(banner).text, '余额不足');
    expect(
      tester.widget<FlareStatusBanner>(banner).tone,
      FlareStatusTone.danger,
    );
    expect(
      tester.getRect(banner).bottom,
      lessThanOrEqualTo(tester.getRect(_submitKey).top),
    );
  });

  testWidgets('a phone page form submits from the pinned bar; a sheet keeps '
      'cancel + submit', (tester) async {
    _surface(tester, 390);
    await tester.pumpWidget(
      _host(
        FlarePluginForm(
          inputs: [_name],
          embedded: true,
          pinSubmit: true,
          submitLabel: '保存',
        ),
      ),
    );
    expect(
      find.ancestor(
        of: _submitKey,
        matching: find.byType(FlarePluginPinnedBar),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('flare-plugin-form-cancel')),
      findsNothing,
    );
    expect(
      tester.getSize(_submitKey),
      const Size(390 - FlareSizes.spacingLg * 2, FlareSizes.controlHeightLg),
    );
    await tester.pumpWidget(_host(FlarePluginForm(inputs: [_name])));
    expect(find.byType(FlarePluginPinnedBar), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('flare-plugin-form-cancel')))
          .width,
      tester.getSize(_submitKey).width,
    );
  });
}
