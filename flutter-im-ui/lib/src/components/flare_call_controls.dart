import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Audio vs video call — spec union `'audio' | 'video'`.
enum FlareCallMode { audio, video }

/// Call control bar — mute, camera, speaker, flip, hang up (adapts to
/// audio/video). Spec: Call/CallControls (`FlareCallControls`).
class FlareCallControls extends StatelessWidget {
  const FlareCallControls({
    super.key,
    this.muted = false,
    this.cameraOn = true,
    this.speakerOn = false,
    this.mode = FlareCallMode.video,
    this.onToggleMute,
    this.onToggleCamera,
    this.onToggleSpeaker,
    this.onSwitchCamera,
    this.onHangup,
  });

  final bool muted;
  final bool cameraOn;
  final bool speakerOn;
  final FlareCallMode mode;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onHangup;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: FlareSizes.spacingLg,
      runSpacing: FlareSizes.spacingLg,
      children: [
        _ctrl(
          muted ? Icons.mic_off : Icons.mic_none,
          'Microphone',
          muted,
          onToggleMute,
        ),
        if (mode == FlareCallMode.video) ...[
          _ctrl(
            cameraOn ? Icons.videocam_outlined : Icons.videocam_off_outlined,
            'Camera',
            !cameraOn,
            onToggleCamera,
          ),
          _ctrl(Icons.cameraswitch, 'Flip', false, onSwitchCamera),
        ] else
          _ctrl(
            Icons.volume_up_outlined,
            'Speaker',
            speakerOn,
            onToggleSpeaker,
          ),
        _hangup(),
      ],
    );
  }

  Widget _ctrl(IconData icon, String label, bool on, VoidCallback? onTap) {
    return SizedBox(
      width: 104,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            toggled: on,
            child: IconButton(
              onPressed: onTap,
              tooltip: label,
              style: IconButton.styleFrom(
                minimumSize: const Size(56, 56),
                backgroundColor: on
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.16),
                foregroundColor: on ? Colors.black : Colors.white,
              ),
              icon: Icon(icon),
            ),
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hangup() {
    return IconButton(
      onPressed: onHangup,
      tooltip: 'Hang up',
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.call_end),
    );
  }
}
