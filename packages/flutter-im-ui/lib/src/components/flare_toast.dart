import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_status_banner.dart' show FlareStatusTone;

/// Visual style of a [FlareToast].
enum FlareToastVariant { info, success, error, warning, loading }

/// Transient toast pill — an icon + message, optional inline action and an
/// optional close button. The loading variant spins its icon. Present one with
/// [FlareToast.show]. Spec: General/Toast (`FlareToast`).
class FlareToast extends StatefulWidget {
  const FlareToast({
    super.key,
    required this.message,
    this.variant = FlareToastVariant.info,
    this.tone,
    this.actionLabel,
    this.onAction,
    this.onClose,
  });

  final String message;
  final FlareToastVariant variant;
  final FlareStatusTone? tone;

  /// The action button shows when both [actionLabel] and [onAction] are set.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Contract event `close`. When non-null a close button is shown after the
  /// message / action; when null no button renders (the host owns dismissal).
  final VoidCallback? onClose;

  /// On screen at once per overlay; a new toast removes the oldest.
  static const int stackLimit = 3;

  /// Shows a toast in the root [Overlay] and returns a function that dismisses
  /// it early. Each overlay keeps one stack, top-center below the safe area.
  /// The toast leaves after [duration] — 4 s, or 6 s for the error variant or
  /// the danger tone; [Duration.zero] keeps it until its action or close runs.
  /// Every toast carries the close button, running the action also dismisses
  /// it, and the message is announced politely to assistive technology.
  static VoidCallback show(
    BuildContext context, {
    required String message,
    FlareToastVariant variant = FlareToastVariant.info,
    FlareStatusTone? tone,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final danger =
        variant == FlareToastVariant.error || tone == FlareStatusTone.danger;
    return _FlareToastQueue.of(Overlay.of(context, rootOverlay: true)).add(
      _FlareToastRequest(
        message: message,
        variant: variant,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration ?? Duration(milliseconds: danger ? 6000 : 4000),
      ),
    );
  }

  @override
  State<FlareToast> createState() => _FlareToastState();
}

class _FlareToastRequest {
  const _FlareToastRequest({
    required this.message,
    required this.variant,
    required this.tone,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
  });

  final String message;
  final FlareToastVariant variant;
  final FlareStatusTone? tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
}

/// One stack per overlay: the entries on screen and the overlay entry that
/// draws them, inserted with the first toast and removed with the last.
class _FlareToastQueue {
  _FlareToastQueue(this._overlay);

  static final _queues = Expando<_FlareToastQueue>('FlareToast.show');

  static _FlareToastQueue of(OverlayState overlay) =>
      _queues[overlay] ??= _FlareToastQueue(overlay);

  final OverlayState _overlay;
  final toasts = ValueNotifier<List<(int, _FlareToastRequest)>>(const []);
  OverlayEntry? _entry;
  int _nextId = 0;

  VoidCallback add(_FlareToastRequest request) {
    final id = ++_nextId;
    final next = [...toasts.value, (id, request)];
    toasts.value = next.length > FlareToast.stackLimit
        ? next.sublist(next.length - FlareToast.stackLimit)
        : next;
    if (_entry == null) {
      final entry = OverlayEntry(builder: (_) => _FlareToastStack(queue: this));
      _entry = entry;
      _overlay.insert(entry);
    }
    return () => dismiss(id);
  }

  void dismiss(int id) {
    final next = toasts.value.where((toast) => toast.$1 != id).toList();
    if (next.length == toasts.value.length) return;
    toasts.value = next;
    if (next.isEmpty) {
      _entry?.remove();
      _entry?.dispose();
      _entry = null;
    }
  }
}

class _FlareToastStack extends StatelessWidget {
  const _FlareToastStack({required this.queue});

  final _FlareToastQueue queue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingLg),
          child: Material(
            type: MaterialType.transparency,
            child: ValueListenableBuilder(
              valueListenable: queue.toasts,
              builder: (context, toasts, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, (id, request)) in toasts.indexed)
                    Padding(
                      key: ValueKey(id),
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : FlareSizes.spacingSm,
                      ),
                      child: _FlareToastItem(
                        request: request,
                        onDismiss: () => queue.dismiss(id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Owns one toast's timer, so the timer ends with the toast however it leaves.
class _FlareToastItem extends StatefulWidget {
  const _FlareToastItem({required this.request, required this.onDismiss});

  final _FlareToastRequest request;
  final VoidCallback onDismiss;

  @override
  State<_FlareToastItem> createState() => _FlareToastItemState();
}

class _FlareToastItemState extends State<_FlareToastItem> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final duration = widget.request.duration;
    if (duration > Duration.zero) _timer = Timer(duration, widget.onDismiss);
    // Platforms that take announcements get one; the others read the live
    // region below, so the message is spoken once either way.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(MediaQuery.maybeSupportsAnnounceOf(context) ?? false)) {
        return;
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        widget.request.message,
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _runAction() {
    final action = widget.request.onAction;
    widget.onDismiss();
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      container: true,
      // The close button and action stay controls of their own.
      explicitChildNodes: true,
      liveRegion: !(MediaQuery.maybeSupportsAnnounceOf(context) ?? false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: reduceMotion ? Duration.zero : FlareMotion.normal,
        curve: FlareMotion.normalCurve,
        builder: (context, shown, child) => Opacity(
          opacity: shown.clamp(0.0, 1.0),
          // Readable from the first frame, while it fades in.
          alwaysIncludeSemantics: true,
          child: Transform.translate(
            offset: Offset(0, (shown - 1) * FlareSizes.spacingSm),
            child: child,
          ),
        ),
        child: FlareToast(
          message: request.message,
          variant: request.variant,
          tone: request.tone,
          actionLabel: request.actionLabel,
          onAction: request.onAction == null ? null : _runAction,
          onClose: widget.onDismiss,
        ),
      ),
    );
  }
}

class _FlareToastState extends State<FlareToast>
    with SingleTickerProviderStateMixin {
  AnimationController? _spin;

  @override
  void initState() {
    super.initState();
    _maybeStartSpin();
  }

  @override
  void didUpdateWidget(covariant FlareToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant != oldWidget.variant) _maybeStartSpin();
  }

  void _maybeStartSpin() {
    final spinning =
        widget.variant == FlareToastVariant.loading &&
        !(WidgetsBinding.instance.disableAnimations);
    if (spinning) {
      _spin ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      _spin!.repeat();
    } else {
      _spin?.stop();
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  IconData get _icon {
    final tone = widget.tone;
    if (tone != null && widget.variant != FlareToastVariant.loading) {
      switch (tone) {
        case FlareStatusTone.success:
          return Icons.check_circle;
        case FlareStatusTone.warning:
          return Icons.warning_amber_rounded;
        case FlareStatusTone.danger:
          return Icons.cancel;
        case FlareStatusTone.info:
        case FlareStatusTone.neutral:
          return Icons.info;
      }
    }
    switch (widget.variant) {
      case FlareToastVariant.info:
        return Icons.info;
      case FlareToastVariant.success:
        return Icons.check_circle;
      case FlareToastVariant.error:
        return Icons.cancel;
      case FlareToastVariant.warning:
        return Icons.warning_amber_rounded;
      case FlareToastVariant.loading:
        return Icons.sync;
    }
  }

  Color _iconColor(FlareColors colors) {
    final tone = widget.tone;
    if (tone != null && widget.variant != FlareToastVariant.loading) {
      return _toneColor(colors, tone);
    }
    switch (widget.variant) {
      case FlareToastVariant.info:
        return colors.primary;
      case FlareToastVariant.success:
        return colors.success;
      case FlareToastVariant.error:
        return colors.error;
      case FlareToastVariant.warning:
        return colors.warning;
      case FlareToastVariant.loading:
        return colors.textSecondary;
    }
  }

  Color _toneColor(FlareColors colors, FlareStatusTone tone) {
    switch (tone) {
      case FlareStatusTone.info:
        return colors.primary;
      case FlareStatusTone.success:
        return colors.success;
      case FlareStatusTone.warning:
        return colors.warning;
      case FlareStatusTone.danger:
        return colors.error;
      case FlareStatusTone.neutral:
        return colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    Widget icon = Icon(_icon, size: 18, color: _iconColor(colors));
    if (widget.variant == FlareToastVariant.loading && _spin != null) {
      icon = RotationTransition(turns: _spin!, child: icon);
    }
    final actionLabel = widget.actionLabel;
    final onAction = widget.onAction;
    final onClose = widget.onClose;
    final hasAction = actionLabel != null && onAction != null;
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      // Controls are full touch targets that reach the pill's end; the
      // message keeps the pill's own vertical padding.
      padding: EdgeInsetsDirectional.only(
        start: 14,
        end: hasAction || onClose != null ? FlareSizes.spacingXs : 14,
      ),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2915131C),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 10),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                widget.message,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeLg,
                ),
              ),
            ),
          ),
          if (hasAction) ...[
            const SizedBox(width: FlareSizes.spacingXs),
            _FlareToastControl(
              label: actionLabel,
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingSm,
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: FlareSizes.fontSizeLg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (onClose != null)
            _FlareToastControl(
              label: strings.close,
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: FlareSizes.iconSizeSm,
                color: colors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

/// A toast control: a full touch target, announced as a button named [label],
/// with [child] as what it shows.
class _FlareToastControl extends StatelessWidget {
  const _FlareToastControl({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Semantics(
      container: true,
      button: true,
      label: label,
      // Ink on a surface of its own, above the toast fill.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          hoverColor: colors.bgHover,
          highlightColor: colors.bgHover,
          focusColor: colors.focusRing,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: FlareSizes.touchTarget,
              minHeight: FlareSizes.touchTarget,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: ExcludeSemantics(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
