import 'package:flutter/material.dart';

import '../../models/haptics.dart';

import '../../tokens/flare_strings.dart';
import '../../tokens/flare_tokens.dart';

/// Hold-to-talk voice button (语音). A composable composer part: press and hold
/// to record, release to send, slide up past the threshold to cancel. The host
/// owns the actual recording via the callbacks.
class FlareVoiceHoldButton extends StatefulWidget {
  const FlareVoiceHoldButton({
    super.key,
    this.label,
    this.recordingLabel,
    this.cancelLabel,
    this.cancelThreshold = 80,
    this.onStart,
    this.onEnd,
    this.onCancel,
  });

  final String? label;
  final String? recordingLabel;

  /// Text shown while sliding up to cancel (host-provided, no baked-in language).
  final String? cancelLabel;

  /// Vertical drag (upward) beyond this many logical px cancels the recording.
  final double cancelThreshold;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final VoidCallback? onCancel;

  @override
  State<FlareVoiceHoldButton> createState() => _FlareVoiceHoldButtonState();
}

class _FlareVoiceHoldButtonState extends State<FlareVoiceHoldButton> {
  String get _label => widget.label ?? FlareStrings.of(context).composerVoice;
  String get _recordingLabel =>
      widget.recordingLabel ?? FlareStrings.of(context).composerVoiceRecording;
  String get _cancelLabel =>
      widget.cancelLabel ?? FlareStrings.of(context).composerVoiceCancel;
  bool _pressing = false;
  bool _willCancel = false;
  double _originDy = 0;

  void _finish() {
    if (!_pressing) return;
    final cancel = _willCancel;
    setState(() {
      _pressing = false;
      _willCancel = false;
    });
    cancel ? widget.onCancel?.call() : widget.onEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final bg = !_pressing
        ? colors.bgSecondary
        : (_willCancel ? colors.error : colors.primary);
    final fg = !_pressing ? colors.textSecondary : Colors.white;

    // Recording starts on the *immediate* press (no long-press delay), matching
    // iOS/Android: pointer-down → onStart, move up past the threshold → cancel
    // state, release → onEnd / onCancel.
    return Listener(
      onPointerDown: (e) {
        _originDy = e.position.dy;
        setState(() {
          _pressing = true;
          _willCancel = false;
        });
        widget.onStart?.call();
      },
      onPointerMove: (e) {
        if (!_pressing) return;
        final cancel = (e.position.dy - _originDy) < -widget.cancelThreshold;
        // Sliding past the line changes what letting go means, so it is felt as well as seen.
        if (flareHapticCrossed(was: _willCancel, now: cancel))
          flareHapticTick();
        if (cancel != _willCancel) setState(() => _willCancel = cancel);
      },
      onPointerUp: (_) => _finish(),
      onPointerCancel: (_) => _finish(),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        ),
        child: Text(
          _pressing ? (_willCancel ? _cancelLabel : _recordingLabel) : _label,
          style: TextStyle(
            color: fg,
            fontSize: FlareSizes.fontSizeLg,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
