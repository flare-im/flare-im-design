import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';
import 'icon_control.dart';
import 'voice_waveform.dart';

/// Voice-recording bar — the in-composer pill shown while recording a voice
/// message: a cancel button, a blinking record dot, elapsed duration, a live
/// waveform, and a send button. When [cancelling] the whole pill tints toward
/// the error colour and offers a "Release to cancel" affordance.
/// Spec: Composer/VoiceRecordingBar (`FlareVoiceRecordingBar`).
class FlareVoiceRecordingBar extends StatefulWidget {
  const FlareVoiceRecordingBar({
    super.key,
    required this.durationLabel,
    this.amplitudes = const [],
    this.cancelling = false,
    this.onCancel,
    this.onSend,
  });

  final String durationLabel;
  final List<double> amplitudes;
  final bool cancelling;
  final VoidCallback? onCancel;
  final VoidCallback? onSend;

  @override
  State<FlareVoiceRecordingBar> createState() => _FlareVoiceRecordingBarState();
}

class _FlareVoiceRecordingBarState extends State<FlareVoiceRecordingBar>
    with SingleTickerProviderStateMixin {
  static const int _barCount = 28;
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  List<double> _normalisedAmplitudes() {
    final src = widget.amplitudes;
    final out = List<double>.filled(_barCount, 0);
    for (var i = 0; i < _barCount; i++) {
      if (src.isEmpty) {
        // Fallback sine pattern.
        out[i] = 0.5 + 0.5 * math.sin(i / _barCount * math.pi * 4);
      } else {
        final v = src[i % src.length];
        out[i] = v.clamp(0.0, 1.0);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final cancelling = widget.cancelling;
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final bg = cancelling
        ? colors.error.withValues(alpha: 0.08)
        : colors.bgPrimary;
    final border = cancelling
        ? colors.error.withValues(alpha: 0.5)
        : colors.borderPrimary;
    final waveColor = cancelling
        ? colors.error
        : colors.primary.withValues(alpha: 0.7);
    final amplitudes = _normalisedAmplitudes();

    return Container(
      // Cancel and send are touch targets around 36-point discs; the pill
      // gives the difference back so it keeps its size.
      padding: const EdgeInsets.all(FlareSizes.spacingSm - _targetInset),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F15131C),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Row(
            children: [
              // Cancel button.
              FlareIconControl(
                label: strings.voiceRecordingCancel,
                onTap: widget.onCancel,
                child: Container(
                  width: _disc,
                  height: _disc,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cancelling ? colors.error : colors.bgSecondary,
                  ),
                  child: FlareIcon(
                    'delete',
                    size: 19,
                    color: cancelling ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: FlareSizes.spacingMd - _targetInset),
              // Blinking dot + duration + waveform.
              Expanded(
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: disableAnim
                          ? const AlwaysStoppedAnimation<double>(1)
                          : Tween<double>(begin: 0.25, end: 1).animate(_blink),
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.durationLabel,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Bars thin out rather than overflow when large text leaves
                    // the waveform little room.
                    Expanded(
                      child: FlareVoiceWaveform(
                        levels: amplitudes,
                        color: waveColor,
                        maxHeight: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FlareSizes.spacingMd - _targetInset),
              // Send / release-to-cancel.
              // The label keeps its width unless large text would push it past
              // a share of the pill; then it wraps instead of overflowing.
              if (cancelling)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width * 0.4),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: _targetInset,
                      end: _targetInset + FlareSizes.spacing2xs,
                    ),
                    child: Text(
                      strings.releaseToCancel,
                      style: TextStyle(
                        color: colors.errorText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                FlareIconControl(
                  label: strings.voiceRecordingSend,
                  onTap: widget.onSend,
                  child: Container(
                    width: _disc,
                    height: _disc,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colors.primary,
                          colors.primary.withValues(alpha: 0.82),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const FlareIcon(
                      'send',
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static const double _disc = 36;

  /// How far a control's touch target reaches past its disc on each side.
  static const double _targetInset = (FlareSizes.touchTarget - _disc) / 2;
}
