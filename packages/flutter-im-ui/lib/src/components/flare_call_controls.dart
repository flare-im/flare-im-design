import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'call_stage.dart';

/// Audio vs video call — spec union `'audio' | 'video'`.
enum FlareCallMode { audio, video }

/// Call control bar — microphone, camera, speaker, flip, hang up (adapts to
/// audio/video), drawn on the dark call stage. Each device key is a switch
/// named by its device and announced as on while the device is on. Spec:
/// Call/CallControls (`FlareCallControls`), docs/plugin-experience.md §3.3.
///
/// Order: microphone, speaker (or devices), camera and flip (flip on phone
/// video only) or "switch to video" (audio), add member, hang up; every key,
/// hang-up included, has its 12 caption under it. Keys stand spacingLg apart
/// on phones and spacing2xl on PC. Phones fit one row and never wrap; with
/// more than four keys before hang-up, hang-up gets its own centred row. On
/// desktop,
/// M toggles the microphone, V the camera and Ctrl/⌘+Shift+H hangs up; the
/// tooltips say so.
class FlareCallControls extends StatelessWidget {
  const FlareCallControls({
    super.key,
    this.muted = false,
    this.cameraOn = true,
    this.speakerOn = false,
    this.speakerPicker = false,
    this.onPickDevices,
    this.mode = FlareCallMode.video,
    this.disabled = false,
    this.showAddMember,
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

  /// No media session yet: every key but hang-up is disabled, drawn at
  /// [FlareOpacity.disabled].
  final bool disabled;

  /// Draws the add-member key; null draws it whenever [onAddMember] is given.
  final bool? showAddMember;
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
    final phone = callIsPhone(context);
    final keyboard = flareCapabilitiesOf(context).keyboardShortcut;
    final mac = flareTargetPlatform == TargetPlatform.macOS;
    String hint(String label, String keys) =>
        keyboard ? '$label ($keys)' : label;
    VoidCallback? live(VoidCallback? onTap) => disabled ? null : onTap;
    final gap = phone ? FlareSizes.spacingLg : FlareSizes.spacing2xl;
    // §3.3 order: microphone, speaker or devices, camera, flip (phone video
    // only), switch to video, add member, hang up.
    final toggles = <Widget>[
      // A device key is named by its device and is "on" while the device
      // is; the filled look marks the state worth noticing (muted, camera
      // off, speaker on).
      _ctrl(
        context,
        muted ? 'mic-off' : 'mic',
        strings.microphone,
        live(onToggleMute),
        tooltip: hint(strings.microphone, 'M'),
        active: muted,
        deviceOn: !muted,
      ),
      Builder(
        builder: (anchorContext) => _ctrl(
          anchorContext,
          speakerPicker || speakerOn ? 'speaker' : 'speaker-off',
          strings.speaker,
          live(
            onPickDevices == null
                ? onToggleSpeaker
                : () => onPickDevices!(anchorContext),
          ),
          active: !speakerPicker && speakerOn,
          deviceOn: speakerPicker ? null : speakerOn,
        ),
      ),
      if (mode == FlareCallMode.video) ...[
        _ctrl(
          context,
          cameraOn ? 'video' : 'camera-off',
          strings.camera,
          live(onToggleCamera),
          tooltip: hint(strings.camera, 'V'),
          active: !cameraOn,
          deviceOn: cameraOn,
        ),
        if (phone)
          _ctrl(
            context,
            'switch-camera',
            strings.flipCamera,
            live(onSwitchCamera),
          ),
      ],
      if (mode == FlareCallMode.audio && onStartVideo != null)
        _ctrl(context, 'video', strings.callSwitchToVideo, live(onStartVideo)),
      if (showAddMember ?? onAddMember != null)
        _ctrl(context, 'person-add', strings.addMember, live(onAddMember)),
    ];
    final ownRow = phone && toggles.length > 4;
    final hangup = _hangup(
      context,
      strings.hangUp,
      hint(strings.hangUp, mac ? '⌘⇧H' : 'Ctrl+Shift+H'),
      ownRow
          ? FlareSizes.componentCallHangupSize
          : FlareSizes.componentCallControlSize,
    );
    Widget bar;
    if (phone) {
      // Phones never wrap: up to four keys and hang-up in one centred row,
      // more keys in one row over a centred hang-up. Each column is one gap
      // wider than its disc, so discs stand spacingLg apart; a screen too
      // narrow for that shrinks the slack, never the discs.
      Widget row(List<Widget> keys) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in keys)
            Flexible(
              child: SizedBox(
                width: FlareSizes.componentCallControlSize + gap,
                child: key,
              ),
            ),
        ],
      );
      bar = ownRow
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                row(toggles),
                const SizedBox(height: FlareSizes.spacingLg),
                hangup,
              ],
            )
          : row([...toggles, hangup]);
    } else {
      // Each key sits in a column one spacingSm wider than its disc, so the
      // Wrap's spacing plus that slack is the gap between discs; hang-up
      // stands one more gap apart.
      Widget slot(Widget key) => SizedBox(
        width: FlareSizes.componentCallControlSize + FlareSizes.spacingSm,
        child: key,
      );
      bar = Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: gap - FlareSizes.spacingSm,
        runSpacing: FlareSizes.spacingLg,
        children: [
          for (final key in toggles) slot(key),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: FlareSizes.spacing2xl,
            ),
            child: slot(hangup),
          ),
        ],
      );
    }
    if (keyboard) {
      // Single keys only while focus is in the call; hang-up needs three keys
      // so it is never pressed by accident.
      bar = CallbackShortcuts(
        bindings: {
          if (live(onToggleMute) != null)
            const SingleActivator(LogicalKeyboardKey.keyM): onToggleMute!,
          if (mode == FlareCallMode.video && live(onToggleCamera) != null)
            const SingleActivator(LogicalKeyboardKey.keyV): onToggleCamera!,
          if (onHangup != null) ...{
            const SingleActivator(
              LogicalKeyboardKey.keyH,
              control: true,
              shift: true,
            ): onHangup!,
            const SingleActivator(
              LogicalKeyboardKey.keyH,
              meta: true,
              shift: true,
            ): onHangup!,
          },
        },
        child: Focus(autofocus: true, child: bar),
      );
    }
    return bar;
  }

  /// A call key. A device key (microphone, camera, speaker) passes [deviceOn],
  /// announced as its toggled state; [active] fills the key.
  Widget _ctrl(
    BuildContext context,
    String icon,
    String label,
    VoidCallback? onTap, {
    String? tooltip,
    bool active = false,
    bool? deviceOn,
  }) {
    final colors = FlareColors.of(context);
    const size = FlareSizes.componentCallControlSize;
    return Opacity(
      opacity: onTap == null ? FlareOpacity.disabled : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _key(
            label: label,
            tooltip: tooltip ?? label,
            icon: icon,
            onTap: onTap,
            size: size,
            toggled: deviceOn,
            background: active ? colors.callControlActive : colors.callControl,
            pressed: active
                ? colors.callControlActive
                : colors.callControlHover,
            foreground: active
                ? colors.callOnControlActive
                : colors.callOnStage,
          ),
          const SizedBox(height: FlareSizes.spacingXs),
          _label(colors, label),
        ],
      ),
    );
  }

  /// A key's caption under its disc; the key itself carries the name.
  Widget _label(FlareColors colors, String label) => ExcludeSemantics(
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colors.callOnStageSecondary,
        fontSize: FlareSizes.fontSizeSm,
      ),
    ),
  );

  Widget _hangup(
    BuildContext context,
    String label,
    String tooltip,
    double size,
  ) {
    final colors = FlareColors.of(context);
    // Centred across, its own height down: in the phone row it tops-aligns
    // with the other keys instead of filling the bar's height.
    return Center(
      heightFactor: 1,
      child: Opacity(
        opacity: onHangup == null ? FlareOpacity.disabled : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _key(
              label: label,
              tooltip: tooltip,
              icon: 'end-call',
              onTap: onHangup,
              size: size,
              background: colors.callHangup,
              pressed: colors.callHangupPressed,
              foreground: colors.callOnStage,
            ),
            const SizedBox(height: FlareSizes.spacingXs),
            _label(colors, label),
          ],
        ),
      ),
    );
  }

  /// A round key: hover / press darken it, keyboard focus rings it.
  Widget _key({
    required String label,
    required String tooltip,
    required String icon,
    required VoidCallback? onTap,
    required double size,
    required Color background,
    required Color pressed,
    required Color foreground,
    bool? toggled,
  }) => Semantics(
    label: label,
    button: true,
    enabled: onTap != null,
    toggled: toggled,
    onTap: onTap,
    child: ExcludeSemantics(
      child: CallFocusRing(
        diameter: size,
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          style: ButtonStyle(
            fixedSize: WidgetStatePropertyAll(Size.square(size)),
            minimumSize: WidgetStatePropertyAll(Size.square(size)),
            shape: const WidgetStatePropertyAll(CircleBorder()),
            iconSize: const WidgetStatePropertyAll(FlareSizes.iconSizeLg),
            foregroundColor: WidgetStatePropertyAll(foreground),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.pressed) ||
                      states.contains(WidgetState.hovered)
                  ? pressed
                  : background,
            ),
          ),
          icon: Icon(flareIconGlyph(icon)),
        ),
      ),
    ),
  );
}
