import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The shell contract (FR-095): the shell measures its own box, keeps every
// destination it has shown, and steps its phone navigation aside while the
// active destination shows a page beyond its root.

const _configuration = FlareIMAppConfiguration(
  features: FlareFeatureSet({'conversations', 'contacts'}),
  navigation: [
    FlareNavigationGroup(
      id: 'main',
      items: [
        FlareNavigationItem(id: 'chats', label: 'Chats', icon: 'chats'),
        FlareNavigationItem(id: 'contacts', label: 'Contacts', icon: 'people'),
      ],
    ),
  ],
);

/// A destination whose only state is its own: a counter the person bumps.
class _Counter extends StatefulWidget {
  const _Counter(this.name, this.mounts);
  final String name;
  final List<String> mounts;
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;
  @override
  void initState() {
    super.initState();
    widget.mounts.add(widget.name);
  }

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => setState(() => _count += 1),
      child: Text('${widget.name} $_count'),
    ),
  );
}

void _size(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _shell({
  required String active,
  required Widget Function(BuildContext, String) destination,
  FlareIMAppConfiguration configuration = _configuration,
  ValueChanged<String>? onNavigate,
}) => MaterialApp(
  home: FlareIMAppKit(
    configuration: configuration,
    activeNavigationId: active,
    onNavigate: onNavigate,
    destinationBuilder: destination,
    label: 'Reference IM',
  ),
);

FlareAdaptiveNavigation _navigation(WidgetTester tester) => tester
    .widget<FlareAdaptiveNavigation>(find.byType(FlareAdaptiveNavigation));

void main() {
  testWidgets('resolves the mode from its own box', (tester) async {
    _size(tester, 1600);
    await tester.pumpWidget(
      _shell(active: 'chats', destination: (_, id) => Text(id)),
    );
    expect(
      _navigation(tester).responsiveMode,
      FlareApplicationResponsiveMode.wideDesktop,
    );

    _size(tester, 390);
    await tester.pumpWidget(
      _shell(active: 'chats', destination: (_, id) => Text(id)),
    );
    await tester.pump();
    expect(
      _navigation(tester).responsiveMode,
      FlareApplicationResponsiveMode.mobile,
    );
  });

  testWidgets(
    'keeps a destination it has shown, with its state, across a switch and a change of mode',
    (tester) async {
      _size(tester, 1200);
      final mounts = <String>[];
      Widget shell(String active) =>
          _shell(active: active, destination: (_, id) => _Counter(id, mounts));
      await tester.pumpWidget(shell('chats'));
      await tester.tap(find.text('chats 0'));
      await tester.pump();
      await tester.tap(find.text('chats 1'));
      await tester.pump();
      expect(find.text('chats 2'), findsOneWidget);

      await tester.pumpWidget(shell('contacts'));
      await tester.pump();
      expect(find.text('contacts 0'), findsOneWidget);
      expect(find.text('chats 2'), findsNothing, reason: 'off stage');
      expect(
        find.text('chats 2', skipOffstage: false),
        findsOneWidget,
        reason: 'but still built',
      );

      // A phone-width window moves the destinations under the bottom bar.
      _size(tester, 390);
      await tester.pumpWidget(shell('chats'));
      await tester.pump();
      expect(find.text('chats 2'), findsOneWidget);
      expect(mounts, ['chats', 'contacts']);
    },
  );

  testWidgets('drops a destination whose navigation item is gone', (
    tester,
  ) async {
    _size(tester, 1200);
    final mounts = <String>[];
    await tester.pumpWidget(
      _shell(active: 'chats', destination: (_, id) => _Counter(id, mounts)),
    );
    await tester.pumpWidget(
      _shell(active: 'contacts', destination: (_, id) => _Counter(id, mounts)),
    );
    await tester.pumpWidget(
      _shell(
        active: 'contacts',
        configuration: const FlareIMAppConfiguration(
          features: FlareFeatureSet({'contacts'}),
          navigation: [
            FlareNavigationGroup(
              id: 'main',
              items: [
                FlareNavigationItem(
                  id: 'contacts',
                  label: 'Contacts',
                  icon: 'people',
                ),
              ],
            ),
          ],
        ),
        destination: (_, id) => _Counter(id, mounts),
      ),
    );
    expect(find.text('chats 0', skipOffstage: false), findsNothing);
    expect(find.text('contacts 0'), findsOneWidget);
  });

  testWidgets(
    'hides the phone navigation while the active destination shows a page with a way back',
    (tester) async {
      _size(tester, 390);
      Widget shell(bool page) => _shell(
        active: 'contacts',
        destination: (_, id) => id == 'contacts' && page
            ? FlareScreen(
                title: 'Ivy Chen',
                onBack: () {},
                child: const SizedBox(),
              )
            : FlareScreen(title: id, child: const SizedBox()),
      );
      await tester.pumpWidget(shell(false));
      await tester.pump();
      expect(find.byType(FlareAdaptiveNavigation), findsOneWidget);

      await tester.pumpWidget(shell(true));
      await tester.pump();
      await tester.pump();
      expect(find.byType(FlareAdaptiveNavigation), findsNothing);

      await tester.pumpWidget(shell(false));
      await tester.pump();
      await tester.pump();
      expect(find.byType(FlareAdaptiveNavigation), findsOneWidget);
    },
  );

  testWidgets('keeps the rail beside a page with a way back on wide layouts', (
    tester,
  ) async {
    _size(tester, 1200);
    await tester.pumpWidget(
      _shell(
        active: 'contacts',
        destination: (_, id) =>
            FlareScreen(title: id, onBack: () {}, child: const SizedBox()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(FlareAdaptiveNavigation), findsOneWidget);
  });

  testWidgets(
    'hands its mode down: a frame inside a phone shell shows one pane, and a chat in the list place is a page',
    (tester) async {
      _size(tester, 390);
      Widget shell(FlareWorkspacePane pane) => _shell(
        active: 'chats',
        destination: (_, id) => FlareAppLayout(
          activePane: pane,
          primary: const Text('Conversation list'),
          content: const Text('Message timeline'),
        ),
      );
      await tester.pumpWidget(shell(FlareWorkspacePane.primary));
      await tester.pump();
      expect(find.text('Conversation list'), findsOneWidget);
      expect(find.text('Message timeline'), findsNothing);
      expect(find.byType(FlareAdaptiveNavigation), findsOneWidget);

      await tester.pumpWidget(shell(FlareWorkspacePane.content));
      await tester.pump();
      await tester.pump();
      expect(find.text('Message timeline'), findsOneWidget);
      expect(find.byType(FlareAdaptiveNavigation), findsNothing);
    },
  );

  testWidgets(
    'a frame takes the mode of the shell it is in, not the mode of its own box',
    (tester) async {
      _size(tester, 1200);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              // 500 wide on its own would be a phone, which draws no navigation.
              child: SizedBox(
                width: 500,
                child: FlareDesktopAppShell(
                  navigation: _configuration.navigation,
                  activeNavigationId: 'chats',
                  content: const Text('Message timeline'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FlareAdaptiveNavigation), findsOneWidget);
      expect(find.text('Message timeline'), findsOneWidget);
    },
  );
}
