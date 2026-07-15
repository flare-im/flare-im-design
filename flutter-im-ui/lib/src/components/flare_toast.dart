import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Visual style of a [FlareToast].
enum FlareToastVariant { info, success, error, warning, loading }

/// Transient toast pill — an icon + message, optional inline action. The
/// loading variant spins its icon. Spec: General/Toast (`FlareToast`).
class FlareToast extends StatefulWidget {
  const FlareToast({
    super.key,
    required this.message,
    this.variant = FlareToastVariant.info,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final FlareToastVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<FlareToast> createState() => _FlareToastState();
}

class _FlareToastState extends State<FlareToast> with SingleTickerProviderStateMixin {
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
    final spinning = widget.variant == FlareToastVariant.loading &&
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
    switch (widget.variant) {
      case FlareToastVariant.info:
        return Icons.info;
      case FlareToastVariant.success:
        return Icons.check_circle;
      case FlareToastVariant.error:
        return Icons.error;
      case FlareToastVariant.warning:
        return Icons.warning_amber_rounded;
      case FlareToastVariant.loading:
        return Icons.sync;
    }
  }

  Color _iconColor(FlareColors colors) {
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

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    Widget icon = Icon(_icon, size: 18, color: _iconColor(colors));
    if (widget.variant == FlareToastVariant.loading && _spin != null) {
      icon = RotationTransition(turns: _spin!, child: icon);
    }
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(color: Color(0x2915131C), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 10),
          Flexible(
            child: Text(widget.message,
                style: TextStyle(
                    color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
          ),
          if (widget.actionLabel != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onAction,
              child: Text(widget.actionLabel!,
                  style: TextStyle(
                      color: colors.primary,
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}
