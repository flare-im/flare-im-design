import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  test('rows say the permission and the battery setting in their words', () {
    expect(FlareNotificationStatus.values.map(notificationStatusLabel), [
      '已开启',
      '已关闭',
      '未开启',
    ]);
    expect(FlareBackgroundDelivery.values.map(backgroundDeliveryLabel), [
      '不受限制',
      '已优化',
      '受限制',
    ]);
  });

  testWidgets('the status row hands the press to the host', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareNotificationDeliverySettings(
            status: FlareNotificationStatus.notTurnedOn,
            footer: '只影响这台设备',
            onStatusAction: () => pressed++,
          ),
        ),
      ),
    );
    expect(find.text('新消息通知'), findsOneWidget);
    expect(find.text('未开启'), findsOneWidget);
    expect(find.text('只影响这台设备'), findsOneWidget);
    expect(find.text('后台接收消息'), findsNothing);
    await tester.tap(find.text('新消息通知'));
    expect(pressed, 1);
  });

  testWidgets('the background row opens the guide with the battery settings', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareNotificationDeliverySettings(
            status: FlareNotificationStatus.on,
            background: FlareBackgroundDelivery.restricted,
            vendorActions: [
              FlareNotificationGuideAction(
                label: '自启动',
                onSelect: () => log.add('autoStart'),
              ),
            ],
            onOpenBatterySettings: () => log.add('battery'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('后台接收消息'));
    await tester.pumpAndSettle();
    expect(find.textContaining('新消息到达时'), findsOneWidget);
    expect(find.textContaining('自启动'), findsWidgets);
    await tester.tap(find.text('电池使用'));
    await tester.tap(find.text('自启动').last);
    expect(log, ['battery', 'autoStart']);
  });

  testWidgets('the section form joins the host list and runs its own rows', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareNotificationDeliverySettings(
            status: FlareNotificationStatus.off,
            background: FlareBackgroundDelivery.restricted,
            vendorActions: [
              FlareNotificationGuideAction(onSelect: () => log.add('autoStart')),
            ],
            onStatusAction: () => log.add('status'),
            onOpenBatterySettings: () => log.add('battery'),
            sectionBuilder: (context, notifications, select) =>
                FlareSettingsList(
                  sections: [
                    const FlareSettingsSection(
                      items: [FlareSettingsItem(key: 'language', label: '语言')],
                    ),
                    notifications,
                  ],
                  onSelect: (item) {
                    if (!select(item)) log.add(item.key);
                  },
                ),
          ),
        ),
      ),
    );
    // One list: the host's row and the group's rows are drawn together.
    expect(find.byType(FlareSettingsList), findsOneWidget);
    await tester.tap(find.text('语言'));
    await tester.tap(find.text('新消息通知'));
    expect(log, ['language', 'status']);

    await tester.tap(find.text('后台接收消息'));
    await tester.pumpAndSettle();
    // A maker's page the host did not name reads the kit's label.
    await tester.tap(find.text('自启动管理'));
    await tester.tap(find.text('电池使用'));
    expect(log, ['language', 'status', 'autoStart', 'battery']);
  });
}
