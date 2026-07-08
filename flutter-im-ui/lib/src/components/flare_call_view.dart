import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart';

/// Call state — spec union `'calling' | 'ringing' | 'connected'`.
enum FlareCallState { calling, ringing, connected }

/// In-call screen — peer video/avatar, state, duration, with an overlaid
/// [FlareCallControls]. Spec: Call/CallView (`FlareCallView`). Video rendering is
/// injected by the host via [videoContent].
class FlareCallView extends StatelessWidget {
  const FlareCallView({
    super.key,
    required this.peerName,
    required this.mode,
    required this.state,
    this.durationLabel,
    this.peerAvatarUrl,
    this.muted = false,
    this.cameraOn = true,
    this.speakerOn = false,
    this.videoContent,
    this.onHangup,
    this.onToggleMute,
    this.onToggleCamera,
    this.onToggleSpeaker,
    this.onSwitchCamera,
  });

  final String peerName;
  final FlareCallMode mode;
  final FlareCallState state;
  final String? durationLabel;
  final String? peerAvatarUrl;
  final bool muted;
  final bool cameraOn;
  final bool speakerOn;
  final Widget? videoContent;
  final VoidCallback? onHangup;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onSwitchCamera;

  String get _statusText {
    switch (state) {
      case FlareCallState.connected:
        return durationLabel ?? 'Connected';
      case FlareCallState.ringing:
        return 'Ringing…';
      case FlareCallState.calling:
        return mode == FlareCallMode.video ? 'Waiting for answer…' : 'Calling…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAvatar = mode == FlareCallMode.audio || videoContent == null;
    return Container(
      color: const Color(0xFF111318),
      child: Stack(
        children: [
          if (mode == FlareCallMode.video && videoContent != null)
            Positioned.fill(child: videoContent!),
          Positioned(
            top: 72,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (showAvatar) ...[
                  FlareAvatar(userId: peerName, displayName: peerName, avatarUrl: peerAvatarUrl, size: 96),
                  const SizedBox(height: FlareSizes.spacingMd),
                ],
                Text(peerName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: FlareSizes.fontSize4xl, fontWeight: FontWeight.w600)),
                const SizedBox(height: FlareSizes.spacingXs),
                Text(_statusText,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: FlareSizes.fontSizeLg)),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: FlareCallControls(
                muted: muted,
                cameraOn: cameraOn,
                speakerOn: speakerOn,
                mode: mode,
                onToggleMute: onToggleMute,
                onToggleCamera: onToggleCamera,
                onToggleSpeaker: onToggleSpeaker,
                onSwitchCamera: onSwitchCamera,
                onHangup: onHangup,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
