import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';

/// Audio vs video call — spec union `'audio' | 'video'`.
enum FlareCallMode { audio, video }

/// Call control bar — microphone, camera, speaker, flip, hang up (adapts to
/// audio/video). Each device key is named by its device and announced as on
/// while the device is on. Spec: Call/CallControls (`FlareCallControls`).
///
/// Order: microphone, then camera and flip (video) or speaker and "switch to
/// video" (audio), then add member, then hang up.
class FlareCallControls extends StatelessWidget {
  const FlareCallControls({
    super.key,
    this.muted = false,
    this.cameraOn = true,
    this.speakerOn = false,
    this.speakerPicker = false,
    this.onPickDevices,
    this.mode = FlareCallMode.video,
    this.onToggleMute,
    this.onToggleCamera,
    this.onToggleSpeaker,
    this.onSwitchCamera,
    this.onHangup,
    this.onAddMember,
    this.onStartVideo,
  });

  final bool muted;
  final bool cameraOn;
  final bool speakerOn;
  final bool speakerPicker;
  final ValueChanged<BuildContext>? onPickDevices;
  final FlareCallMode mode;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onHangup;

  /// Invite-to-call key; rendered before hang-up only when the host supplies it.
  final VoidCallback? onAddMember;

  /// "Switch to video" key: asks the host to turn the audio call into a video
  /// call. Rendered after the speaker in an audio call, only when supplied.
  final VoidCallback? onStartVideo;

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: FlareSizes.spacingLg,
      runSpacing: FlareSizes.spacingLg,
      children: [
        // A device key is named by its device and is "on" while the device
        // is; the filled look marks the state worth noticing (muted, camera
        // off, speaker on).
        _ctrl(
          context,
          muted ? 'mic-off' : 'mic',
          strings.microphone,
          onToggleMute,
          active: muted,
          deviceOn: !muted,
        ),
        if (mode == FlareCallMode.video) ...[
          _ctrl(
            context,
            cameraOn ? 'video' : 'camera-off',
            strings.camera,
            onToggleCamera,
            active: !cameraOn,
            deviceOn: cameraOn,
          ),
          _ctrl(context, 'switch-camera', strings.flipCamera, onSwitchCamera),
        ],
        Builder(
          builder: (anchorContext) => _ctrl(
            anchorContext,
            speakerPicker || speakerOn ? 'speaker' : 'speaker-off',
            strings.speaker,
            onPickDevices == null
                ? onToggleSpeaker
                : () => onPickDevices!(anchorContext),
            active: !speakerPicker && speakerOn,
            deviceOn: speakerPicker ? null : speakerOn,
          ),
        ),
        if (mode == FlareCallMode.audio && onStartVideo != null)
          _ctrl(context, 'video', strings.callSwitchToVideo, onStartVideo),
        if (onAddMember != null)
          _ctrl(context, 'person-add', strings.addMember, onAddMember),
        _hangup(context, strings.hangUp),
      ],
    );
  }

  /// A call key. A device key (microphone, camera, speaker) passes [deviceOn],
  /// announced as its toggled state; [active] fills the key.
  Widget _ctrl(
    BuildContext context,
    String icon,
    String label,
    VoidCallback? onTap, {
    bool active = false,
    bool? deviceOn,
  }) {
    final colors = FlareColors.of(context);
    final audio = mode == FlareCallMode.audio;
    return SizedBox(
      width: FlareSizes.controlHeightMd * 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: label,
            button: true,
            enabled: onTap != null,
            toggled: deviceOn,
            onTap: onTap,
            child: ExcludeSemantics(
              child: IconButton(
                onPressed: onTap,
                tooltip: label,
                style: IconButton.styleFrom(
                  minimumSize: const Size(56, 56),
                  backgroundColor: audio
                      ? (active ? colors.bgSelected : colors.bgSecondary)
                      : active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.16),
                  foregroundColor: audio
                      ? (active ? colors.primaryText : colors.textPrimary)
                      : active
                      ? Colors.black
                      : Colors.white,
                ),
                icon: Icon(flareIconGlyph(icon)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: audio
                    ? colors.textSecondary
                    : Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hangup(BuildContext context, String label) {
    return Semantics(
      label: label,
      button: true,
      enabled: onHangup != null,
      onTap: onHangup,
      child: ExcludeSemantics(
        child: IconButton(
          onPressed: onHangup,
          tooltip: label,
          style: IconButton.styleFrom(
            minimumSize: const Size(56, 56),
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          icon: Icon(flareIconGlyph('end-call')),
        ),
      ),
    );
  }
}
