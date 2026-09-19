import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

/// The shell collapses on narrow windows; give it a real desktop viewport.
Future<void> pumpDesktop(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(host(child));
}

bool _isShellScope(Widget widget) =>
    widget is Shortcuts &&
    widget.shortcuts.containsKey(
      const SingleActivator(LogicalKeyboardKey.slash, alt: true),
    );

const navigation = [
  FlareNavigationGroup(
    id: 'main',
    items: [
      FlareNavigationItem(id: 'chats', label: 'Chats', icon: 'chats'),
      FlareNavigationItem(id: 'contacts', label: 'Contacts', icon: 'people'),
    ],
  ),
];

FlareDesktopAppShell shell({
  ValueChanged<FlareDesktopShellCommand>? onCommand,
  ValueChanged<String>? onNavigate,
}) => FlareDesktopAppShell(
  navigation: navigation,
  activeNavigationId: 'chats',
  primary: const Text('primary'),
  content: const Text('content'),
  detail: const Text('detail'),
  hasDetail: true,
  responsiveMode: FlareApplicationResponsiveMode.wideDesktop,
  onCommand: onCommand,
  onNavigate: onNavigate,
);

Future<void> press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  List<LogicalKeyboardKey> modifiers = const [],
}) async {
  for (final modifier in modifiers) {
    await tester.sendKeyDownEvent(modifier);
  }
  await tester.sendKeyEvent(key);
  for (final modifier in modifiers.reversed) {
    await tester.sendKeyUpEvent(modifier);
  }
}

void main() {
  testWidgets('composes navigation with the pane regions', (tester) async {
    await pumpDesktop(tester, shell());
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('primary'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
    expect(find.text('detail'), findsOneWidget);
  });

  testWidgets('forwards navigation taps to the host', (tester) async {
    String? navigated;
    await tester.pumpWidget(host(shell(onNavigate: (id) => navigated = id)));
    await tester.tap(find.text('Contacts'));
    expect(navigated, 'contacts');
  });

  testWidgets('emits one command per desktop shortcut', (tester) async {
    final commands = <FlareDesktopShellCommand>[];
    await tester.pumpWidget(host(shell(onCommand: commands.add)));
    await tester.pump();
    expect(find.byWidgetPredicate(_isShellScope), findsOneWidget);
    const control = [LogicalKeyboardKey.controlLeft];
    await press(tester, LogicalKeyboardKey.keyK, modifiers: control);
    await press(tester, LogicalKeyboardKey.keyF, modifiers: control);
    await press(tester, LogicalKeyboardKey.keyN, modifiers: control);
    await press(
      tester,
      LogicalKeyboardKey.keyD,
      modifiers: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftLeft],
    );
    await press(tester, LogicalKeyboardKey.comma, modifiers: control);
    await press(
      tester,
      LogicalKeyboardKey.slash,
      modifiers: [LogicalKeyboardKey.altLeft],
    );
    await press(tester, LogicalKeyboardKey.escape);
    await press(tester, LogicalKeyboardKey.keyK);
    expect(commands, const [
      FlareDesktopShellCommand.openCommandPalette,
      FlareDesktopShellCommand.openSearch,
      FlareDesktopShellCommand.newConversation,
      FlareDesktopShellCommand.toggleDetails,
      FlareDesktopShellCommand.openSettings,
      FlareDesktopShellCommand.moreActions,
      FlareDesktopShellCommand.closeOverlay,
    ]);
  });

  testWidgets('installs no keyboard scope when the host takes no commands', (
    tester,
  ) async {
    await tester.pumpWidget(host(shell()));
    expect(find.byWidgetPredicate(_isShellScope), findsNothing);
  });
}
