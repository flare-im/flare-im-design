import 'package:flutter/material.dart';

import '../../tokens/flare_tokens.dart';

/// Hold-to-talk voice button (语音). A composable composer part: press and hold
/// to record, release to send, slide up past the threshold to cancel. The host
/// owns the actual recording via the callbacks.
class FlareVoiceHoldButton extends StatefulWidget {
  const FlareVoiceHoldButton({
    super.key,
    this.label = 'Hold to talk',
    this.recordingLabel = 'Release to send · slide up to cancel',
    this.cancelLabel = 'Release to cancel',
    this.cancelThreshold = 80,
    this.onStart,
    this.onEnd,
    this.onCancel,
  });

  final String label;
  final String recordingLabel;

  /// Text shown while sliding up to cancel (host-provided, no baked-in language).
  final String cancelLabel;

  /// Vertical drag (upward) beyond this many logical px cancels the recording.
  final double cancelThreshold;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final VoidCallback? onCancel;

  @override
  State<FlareVoiceHoldButton> createState() => _FlareVoiceHoldButtonState();
}

class _FlareVoiceHoldButtonState extends State<FlareVoiceHoldButton> {
  bool _pressing = false;
  bool _willCancel = false;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final bg = !_pressing
        ? colors.bgSecondary
        : (_willCancel ? colors.error : colors.primary);
    final fg = !_pressing ? colors.textSecondary : Colors.white;

    return GestureDetector(
      onLongPressStart: (_) {
        setState(() {
          _pressing = true;
          _willCancel = false;
        });
        widget.onStart?.call();
      },
      onLongPressMoveUpdate: (d) {
        final cancel = d.offsetFromOrigin.dy < -widget.cancelThreshold;
        if (cancel != _willCancel) setState(() => _willCancel = cancel);
      },
      onLongPressEnd: (_) {
        final cancel = _willCancel;
        setState(() {
          _pressing = false;
          _willCancel = false;
        });
        cancel ? widget.onCancel?.call() : widget.onEnd?.call();
      },
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        ),
        child: Text(
          _pressing
              ? (_willCancel ? widget.cancelLabel : widget.recordingLabel)
              : widget.label,
          style: TextStyle(
              color: fg,
              fontSize: FlareSizes.fontSizeLg,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
