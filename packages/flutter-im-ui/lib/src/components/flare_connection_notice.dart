import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/connection_notice.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_status_banner.dart';

/// The connection notice an app shell places once, above every tab. Spec:
/// IM/ConnectionNotice (`FlareConnectionNotice`).
///
/// The host hands in the core SDK's connection status (`connection://status`)
/// as it arrives; what shows when is [FlareConnectionNoticeTracker]'s call
/// (`spec/connection-notice-vectors.json`, the same in every kit). The widget
/// feeds it the status, wakes when the presentation can next change (a delay
/// ends, the countdown turns over, a hold ends) and draws the banner with
/// [FlareStatusBanner]. An action is drawn only when the host passes its
/// handler. The message is announced when it changes; the countdown is not
/// re-announced every second.
class FlareConnectionNotice extends StatefulWidget {
  const FlareConnectionNotice({
    super.key,
    required this.status,
    this.floating = false,
    this.onRetry,
    this.onSignIn,
    this.onUpdate,
    this.onDiagnose,
  });

  /// The latest `connection://status`; null before the SDK has reported one.
  final FlareConnectionStatus? status;

  /// Hang the banner over the content ([FlareStatusBanner.floating]).
  final bool floating;

  /// Reconnect now (the SDK's `connection.reconnectNow`), offered while
  /// reconnecting.
  final VoidCallback? onRetry;

  /// Sign in again, offered when the session was kicked or expired.
  final VoidCallback? onSignIn;

  /// Open the app update, offered when the server requires a newer app.
  final VoidCallback? onUpdate;

  /// Open the network diagnostics, offered while the service is unavailable.
  final VoidCallback? onDiagnose;

  @override
  State<FlareConnectionNotice> createState() => _FlareConnectionNoticeState();
}

class _FlareConnectionNoticeState extends State<FlareConnectionNotice> {
  final _tracker = FlareConnectionNoticeTracker();
  FlareConnectionNoticeModel _model = FlareConnectionNoticeModel.hidden;
  Timer? _wake;
  String? _announced;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _observe();
  }

  @override
  void didUpdateWidget(FlareConnectionNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) _observe();
  }

  @override
  void dispose() {
    _wake?.cancel();
    super.dispose();
  }

  void _observe() {
    _tracker.observe(
      widget.status ??
          const FlareConnectionStatus(phase: FlareConnectionPhase.idle),
      _now(),
    );
    _refresh(rebuild: false);
  }

  void _refresh({bool rebuild = true}) {
    _wake?.cancel();
    _wake = null;
    final now = _now();
    final next = _tracker.present(now);
    if (next != _model) {
      if (rebuild) {
        setState(() => _model = next);
      } else {
        _model = next;
      }
    }
    final at = _tracker.nextChangeAt(now);
    if (at != null) {
      _wake = Timer(Duration(milliseconds: at - now < 0 ? 0 : at - now), () {
        if (mounted) _refresh();
      });
    }
  }

  VoidCallback? _handler(FlareConnectionNoticeAction? action) =>
      switch (action) {
        FlareConnectionNoticeAction.retry => widget.onRetry,
        FlareConnectionNoticeAction.signIn => widget.onSignIn,
        FlareConnectionNoticeAction.update => widget.onUpdate,
        FlareConnectionNoticeAction.diagnose => widget.onDiagnose,
        null => null,
      };

  void _announce(String? message) {
    if (message == _announced) return;
    _announced = message;
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(MediaQuery.maybeSupportsAnnounceOf(context) ?? false)) {
        return;
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final model = _model;
    final perform = _handler(model.action);
    _announce(model.visible ? model.message(strings) : null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (model.badge)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              key: const ValueKey('flare-connection-notice-badge'),
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingSm,
                vertical: FlareSizes.spacing3xs,
              ),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
              ),
              child: Text(
                strings.connectionDevelopmentMode,
                style: TextStyle(
                  color: colors.warningText,
                  fontSize: FlareSizes.fontSizeXs,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (model.badge && model.visible)
          const SizedBox(height: FlareSizes.spacingXs),
        if (model.visible)
          FlareStatusBanner(
            text: model.bannerText(strings),
            tone: model.tone ?? FlareStatusTone.info,
            pulse: model.pulse,
            actionText: perform == null || model.action == null
                ? null
                : flareConnectionActionLabel(model.action!, strings),
            onAction: perform,
            floating: widget.floating,
          ),
      ],
    );
  }
}
