import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('checkbox exposes checked / mixed state and a label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(FlareCheckbox(value: true, label: '免打扰', onChanged: (_) {})),
    );
    expect(
      tester.getSemantics(find.byType(FlareCheckbox)),
      matchesSemantics(
        label: '免打扰',
        hasCheckedState: true,
        isChecked: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
      ),
    );
    await tester.pumpWidget(
      _host(FlareCheckbox(value: false, indeterminate: true, label: '部分')),
    );
    expect(
      tester.getSemantics(find.byType(FlareCheckbox)),
      matchesSemantics(
        label: '部分',
        hasCheckedState: true,
        isCheckStateMixed: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('radio rows are a mutually exclusive group with checked state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    String? picked;
    await tester.pumpWidget(
      _host(
        FlareRadioGroup(
          options: const [
            FlareSelectOption(value: 'a', label: '甲'),
            FlareSelectOption(value: 'b', label: '乙'),
          ],
          value: 'a',
          onSelect: (v) => picked = v,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('甲')),
      matchesSemantics(
        label: '甲',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.text('乙'));
    expect(picked, 'b');
    handle.dispose();
  });

  testWidgets('incoming call accept / reject are labelled buttons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final strings = FlareStrings();
    var accepted = 0;
    await tester.pumpWidget(
      _host(
        FlareIncomingCall(
          callerName: 'Ivy',
          mode: FlareCallMode.video,
          onAccept: () => accepted++,
          onReject: () {},
        ),
      ),
    );
    expect(find.text('Answer'), findsNothing);
    expect(find.text(strings.incomingVideoCall), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(strings.accept)),
      matchesSemantics(
        label: strings.accept,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    await tester.tap(find.bySemanticsLabel(strings.accept));
    expect(accepted, 1);
    handle.dispose();
  });

  testWidgets('call controls render an add-member key only when supplied', (
    tester,
  ) async {
    final strings = FlareStrings();
    var invited = 0;
    await tester.pumpWidget(_host(const FlareCallControls()));
    expect(find.byTooltip(strings.addMember), findsNothing);
    await tester.pumpWidget(
      _host(FlareCallControls(onAddMember: () => invited++)),
    );
    await tester.tap(find.byTooltip(strings.addMember));
    expect(invited, 1);
    await tester.pumpWidget(
      _host(
        FlareGroupCallView(
          participants: const [],
          mode: FlareCallMode.video,
          state: 'connected',
          onAddMember: () => invited++,
        ),
      ),
    );
    expect(find.byTooltip(strings.addMember), findsOneWidget);
  });
}
