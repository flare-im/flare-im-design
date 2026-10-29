import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

/// Call state — spec union `'calling' | 'ringing' | 'connected' | 'reconnecting' | 'failed'`.
enum FlareCallState { calling, ringing, connected, reconnecting, failed }

/// In-call screen — peer video/avatar, state, duration, with an overlaid
/// [FlareCallControls]. Spec: Call/CallView (`FlareCallView`). Video rendering is
/// injected by the host via [videoContent].
///
/// [onMinimize] draws the collapse control at the top leading corner (the
/// same disc as [FlareGroupCallView]); the host shrinks the call into its
/// [FlareCallDock]. Without it the control is not drawn.
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
    this.onMinimize,
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

  /// Shrinks the call into the host's dock; null hides the control.
  final VoidCallback? onMinimize;

  /// The minimize disc, inside a full touch target.
  static const double _disc = 36;
  static const double _targetInset = (FlareSizes.touchTarget - _disc) / 2;

  String _statusText(FlareStrings strings) {
    switch (state) {
      case FlareCallState.reconnecting:
        return strings.callReconnecting;
      case FlareCallState.failed:
        return strings.callFailed;
      case FlareCallState.connected:
        return durationLabel ?? strings.callConnected;
      case FlareCallState.ringing:
        return strings.callRinging;
      case FlareCallState.calling:
        return mode == FlareCallMode.video
            ? strings.callWaitingAnswer
            : strings.callCalling;
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
                        _statusText(FlareStrings.of(context)),
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
          if (onMinimize != null)
            SafeArea(
              child: Padding(
                // The touch target reaches past the disc; the padding gives
                // the difference back so the disc sits spacingLg from the edges.
                padding: const EdgeInsetsDirectional.only(
                  start: FlareSizes.spacingLg - _targetInset,
                  top: FlareSizes.spacingLg - _targetInset,
                ),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: FlareIconControl(
                    label: FlareStrings.of(context).callMinimize,
                    onTap: onMinimize,
                    child: Container(
                      width: _disc,
                      height: _disc,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const FlareIcon(
                        'collapse',
                        color: Colors.white,
                        size: FlareSizes.iconSizeMd,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
