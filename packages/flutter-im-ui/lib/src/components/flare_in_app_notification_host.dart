import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/in_app_notification.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_in_app_notification_banner.dart';

/// Puts the in-app new-message banner on screen. Spec:
/// Feedback/InAppNotificationHost (`FlareInAppNotificationHost`).
///
/// Wrap the app with it — typically in `MaterialApp.builder`, so the banner
/// sits above every route — and feed [notifications] from the engine's
/// `notification.present` (surface `inApp`) and `notification.clear` events:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => FlareInAppNotificationHost(
///     notifications: inApp,
///     onOpen: (conversationId, messageId) => router.openChat(conversationId),
///     child: child!,
///   ),
/// )
/// ```
///
/// The presenter decides what shows and what waits
/// (spec/in-app-notification-vectors.json); the host owns the time: each
/// banner stays [inAppNotificationDuration] after it shows or is replaced, the
/// time stops while a finger is on it and starts over when it lifts, and while
/// a screen reader is in use the banner stays until it is dismissed, replaced
/// or cleared. Opening dismisses the banner and calls [onOpen]. Each banner
/// that shows is announced once. Reduced motion: it fades instead of sliding.
class FlareInAppNotificationHost extends StatefulWidget {
  const FlareInAppNotificationHost({
    super.key,
    required this.notifications,
    this.onOpen,
    required this.child,
  });

  /// The presenter the app feeds.
  final FlareInAppNotifications notifications;

  /// Opens the conversation: `(conversationId, messageId)`.
  final void Function(String conversationId, String? messageId)? onOpen;

  /// The app.
  final Widget child;

  @override
  State<FlareInAppNotificationHost> createState() =>
      _FlareInAppNotificationHostState();
}

class _FlareInAppNotificationHostState
    extends State<FlareInAppNotificationHost> {
  Timer? _timer;
  int? _revision;
  bool _screenReader = false;

  /// The banner a finger is on, by collapse id: the hold belongs to that
  /// banner, so a different one that takes its place runs its own time.
  String? _pressed;

  @override
  void initState() {
    super.initState();
    widget.notifications.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenReader = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
    if (_revision == null) {
      _screenReader = screenReader;
      _seen();
    } else if (screenReader != _screenReader) {
      _screenReader = screenReader;
      _schedule();
    }
  }

  @override
  void didUpdateWidget(FlareInAppNotificationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifications != widget.notifications) {
      oldWidget.notifications.removeListener(_changed);
      widget.notifications.addListener(_changed);
      _revision = null;
      _seen();
    }
  }

  @override
  void dispose() {
    widget.notifications.removeListener(_changed);
    _timer?.cancel();
    super.dispose();
  }

  void _changed() {
    setState(_seen);
  }

  /// Catches up with the presenter: a banner that showed or was replaced is
  /// announced and its time starts over; nothing showing, no time runs.
  void _seen() {
    final notifications = widget.notifications;
    final current = notifications.current;
    if (notifications.revision == _revision) {
      if (current == null) _cancel();
      return;
    }
    _revision = notifications.revision;
    if (current != null) _announce(current);
    _schedule();
  }

  bool get _held {
    final current = widget.notifications.current;
    return current != null && _pressed == current.collapseId;
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    _cancel();
    if (widget.notifications.current == null || _held || _screenReader) return;
    _timer = Timer(inAppNotificationDuration, () {
      _timer = null;
      widget.notifications.dismiss();
    });
  }

  void _press(String? collapseId) {
    if (_pressed == collapseId) return;
    _pressed = collapseId;
    _schedule();
  }

  void _announce(FlareInAppNotification notification) {
    final text = notification.spoken(FlareStrings.of(context));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(MediaQuery.maybeSupportsAnnounceOf(context) ?? false)) {
        return;
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        text,
        Directionality.of(context),
      );
    });
  }

  void _open(String conversationId, String? messageId) {
    widget.notifications.dismiss();
    widget.onOpen?.call(conversationId, messageId);
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.notifications.current;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingMd,
                FlareSizes.spacingSm,
                FlareSizes.spacingMd,
                0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: FlareSizes.authFormMaxWidth,
                  ),
                  child: AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : FlareMotion.normal,
                    transitionBuilder: (child, animation) {
                      final faded = FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                      if (reduceMotion) return faded;
                      return SlideTransition(
                        position: Tween(
                          begin: const Offset(0, -1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: faded,
                      );
                    },
                    child: current == null
                        ? const SizedBox.shrink()
                        : Listener(
                            key: ValueKey(current.collapseId),
                            onPointerDown: (_) => _press(current.collapseId),
                            onPointerUp: (_) => _press(null),
                            onPointerCancel: (_) => _press(null),
                            child: Material(
                              type: MaterialType.transparency,
                              child: FlareInAppNotificationBanner(
                                notification: current,
                                onOpen: _open,
                                onDismiss: widget.notifications.dismiss,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
