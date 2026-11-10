import 'dart:convert';
import 'dart:io';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _fixture =
    (jsonDecode(
              File(
                '../../spec/plugin-file-input-vectors.json',
              ).readAsStringSync(),
            )
            as Map)
        .cast<String, Object?>();
final _inputs = (_fixture['inputs'] as List)
    .map((v) => FlarePluginInput.fromJson((v as Map).cast<String, Object?>())!)
    .toList();
const _values = <String, Object?>{
  'kind': 'alipay',
  'name': '测试',
  'account': 'qa',
};

void main() {
  test('shared vectors only submit visible opaque file receipts', () {
    for (final v in (_fixture['cases'] as List).cast<Map>()) {
      expect(
        flarePluginFormValues(
          _inputs,
          (v['values'] as Map).cast<String, Object?>(),
        ),
        v['expectedValues'],
      );
    }
    for (final v in _fixture['validFileValues'] as List) {
      expect(FlarePluginFileValue.fromValue(v), isNotNull);
    }
    for (final v in _fixture['invalidFileValues'] as List) {
      expect(FlarePluginFileValue.fromValue(v), isNull);
    }
    final draft = flarePluginDraft(_inputs, null);
    expect(draft['name'], '初始姓名');
    expect(draft.containsKey('bankName'), isFalse);
  });

  testWidgets(
    'upload blocks submission until matching scope and generation receipt',
    (tester) async {
      final actions = <FlarePluginFileAction>[];
      final submitted = <Map<String, Object?>>[];
      var states = <String, FlarePluginFileState>{};
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return SingleChildScrollView(
                  child: FlarePluginForm(
                    inputs: [
                      for (final raw in _fixture['inputs'] as List)
                        FlarePluginInput.fromJson({
                          ...(raw as Map).cast<String, Object?>(),
                          if (raw['id'] == 'qr') 'required': false,
                        })!,
                    ],
                    values: _values,
                    fileStates: states,
                    onFileAction: actions.add,
                    onSubmit: submitted.add,
                  ),
                );
              },
            ),
          ),
        ),
      );
      tester.widget<FlareFileUpload>(find.byType(FlareFileUpload)).onChoose!();
      await tester.pump();
      final action = actions.last;
      expect(action.action, FlarePluginFileActionKind.choose);
      expect(action.generation, 1);
      expect(action.formValues, _values);
      expect(action.input.file!.upload.purpose, 'payoutQr');
      Future<void> accept(
        String scope,
        int generation,
        FlarePluginFilePhase phase,
      ) async {
        update(
          () => states = {
            'qr': FlarePluginFileState(
              scope: scope,
              generation: generation,
              phase: phase,
              value: const FlarePluginFileValue(fileId: 'material_1'),
              fileName: 'receipt.png',
              preview: true,
            ),
          },
        );
        await tester.pump();
      }

      Future<void> submit() async {
        await tester.ensureVisible(
          find.byKey(const ValueKey('flare-plugin-form-submit')),
        );
        await tester.tap(
          find.byKey(const ValueKey('flare-plugin-form-submit')),
        );
        await tester.pump();
      }

      await accept(
        '${action.scope}-old',
        action.generation,
        FlarePluginFilePhase.uploaded,
      );
      await submit();
      expect(submitted, isEmpty);
      await accept(
        action.scope,
        action.generation - 1,
        FlarePluginFilePhase.uploaded,
      );
      await submit();
      expect(submitted, isEmpty);
      for (final phase in [
        FlarePluginFilePhase.selected,
        FlarePluginFilePhase.uploading,
        FlarePluginFilePhase.failed,
      ]) {
        await accept(action.scope, action.generation, phase);
        await submit();
        expect(submitted, isEmpty);
        update(() => states = {});
        await tester.pump();
        await submit();
        expect(submitted, isEmpty);
      }
      await accept(
        action.scope,
        action.generation,
        FlarePluginFilePhase.uploaded,
      );
      await submit();
      expect(submitted.single, {
        ..._values,
        'qr': {'fileId': 'material_1'},
      });
      tester.widget<FlareFileUpload>(find.byType(FlareFileUpload)).onPreview!();
      await tester.pump();
      expect(actions.last.action, FlarePluginFileActionKind.preview);
      expect(actions.last.generation, action.generation);
      update(() => states = {});
      await tester.pump();
      final refreshed = tester.widget<FlareFileUpload>(find.byType(FlareFileUpload));
      expect(refreshed.state, FlareImageUploadState.uploaded);
      expect(refreshed.fileName, 'receipt.png');
      expect(refreshed.preview, isFalse);
      await submit();
      expect(submitted, hasLength(2));
      expect(submitted.last['qr'], {'fileId': 'material_1'});
      refreshed.onRemove!();
      await tester.pump();
      // The original completion cannot resurrect a deliberately cleared ticket.
      await accept(action.scope, action.generation, FlarePluginFilePhase.uploaded);
      await submit();
      expect(submitted.last, _values);
    },
  );

  testWidgets(
    'changing kind clears still visible dependent fields and stale upload',
    (tester) async {
      final actions = <FlarePluginFileAction>[];
      final submitted = <Map<String, Object?>>[];
      var states = <String, FlarePluginFileState>{};
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return SingleChildScrollView(
                  child: FlarePluginForm(
                    inputs: [
                      _inputs[0],
                      _inputs[4],
                      ..._inputs.sublist(1, 4),
                      _inputs[5],
                    ],
                    values: _values,
                    fileStates: states,
                    onFileAction: actions.add,
                    onSubmit: submitted.add,
                  ),
                );
              },
            ),
          ),
        ),
      );
      tester.widget<FlareFileUpload>(find.byType(FlareFileUpload)).onChoose!();
      await tester.pump();
      final ticket = actions.last;
      update(
        () => states = {
          'qr': FlarePluginFileState(
            scope: ticket.scope,
            generation: ticket.generation,
            phase: FlarePluginFilePhase.uploaded,
            value: const FlarePluginFileValue(fileId: 'alipay_qr'),
          ),
        },
      );
      await tester.pump();
      update(() => states = {});
      await tester.pump();
      tester.widget<FlareRadioGroup>(find.byType(FlareRadioGroup)).onSelect!(
        'wechat',
      );
      await tester.pump();
      expect(actions.last.action, FlarePluginFileActionKind.invalidate);
      expect(actions.last.generation, 2);
      expect(actions.last.formValues, {'kind': 'wechat'});
      expect(
        tester.widget<FlareFileUpload>(find.byType(FlareFileUpload)).state,
        FlareImageUploadState.empty,
      );
      expect(
        tester
            .widgetList<FlareInput>(find.byType(FlareInput))
            .map((w) => w.controller!.text),
        everyElement(isEmpty),
      );
      update(
        () => states = {
          'qr': FlarePluginFileState(
            scope: ticket.scope,
            generation: ticket.generation,
            phase: FlarePluginFilePhase.uploaded,
            value: const FlarePluginFileValue(fileId: 'late'),
          ),
        },
      );
      await tester.pump();
      expect(
        tester.widget<FlareFileUpload>(find.byType(FlareFileUpload)).state,
        FlareImageUploadState.empty,
      );
      tester.widget<FlareRadioGroup>(find.byType(FlareRadioGroup)).onSelect!(
        'address',
      );
      await tester.pump();
      expect(find.byType(FlareFileUpload), findsNothing);
    },
  );

  testWidgets(
    'file surface exposes cancel retry replace remove and private preview intents',
    (tester) async {
      var taps = <String>[];
      Future<void> show(
        FlareImageUploadState phase, {
        bool preview = false,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlareFileUpload(
                title: '凭证',
                state: phase,
                preview: preview,
                progress: 50,
                onCancel: () => taps.add('cancel'),
                onRetry: () => taps.add('retry'),
                onReplace: () => taps.add('replace'),
                onRemove: () => taps.add('remove'),
                onPreview: () => taps.add('preview'),
              ),
            ),
          ),
        );
      }

      final s = FlareStrings();
      await show(FlareImageUploadState.uploading);
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(FlareImageUploadSlot),
                matching: find.byType(AspectRatio),
              ),
            )
            .height,
        FlareSizes.touchTargetMin * 2.5,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .5,
      );
      await tester.tap(find.text(s.cancel));
      await show(FlareImageUploadState.failed);
      await tester.tap(find.text(s.retry));
      await tester.tap(find.text(s.pluginFileReplace));
      await tester.tap(find.text(s.pluginFileRemove));
      await show(FlareImageUploadState.uploaded, preview: true);
      await tester.tap(find.text(s.pluginFilePreview));
      expect(taps, ['cancel', 'retry', 'replace', 'remove', 'preview']);
    },
  );
}
