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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ctrl(muted ? Icons.mic_off : Icons.mic_none, '麦克风', muted, onToggleMute),
        const SizedBox(width: FlareSizes.spacingLg),
        if (mode == FlareCallMode.video) ...[
          _ctrl(cameraOn ? Icons.videocam_outlined : Icons.videocam_off_outlined, '摄像头', !cameraOn, onToggleCamera),
          const SizedBox(width: FlareSizes.spacingLg),
          _ctrl(Icons.cameraswitch, '翻转', false, onSwitchCamera),
        ] else
          _ctrl(Icons.volume_up_outlined, '扬声器', speakerOn, onToggleSpeaker),
        const SizedBox(width: FlareSizes.spacingLg),
        _hangup(),
      ],
    );
  }

  Widget _ctrl(IconData icon, String label, bool on, VoidCallback? onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: on ? Colors.white : Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: on ? Colors.black : Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
      ],
    );
  }

  Widget _hangup() {
    return GestureDetector(
      onTap: onHangup,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
        child: const Icon(Icons.call_end, color: Colors.white),
      ),
    );
  }
}
