import 'dart:async';
import 'dart:convert';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_plugin_bundle_host/flare_plugin_bundle_host.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();

  tearDown(() {
    FlarePluginBundleBindings.uninstall();
    messenger.setMockMethodCallHandler(FlarePluginBundleBindings.channel, null);
  });

  /// A native host calling the engine through Dart.
  Future<Object?> nativeCall(String method, Object? arguments) async {
    final reply = Completer<ByteData?>();
    await messenger.handlePlatformMessage(
      FlarePluginBundleBindings.channel.name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
      reply.complete,
    );
    return codec.decodeEnvelope((await reply.future)!);
  }

  group('open request', () {
    test(
      'carries the conversation only with an id, the route only when set',
      () {
        const request = FlarePluginBundleOpenRequest(
          pluginId: 'acme.task',
          contributionId: 'task.page.dashboard',
          route: ' ',
          arguments: {'filter': 'mine'},
          conversationId: 'c1',
          conversationType: 'group',
          locale: 'zh-CN',
        );
        expect(request.toJson(), {
          'pluginId': 'acme.task',
          'contributionId': 'task.page.dashboard',
          'arguments': {'filter': 'mine'},
          'presentation': 'page',
          'conversation': {'id': 'c1', 'type': 'group'},
          'locale': 'zh-CN',
        });
        const bare = FlarePluginBundleOpenRequest(
          pluginId: 'acme.task',
          contributionId: 'task.form',
          route: '/new',
          presentation: FlarePluginBundlePresentation.composerForm,
          conversationId: '',
        );
        expect(bare.toJson(), {
          'pluginId': 'acme.task',
          'contributionId': 'task.form',
          'route': '/new',
          'arguments': <String, Object?>{},
          'presentation': 'composerForm',
          'locale': '',
        });
        expect(
          const FlarePluginBundleOpenRequest(
            pluginId: 'p',
            contributionId: 'c',
            conversationId: 'c1',
          ).toJson()['conversation'],
          {'id': 'c1', 'type': 'single'},
        );
      },
    );

    test('a locale change keeps the page, anything else opens another', () {
      const request = FlarePluginBundleOpenRequest(
        pluginId: 'p',
        contributionId: 'c',
        locale: 'zh-CN',
      );
      expect(request.copyWith(locale: 'en').identity, request.identity);
      expect(request.copyWith(locale: 'en'), isNot(request));
      expect(request.copyWith(route: '/b').identity, isNot(request.identity));
    });

    test('creation params name the native copy by the locale', () {
      const zh = FlarePluginBundleOpenRequest(
        pluginId: 'p',
        contributionId: 'c',
        locale: 'zh-Hans',
      );
      final params = flarePluginBundleCreationParams(
        zh,
        dark: true,
        navigable: true,
        resizable: false,
      );
      expect(jsonDecode(params['request']! as String), zh.toJson());
      expect(params['dark'], isTrue);
      expect(params['english'], isFalse);
      expect(params['navigable'], isTrue);
      expect(params['resizable'], isFalse);
      expect(
        flarePluginBundleCreationParams(
          zh.copyWith(locale: 'en-US'),
          dark: false,
          navigable: false,
          resizable: true,
        )['english'],
        isTrue,
      );
    });
  });

  group('host requests', () {
    test('navigation names a page or a bundle route, never both', () {
      expect(
        FlarePluginBundleNavigation.of({
          'page': 'detail',
          'arguments': {'id': 1},
        }),
        const FlarePluginBundlePageTarget('detail', arguments: {'id': 1}),
      );
      expect(
        FlarePluginBundleNavigation.of({'bundleRoute': '/stats'}),
        const FlarePluginBundleRouteTarget('/stats'),
      );
      expect(
        FlarePluginBundleNavigation.of({'page': 'a', 'bundleRoute': '/b'}),
        isNull,
      );
      expect(FlarePluginBundleNavigation.of({'page': ' '}), isNull);
      expect(FlarePluginBundleNavigation.of(const {}), isNull);
    });

    test('confirm copy is bounded and needs a title', () {
      final ask = FlarePluginBundleConfirm.of({
        'title': 'T' * 80,
        'message': 'M' * 600,
        'confirmLabel': 'L' * 20,
      })!;
      expect(ask.title.length, 64);
      expect(ask.message!.length, 512);
      expect(ask.confirmLabel!.length, 16);
      expect(FlarePluginBundleConfirm.of({'title': '  '}), isNull);
      expect(FlarePluginBundleConfirm.of({'message': 'm'}), isNull);
    });

    test('external links are https with a host and no credentials', () {
      expect(
        flarePluginBundleExternalUrl('https://help.example.com/a?b=1'),
        Uri.parse('https://help.example.com/a?b=1'),
      );
      for (final url in [
        'http://example.com',
        'javascript:alert(1)',
        'https://user:pass@example.com',
        'https:///path',
        'flare-plugin://abc/index.html',
        'https://example.com/${'a' * 2048}',
        42,
        null,
      ]) {
        expect(flarePluginBundleExternalUrl(url), isNull, reason: '$url');
      }
    });

    test('answers are a result object or an error code', () {
      expect(flarePluginBundleHostAnswer(), {'result': '{}'});
      expect(flarePluginBundleHostAnswer(result: {'confirmed': true}), {
        'result': '{"confirmed":true}',
      });
      expect(flarePluginBundleHostAnswer(error: 'cancelled'), {
        'error': 'cancelled',
      });
    });

    test('toast kinds map to the kit toast', () {
      expect(
        flarePluginBundleToastVariant('success'),
        FlareToastVariant.success,
      );
      expect(flarePluginBundleToastVariant('error'), FlareToastVariant.error);
      expect(
        flarePluginBundleToastVariant('warning'),
        FlareToastVariant.warning,
      );
      expect(flarePluginBundleToastVariant(null), FlareToastVariant.info);
    });

    test('every bridge error code has words in both languages', () {
      const codes = [
        'invalid_envelope',
        'unsupported_bridge',
        'not_ready',
        'method_not_found',
        'invalid_params',
        'payload_too_large',
        'permission_denied',
        'rate_limited',
        'cancelled',
        'gesture_required',
        'quota_exceeded',
        'not_found',
        'unavailable',
        'timeout',
        'operation_failed',
        'revoked',
      ];
      for (final strings in [const FlareStrings(), flareStringsEnglish]) {
        final internal = flarePluginBridgeErrorText('internal', strings);
        final words = {
          for (final code in codes) flarePluginBridgeErrorText(code, strings),
        };
        expect(words.length, codes.length);
        expect(words, isNot(contains(internal)));
        expect(
          flarePluginBridgeErrorText('plugin.bridge.permissionDenied', strings),
          flarePluginBridgeErrorText('permission_denied', strings),
        );
      }
    });
  });

  group('engine bindings', () {
    test('refusal reasons come out of the SDK error text', () {
      expect(
        flarePluginBundleFailureReason(
          StateError('sdk.plugin_bundle.not_offered: no bundle'),
        ),
        'not_offered',
      );
      expect(
        flarePluginBundleFailureReason(PlatformException(code: 'unsupported')),
        'unsupported',
      );
      expect(flarePluginBundleFailureReason(Exception('boom')), 'unavailable');
      expect(flarePluginBundleFailureReason(null), 'unavailable');
    });

    test('a native engine call runs the installed engine', () async {
      final calls = <(String, Map<String, Object?>)>[];
      FlarePluginBundleBindings.install((route, payload) async {
        calls.add((route, payload));
        return {'envelope': '{"id":"1"}'};
      });
      final answer = await nativeCall('engine', {
        'route': 'plugin_bundle_bridge',
        'payload': jsonEncode({'sessionId': 's', 'envelope': '{}'}),
      });
      expect(jsonDecode(answer! as String), {'envelope': '{"id":"1"}'});
      expect(calls.single.$1, 'plugin_bundle_bridge');
      expect(calls.single.$2, {'sessionId': 's', 'envelope': '{}'});
    });

    test('refusals reach the native host as their reason', () async {
      FlarePluginBundleBindings.install(
        (route, payload) async =>
            throw StateError('sdk.plugin_bundle.not_offered'),
      );
      await expectLater(
        nativeCall('engine', {
          'route': 'plugin_bundle_open',
          'payload': '{"pluginId":"p"}',
        }),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'not_offered'),
        ),
      );
    });

    test('only the bundle routes and object payloads are run', () async {
      var ran = false;
      FlarePluginBundleBindings.install((route, payload) async {
        ran = true;
        return const {};
      });
      for (final args in [
        {'route': 'plugin_ui_invoke', 'payload': '{}'},
        {'route': 'plugin_bundle_open', 'payload': '[1]'},
        {'route': 'plugin_bundle_open', 'payload': 'not json'},
        {'route': 'plugin_bundle_open'},
      ]) {
        await expectLater(
          nativeCall('engine', args),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'invalid_request',
            ),
          ),
        );
      }
      expect(ran, isFalse);
    });

    test('without an engine every call is unavailable', () async {
      FlarePluginBundleBindings.install((route, payload) async => const {});
      FlarePluginBundleBindings.uninstall();
      expect(FlarePluginBundleBindings.installed, isFalse);
      await expectLater(
        FlarePluginBundleBindings.handle(
          const MethodCall('engine', {
            'route': 'plugin_bundle_close',
            'payload': '{"sessionId":"s"}',
          }),
        ),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'unavailable'),
        ),
      );
      expect(await FlarePluginBundleBindings.prefetch(), 0);
    });

    test('prefetch asks for Wi-Fi and idle and reads the count', () async {
      Map<String, Object?>? sent;
      FlarePluginBundleBindings.install((route, payload) async {
        expect(route, 'plugin_bundle_prefetch');
        sent = payload;
        return {'fetched': 2};
      });
      expect(await FlarePluginBundleBindings.prefetch(), 2);
      expect(sent, {'wifi': true, 'idle': true});
    });
  });

  group('native host', () {
    test('the runtime profile is what the native host reports', () async {
      messenger.setMockMethodCallHandler(FlarePluginBundleBindings.channel, (
        call,
      ) async {
        if (call.method == 'runtime') {
          return '{"bridge":1,"engine":"webview","engineMajor":128}';
        }
        return null;
      });
      expect(await FlarePluginBundleRuntime.profile(), {
        'bridge': 1,
        'engine': 'webview',
        'engineMajor': 128,
      });
    });

    test('no native host, or below the floor, reports no runtime', () async {
      expect(await FlarePluginBundleRuntime.profile(), isNull);
      messenger.setMockMethodCallHandler(
        FlarePluginBundleBindings.channel,
        (call) async => null,
      );
      expect(await FlarePluginBundleRuntime.profile(), isNull);
      expect(await FlarePluginBundleRuntime.unmeteredNetwork(), isFalse);
    });

    test('engine events go to the native host as JSON text', () async {
      Object? sent;
      messenger.setMockMethodCallHandler(FlarePluginBundleBindings.channel, (
        call,
      ) async {
        if (call.method != 'event') return null;
        sent = (call.arguments as Map)['payload'];
        return true;
      });
      final payload = {'sessionId': 's1', 'close': 'withdrawn'};
      expect(await FlarePluginBundleEvents.dispatch(payload), isTrue);
      expect(jsonDecode(sent! as String), payload);
      expect(await FlarePluginBundleEvents.dispatch({'close': 'x'}), isFalse);
      expect(await FlarePluginBundleEvents.dispatch('nope'), isFalse);
    });
  });

  testWidgets('falls back at once where no native host runs', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    String? reason;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FlarePluginBundleHost(
          request: const FlarePluginBundleOpenRequest(
            pluginId: 'p',
            contributionId: 'c',
            presentation: FlarePluginBundlePresentation.detail,
          ),
          title: 'Tasks',
          onFallback: (value) => reason = value,
          onClose: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(reason, 'unsupported');
    debugDefaultTargetPlatformOverride = null;
  });
}
