import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _viewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _screen({
  Widget? form,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  VoidCallback? onBack,
}) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: FlareAuthShell(
      product: 'Flare IM',
      tagline: 'Every conversation, connected',
      headline: 'Keep people close.\nKeep conversations going.',
      description: 'Messages, files and groups in one familiar workspace.',
      title: 'Welcome back',
      subtitle: 'Sign in to continue your conversation.',
      eyebrow: 'YOUR ACCOUNT',
      footer: 'Flare IM account entrance',
      backLabel: onBack != null ? 'Back to sign in' : null,
      onBack: onBack,
      child: form ?? const Text('Account fields'),
    ),
  ),
);

void main() {
  testWidgets('mobile keeps the brand and account task near the safe top', (
    tester,
  ) async {
    await _viewport(tester, const Size(390, 844));
    await tester.pumpWidget(_screen());
    expect(tester.takeException(), isNull);
    expect(find.text('Flare IM'), findsOneWidget);
    expect(
      find.text('Keep people close.\nKeep conversations going.'),
      findsNothing,
    );
    expect(tester.getTopLeft(find.text('Flare IM')).dy, lessThan(100));
    expect(tester.getTopLeft(find.text('Welcome back')).dy, lessThan(200));
    expect(find.text('Flare IM account entrance'), findsOneWidget);
  });

  testWidgets('desktop has a separate brand story and a bounded form', (
    tester,
  ) async {
    await _viewport(tester, const Size(1440, 900));
    await tester.pumpWidget(_screen());
    expect(tester.takeException(), isNull);
    final story = tester.getRect(
      find.text('Keep people close.\nKeep conversations going.'),
    );
    final form = tester.getRect(find.text('Account fields'));
    expect(story.right, lessThan(form.left));
    expect(form.width, lessThanOrEqualTo(420));
    expect(form.top, greaterThan(200));
    expect(find.text('YOUR ACCOUNT'), findsOneWidget);
  });

  testWidgets(
    'the keyboard leaves submit reachable and keeps the typed account',
    (tester) async {
      await _viewport(tester, const Size(320, 600));
      final account = TextEditingController();
      addTearDown(account.dispose);
      var submissions = 0;
      await tester.pumpWidget(
        _screen(
          form: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FlareFormField(
                label: 'Account',
                child: FlareInput(controller: account, placeholder: 'Account'),
              ),
              const SizedBox(height: 24),
              const FlareFormField(
                label: 'Password',
                child: FlareInput(placeholder: 'Password', secure: true),
              ),
              const SizedBox(height: 24),
              FlareButton(
                onPressed: () => submissions++,
                label: 'Sign in',
                block: true,
              ),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'alice');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(FlareButton, 'Sign in'));
      await tester.tap(find.widgetWithText(FlareButton, 'Sign in'));
      await tester.pump();
      expect(submissions, 1);
      expect(account.text, 'alice');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large text and dark theme wrap without clipping at the split breakpoint',
    (tester) async {
      await _viewport(tester, const Size(900, 420));
      await tester.pumpWidget(
        _screen(brightness: Brightness.dark, textScale: 1.6),
      );
      await tester.ensureVisible(find.text('Flare IM account entrance'));
      expect(tester.takeException(), isNull);
      final subtitle = tester.widget<Text>(
        find.text('Sign in to continue your conversation.'),
      );
      expect(subtitle.style?.color, FlareColors.dark.textSecondary);
    },
  );

  testWidgets(
    'the labelled back action does not replace the form or its value',
    (tester) async {
      await _viewport(tester, const Size(390, 844));
      final account = TextEditingController(text: 'alice');
      addTearDown(account.dispose);
      var backs = 0;
      await tester.pumpWidget(
        _screen(
          onBack: () => backs++,
          form: FlareInput(controller: account),
        ),
      );
      await tester.tap(find.text('Back to sign in'));
      expect(backs, 1);
      expect(account.text, 'alice');
    },
  );

  testWidgets(
    'standalone brand mark identifies Flare IM for assistive technology',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(const MaterialApp(home: FlareBrandLogo()));
      expect(find.bySemanticsLabel('Flare IM'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
