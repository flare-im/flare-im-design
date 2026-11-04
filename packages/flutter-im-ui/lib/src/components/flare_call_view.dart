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
/// injected by the host via [videoContent]; the host's own camera goes in
/// [localVideoContent], drawn as the corner preview.
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
    this.speakerPicker = false,
    this.onPickDevices,
    this.videoContent,
    this.localVideoContent,
    this.peerMuted = false,
    this.peerSpeaking = false,
    this.onHangup,
    this.onToggleMute,
    this.onToggleCamera,
    this.onToggleSpeaker,
    this.onSwitchCamera,
    this.onMinimize,
    this.onStartVideo,
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
  final bool speakerPicker;
  final ValueChanged<BuildContext>? onPickDevices;
  final Widget? videoContent;

  /// The host's own camera, drawn as a picture-in-picture at the top trailing
  /// corner in video calls ([FlareSizes.componentCallPreviewWidth] wide, 3:4).
  final Widget? localVideoContent;

  /// The peer muted their microphone: a mic-off badge beside the name.
  final bool peerMuted;

  /// The peer is speaking: the speaking ring around the avatar (never while
  /// [peerMuted]).
  final bool peerSpeaking;
  final VoidCallback? onHangup;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onSwitchCamera;

  /// Shrinks the call into the host's dock; null hides the control.
  final VoidCallback? onMinimize;

  /// Asks the host to turn the audio call into a video call; the "switch to
  /// video" key is drawn in an audio call only when this is supplied.
  final VoidCallback? onStartVideo;

  /// The minimize disc, inside a full touch target.
  static const double _disc = 36;
  static const double _targetInset = (FlareSizes.touchTarget - _disc) / 2;

  /// The corner preview's height and its inset above and below.

  /// The [FlareGroupCallView] tile's speaking green.
  static const Color _speakingColor = Color(0xFF34D17F);

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
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final ink = mode == FlareCallMode.audio ? colors.textPrimary : Colors.white;
    final secondary = mode == FlareCallMode.audio
        ? colors.textSecondary
        : Colors.white.withValues(alpha: .7);
    final showAvatar = mode == FlareCallMode.audio || videoContent == null;
    final speaking = peerSpeaking && !peerMuted;
    final preview = mode == FlareCallMode.video && localVideoContent != null;
    return Container(
      color: mode == FlareCallMode.audio
          ? colors.bgPrimary
          : const Color(0xFF111318),
      child: Stack(
        children: [
          if (mode == FlareCallMode.video && videoContent != null)
            Positioned.fill(child: videoContent!),
          if (mode == FlareCallMode.video)
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99000000),
                        Color(0x00000000),
                        Color(0xBB000000),
                      ],
                      stops: [0, .45, 1],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: 56,
                      end: preview ? 128 : 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                peerName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: FlareSizes.fontSizeXl,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (peerMuted) ...[
                              const SizedBox(width: FlareSizes.spacingSm),
                              _mutedBadge(strings),
                            ],
                          ],
                        ),
                        const SizedBox(height: FlareSizes.spacingXs),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _statusText(strings),
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: secondary,
                              fontSize: FlareSizes.fontSizeLg,
                            ),
                          ),
                        ),
                        if (statusDetail != null)
                          Text(
                            statusDetail!,
                            textAlign: TextAlign.start,
                            style: TextStyle(color: ink),
                          ),
                        if (state == FlareCallState.failed &&
                            recoveryText != null)
                          TextButton(
                            onPressed: onRecover,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: ink,
                            ),
                            child: Text(recoveryText!),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: showAvatar
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: speaking
                                    ? [
                                        const BoxShadow(
                                          color: _speakingColor,
                                          spreadRadius: 3,
                                        ),
                                        BoxShadow(
                                          color: _speakingColor.withValues(
                                            alpha: 0.28,
                                          ),
                                          spreadRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: FlareAvatar(
                                userId: peerName,
                                displayName: peerName,
                                avatarUrl: peerAvatarUrl,
                                size: 96,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  FlareCallControls(
                    muted: muted,
                    cameraOn: cameraOn,
                    speakerOn: speakerOn,
                    speakerPicker: speakerPicker,
                    onPickDevices: onPickDevices,
                    mode: mode,
                    onToggleMute: onToggleMute,
                    onToggleCamera: onToggleCamera,
                    onToggleSpeaker: onToggleSpeaker,
                    onSwitchCamera: onSwitchCamera,
                    onHangup: onHangup,
                    onStartVideo: onStartVideo,
                  ),
                ],
              ),
            ),
          ),
          if (preview)
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: FlareSizes.spacingLg,
                    end: FlareSizes.spacingLg,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
                    child: SizedBox(
                      width: FlareSizes.componentCallPreviewWidth,
                      height: FlareSizes.componentCallPreviewWidth * 4 / 3,
                      child: ColoredBox(
                        color: Colors.black,
                        child: localVideoContent,
                      ),
                    ),
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
                    label: strings.callMinimize,
                    onTap: onMinimize,
                    child: Container(
                      width: _disc,
                      height: _disc,
                      decoration: BoxDecoration(
                        color: mode == FlareCallMode.audio
                            ? colors.bgSecondary
                            : Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: FlareIcon(
                        'collapse',
                        color: ink,
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

  /// The [FlareGroupCallView] tile's mute badge, named for screen readers.
  Widget _mutedBadge(FlareStrings strings) => Semantics(
    label: strings.callPeerMuted,
    image: true,
    excludeSemantics: true,
    child: Container(
      width: FlareSizes.iconSizeMd,
      height: FlareSizes.iconSizeMd,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
      ),
      child: const FlareIcon('mic-off', color: Colors.white, size: 12),
    ),
  );
}
