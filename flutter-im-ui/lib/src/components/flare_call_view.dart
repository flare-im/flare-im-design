import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart';

/// Call state — spec union `'calling' | 'ringing' | 'connected' | 'reconnecting' | 'failed'`.
enum FlareCallState { calling, ringing, connected, reconnecting, failed }

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
    this.statusDetail,
    this.recoveryText,
    this.onRecover,
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
  final String? statusDetail;
  final String? recoveryText;
  final VoidCallback? onRecover;
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
      case FlareCallState.reconnecting:
        return 'Reconnecting call…';
      case FlareCallState.failed:
        return 'Call connection failed';
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 48),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    if (showAvatar) ...[
                      FlareAvatar(
                        userId: peerName,
                        displayName: peerName,
                        avatarUrl: peerAvatarUrl,
                        size: 96,
                      ),
                      const SizedBox(height: FlareSizes.spacingMd),
                    ],
                    Text(
                      peerName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: FlareSizes.fontSize4xl,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: FlareSizes.spacingXs),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: FlareSizes.fontSizeLg,
                        ),
                      ),
                    ),
                    if (statusDetail != null)
                      Text(
                        statusDetail!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (state == FlareCallState.failed && recoveryText != null)
                      TextButton(
                        onPressed: onRecover,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(recoveryText!),
                      ),
                    const SizedBox(height: 32),
                    FlareCallControls(
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
