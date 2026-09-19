import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';

/// Audio vs video call — spec union `'audio' | 'video'`.
enum FlareCallMode { audio, video }

/// Call control bar — microphone, camera, speaker, flip, hang up (adapts to
/// audio/video). Each device key is named by its device and announced as on
/// while the device is on. Spec: Call/CallControls (`FlareCallControls`).
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
    this.onAddMember,
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

  /// Invite-to-call key; rendered before hang-up only when the host supplies it.
  final VoidCallback? onAddMember;

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
          muted ? 'mic-off' : 'mic',
          strings.microphone,
          onToggleMute,
          active: muted,
          deviceOn: !muted,
        ),
        if (mode == FlareCallMode.video) ...[
          _ctrl(
            cameraOn ? 'video' : 'camera-off',
            strings.camera,
            onToggleCamera,
            active: !cameraOn,
            deviceOn: cameraOn,
          ),
          _ctrl('switch-camera', strings.flipCamera, onSwitchCamera),
        ] else
          _ctrl(
            speakerOn ? 'speaker' : 'speaker-off',
            strings.speaker,
            onToggleSpeaker,
            active: speakerOn,
            deviceOn: speakerOn,
          ),
        if (onAddMember != null)
          _ctrl('person-add', strings.addMember, onAddMember),
        _hangup(strings.hangUp),
      ],
    );
  }

  /// A call key. A device key (microphone, camera, speaker) passes [deviceOn],
  /// announced as its toggled state; [active] fills the key.
  Widget _ctrl(
    String icon,
    String label,
    VoidCallback? onTap, {
    bool active = false,
    bool? deviceOn,
  }) {
    return SizedBox(
      width: 104,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onTap,
            tooltip: label,
            style: IconButton.styleFrom(
              minimumSize: const Size(56, 56),
              backgroundColor: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.16),
              foregroundColor: active ? Colors.black : Colors.white,
            ),
            // Inside the button, so the state lands on the button's own node.
            icon: Semantics(
              toggled: deviceOn,
              child: Icon(flareIconGlyph(icon)),
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

  Widget _hangup(String label) {
    return IconButton(
      onPressed: onHangup,
      tooltip: label,
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
      ),
      icon: Icon(flareIconGlyph('end-call')),
    );
  }
}
