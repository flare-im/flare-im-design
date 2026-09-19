// Layer 5 — Platform Contract (shared truth: spec/platform-contract.json).
// One capability record, one adapter interface and one error model. The host
// declares what it can do and performs the native work (image_picker,
// file_picker, share_plus …); components read capabilities through
// [FlarePlatform.of] and never branch on platform identity. This file is the
// only place in the kit allowed to consult [defaultTargetPlatform].
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum FlarePlatformKind { web, tauri, ios, android, flutter }

enum FlareCapabilitySupport { supported, fallback, unsupported }

enum FlarePointerKind { fine, coarse, mixed, unknown }

enum FlarePlatformErrorCode { unsupported, cancelled, permissionDenied, timeout, failed }

@immutable
class FlarePlatformCapabilities {
  const FlarePlatformCapabilities({
    this.pointer = FlarePointerKind.unknown,
    this.hover = false,
    this.contextMenu = false,
    this.keyboardShortcut = false,
    this.bottomSheet = false,
    this.nativeBack = false,
    this.safeArea = false,
    this.filePicker = FlareCapabilitySupport.unsupported,
    this.imagePicker = FlareCapabilitySupport.unsupported,
    this.share = FlareCapabilitySupport.unsupported,
  });

  final FlarePointerKind pointer;
  final bool hover;
  final bool contextMenu;
  final bool keyboardShortcut;

  /// Contextual layers present as bottom sheets (phone form factor).
  final bool bottomSheet;
  final bool nativeBack;
  final bool safeArea;
  final FlareCapabilitySupport filePicker;
  final FlareCapabilitySupport imagePicker;
  final FlareCapabilitySupport share;

  FlarePlatformCapabilities copyWith({
    FlarePointerKind? pointer,
    bool? hover,
    bool? contextMenu,
    bool? keyboardShortcut,
    bool? bottomSheet,
    bool? nativeBack,
    bool? safeArea,
    FlareCapabilitySupport? filePicker,
    FlareCapabilitySupport? imagePicker,
    FlareCapabilitySupport? share,
  }) {
    return FlarePlatformCapabilities(
      pointer: pointer ?? this.pointer,
      hover: hover ?? this.hover,
      contextMenu: contextMenu ?? this.contextMenu,
      keyboardShortcut: keyboardShortcut ?? this.keyboardShortcut,
      bottomSheet: bottomSheet ?? this.bottomSheet,
      nativeBack: nativeBack ?? this.nativeBack,
      safeArea: safeArea ?? this.safeArea,
      filePicker: filePicker ?? this.filePicker,
      imagePicker: imagePicker ?? this.imagePicker,
      share: share ?? this.share,
    );
  }

  /// Capabilities the Flutter target itself determines: pointer / hover /
  /// context menu / shortcuts from the target platform, `bottomSheet` from the
  /// window width (< 600 logical px), `nativeBack` on Android. Pickers and
  /// share stay `unsupported` until the host adapter declares them.
  static FlarePlatformCapabilities detect({
    TargetPlatform? platform,
    bool? isWeb,
    double? width,
  }) {
    final target = platform ?? defaultTargetPlatform;
    final web = isWeb ?? kIsWeb;
    final desktop = target == TargetPlatform.macOS ||
        target == TargetPlatform.windows ||
        target == TargetPlatform.linux;
    final fine = desktop || web;
    return FlarePlatformCapabilities(
      pointer: fine ? FlarePointerKind.fine : FlarePointerKind.coarse,
      hover: fine,
      contextMenu: fine,
      keyboardShortcut: fine,
      bottomSheet: (width ?? double.infinity) < 600,
      nativeBack: target == TargetPlatform.android && !web,
      safeArea: !desktop,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FlarePlatformCapabilities &&
      other.pointer == pointer &&
      other.hover == hover &&
      other.contextMenu == contextMenu &&
      other.keyboardShortcut == keyboardShortcut &&
      other.bottomSheet == bottomSheet &&
      other.nativeBack == nativeBack &&
      other.safeArea == safeArea &&
      other.filePicker == filePicker &&
      other.imagePicker == imagePicker &&
      other.share == share;

  @override
  int get hashCode => Object.hash(pointer, hover, contextMenu, keyboardShortcut,
      bottomSheet, nativeBack, safeArea, filePicker, imagePicker, share);
}

/// The contract's error model; `cause` keeps the original throwable.
@immutable
class FlarePlatformError implements Exception {
  const FlarePlatformError(this.code, {this.message, this.cause});

  final FlarePlatformErrorCode code;
  final String? message;
  final Object? cause;

  @override
  String toString() => 'FlarePlatformError(${code.name}${message == null ? '' : ': $message'})';
}

/// `Ok(value)` or `Err(error)` — the only two shapes an adapter operation returns.
sealed class FlarePlatformResult<T> {
  const FlarePlatformResult();

  const factory FlarePlatformResult.ok(T value) = FlarePlatformOk<T>;
  const factory FlarePlatformResult.err(FlarePlatformError error) = FlarePlatformErr<T>;

  factory FlarePlatformResult.failure(
    FlarePlatformErrorCode code, {
    String? message,
    Object? cause,
  }) =>
      FlarePlatformErr<T>(FlarePlatformError(code, message: message, cause: cause));

  bool get isOk => this is FlarePlatformOk<T>;
  T? get valueOrNull => switch (this) { FlarePlatformOk<T>(:final value) => value, _ => null };
  FlarePlatformError? get errorOrNull =>
      switch (this) { FlarePlatformErr<T>(:final error) => error, _ => null };
  FlarePlatformErrorCode? get code => errorOrNull?.code;
}

final class FlarePlatformOk<T> extends FlarePlatformResult<T> {
  const FlarePlatformOk(this.value);
  final T value;
}

final class FlarePlatformErr<T> extends FlarePlatformResult<T> {
  const FlarePlatformErr(this.error);
  final FlarePlatformError error;
}

@immutable
class FlarePickedFile {
  const FlarePickedFile({required this.name, this.size, this.mimeType, this.path, this.uri});
  final String name;
  final int? size;
  final String? mimeType;

  /// Native filesystem path when the platform exposes one.
  final String? path;

  /// Content uri / object URL when the platform exposes one instead of a path.
  final String? uri;
}

@immutable
class FlarePickFilesOptions {
  const FlarePickFilesOptions({this.multiple = false, this.accept = const []});
  final bool multiple;

  /// MIME types or extensions, e.g. ["image/*", ".pdf"].
  final List<String> accept;
}

@immutable
class FlarePickImagesOptions {
  const FlarePickImagesOptions({this.multiple = false, this.video = false});
  final bool multiple;
  final bool video;
}

@immutable
class FlareSharePayload {
  const FlareSharePayload({this.title, this.text, this.url, this.files = const []});
  final String? title;
  final String? text;
  final String? url;
  final List<FlarePickedFile> files;
}

@immutable
class FlareSafeAreaInsets {
  const FlareSafeAreaInsets({this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});
  final double top;
  final double right;
  final double bottom;
  final double left;
}

/// Host-implemented native operations. Every operation defaults to
/// UNSUPPORTED, so a host overrides only what it can do and declares it in
/// [capabilities].
abstract class FlarePlatformAdapter {
  const FlarePlatformAdapter();

  FlarePlatformKind get kind => FlarePlatformKind.flutter;

  FlarePlatformCapabilities get capabilities;

  Future<FlarePlatformResult<List<FlarePickedFile>>> pickFiles([
    FlarePickFilesOptions options = const FlarePickFilesOptions(),
  ]) async =>
      FlarePlatformResult.failure(FlarePlatformErrorCode.unsupported,
          message: 'pickFiles is not provided by this host');

  Future<FlarePlatformResult<List<FlarePickedFile>>> pickImages([
    FlarePickImagesOptions options = const FlarePickImagesOptions(),
  ]) async =>
      FlarePlatformResult.failure(FlarePlatformErrorCode.unsupported,
          message: 'pickImages is not provided by this host');

  Future<FlarePlatformResult<void>> share(FlareSharePayload payload) async =>
      FlarePlatformResult.failure(FlarePlatformErrorCode.unsupported,
          message: 'share is not provided by this host');

  /// Returns the unsubscribe, or null when the host has no native back to intercept.
  VoidCallback? onNativeBack(bool Function() handler) => null;

  FlareSafeAreaInsets safeAreaInsets(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return FlareSafeAreaInsets(
        top: padding.top, right: padding.right, bottom: padding.bottom, left: padding.left);
  }
}

/// The adapter in effect when the host installs none: nothing native is
/// available, capabilities are what the target platform determines.
class FlareUnsupportedPlatformAdapter extends FlarePlatformAdapter {
  const FlareUnsupportedPlatformAdapter({FlarePlatformCapabilities? capabilities})
      : _capabilities = capabilities;

  final FlarePlatformCapabilities? _capabilities;

  @override
  FlarePlatformCapabilities get capabilities =>
      _capabilities ?? FlarePlatformCapabilities.detect();
}

/// Map a thrown value to the contract's error model: plugin
/// [PlatformException] codes (cancel → CANCELLED, permission / denied →
/// PERMISSION_DENIED), [TimeoutException] → TIMEOUT, [MissingPluginException]
/// / [UnsupportedError] → UNSUPPORTED, anything else FAILED.
FlarePlatformError normalizeFlarePlatformError(Object error) {
  if (error is FlarePlatformError) return error;
  final code = error is PlatformException ? (error.code) : '';
  final message = switch (error) {
    PlatformException(:final message) => message,
    TimeoutException(:final message) => message,
    _ => error.toString(),
  };
  final text = '$code ${message ?? ''} ${error.runtimeType}'.toLowerCase();
  FlarePlatformError result(FlarePlatformErrorCode c) =>
      FlarePlatformError(c, message: message, cause: error);
  if (error is TimeoutException || RegExp(r'time(d)? ?out').hasMatch(text)) {
    return result(FlarePlatformErrorCode.timeout);
  }
  if (RegExp(r'cancel(l)?ed|abort').hasMatch(text)) return result(FlarePlatformErrorCode.cancelled);
  if (RegExp(r'permission|denied|not allowed').hasMatch(text)) {
    return result(FlarePlatformErrorCode.permissionDenied);
  }
  if (error is MissingPluginException ||
      error is UnsupportedError ||
      error is UnimplementedError ||
      RegExp(r'unsupported|not supported|not implemented').hasMatch(text)) {
    return result(FlarePlatformErrorCode.unsupported);
  }
  return result(FlarePlatformErrorCode.failed);
}

/// Resolve to TIMEOUT when the native surface does not answer in [timeout].
Future<FlarePlatformResult<T>> withFlarePlatformTimeout<T>(
  Future<FlarePlatformResult<T>> operation,
  Duration timeout,
) {
  // A Completer rather than Future.timeout: hosts hand in futures whose runtime
  // type parameter is narrower than T, and Future.timeout's onTimeout callback
  // would then fail the contravariant runtime check.
  final completer = Completer<FlarePlatformResult<T>>();
  final timer = Timer(timeout, () {
    if (completer.isCompleted) return;
    completer.complete(FlarePlatformResult.failure(
      FlarePlatformErrorCode.timeout,
      message: 'platform operation exceeded ${timeout.inMilliseconds}ms',
    ));
  });
  operation.then(
    (value) {
      timer.cancel();
      if (!completer.isCompleted) completer.complete(value);
    },
    onError: (Object error) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.complete(FlarePlatformResult.err(normalizeFlarePlatformError(error)));
      }
    },
  );
  return completer.future;
}

/// Run an adapter operation through the contract: a thrown value is
/// normalized and an optional timeout applies.
Future<FlarePlatformResult<T>> callFlarePlatform<T>(
  Future<FlarePlatformResult<T>> Function() operation, {
  Duration? timeout,
}) async {
  try {
    final pending = operation();
    return await (timeout == null ? pending : withFlarePlatformTimeout(pending, timeout));
  } catch (error) {
    return FlarePlatformResult.err(normalizeFlarePlatformError(error));
  }
}

/// Installs the host's [FlarePlatformAdapter] for a subtree; read it with
/// [FlarePlatform.of] / [FlarePlatform.maybeOf].
class FlarePlatformScope extends InheritedWidget {
  const FlarePlatformScope({super.key, required this.adapter, required super.child});

  final FlarePlatformAdapter adapter;

  @override
  bool updateShouldNotify(FlarePlatformScope oldWidget) => oldWidget.adapter != adapter;
}

abstract final class FlarePlatform {
  static const FlarePlatformAdapter _fallback = FlareUnsupportedPlatformAdapter();

  static FlarePlatformAdapter? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlarePlatformScope>()?.adapter;

  /// The host adapter, or the unsupported fallback so components always have
  /// capabilities to read.
  static FlarePlatformAdapter of(BuildContext context) => maybeOf(context) ?? _fallback;
}
