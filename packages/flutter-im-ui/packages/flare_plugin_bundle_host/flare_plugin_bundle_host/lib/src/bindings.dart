import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The engine's `plugin_bundle_*` routes as the app's core SDK reaches them:
/// `capability.<route>` with `{payload}`. Answers the engine's object as it
/// came; throws on a refusal, whose text carries `sdk.plugin_bundle.<reason>`.
typedef FlarePluginBundleEngine =
    Future<Object?> Function(String route, Map<String, Object?> payload);

/// The routes a native host may run through [FlarePluginBundleBindings]; any
/// other name is refused before it reaches the engine.
const flarePluginBundleRoutes = {
  'plugin_bundle_open',
  'plugin_bundle_bridge',
  'plugin_bundle_host_result',
  'plugin_bundle_host_event',
  'plugin_bundle_close',
  'plugin_bundle_prefetch',
};

/// The `sdk.plugin_bundle.*` reason an engine refusal names (`not_offered`,
/// `unsupported`, `unavailable`, `rejected`, …); `unavailable` otherwise.
String flarePluginBundleFailureReason(Object? error) {
  if (error is PlatformException && _reason.hasMatch(error.code)) {
    return error.code;
  }
  final match = RegExp(
    r'\bsdk\.plugin_bundle\.([a-z_]+)\b',
  ).firstMatch(error?.toString() ?? '');
  return match?.group(1) ?? 'unavailable';
}

final _reason = RegExp(r'^[a-z_]+$');

/// The plugin's method channel: the native hosts call the engine through it
/// (`engine`), and Dart asks them for the runtime (`runtime`), hands them
/// `plugin.bundle_event` (`event`) and asks for the network (`unmetered`).
abstract final class FlarePluginBundleBindings {
  /// The channel both sides use.
  static const channel = MethodChannel('flare_plugin_bundle_host');

  static FlarePluginBundleEngine? _engine;

  /// Gives the native hosts the engine. Call once the core SDK is up (and
  /// again with another SDK); without it every page falls back.
  static void install(FlarePluginBundleEngine engine) {
    _engine = engine;
    channel.setMethodCallHandler(handle);
  }

  /// Takes the engine away: pages opened afterwards fall back.
  static void uninstall() {
    _engine = null;
    channel.setMethodCallHandler(null);
  }

  /// Whether an engine is installed.
  static bool get installed => _engine != null;

  /// A native host's call. `engine` `{route, payload}` (the payload as JSON
  /// text) answers the engine's object as JSON text, or a
  /// [PlatformException] whose code is the refusal's reason.
  @visibleForTesting
  static Future<Object?> handle(MethodCall call) async {
    if (call.method != 'engine') {
      throw MissingPluginException('flare_plugin_bundle_host: ${call.method}');
    }
    final args = call.arguments;
    final route = args is Map ? args['route'] : null;
    final text = args is Map ? args['payload'] : null;
    if (route is! String || !flarePluginBundleRoutes.contains(route)) {
      throw PlatformException(code: 'invalid_request');
    }
    Map<String, Object?> payload;
    try {
      final decoded = text is String ? jsonDecode(text) : null;
      if (decoded is! Map) throw const FormatException('payload');
      payload = Map<String, Object?>.from(decoded);
    } on FormatException {
      throw PlatformException(code: 'invalid_request');
    }
    final engine = _engine;
    if (engine == null) throw PlatformException(code: 'unavailable');
    try {
      final answer = await engine(route, payload);
      return jsonEncode(answer is Map ? answer : const <String, Object?>{});
    } catch (error) {
      throw PlatformException(code: flarePluginBundleFailureReason(error));
    }
  }

  /// `plugin_bundle_prefetch` `{wifi, idle}`: entry bundles fetched ahead. The
  /// number fetched; 0 without an engine or on a refusal.
  static Future<int> prefetch({bool wifi = true, bool idle = true}) async {
    final engine = _engine;
    if (engine == null) return 0;
    try {
      final answer = await engine('plugin_bundle_prefetch', {
        'wifi': wifi,
        'idle': idle,
      });
      final fetched = answer is Map ? answer['fetched'] : null;
      return fetched is num ? fetched.toInt() : 0;
    } catch (_) {
      return 0;
    }
  }
}

/// The bundle runtime this device's native host offers, as the host profile
/// reports it (`bundleRuntime`).
abstract final class FlarePluginBundleRuntime {
  /// `{bridge, engine, engineMajor}`; null when no native host is registered
  /// (web, desktop, an iOS app without `flare_plugin_bundle_host_ios`) or the
  /// device is below the floor (Android System WebView 111 and Android 8, iOS
  /// 16; D-17). The profile then carries no runtime and Core never selects a
  /// bundle.
  static Future<Map<String, Object?>?> profile() async {
    if (kIsWeb) return null;
    try {
      final text = await FlarePluginBundleBindings.channel.invokeMethod<String>(
        'runtime',
      );
      if (text == null) return null;
      final decoded = jsonDecode(text);
      return decoded is Map ? Map<String, Object?>.from(decoded) : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Whether the device is on an unmetered network (Wi-Fi), the only place
  /// entry bundles are fetched ahead. False when it cannot be told.
  static Future<bool> unmeteredNetwork() async {
    if (kIsWeb) return false;
    try {
      return await FlarePluginBundleBindings.channel.invokeMethod<bool>(
            'unmetered',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

/// The web storage bundle pages keep, per signed-in user. The app calls
/// [signedIn] once the user is known (sign-in, a restored session, a switch to
/// another account) and [signedOut] when the session ends. On Android each user
/// gets a WebView profile of their own (or a per-origin wipe where profiles are
/// not supported), and another user's storage is deleted at [signedIn]; on iOS
/// every page already runs in a store that ends with it, so both are no-ops.
abstract final class FlarePluginBundleStorage {
  /// [scope] signed in: a stable key of the user (deployment, tenant and user
  /// id). False when no native host keeps bundle storage (web, desktop, iOS,
  /// below the floor).
  static Future<bool> signedIn(String scope) =>
      scope.isEmpty ? Future.value(false) : _call('signedIn', {'scope': scope});

  /// The session ended: everything bundles kept for that user is deleted.
  static Future<bool> signedOut() => _call('signedOut', null);

  static Future<bool> _call(String method, Object? arguments) async {
    if (kIsWeb) return false;
    try {
      return await FlarePluginBundleBindings.channel.invokeMethod<bool>(
            method,
            arguments,
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

/// The engine's own messages for open pages (`plugin.bundle_event`, event
/// 7004): the app's event subscription passes each payload here, and the
/// native host of that session posts the envelope or closes.
abstract final class FlarePluginBundleEvents {
  /// The core event code.
  static const eventCode = 7004;

  /// Hands one `{sessionId, envelope?, close?}` payload to its page; false
  /// when no open page has that session (or no native host is registered).
  static Future<bool> dispatch(Object? payload) async {
    if (kIsWeb || payload is! Map) return false;
    final sessionId = payload['sessionId'];
    if (sessionId is! String || sessionId.isEmpty) return false;
    try {
      return await FlarePluginBundleBindings.channel.invokeMethod<bool>(
            'event',
            {'payload': jsonEncode(payload)},
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

/// Fetches entry bundles ahead while the app sits idle on Wi-Fi: [schedule]
/// after the places that show entries load or the app comes to the
/// foreground; each call restarts the wait, [cancel] drops it (background,
/// sign-out).
class FlarePluginBundlePrefetch {
  FlarePluginBundlePrefetch({this.idle = const Duration(seconds: 10)});

  /// How long the app stays idle before the fetch.
  final Duration idle;
  Timer? _timer;

  /// Whether a fetch is waiting.
  bool get pending => _timer?.isActive ?? false;

  void schedule() {
    _timer?.cancel();
    _timer = Timer(idle, () => unawaited(_run()));
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _run() async {
    _timer = null;
    if (!FlarePluginBundleBindings.installed) return;
    if (!await FlarePluginBundleRuntime.unmeteredNetwork()) return;
    await FlarePluginBundleBindings.prefetch();
  }
}
