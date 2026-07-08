import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double w = 400, double h = 700}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: w, height: h, child: child)),
    );

void main() {
  testWidgets('FlareSearchBar shows placeholder + clears', (tester) async {
    await tester.pumpWidget(_host(const FlareSearchBar(placeholder: '搜一搜')));
    expect(find.text('搜一搜'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.pump();
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });

  testWidgets('FlareInput enforces maxLength + counter', (tester) async {
    await tester.pumpWidget(_host(const FlareInput(maxLength: 5)));
    await tester.enterText(find.byType(TextField), 'abcdefgh');
    await tester.pump();
    expect(find.text('5/5'), findsOneWidget);
  });

  testWidgets('FlareEmptyState renders title/desc/action', (tester) async {
    var acted = false;
    await tester.pumpWidget(_host(FlareEmptyState(
        title: '空空如也', description: '来点内容', actionText: '去添加', onAction: () => acted = true)));
    expect(find.text('空空如也'), findsOneWidget);
    await tester.tap(find.text('去添加'));
    expect(acted, isTrue);
  });

  testWidgets('FlareContactList groups A-Z and shows index', (tester) async {
    await tester.pumpWidget(_host(FlareContactList(items: const [
      FlareContact(id: 'u1', name: 'Henry'),
      FlareContact(id: 'u2', name: 'Ivy'),
    ])));
    expect(find.text('H'), findsWidgets);
    expect(find.text('Henry'), findsOneWidget);
    expect(find.text('Ivy'), findsOneWidget);
  });

  testWidgets('FlareNewFriendRequests accepts', (tester) async {
    FlareFriendRequest? accepted;
    await tester.pumpWidget(_host(FlareNewFriendRequests(
      items: const [FlareFriendRequest(id: 'r1', name: 'Bob', message: 'hi')],
      onAccept: (r) => accepted = r,
    )));
    await tester.tap(find.text('Accept'));
    expect(accepted?.id, 'r1');
  });

  testWidgets('FlareGroupList renders member count', (tester) async {
    await tester.pumpWidget(_host(const FlareGroupList(
        items: [FlareGroupSummary(id: 'g1', name: 'Team', memberCount: 4)])));
    expect(find.text('Team'), findsOneWidget);
    expect(find.text('4 members'), findsOneWidget);
  });

  testWidgets('FlareProfilePanel + ProfileEditor + SettingsList construct', (tester) async {
    const user = FlareUserProfile(id: 'me', name: '我', flareId: 'flare_me');
    await tester.pumpWidget(_host(const FlareProfilePanel(user: user)));
    expect(find.text('Flare ID: flare_me'), findsOneWidget);
    await tester.pumpWidget(_host(const FlareProfileEditor(user: user)));
    await tester.pumpWidget(_host(const FlareSettingsList(sections: [
      FlareSettingsSection(title: '通用', items: [
        FlareSettingsItem(key: 'mute', label: '免打扰', kind: FlareSettingKind.toggle, value: true),
      ]),
    ])));
    expect(find.text('免打扰'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('Call components render + hangup', (tester) async {
    var hung = false;
    await tester.pumpWidget(_host(FlareCallControls(mode: FlareCallMode.video, onHangup: () => hung = true)));
    await tester.tap(find.byIcon(Icons.call_end));
    expect(hung, isTrue);

    await tester.pumpWidget(_host(const FlareCallView(
        peerName: 'Henry', mode: FlareCallMode.video, state: FlareCallState.connected, durationLabel: '02:14')));
    expect(find.text('Henry'), findsOneWidget);
    expect(find.text('02:14'), findsOneWidget);

    await tester.pumpWidget(_host(const FlareIncomingCall(callerName: 'Ivy', mode: FlareCallMode.audio)));
    expect(find.text('is inviting you to a voice call'), findsOneWidget);
  });

  testWidgets('FlareResponsiveLayout: wide shows two panes, narrow single', (tester) async {
    await tester.pumpWidget(_host(
      const FlareResponsiveLayout(list: Text('L'), chat: Text('C')),
      w: 800,
    ));
    expect(find.text('L'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);

    await tester.pumpWidget(_host(
      const FlareResponsiveLayout(list: Text('L'), chat: Text('C'), activePane: FlarePane.list),
      w: 400,
    ));
    expect(find.text('L'), findsOneWidget);
    expect(find.text('C'), findsNothing);
  });

  testWidgets('FlareAppShell adapts (bottom bar when narrow)', (tester) async {
    await tester.pumpWidget(_host(
      FlareAppShell(
        items: const [
          FlareNavItem(key: 'chat', label: '消息', icon: Icons.chat, badge: 3),
          FlareNavItem(key: 'me', label: '我', icon: Icons.person),
        ],
        activeKey: 'chat',
        child: const Center(child: Text('内容')),
      ),
      w: 400,
    ));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('内容'), findsOneWidget);
  });
}
