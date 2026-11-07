import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared update table (`spec/update-prompt-vectors.json`): what the host
/// read in, what the prompt, the bar and the version panel show out. The Vue,
/// SwiftUI and Compose kits run the same file.
void main() {
  final table =
      jsonDecode(
            File('../../spec/update-prompt-vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  List<Map<String, dynamic>> rows(String key) =>
      (table[key] as List).cast<Map<String, dynamic>>();

  FlareUpdateProgress? progressOf(Map<String, dynamic>? raw) => raw == null
      ? null
      : FlareUpdateProgress(
          received: raw['received'] as int,
          total: raw['total'] as int?,
        );

  group('rules', () {
    for (final vector in rows('cases')) {
      test(vector['name'] as String, () {
        final input = vector['input'] as Map<String, dynamic>;
        final model = flareUpdatePrompt(
          form: FlareUpdatePromptForm.values.byName(input['form'] as String),
          mandatory: input['mandatory'] as bool? ?? false,
          state: input['state'] as String?,
          progress: progressOf(input['progress'] as Map<String, dynamic>?),
          errorCode: input['errorCode'] as String?,
          retryable: input['retryable'] as bool? ?? true,
          sizeBytes: input['sizeBytes'] as int?,
          canContinueReadOnly: input['canContinueReadOnly'] as bool? ?? false,
          reason: input['reason'] as String?,
        );
        final want = vector['expect'] as Map<String, dynamic>;
        expect(model.phase.name, want['phase']);
        expect(model.forced, want['forced']);
        expect(model.dismissible, want['dismissible']);
        expect(model.live.name, want['live']);
        expect(model.title.name, want['title']);
        expect(model.message?.name, want['message']);
        expect([for (final a in model.actions) a.name], want['actions']);
        expect(model.notes, want['notes']);
        final bar = want['progress'] as Map<String, dynamic>?;
        if (bar == null) {
          expect(model.progress, isNull);
        } else {
          expect(model.progress?.value, bar['value']);
          expect(model.progress?.percent, bar['percent']);
        }
      });
    }

    for (final vector in rows('failures')) {
      test('reads ${vector['errorCode']} as ${vector['message']}', () {
        expect(
          flareUpdateFailure(vector['errorCode'] as String?).name,
          vector['message'],
        );
      });
    }

    for (final vector in rows('versions')) {
      test('version line for "${vector['version']}"', () {
        expect(
          flareUpdateVersionShown(vector['version'] as String?),
          vector['shown'],
        );
      });
    }

    for (final vector in rows('progressBar')) {
      test('bar reads ${vector['value']}', () {
        final shown = flareProgressBarValue(
          (vector['value'] as num?)?.toDouble(),
          indeterminate: vector['indeterminate'] as bool,
        );
        expect(shown.value, (vector['shown'] as num?)?.toDouble());
        expect(shown.percent, vector['percent']);
      });
    }

    test('a bar value that is not finite reads as indeterminate', () {
      expect(flareProgressBarValue(double.nan), FlareProgressBarValue.none);
      expect(
        flareProgressBarValue(double.infinity),
        FlareProgressBarValue.none,
      );
    });

    for (final vector in rows('versionPanel')) {
      test('panel reads ${vector['updateState']}', () {
        final model = flareVersionPanel(vector['updateState'] as String?);
        expect(model.row.name, vector['row']);
        expect(model.action?.name, vector['action']);
        expect(model.detail?.name, vector['detail']);
      });
    }

    for (final vector in rows('channels')) {
      test('channel reads ${vector['channel']}', () {
        expect(
          flareVersionChannelText(vector['channel'] as String?)?.name,
          vector['text'],
        );
      });
    }
  });

  group('words', () {
    test('every message has words in both languages', () {
      for (final message in FlareUpdatePromptMessage.values) {
        expect(
          flareUpdateMessageLabel(
            message,
            const FlareStrings(),
            size: '1 MB',
            reason: 'Withdrawn',
          ),
          isNotEmpty,
        );
        expect(
          flareUpdateMessageLabel(
            message,
            flareStringsEnglish,
            size: '1 MB',
            reason: 'Withdrawn',
          ),
          isNotEmpty,
        );
      }
    });

    test('the reason is the host\'s words', () {
      expect(
        flareUpdateMessageLabel(
          FlareUpdatePromptMessage.reason,
          const FlareStrings(),
          reason: '这个版本已撤回，请更新。',
        ),
        '这个版本已撤回，请更新。',
      );
    });

    test('the metered sentence ends with the size', () {
      expect(
        flareUpdateMessageLabel(
          FlareUpdatePromptMessage.metered,
          const FlareStrings(),
          size: '50.0 MB',
        ),
        '当前是计费网络，这次下载约 50.0 MB',
      );
    });

    test('the update action is the connection banner\'s', () {
      expect(
        flareUpdateActionLabel(
          FlareUpdatePromptAction.update,
          const FlareStrings(),
        ),
        '立即更新',
      );
      expect(
        flareUpdateActionLabel(
          FlareUpdatePromptAction.update,
          flareStringsEnglish,
        ),
        'Update now',
      );
    });

    test('the fallback names where it goes', () {
      const strings = FlareStrings();
      expect(
        flareUpdateActionLabel(FlareUpdatePromptAction.fallback, strings),
        '前往官网下载',
      );
      expect(
        flareUpdateActionLabel(
          FlareUpdatePromptAction.fallback,
          strings,
          fallbackTarget: FlareUpdateFallbackTarget.store,
        ),
        '前往应用商店',
      );
    });
  });

  group('FlareUpdatePrompt', () {
    Future<void> pumpPrompt(
      WidgetTester tester,
      FlareUpdatePrompt prompt,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SizedBox.expand(child: prompt)),
        ),
      );
      await tester.pump();
    }

    testWidgets('draws an action only when the host handles it', (
      tester,
    ) async {
      await pumpPrompt(
        tester,
        FlareUpdatePrompt(
          form: FlareUpdatePromptForm.sheet,
          version: '2.4.0',
          state: 'available',
          onUpdate: () {},
        ),
      );
      expect(find.text('立即更新'), findsOneWidget);
      expect(find.text('稍后'), findsNothing);
      expect(find.text('跳过此版本'), findsNothing);
    });

    testWidgets('a forced prompt offers no later, and read-only when allowed', (
      tester,
    ) async {
      var readOnly = 0;
      await pumpPrompt(
        tester,
        FlareUpdatePrompt(
          form: FlareUpdatePromptForm.modal,
          version: '2.4.0',
          mandatory: true,
          state: 'required',
          canContinueReadOnly: true,
          onUpdate: () {},
          onLater: () {},
          onSkip: () {},
          onContinueReadOnly: () => readOnly += 1,
        ),
      );
      expect(find.text('稍后'), findsNothing);
      expect(find.text('跳过此版本'), findsNothing);
      await tester.tap(find.text('继续浏览'));
      expect(readOnly, 1);
    });

    testWidgets('a forced offer says the reason in place of the fixed words', (
      tester,
    ) async {
      await pumpPrompt(
        tester,
        FlareUpdatePrompt(
          form: FlareUpdatePromptForm.modal,
          state: 'required',
          reason: '这个版本已撤回，请更新。',
          onUpdate: () {},
        ),
      );
      expect(find.text('这个版本已撤回，请更新。'), findsOneWidget);
      expect(find.text('当前版本已停止支持，更新后才能继续使用。'), findsNothing);
    });

    testWidgets('a blank reason keeps the fixed words', (tester) async {
      await pumpPrompt(
        tester,
        FlareUpdatePrompt(
          form: FlareUpdatePromptForm.modal,
          state: 'required',
          reason: '   ',
          onUpdate: () {},
        ),
      );
      expect(find.text('当前版本已停止支持，更新后才能继续使用。'), findsOneWidget);
    });

    testWidgets('a failure keeps its own words over the reason', (
      tester,
    ) async {
      await pumpPrompt(
        tester,
        FlareUpdatePrompt(
          form: FlareUpdatePromptForm.modal,
          mandatory: true,
          state: 'failed',
          errorCode: 'update.downloadFailed',
          reason: '这个版本已撤回，请更新。',
          onRetry: () {},
        ),
      );
      expect(find.text('这个版本已撤回，请更新。'), findsNothing);
    });

    testWidgets('shows the download with its number', (tester) async {
      await pumpPrompt(
        tester,
        const FlareUpdatePrompt(
          form: FlareUpdatePromptForm.modal,
          version: '2.4.0',
          sizeBytes: 52428800,
          state: 'downloading',
          progress: FlareUpdateProgress(received: 26214400, total: 52428800),
        ),
      );
      expect(find.text('版本 2.4.0 · 50.0 MB'), findsOneWidget);
      expect(find.text('50% · 25.0 MB / 50.0 MB'), findsOneWidget);
      expect(find.byType(FlareProgressBar), findsOneWidget);
    });

    testWidgets('draws no version line before a manifest has arrived', (
      tester,
    ) async {
      await pumpPrompt(
        tester,
        FlareUpdatePrompt(
          form: FlareUpdatePromptForm.modal,
          state: 'required',
          onUpdate: () {},
          onLater: () {},
        ),
      );
      expect(find.text('需要更新'), findsOneWidget);
      expect(find.text('稍后'), findsNothing);
      // The message says 当前版本; the version line starts with the word.
      expect(find.textContaining(RegExp('^版本')), findsNothing);
    });

    testWidgets('draws no fallback while the host has no address', (
      tester,
    ) async {
      await pumpPrompt(
        tester,
        FlareUpdatePrompt(
          form: FlareUpdatePromptForm.modal,
          version: '2.4.0',
          state: 'failed',
          errorCode: 'update.downloadFailed',
          onRetry: () {},
          onLater: () {},
        ),
      );
      expect(find.text('重试'), findsOneWidget);
      expect(find.text('前往官网下载'), findsNothing);
    });

    testWidgets('fullscreen brings its own page', (tester) async {
      await pumpPrompt(
        tester,
        FlareUpdatePrompt(
          form: FlareUpdatePromptForm.fullscreen,
          version: '2.4.0',
          state: 'required',
          onUpdate: () {},
        ),
      );
      expect(find.byType(FlareScreen), findsOneWidget);
    });
  });

  group('FlareUpdatePromptPresenter', () {
    Widget app(bool open, FlareUpdatePrompt prompt) => MaterialApp(
      home: Scaffold(
        body: FlareUpdatePromptPresenter(
          open: open,
          prompt: prompt,
          child: const SizedBox.expand(),
        ),
      ),
    );

    testWidgets('opens and closes with the host, and updates in place', (
      tester,
    ) async {
      FlareUpdatePrompt prompt(String state, {FlareUpdateProgress? progress}) =>
          FlareUpdatePrompt(
            form: FlareUpdatePromptForm.modal,
            version: '2.4.0',
            state: state,
            progress: progress,
            onUpdate: () {},
          );
      await tester.pumpWidget(app(false, prompt('available')));
      await tester.pump();
      expect(find.text('发现新版本'), findsNothing);

      await tester.pumpWidget(app(true, prompt('available')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('发现新版本'), findsOneWidget);

      await tester.pumpWidget(
        app(
          true,
          prompt(
            'downloading',
            progress: const FlareUpdateProgress(received: 1, total: 4),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('正在下载更新'), findsOneWidget);
      expect(find.text('发现新版本'), findsNothing);

      await tester.pumpWidget(app(false, prompt('available')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('发现新版本'), findsNothing);
      expect(find.text('正在下载更新'), findsNothing);
    });

    testWidgets('the scrim asks for later and leaves closing to the host', (
      tester,
    ) async {
      var later = 0;
      await tester.pumpWidget(
        app(
          true,
          FlareUpdatePrompt(
            form: FlareUpdatePromptForm.modal,
            version: '2.4.0',
            state: 'available',
            onUpdate: () {},
            onLater: () => later += 1,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tapAt(const Offset(4, 4));
      await tester.pump();
      expect(later, 1);
      expect(find.text('发现新版本'), findsOneWidget);
    });

    testWidgets('a forced prompt ignores the back key', (tester) async {
      var later = 0;
      await tester.pumpWidget(
        app(
          true,
          FlareUpdatePrompt(
            form: FlareUpdatePromptForm.fullscreen,
            version: '2.4.0',
            mandatory: true,
            state: 'required',
            onUpdate: () {},
            onLater: () => later += 1,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(later, 0);
      expect(find.text('需要更新'), findsOneWidget);
    });
  });

  group('FlareProgressBar', () {
    Future<void> pumpBar(WidgetTester tester, Widget bar) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: bar)));
      await tester.pump();
    }

    testWidgets('reads its number to a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBar(
        tester,
        const FlareProgressBar(value: 0.42, label: '下载进度'),
      );
      final node = tester.getSemantics(find.byType(FlareProgressBar));
      expect(node.label, '下载进度');
      expect(node.value, '42%');
      handle.dispose();
    });

    testWidgets('says the work is under way without a number', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBar(tester, const FlareProgressBar(indeterminate: true));
      final node = tester.getSemantics(find.byType(FlareProgressBar));
      expect(node.value, '进行中');
      handle.dispose();
    });

    testWidgets('stands still under reduced motion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: FlareProgressBar(indeterminate: true)),
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('FlareVersionPanel', () {
    Future<void> pumpPanel(WidgetTester tester, Widget panel) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: panel)),
        ),
      );
      await tester.pump();
    }

    testWidgets('lists the version, the build, the channel and the row', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        const FlareVersionPanel(
          version: '2.3.2',
          build: 20302,
          channel: 'stable',
        ),
      );
      expect(find.text('2.3.2'), findsOneWidget);
      expect(find.text('20302'), findsOneWidget);
      expect(find.text('正式版'), findsOneWidget);
      expect(find.text('检查更新'), findsOneWidget);
    });

    testWidgets('checks from the idle row', (tester) async {
      var checks = 0;
      await pumpPanel(
        tester,
        FlareVersionPanel(version: '2.3.2', onCheck: () => checks += 1),
      );
      await tester.tap(find.text('检查更新'));
      expect(checks, 1);
    });

    testWidgets('offers the update and ignores taps while downloading', (
      tester,
    ) async {
      var updates = 0;
      await pumpPanel(
        tester,
        FlareVersionPanel(
          version: '2.3.2',
          updateState: 'available',
          onUpdate: () => updates += 1,
        ),
      );
      await tester.tap(find.text('立即更新'));
      expect(updates, 1);
      await pumpPanel(
        tester,
        FlareVersionPanel(
          version: '2.3.2',
          updateState: 'downloading',
          onUpdate: () => updates += 1,
        ),
      );
      expect(find.text('正在下载更新'), findsOneWidget);
      await tester.tap(find.text('立即更新'), warnIfMissed: false);
      expect(updates, 1);
    });
  });
}
