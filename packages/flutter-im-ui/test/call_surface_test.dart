import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'voice keeps chat behind a bounded themed modal in either theme',
    (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: Stack(
                children: [
                  const Text('chat'),
                  FlareCallSurface(
                    mode: FlareCallMode.audio,
                    child: FlareCallView(
                      peerName: 'Peer',
                      mode: FlareCallMode.audio,
                      state: FlareCallState.connected,
                      onHangup: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('chat'), findsOneWidget);
        final modal = tester.getRect(find.byType(FlareCallView));
        expect(modal.width, lessThan(tester.view.physicalSize.width));
        expect(modal.height, lessThan(tester.view.physicalSize.height));
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('three conference members fit above the controls on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1360, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareCallSurface(
            mode: FlareCallMode.video,
            expanded: true,
            child: FlareGroupCallView(
              mode: FlareCallMode.video,
              state: FlareCallState.connected,
              participants: [
                for (final name in ['Alice', 'Bob', 'Carol'])
                  FlareCallParticipant(id: name, name: name),
              ],
              onHangup: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final stage = tester.getRect(find.byType(FlareGroupCallView));
    final controls = tester.getRect(find.byType(FlareCallControls));
    for (final name in ['Alice', 'Bob', 'Carol']) {
      final tileLabel = tester.getRect(find.text(name));
      expect(tileLabel.bottom, lessThan(controls.top));
      expect(stage.contains(tileLabel.center), isTrue);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('video expands within the window without remounting the stage', (
    tester,
  ) async {
    var mounts = 0;
    Widget host(bool expanded) => MaterialApp(
      home: Scaffold(
        body: FlareCallSurface(
          mode: FlareCallMode.video,
          expanded: expanded,
          child: _Stage(onMount: () => mounts++),
        ),
      ),
    );
    await tester.pumpWidget(host(false));
    final compact = tester.getSize(find.byType(_Stage));
    await tester.pumpWidget(host(true));
    final expanded = tester.getSize(find.byType(_Stage));
    expect(expanded.width, greaterThan(compact.width));
    expect(
      mounts,
      1,
      reason: 'growing a conference must not restart its media',
    );
    expect(tester.takeException(), isNull);
  });
}

class _Stage extends StatefulWidget {
  const _Stage({required this.onMount});
  final VoidCallback onMount;
  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
