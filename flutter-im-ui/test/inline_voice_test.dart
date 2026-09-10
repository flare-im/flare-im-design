import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:record_platform_interface/record_platform_interface.dart';

class FakeCapture extends RecordPlatform {
  final data = StreamController<Uint8List>.broadcast();
  int starts = 0, pauses = 0, resumes = 0, stops = 0, disposes = 0;
  Completer<bool>? permission;
  @override
  Future<void> create(String id) async {}
  @override
  Future<bool> hasPermission(String id, {bool request = true}) async =>
      permission == null ? true : permission!.future;
  @override
  Future<Stream<Uint8List>> startStream(String id, RecordConfig config) async {
    starts++;
    return data.stream;
  }

  @override
  Stream<RecordState> onStateChanged(String id) => const Stream.empty();
  @override
  Future<void> pause(String id) async {
    pauses++;
  }

  @override
  Future<void> resume(String id) async {
    resumes++;
  }

  @override
  Future<String?> stop(String id) async {
    stops++;
    return null;
  }

  @override
  Future<void> dispose(String id) async {
    disposes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeCapture capture;
  late Directory temp;
  setUp(() async {
    capture = FakeCapture();
    RecordPlatform.instance = capture;
    temp = await Directory.systemTemp.createTemp('flare-voice-test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temp.path,
        );
  });
  tearDown(() async {
    await capture.data.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });
  Future<void> settleIO(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
  }

  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await settleIO(tester);
    }
    expect(
      done(),
      isTrue,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .join(' | '),
    );
  }

  testWidgets(
    'pause/resume preserves PCM and failed send keeps a retryable WAV',
    (tester) async {
      var attempts = 0, keyboard = 0;
      String? path;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: FlareInlineVoice(
                onKeyboard: () {
                  keyboard++;
                },
                onSend: (p, duration) async {
                  path = p;
                  expect(duration, 2000);
                  attempts++;
                  return attempts > 1;
                },
              ),
            ),
          ),
        ),
      );
      expect(capture.starts, 0);
      await tester.tap(find.byTooltip('Start recording'));
      await tester.pump();
      await settleIO(tester);
      capture.data.add(Uint8List(32000));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byTooltip('Pause recording'));
      await waitFor(
        tester,
        () => find.byTooltip('Resume recording').evaluate().isNotEmpty,
      );
      expect(capture.pauses, 1);
      expect(
        find.byTooltip("Resume recording"),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(" | "),
      );
      await tester.tap(find.byTooltip('Resume recording'));
      await tester.pump();
      await settleIO(tester);
      capture.data.add(Uint8List(32000));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byTooltip('Pause recording'));
      await waitFor(
        tester,
        () => find.byTooltip('Resume recording').evaluate().isNotEmpty,
      );
      await tester.tap(find.byTooltip('Send'));
      await settleIO(tester);
      expect(attempts, 1);
      expect(keyboard, 0);
      final bytes = await tester.runAsync(() => File(path!).readAsBytes());
      expect(bytes!.length, 64044);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(ByteData.sublistView(bytes).getUint32(40, Endian.little), 64000);
      await tester.tap(find.byTooltip('Send'));
      await settleIO(tester);
      await waitFor(tester, () => keyboard == 1);
      expect(attempts, 2);
      expect(keyboard, 1);
      await tester.pumpWidget(const SizedBox());
      await waitFor(tester, () => capture.disposes == 1);
    },
  );
  testWidgets(
    'keyboard cancels a pending microphone request without starting capture',
    (tester) async {
      capture.permission = Completer<bool>();
      var keyboard = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareInlineVoice(
              onKeyboard: () {
                keyboard++;
              },
              onSend: (_, _) async => true,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Start recording'));
      await tester.pump();
      await tester.tap(find.byTooltip('Keyboard: discard recording'));
      await tester.pump();
      capture.permission!.complete(true);
      await tester.pump(const Duration(seconds: 1));
      await settleIO(tester);
      await waitFor(tester, () => keyboard == 1);
      expect(capture.starts, 0);
      expect(keyboard, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await waitFor(tester, () => capture.disposes == 1);
    },
  );
}
