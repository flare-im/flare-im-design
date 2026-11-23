import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(320, 640),
      disableAnimations: reduceMotion,
    ),
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(FlareSizes.spacingLg),
        child: child,
      ),
    ),
  ),
);

/// A host that owns the value, the way a form wires the input.
class _Harness extends StatefulWidget {
  const _Harness({required this.changes, required this.completed});
  final List<String> changes;
  final List<String> completed;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String value = '';
  bool error = false;
  void fail() => setState(() => error = true);
  @override
  Widget build(BuildContext context) => FlarePinInput(
    value: value,
    label: '支付密码',
    error: error,
    onChange: (v) {
      widget.changes.add(v);
      setState(() => value = v);
    },
    onComplete: widget.completed.add,
  );
}

void main() {
  final input = find.byType(TextField);

  testWidgets('digits only, dots for each, completes once at six', (
    tester,
  ) async {
    final changes = <String>[], completed = <String>[];
    await tester.pumpWidget(
      host(_Harness(changes: changes, completed: completed)),
    );
    final field = tester.widget<TextField>(input);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.obscureText, isTrue);
    expect(field.keyboardType, TextInputType.number);
    await tester.enterText(input, '12a3');
    await tester.pump();
    expect(changes.last, '123');
    expect(find.byKey(FlarePinInput.dotKey(2)), findsOneWidget);
    expect(find.byKey(FlarePinInput.dotKey(3)), findsNothing);
    await tester.enterText(input, '1234567');
    await tester.pump();
    expect(completed, ['123456']);
    expect(find.byKey(FlarePinInput.dotKey(5)), findsOneWidget);
  });

  testWidgets('a host value fills the cells', (tester) async {
    await tester.pumpWidget(
      host(const FlarePinInput(value: '12', label: '支付密码', autoFocus: false)),
    );
    expect(find.byKey(FlarePinInput.dotKey(1)), findsOneWidget);
    expect(find.byKey(FlarePinInput.dotKey(2)), findsNothing);
  });

  testWidgets('one label with the count, cells 44 by 52', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const FlarePinInput(label: '支付密码', autoFocus: false)),
    );
    await tester.enterText(input, '12');
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('支付密码，已输入 2 位')), findsOneWidget);
    final cell = find
        .ancestor(
          of: find.byKey(FlarePinInput.dotKey(0)),
          matching: find.byType(Container),
        )
        .first;
    expect(tester.getSize(cell), const Size(44, 52));
    semantics.dispose();
  });

  testWidgets('§12.22: only the focused current cell has the focus ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const FlarePinInput(label: '支付密码', autoFocus: false)),
    );
    await tester.enterText(input, '12');
    await tester.pump();
    List<BoxShadow?> rings() => [
      for (final box in tester.widgetList<Container>(
        find.descendant(
          of: find.byType(FlarePinInput),
          matching: find.byType(Container),
        ),
      ))
        if (box.decoration case BoxDecoration(:final border?)
            when border is Border)
          (box.decoration as BoxDecoration).boxShadow?.firstOrNull,
    ];
    final focused = rings();
    expect(focused, hasLength(6));
    expect(focused.whereType<BoxShadow>(), hasLength(1));
    expect(focused[2], isNotNull);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(rings().whereType<BoxShadow>(), isEmpty);
  });

  testWidgets('unlocked after a failed check, it takes focus again', (
    tester,
  ) async {
    Widget pin({bool disabled = false, bool error = false}) =>
        host(FlarePinInput(label: '支付密码', disabled: disabled, error: error));
    await tester.pumpWidget(pin());
    await tester.pump();
    await tester.pumpWidget(pin(disabled: true));
    await tester.pump();
    expect(tester.widget<TextField>(input).focusNode!.hasFocus, isFalse);
    await tester.pumpWidget(pin(error: true));
    await tester.pump();
    expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);
  });

  testWidgets('disabled locks the input', (tester) async {
    await tester.pumpWidget(
      host(const FlarePinInput(label: '支付密码', disabled: true)),
    );
    expect(tester.widget<TextField>(input).enabled, isFalse);
  });

  for (final reduce in [false, true]) {
    testWidgets(
      'an error clears the digits${reduce ? ' without shaking' : ' and shakes'}',
      (tester) async {
        final changes = <String>[], completed = <String>[];
        await tester.pumpWidget(
          host(
            _Harness(changes: changes, completed: completed),
            reduceMotion: reduce,
          ),
        );
        await tester.enterText(input, '1234');
        await tester.pumpAndSettle();
        tester.state<_HarnessState>(find.byType(_Harness)).fail();
        await tester.pump();
        expect(find.byKey(FlarePinInput.dotKey(0)), findsNothing);
        expect(changes.last, '');
        expect(tester.hasRunningAnimations, !reduce);
        await tester.pumpAndSettle();
      },
    );
  }
}
