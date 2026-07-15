import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Voice-message player bubble — a play/pause control, a seekable waveform, an
/// elapsed/total time readout, a playback-speed pill, and an optional
/// speech-to-text transcript. Renders as an inbound bubble by default; when
/// [outbound] it tints toward the brand selection colour and mirrors its
/// corner radius. Spec: Message/VoicePlayer (`FlareVoicePlayer`).
class FlareVoicePlayer extends StatelessWidget {
  const FlareVoicePlayer({
    super.key,
    required this.durationLabel,
    this.elapsedLabel,
    this.progress = 0,
    this.playing = false,
    this.amplitudes = const [],
    this.speed = 1,
    this.transcript,
    this.transcriptOpen = false,
    this.unplayed = false,
    this.outbound = false,
    this.onToggle,
    this.onSeek,
    this.onCycleSpeed,
    this.onToggleTranscript,
  });

  final String durationLabel;
  final String? elapsedLabel;
  final double progress;
  final bool playing;
  final List<double> amplitudes;
  final double speed;
  final String? transcript;
  final bool transcriptOpen;
  final bool unplayed;
  final bool outbound;
  final VoidCallback? onToggle;
  final void Function(double ratio)? onSeek;
  final VoidCallback? onCycleSpeed;
  final VoidCallback? onToggleTranscript;

  static const int _barCount = 32;

  List<double> _bars() {
    final out = List<double>.filled(_barCount, 0);
    for (var i = 0; i < _barCount; i++) {
      if (amplitudes.isEmpty) {
        out[i] = 0.5 + 0.5 * math.sin(i / _barCount * math.pi * 4);
      } else {
        out[i] = amplitudes[i % amplitudes.length].clamp(0.0, 1.0);
      }
    }
    return out;
  }

  String _speedLabel() {
    if (speed == speed.roundToDouble()) {
      return '${speed.toInt()}×';
    }
    return '${speed.toStringAsFixed(1)}×';
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final bg = outbound
        ? colors.bgSelected
        : colors.bgPrimary;
    final border = outbound
        ? colors.primary.withValues(alpha: 0.24)
        : colors.borderPrimary;
    final radius = outbound
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          );

    final timeLabel =
        (playing && elapsedLabel != null) ? elapsedLabel! : durationLabel;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _playButton(colors),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(child: _waveform(colors)),
              const SizedBox(width: FlareSizes.spacingSm),
              Text(
                timeLabel,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: FlareSizes.spacingSm),
              _speedPill(colors),
            ],
          ),
          if (transcript != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onToggleTranscript,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 14, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    transcriptOpen ? 'Hide text' : 'To text',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: FlareSizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (transcriptOpen)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colors.borderPrimary,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: Text(
                  transcript!,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: FlareSizes.lineHeightNormal,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _playButton(FlareColors colors) {
    return GestureDetector(
      onTap: onToggle,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primary.withValues(alpha: 0.82)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                playing ? Icons.pause : Icons.play_arrow,
                size: 20,
                color: Colors.white,
              ),
            ),
            if (unplayed && !playing)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.error,
                    border: Border.all(color: colors.bgPrimary, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _waveform(FlareColors colors) {
    final bars = _bars();
    final filled = (progress.clamp(0.0, 1.0) * _barCount).round();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onSeek == null
              ? null
              : (details) {
                  final ratio = (details.localPosition.dx / width)
                      .clamp(0.0, 1.0);
                  onSeek!(ratio);
                },
          child: SizedBox(
            height: 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _barCount; i++)
                  Container(
                    width: 2.5,
                    height: 4 + bars[i] * 18,
                    decoration: BoxDecoration(
                      color: i < filled ? colors.primary : colors.borderHover,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _speedPill(FlareColors colors) {
    return GestureDetector(
      onTap: onCycleSpeed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
          border: Border.all(color: colors.borderPrimary),
        ),
        child: Text(
          _speedLabel(),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: FlareSizes.fontSizeXs,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
