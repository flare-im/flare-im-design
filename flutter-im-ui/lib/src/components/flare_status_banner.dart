import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Semantic tone for [FlareStatusBanner].
enum FlareStatusTone { info, success, warning, danger, neutral }

/// A compact status strip (connection / sync / runtime state) with an optional
/// pulsing dot and an optional inline action. Replaces per-app bespoke
/// runtime/connection/sync banners. Spec: General/StatusBanner
/// (`FlareStatusBanner`).
class FlareStatusBanner extends StatefulWidget {
  const FlareStatusBanner({
    super.key,
    required this.text,
    this.tone = FlareStatusTone.info,
    this.dot = true,
    this.pulse = false,
    this.actionText,
    this.onAction,
  });

  final String text;
  final FlareStatusTone tone;
  final bool dot;
  final bool pulse;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  State<FlareStatusBanner> createState() => _FlareStatusBannerState();
}

class _FlareStatusBannerState extends State<FlareStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(FlareStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse || widget.dot != oldWidget.dot) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.dot && widget.pulse) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _toneColor(FlareColors colors) {
    switch (widget.tone) {
      case FlareStatusTone.info:
        return colors.info;
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
    final colors = FlareColors.of(Theme.of(context).brightness);
    final tone = _toneColor(colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: tone.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          if (widget.dot) ...[
            _StatusDot(color: tone, controller: _controller, pulse: widget.pulse),
            const SizedBox(width: FlareSizes.spacingSm),
          ],
          Expanded(
            child: Text(
              widget.text,
              style: TextStyle(
                color: tone,
                fontSize: FlareSizes.fontSizeMd,
                height: 1.4,
              ),
            ),
          ),
          if (widget.actionText != null && widget.actionText!.isNotEmpty) ...[
            const SizedBox(width: FlareSizes.spacingSm),
            GestureDetector(
              onTap: widget.onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                widget.actionText!,
                style: TextStyle(
                  color: tone,
                  fontSize: FlareSizes.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  decoration: TextDecoration.underline,
                  decorationColor: tone,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.color,
    required this.controller,
    required this.pulse,
  });

  final Color color;
  final AnimationController controller;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (!pulse) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.35).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: dot,
    );
  }
}
