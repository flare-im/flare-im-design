import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Round 5 Batch 1 leftovers: the voice player's transcript toggle and the
// composer's expand key read their copy from FlareStrings (Chinese by
// default, overridable at the root), not from English or locale-switched
// literals.

const _strings = FlareStrings();

Widget _host(Widget child, {FlareStrings strings = _strings}) =>
    FlareStringsScope(
      strings: strings,
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('transcript toggle: kit copy, host override, a named target', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var toggles = 0;
    Widget player({required bool open}) => SizedBox(
      width: 300,
      child: FlareVoicePlayer(
        durationLabel: '0:07',
        transcript: 'hello',
        transcriptOpen: open,
        onToggle: () {},
        onToggleTranscript: () => toggles++,
      ),
    );

    await tester.pumpWidget(_host(player(open: false)));
    expect(find.text(_strings.showTranscript), findsOneWidget);
    expect(find.text('To text'), findsNothing);
    final node = tester.getSemantics(find.text(_strings.showTranscript));
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    expect(node.rect.height, greaterThanOrEqualTo(FlareSizes.touchTarget));
    await tester.tap(find.text(_strings.showTranscript));
    expect(toggles, 1);

    await tester.pumpWidget(_host(player(open: true)));
    expect(find.text(_strings.hideTranscript), findsOneWidget);
    expect(find.text('Hide text'), findsNothing);

    await tester.pumpWidget(
      _host(
        player(open: true),
        strings: _strings.copyWith(hideTranscript: 'Hide text'),
      ),
    );
    expect(find.text('Hide text'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('composer expand key: kit copy and host override', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    var expanded = 0;
    Widget field() => SizedBox(
      width: 320,
      child: ComposerInlineTextField(
        controller: controller,
        focusNode: focus,
        hintText: '',
        onExpandPressed: () => expanded++,
      ),
    );

    await tester.pumpWidget(_host(field()));
    expect(find.byTooltip(_strings.composerExpandInput), findsOneWidget);
    await tester.tap(find.byTooltip(_strings.composerExpandInput));
    expect(expanded, 1);

    await tester.pumpWidget(
      _host(
        field(),
        strings: _strings.copyWith(composerExpandInput: 'Expand input'),
      ),
    );
    expect(find.byTooltip('Expand input'), findsOneWidget);
  });

  testWidgets('profile editor, device picker and emoji tab: kit copy, host '
      'override (B5.3)', (tester) async {
    await tester.pumpWidget(
      _host(
        const FlareProfileEditor(
          user: FlareUserProfile(id: 'me', name: 'Ann'),
        ),
      ),
    );
    // Defaults are the strings table's Chinese, not English literals.
    // The label and the field placeholder use the same word.
    expect(find.text(_strings.profileEditorNickname), findsWidgets);
    expect(find.text(_strings.profileEditorBio), findsOneWidget);
    expect(find.text(_strings.profileEditorSave), findsOneWidget);
    expect(find.text('Nickname'), findsNothing);
    expect(find.text('Save'), findsNothing);

    await tester.pumpWidget(
      _host(
        const FlareProfileEditor(
          user: FlareUserProfile(id: 'me', name: 'Ann'),
        ),
        strings: _strings.copyWith(profileEditorSave: 'Save'),
      ),
    );
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('the call device picker names its empty selection from the '
      'strings table (B5.3)', (tester) async {
    Widget picker() => const SizedBox(
      width: 320,
      child: FlareCallDevicePicker(
        groups: [
          FlareCallDeviceGroup(
            kind: FlareCallDeviceKind.microphone,
            label: '麦克风',
            devices: [FlareCallDevice(id: 'm1', label: 'MacBook')],
          ),
        ],
        permission: FlareCapabilityState.available,
        permissionText: '',
      ),
    );
    await tester.pumpWidget(_host(picker()));
    expect(find.text(_strings.callDevicePickerPlaceholder), findsOneWidget);
    expect(find.text('Choose device'), findsNothing);

    await tester.pumpWidget(
      _host(
        picker(),
        strings: _strings.copyWith(callDevicePickerPlaceholder: 'Choose'),
      ),
    );
    expect(find.text('Choose'), findsOneWidget);
  });
}
