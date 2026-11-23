import 'dart:async';
import 'dart:convert';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'request.dart';

/// The platform view type both native hosts register.
const flarePluginBundleViewType = 'flare_plugin_bundle_host/view';

/// Where a bundle page stands, as the host draws it.
enum FlarePluginBundlePhase {
  /// Opening the session, downloading the bundle the first time, loading the
  /// entry, or suspended until it is shown again.
  opening,

  /// The entry loaded.
  ready,

  /// The renderer went away; Reload opens it again.
  crashed,
}

/// The creation parameters of the platform view: the request without the
/// theme as JSON text, the theme mode, the kit language of the native copy,
/// and which host callbacks exist.
@visibleForTesting
Map<String, Object?> flarePluginBundleCreationParams(
  FlarePluginBundleOpenRequest request, {
  required bool dark,
  required bool navigable,
  required bool resizable,
}) => {
  'request': jsonEncode(request.toJson()),
  'dark': dark,
  'english': !request.locale.toLowerCase().startsWith('zh'),
  'navigable': navigable,
  'resizable': resizable,
};

/// A host request's answer as the native host reads it: `{result}` (JSON
/// text of the result object) or `{error}` (`cancelled`, `unavailable`,
/// `gesture_required`, `timeout`, `not_found`).
@visibleForTesting
Map<String, Object?> flarePluginBundleHostAnswer({
  Map<String, Object?>? result,
  String? error,
}) => error != null
    ? {'error': error}
    : {'result': jsonEncode(result ?? const <String, Object?>{})};

/// `ui.toast` kind to the kit's toast.
@visibleForTesting
FlareToastVariant flarePluginBundleToastVariant(Object? kind) => switch (kind) {
  'success' => FlareToastVariant.success,
  'error' => FlareToastVariant.error,
  'warning' => FlareToastVariant.warning,
  _ => FlareToastVariant.info,
};

/// This kit's words for a bridge error code (`permission_denied`) or its
/// message key (`plugin.bridge.permissionDenied`).
String flarePluginBridgeErrorText(
  String code,
  FlareStrings strings,
) => switch (code.replaceFirst('plugin.bridge.', '')) {
  'invalid_envelope' ||
  'invalidEnvelope' => strings.pluginBridgeErrorInvalidEnvelope,
  'unsupported_bridge' ||
  'unsupportedBridge' => strings.pluginBridgeErrorUnsupportedBridge,
  'not_ready' || 'notReady' => strings.pluginBridgeErrorNotReady,
  'method_not_found' ||
  'methodNotFound' => strings.pluginBridgeErrorMethodNotFound,
  'invalid_params' || 'invalidParams' => strings.pluginBridgeErrorInvalidParams,
  'payload_too_large' ||
  'payloadTooLarge' => strings.pluginBridgeErrorPayloadTooLarge,
  'permission_denied' ||
  'permissionDenied' => strings.pluginBridgeErrorPermissionDenied,
  'rate_limited' || 'rateLimited' => strings.pluginBridgeErrorRateLimited,
  'cancelled' => strings.pluginBridgeErrorCancelled,
  'gesture_required' ||
  'gestureRequired' => strings.pluginBridgeErrorGestureRequired,
  'quota_exceeded' || 'quotaExceeded' => strings.pluginBridgeErrorQuotaExceeded,
  'not_found' || 'notFound' => strings.pluginBridgeErrorNotFound,
  'unavailable' => strings.pluginBridgeErrorUnavailable,
  'timeout' => strings.pluginBridgeErrorTimeout,
  'operation_failed' ||
  'operationFailed' => strings.pluginBridgeErrorOperationFailed,
  'revoked' => strings.pluginBridgeErrorRevoked,
  _ => strings.pluginBridgeErrorInternal,
};

/// A plugin web bundle (L3) in Flutter: the native host of the platform
/// (Android `FlarePluginBundleView`, iOS `FlarePluginBundleHostViewController`)
/// in a platform view, with its engine calls carried to the app's core SDK
/// through [FlarePluginBundleBindings].
///
/// The page presentation draws the kit page frame ([FlareScreen], the
/// bundle's `ui.setTitle` over [title]); a detail or composer form draws none,
/// its sheet is the frame. On Android the opening and crash states and the
/// host requests (`ui.toast`, `ui.confirm`, `ui.openExternal`,
/// `clipboard.write`) are drawn here with kit components; on iOS the native
/// host draws them with the SwiftUI kit.
///
/// - [onFallback]: show the declarative variant instead (not offered, failed
///   to open, crashed three times, withdrawn, suspended, disabled, replaced).
///   Also called at once where no native host runs (web, desktop, an iOS app
///   without `flare_plugin_bundle_host_ios`).
/// - [onClose]: `ui.close`, with the result object for a composer form; also
///   a signed-out session (null).
/// - [onNavigate]: `ui.navigate`; false answers `not_found`.
/// - [onOpenExternal]: opens an `https` link the viewer confirmed; the
///   default asks the native host for the system browser.
/// - [onHeightChange]: `ui.resize` in a sheet (logical pixels); without it the
///   request is `unavailable`.
class FlarePluginBundleHost extends StatefulWidget {
  const FlarePluginBundleHost({
    super.key,
    required this.request,
    required this.title,
    required this.onFallback,
    required this.onClose,
    this.onBack,
    this.onNavigate,
    this.onOpenExternal,
    this.onHeightChange,
    this.gestureRecognizers,
  });

  final FlarePluginBundleOpenRequest request;
  final String title;
  final ValueChanged<String> onFallback;
  final ValueChanged<Map<String, Object?>?> onClose;
  final VoidCallback? onBack;
  final bool Function(FlarePluginBundleNavigation target)? onNavigate;
  final Future<bool> Function(Uri url)? onOpenExternal;
  final ValueChanged<double>? onHeightChange;

  /// Gestures the page claims; by default all of them (it scrolls itself).
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  State<FlarePluginBundleHost> createState() => _FlarePluginBundleHostState();
}

class _FlarePluginBundleHostState extends State<FlarePluginBundleHost>
    with WidgetsBindingObserver {
  MethodChannel? _view;
  FlarePluginBundlePhase _phase = FlarePluginBundlePhase.opening;
  String? _title;
  bool _dark = false;
  bool _themeRead = false;

  /// The fallback or close was reported: nothing more goes to the app.
  bool _finished = false;

  static const _defaultGestures = <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  bool get _android => defaultTargetPlatform == TargetPlatform.android;
  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _macos => defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb || (!_android && !_ios && !_macos)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fallback('unsupported'),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = FlareColors.of(context).bgPrimary.computeLuminance() < 0.5;
    if (_themeRead && dark == _dark) return;
    final changed = _themeRead;
    _themeRead = true;
    _dark = dark;
    if (changed) unawaited(_call('setDark', {'dark': dark}));
  }

  @override
  void didUpdateWidget(covariant FlarePluginBundleHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.identity != widget.request.identity) {
      // Another page: the keyed platform view is replaced and opens afresh.
      _view?.setMethodCallHandler(null);
      _view = null;
      _phase = FlarePluginBundlePhase.opening;
      _title = null;
      _finished = false;
    } else if (oldWidget.request.locale != widget.request.locale) {
      unawaited(_call('setLocale', {'locale': widget.request.locale}));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android's view follows the screen: paused in the background, destroyed
    // after 30 s, back on return. iOS's controller follows the app itself.
    if (!_android) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_call('resume'));
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        unawaited(_call('pause'));
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _view?.setMethodCallHandler(null);
    _view = null;
    super.dispose();
  }

  Future<void> _call(String method, [Map<String, Object?>? arguments]) async {
    final view = _view;
    if (view == null) return;
    try {
      await view.invokeMethod<void>(method, arguments);
    } on PlatformException {
      // The view is gone; nothing to tell it.
    } on MissingPluginException {
      // Same.
    }
  }

  void _created(int id) {
    final view = MethodChannel('$flarePluginBundleViewType/view_$id');
    _view?.setMethodCallHandler(null);
    _view = view;
    view.setMethodCallHandler(_onViewCall);
    unawaited(_attach(view));
  }

  /// Reads the state the view reached before this handler was set (a
  /// fallback right at creation would otherwise be lost).
  Future<void> _attach(MethodChannel view) async {
    try {
      final state = await view.invokeMethod<Object?>('attach');
      if (!mounted || !identical(view, _view) || state is! Map) return;
      _state(Map<String, Object?>.from(state));
    } on PlatformException {
      // Gone already.
    } on MissingPluginException {
      // Same.
    }
  }

  void _fallback(String reason) {
    if (_finished || !mounted) return;
    if (reason == 'signedOut') return _closed(null);
    _finished = true;
    widget.onFallback(reason);
  }

  void _closed(Map<String, Object?>? result) {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onClose(result);
  }

  Map<String, Object?> _decode(Object? text) {
    if (text is! String) return const {};
    try {
      final decoded = jsonDecode(text);
      return decoded is Map ? Map<String, Object?>.from(decoded) : const {};
    } on FormatException {
      return const {};
    }
  }

  Future<Object?> _onViewCall(MethodCall call) async {
    if (!mounted) throw PlatformException(code: 'unavailable');
    final args = call.arguments is Map
        ? Map<String, Object?>.from(call.arguments as Map)
        : const <String, Object?>{};
    switch (call.method) {
      case 'state':
        _state(args);
        return null;
      case 'hostRequest':
        return _hostRequest(
          args['method'] as String? ?? '',
          _decode(args['params']),
        );
      // The iOS host draws its own requests and hands these back.
      case 'title':
        final title = args['title'];
        if (title is String && title.trim().isNotEmpty) {
          setState(() => _title = title.trim());
        }
        return null;
      case 'navigate':
        final target = FlarePluginBundleNavigation.of(_decode(args['params']));
        return target != null && (widget.onNavigate?.call(target) ?? false);
      case 'close':
        final result = _decode(args['result']);
        _closed(args['result'] == null ? null : result);
        return null;
      case 'fallback':
        _fallback(args['reason'] as String? ?? 'unavailable');
        return null;
    }
    throw MissingPluginException(
      'flare_plugin_bundle_host view: ${call.method}',
    );
  }

  void _state(Map<String, Object?> args) {
    switch (args['state']) {
      case 'opening' || 'suspended':
        setState(() => _phase = FlarePluginBundlePhase.opening);
      case 'ready':
        setState(() => _phase = FlarePluginBundlePhase.ready);
      case 'crashed':
        setState(() => _phase = FlarePluginBundlePhase.crashed);
      case 'fallback':
        _fallback(args['reason'] as String? ?? 'unavailable');
      case 'closed':
        _closed(null);
    }
  }

  /// A request the engine handed the Android host to draw.
  Future<Map<String, Object?>> _hostRequest(
    String method,
    Map<String, Object?> params,
  ) async {
    final strings = FlareStrings.of(context);
    String? text(String key, int limit) {
      final value = params[key];
      if (value is! String || value.trim().isEmpty) return null;
      final runes = value.trim().runes;
      return runes.length <= limit
          ? value.trim()
          : String.fromCharCodes(runes.take(limit));
    }

    switch (method) {
      case 'ui.setTitle':
        final title = text('title', 64);
        if (title == null)
          return flarePluginBundleHostAnswer(error: 'unavailable');
        setState(() => _title = title);
        return flarePluginBundleHostAnswer();
      case 'ui.toast':
        final message = text('message', 200);
        if (message == null)
          return flarePluginBundleHostAnswer(error: 'unavailable');
        FlareToast.show(
          context,
          message: message,
          variant: flarePluginBundleToastVariant(params['kind']),
        );
        return flarePluginBundleHostAnswer();
      case 'ui.confirm':
        final ask = FlarePluginBundleConfirm.of(params);
        if (ask == null)
          return flarePluginBundleHostAnswer(error: 'unavailable');
        final confirmed = await FlareDangerConfirm.show(
          context,
          title: ask.title,
          description: ask.message ?? '',
          confirmText: ask.confirmLabel,
        );
        return flarePluginBundleHostAnswer(result: {'confirmed': confirmed});
      case 'ui.openExternal':
        final url = flarePluginBundleExternalUrl(params['url']);
        if (url == null)
          return flarePluginBundleHostAnswer(error: 'unavailable');
        final confirmed = await FlareDangerConfirm.show(
          context,
          title: strings.pluginBundleExternalTitle,
          description: strings.pluginBundleExternalMessage,
          target: url.toString(),
          confirmText: strings.pluginBundleExternalOpen,
        );
        if (!confirmed) return flarePluginBundleHostAnswer(error: 'cancelled');
        final open = widget.onOpenExternal;
        var opened = false;
        try {
          if (open != null) {
            opened = await open(url);
          } else {
            opened =
                await _view?.invokeMethod<bool>('openExternal', {
                  'url': url.toString(),
                }) ??
                false;
          }
        } catch (_) {
          opened = false;
        }
        if (opened) return flarePluginBundleHostAnswer();
        if (mounted) {
          FlareToast.show(
            context,
            message: strings.pluginBridgeErrorUnavailable,
            variant: FlareToastVariant.error,
          );
        }
        return flarePluginBundleHostAnswer(error: 'unavailable');
      case 'clipboard.write':
        final value = params['text'];
        if (value is! String)
          return flarePluginBundleHostAnswer(error: 'unavailable');
        await Clipboard.setData(ClipboardData(text: value));
        if (mounted) {
          FlareToast.show(
            context,
            message: strings.pluginBundleCopied,
            variant: FlareToastVariant.success,
          );
        }
        return flarePluginBundleHostAnswer();
      case 'ui.navigate':
        final target = FlarePluginBundleNavigation.of(params);
        final handled =
            target != null && (widget.onNavigate?.call(target) ?? false);
        return handled
            ? flarePluginBundleHostAnswer()
            : flarePluginBundleHostAnswer(error: 'not_found');
      case 'ui.resize':
        final height = params['height'];
        final resize = widget.onHeightChange;
        if (height is! num || height <= 0 || resize == null) {
          return flarePluginBundleHostAnswer(error: 'unavailable');
        }
        resize(height.toDouble());
        return flarePluginBundleHostAnswer();
      case 'ui.close':
        final raw = params['result'];
        final result = raw is Map ? Map<String, Object?>.from(raw) : null;
        // Answered first, so the page hears it before it goes.
        Timer.run(() => _closed(result));
        return flarePluginBundleHostAnswer();
    }
    return flarePluginBundleHostAnswer(error: 'unavailable');
  }

  Widget _platformView() {
    final params = flarePluginBundleCreationParams(
      widget.request,
      dark: _dark,
      navigable: widget.onNavigate != null,
      resizable: widget.onHeightChange != null,
    );
    final gestures = widget.gestureRecognizers ?? _defaultGestures;
    if (_android) {
      return AndroidView(
        viewType: flarePluginBundleViewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
        gestureRecognizers: gestures,
      );
    }
    if (_ios) {
      return UiKitView(
        viewType: flarePluginBundleViewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
        gestureRecognizers: gestures,
      );
    }
    if (_macos && !kIsWeb) {
      return AppKitView(
        viewType: flarePluginBundleViewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
      );
    }
    return const SizedBox.shrink();
  }

  Widget? _stateLayer(FlareStrings strings, FlareColors colors) {
    // Apple hosts draw their own states.
    if (!_android) return null;
    return switch (_phase) {
      FlarePluginBundlePhase.ready => null,
      FlarePluginBundlePhase.opening => ColoredBox(
        color: colors.bgPrimary,
        child: Center(
          child: FlareEmptyState(
            title: strings.pluginBundleOpening,
            icon: 'plugin',
            loading: true,
          ),
        ),
      ),
      FlarePluginBundlePhase.crashed => ColoredBox(
        color: colors.bgPrimary,
        child: Center(
          child: FlareEmptyState(
            title: strings.pluginBundleCrashed,
            description: strings.pluginBundleCrashedHint,
            actionText: strings.pluginBundleReload,
            icon: 'warning',
            tone: FlareEmptyStateTone.error,
            onAction: () {
              setState(() => _phase = FlarePluginBundlePhase.opening);
              unawaited(_call('reload'));
            },
          ),
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final layer = _stateLayer(strings, colors);
    final body = Stack(
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: ValueKey(widget.request.identity),
          child: _platformView(),
        ),
        ?layer,
      ],
    );
    if (widget.request.presentation != FlarePluginBundlePresentation.page) {
      return body;
    }
    return FlareScreen(
      title: _title ?? widget.title,
      onBack: widget.onBack,
      scroll: false,
      child: body,
    );
  }
}
