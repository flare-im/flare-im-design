// Contract tests for Layer 5 (spec/platform-contract.json vectors). A scripted
// adapter plays each native outcome; the assertions are on the contract's
// normalization and result shape, not on any real picker — the capability
// matrix records this as PASS_TEST, never PASS_RUNTIME.
import 'dart:async';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Outcome { success, cancelled, unsupported, denied, timeout, failed }

class _ScriptedAdapter extends FlarePlatformAdapter {
  const _ScriptedAdapter(this.outcome);
  final _Outcome outcome;

  @override
  FlarePlatformCapabilities get capabilities => const FlarePlatformCapabilities(
        filePicker: FlareCapabilitySupport.supported,
        imagePicker: FlareCapabilitySupport.supported,
        share: FlareCapabilitySupport.supported,
      );

  Future<FlarePlatformResult<T>> _play<T>(T value) async {
    switch (outcome) {
      case _Outcome.success:
        return FlarePlatformResult.ok(value);
      case _Outcome.cancelled:
        // image_picker / file_picker report a dismissed picker as null; the host maps it.
        return FlarePlatformResult.failure(FlarePlatformErrorCode.cancelled, message: 'picker dismissed');
      case _Outcome.unsupported:
        throw MissingPluginException('No implementation found for method pick');
      case _Outcome.denied:
        throw PlatformException(code: 'photo_access_denied', message: 'The user did not allow photo access.');
      case _Outcome.timeout:
        return Completer<FlarePlatformResult<T>>().future;
      case _Outcome.failed:
        throw StateError('native surface crashed');
    }
  }

  @override
  Future<FlarePlatformResult<List<FlarePickedFile>>> pickFiles([FlarePickFilesOptions options = const FlarePickFilesOptions()]) =>
      _play([const FlarePickedFile(name: 'spec.pdf', size: 4, mimeType: 'application/pdf', path: '/tmp/spec.pdf')]);

  @override
  Future<FlarePlatformResult<List<FlarePickedFile>>> pickImages([FlarePickImagesOptions options = const FlarePickImagesOptions()]) =>
      _play([const FlarePickedFile(name: 'shot.png', mimeType: 'image/png', path: '/tmp/shot.png')]);

  @override
  Future<FlarePlatformResult<void>> share(FlareSharePayload payload) => _play(null);
}

Future<FlarePlatformResult<Object?>> _run(String operation, _Outcome outcome) {
  final adapter = _ScriptedAdapter(outcome);
  const timeout = Duration(milliseconds: 20);
  return callFlarePlatform<Object?>(
    () => switch (operation) {
      'pickFiles' => adapter.pickFiles(),
      'pickImages' => adapter.pickImages(),
      _ => adapter.share(const FlareSharePayload(text: 'hi')),
    },
    timeout: timeout,
  );
}

void main() {
  const operations = ['pickFiles', 'pickImages', 'share'];
  const expected = {
    _Outcome.cancelled: FlarePlatformErrorCode.cancelled,
    _Outcome.unsupported: FlarePlatformErrorCode.unsupported,
    _Outcome.denied: FlarePlatformErrorCode.permissionDenied,
    _Outcome.timeout: FlarePlatformErrorCode.timeout,
    _Outcome.failed: FlarePlatformErrorCode.failed,
  };

  group('platform contract vectors', () {
    for (final operation in operations) {
      test('$operation.success carries the picked value', () async {
        final result = await _run(operation, _Outcome.success);
        expect(result.isOk, isTrue);
        if (operation != 'share') {
          final files = result.valueOrNull! as List<FlarePickedFile>;
          expect(files.single.name, operation == 'pickFiles' ? 'spec.pdf' : 'shot.png');
        }
      });
      for (final entry in expected.entries) {
        final id = '$operation.${entry.key.name}';
        test('$id normalizes to ${entry.value.name}', () async {
          final result = await _run(operation, entry.key);
          expect(result.isOk, isFalse, reason: id);
          expect(result.code, entry.value, reason: id);
          expect(result.errorOrNull!.message, isNotEmpty, reason: '$id keeps a message');
        });
      }
    }
    // Explicit ids so the contract gate can match them: pickFiles.success
    // pickFiles.cancelled pickFiles.unsupported pickFiles.denied pickFiles.timeout
    // pickFiles.failed pickImages.success pickImages.cancelled
    // pickImages.unsupported pickImages.denied pickImages.timeout
    // pickImages.failed share.success share.cancelled share.unsupported
    // share.denied share.timeout share.failed
  });

  group('error model', () {
    test('maps plugin and Dart errors onto the five codes', () {
      expect(normalizeFlarePlatformError(PlatformException(code: 'cancelled')).code, FlarePlatformErrorCode.cancelled);
      expect(normalizeFlarePlatformError(PlatformException(code: 'permission_denied')).code, FlarePlatformErrorCode.permissionDenied);
      expect(normalizeFlarePlatformError(TimeoutException('slow')).code, FlarePlatformErrorCode.timeout);
      expect(normalizeFlarePlatformError(UnsupportedError('no')).code, FlarePlatformErrorCode.unsupported);
      expect(normalizeFlarePlatformError(StateError('x')).code, FlarePlatformErrorCode.failed);
      const passthrough = FlarePlatformError(FlarePlatformErrorCode.timeout, message: 'kept');
      expect(identical(normalizeFlarePlatformError(passthrough), passthrough), isTrue);
    });

    test('an adapter that overrides nothing answers UNSUPPORTED everywhere', () async {
      const adapter = FlareUnsupportedPlatformAdapter();
      expect((await adapter.pickFiles()).code, FlarePlatformErrorCode.unsupported);
      expect((await adapter.pickImages()).code, FlarePlatformErrorCode.unsupported);
      expect((await adapter.share(const FlareSharePayload())).code, FlarePlatformErrorCode.unsupported);
      expect(adapter.onNativeBack(() => true), isNull);
      expect(adapter.capabilities.filePicker, FlareCapabilitySupport.unsupported);
    });
  });

  group('capability detection', () {
    test('desktop targets get a fine pointer with hover / context menu / shortcuts', () {
      final caps = FlarePlatformCapabilities.detect(platform: TargetPlatform.macOS, isWeb: false, width: 1280);
      expect(caps.pointer, FlarePointerKind.fine);
      expect(caps.hover, isTrue);
      expect(caps.contextMenu, isTrue);
      expect(caps.keyboardShortcut, isTrue);
      expect(caps.bottomSheet, isFalse);
      expect(caps.nativeBack, isFalse);
      expect(caps.safeArea, isFalse);
    });
    test('android phones are coarse, sheet-first, with native back and safe area', () {
      final caps = FlarePlatformCapabilities.detect(platform: TargetPlatform.android, isWeb: false, width: 390);
      expect(caps.pointer, FlarePointerKind.coarse);
      expect(caps.hover, isFalse);
      expect(caps.bottomSheet, isTrue);
      expect(caps.nativeBack, isTrue);
      expect(caps.safeArea, isTrue);
    });

    testWidgets('FlarePlatformScope installs the host adapter for descendants', (tester) async {
      FlarePlatformAdapter? seen;
      await tester.pumpWidget(
        FlarePlatformScope(
          adapter: const _ScriptedAdapter(_Outcome.success),
          child: Builder(builder: (context) {
            seen = FlarePlatform.of(context);
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(seen, isA<_ScriptedAdapter>());
      expect(seen!.capabilities.filePicker, FlareCapabilitySupport.supported);
      await tester.pumpWidget(Builder(builder: (context) {
        seen = FlarePlatform.of(context);
        return const SizedBox.shrink();
      }));
      expect(seen, isA<FlareUnsupportedPlatformAdapter>());
    });
  });
}
