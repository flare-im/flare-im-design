import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'call_stage.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

/// Call state — spec union
/// `'calling' | 'ringing' | 'connected' | 'reconnecting' | 'failed' | 'ended'`.
/// [ended] is the call view's last look before the host closes it.
enum FlareCallState { calling, ringing, connected, reconnecting, failed, ended }

/// In-call screen on the dark call stage — peer video/avatar, state, duration,
/// with [FlareCallControls] below. Spec: Call/CallView (`FlareCallView`),
/// docs/plugin-experience.md §3.3. Video rendering is injected by the host via
/// [videoContent]; the host's own camera goes in [localVideoContent], drawn as
/// the corner preview.
///
/// Without the peer's picture the avatar, name and status sit in the middle
/// of the stage (a breathing halo while calling or ringing); with it they move
/// to the top bar, which fades after 4 s without input (never under reduced
/// motion or a screen reader). The preview can be dragged to any corner, and
/// tapping it swaps the big and small pictures. A failed call swaps the
/// control bar for Close ([onClose], else [onHangup]) and Call again
/// ([onRecover]); an ended call disables every key and announces itself, and
/// the host closes it.
///
/// [onMinimize] draws the collapse control at the top leading corner (the
/// same disc as [FlareGroupCallView]); the host shrinks the call into its
/// [FlareCallDock]. Without it the control is not drawn.
class FlareCallView extends StatefulWidget {
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
    this.controlsDisabled = false,
    this.encrypted = false,
    this.onPickDevices,
    this.videoContent,
    this.localVideoContent,
    this.peerMuted = false,
    this.peerSpeaking = false,
    this.onHangup,
    this.onClose,
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

  /// Host detail under the status line; in the failed state it is the status
  /// line (the reason the call failed).
  final String? statusDetail;

  /// The Call again key's label in the failed state (`callRedial` when null).
  final String? recoveryText;

  /// Call again, in the failed state.
  final VoidCallback? onRecover;
  final String? peerAvatarUrl;
  final bool muted;
  final bool cameraOn;
  final bool speakerOn;
  final bool speakerPicker;

  /// No media session yet: every control but hang-up is disabled.
  final bool controlsDisabled;

  /// Shows the lock and `callEncrypted` in the top bar.
  final bool encrypted;
  final ValueChanged<BuildContext>? onPickDevices;
  final Widget? videoContent;

  /// The host's own camera, drawn as a picture-in-picture in video calls
  /// ([FlareSizes.componentCallPreviewWidth] wide, 9:16), at the top trailing
  /// corner until the user drags it to another.
  final Widget? localVideoContent;

  /// The peer muted their microphone: a mic-off badge after the status line.
  final bool peerMuted;

  /// The peer is speaking: the speaking ring around the avatar (never while
  /// [peerMuted]).
  final bool peerSpeaking;

  /// Hangs up; in the failed state it is also the Close key when [onClose]
  /// is null.
  final VoidCallback? onHangup;

  /// The failed call's Close key.
  final VoidCallback? onClose;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onSwitchCamera;

  /// Shrinks the call into the host's dock; null hides the control.
  final VoidCallback? onMinimize;

  /// Asks the host to turn the audio call into a video call; the "switch to
  /// video" key is drawn in an audio call only when this is supplied.
  final VoidCallback? onStartVideo;

  @override
  State<FlareCallView> createState() => _FlareCallViewState();
}

class _FlareCallViewState extends State<FlareCallView> {
  /// The minimize disc, inside a full touch target.
  static const double _disc = 36;
  static const double _targetInset = (FlareSizes.touchTarget - _disc) / 2;

  /// §3.3: the top bar fades after this long without input (no token).
  static const Duration _idle = Duration(seconds: 4);

  static const double _previewWidth = FlareSizes.componentCallPreviewWidth;
  static const double _previewHeight = _previewWidth * 16 / 9;

  // The host's pictures keep their state when they trade places.
  final GlobalKey _remoteKey = GlobalKey();
  final GlobalKey _localKey = GlobalKey();
  bool _swapped = false;

  /// The preview's corner, and its start/top offset while dragged.
  bool _end = true;
  bool _bottom = false;
  Offset? _drag;

  /// Reduced motion or a screen reader: nothing fades or glides.
  bool _still = false;
  bool _chrome = true;
  Timer? _fade;

  FlareCallView get w => widget;
  bool get _picture => w.mode == FlareCallMode.video && w.videoContent != null;
  bool get _preview =>
      w.mode == FlareCallMode.video && w.localVideoContent != null;
  bool get _fades => !_still && _picture && w.state == FlareCallState.connected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        (MediaQuery.maybeAccessibleNavigationOf(context) ?? false);
    _syncFade();
  }

  @override
  void didUpdateWidget(FlareCallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFade();
  }

  @override
  void dispose() {
    _fade?.cancel();
    super.dispose();
  }

  /// Arms the fade when it applies; otherwise shows the top bar for good.
  /// A running countdown is left alone (the duration ticks every second).
  void _syncFade() {
    if (!_fades) {
      _fade?.cancel();
      _fade = null;
      _chrome = true;
    } else if (_chrome && !(_fade?.isActive ?? false)) {
      _arm();
    }
  }

  void _arm() {
    _fade?.cancel();
    _fade = Timer(_idle, () {
      if (mounted) setState(() => _chrome = false);
    });
  }

  /// Any pointer brings the top bar back and restarts the countdown.
  void _poke() {
    if (!_fades) return;
    _arm();
    if (!_chrome) setState(() => _chrome = true);
  }

  String _statusText(FlareStrings strings) {
    switch (w.state) {
      case FlareCallState.reconnecting:
        return strings.callReconnecting;
      case FlareCallState.failed:
        return w.statusDetail ?? strings.callFailed;
      case FlareCallState.ended:
        return callEndedText(strings, w.durationLabel);
      case FlareCallState.connected:
        return w.durationLabel ?? strings.callConnected;
      case FlareCallState.ringing:
        return strings.callRinging;
      case FlareCallState.calling:
        return w.mode == FlareCallMode.video
            ? strings.callWaitingAnswer
            : strings.callCalling;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final phone = callIsPhone(context);
    final picture = _picture;
    final speaking = w.peerSpeaking && !w.peerMuted;
    final ended = w.state == FlareCallState.ended;
    final ringing =
        w.state == FlareCallState.calling || w.state == FlareCallState.ringing;
    final status = _statusText(strings);
    final detail = w.state == FlareCallState.failed ? null : w.statusDetail;
    final remote = w.videoContent == null
        ? null
        : KeyedSubtree(key: _remoteKey, child: w.videoContent!);
    final local = w.localVideoContent == null
        ? null
        : KeyedSubtree(key: _localKey, child: w.localVideoContent!);
    final swappable = picture && _preview;
    final swapped = _swapped && swappable;
    final big = swapped ? local : (picture ? remote : null);
    final small = _preview ? (swapped ? remote : local) : null;
    final statusStyle = TextStyle(
      // §12.17: a failure on the stage reads in call.errorText.
      color: w.state == FlareCallState.failed
          ? colors.callErrorText
          : colors.callOnStageSecondary,
      fontSize: FlareSizes.fontSizeXl,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Screen readers hear the state when it changes, never the running
    // duration (the status line is not a live region).
    final statusLine = CallAnnouncer(
      message: w.state == FlareCallState.connected
          ? strings.callConnected
          : status,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (w.state == FlareCallState.reconnecting) ...[
            const CallPulseDot(),
            const SizedBox(width: FlareSizes.spacingSm),
          ],
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: statusStyle,
            ),
          ),
          if (w.peerMuted) ...[
            const SizedBox(width: FlareSizes.spacingSm),
            Flexible(child: _peerMuted(strings, colors, statusStyle)),
          ],
        ],
      ),
    );
    final detailText = detail == null
        ? null
        : Text(
            detail,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.callOnStageSecondary,
              fontSize: FlareSizes.fontSizeMd,
            ),
          );
    final centre = picture
        ? const SizedBox.shrink()
        : SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // §3.3: a 3-wide speaking ring, nothing more.
                    boxShadow: speaking
                        ? [
                            BoxShadow(
                              color: colors.callSpeaking,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: CallHalo(
                    color: ringing
                        ? colors.callOnStage.withValues(alpha: .2)
                        : Colors.transparent,
                    breathing: ringing,
                    child: FlareAvatar(
                      userId: w.peerName,
                      displayName: w.peerName,
                      avatarUrl: w.peerAvatarUrl,
                      size: phone
                          ? FlareSizes.componentCallAvatarSize
                          : FlareSizes.componentCallAvatarSizeWindow,
                    ),
                  ),
                ),
                const SizedBox(height: FlareSizes.spacingLg),
                Text(
                  w.peerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.callOnStage,
                    fontSize: phone
                        ? FlareSizes.fontSize5xl
                        : FlareSizes.fontSize4xl,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: FlareSizes.spacingXs),
                statusLine,
                if (detailText != null) ...[
                  const SizedBox(height: FlareSizes.spacingXs),
                  detailText,
                ],
              ],
            ),
          );
    // The top bar and the minimize disc fade together; keyboard focus on a
    // hidden key brings them back, as a pointer does.
    Widget chrome(Widget child) => Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) {
        if (focused) _poke();
      },
      child: IgnorePointer(
        ignoring: !_chrome,
        child: AnimatedOpacity(
          opacity: _chrome ? 1 : 0,
          duration: FlareMotion.slow,
          curve: FlareMotion.slowCurve,
          child: child,
        ),
      ),
    );
    // The top bar's two ends are equally wide, so the name sits in the
    // middle: the start clears the minimize disc, the end holds the
    // encryption caption and clears the window's expand key.
    final windowEnd = CallWindowInsets.endOf(context);
    final side = math.max(
      _disc + FlareSizes.spacingXl,
      windowEnd + (w.encrypted ? FlareSizes.componentActionMinWidth : 0),
    );
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _poke(),
      onPointerHover: (_) => _poke(),
      child: DecoratedBox(
        decoration: callStageDecoration(colors),
        child: Stack(
          children: [
            if (big != null) Positioned.fill(child: big),
            // Reconnecting keeps the last frame, dimmed.
            if (big != null && w.state == FlareCallState.reconnecting)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: colors.callStage.withValues(alpha: FlareOpacity.dim),
                  ),
                ),
              ),
            if (big != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.callStage.withValues(alpha: .6),
                          colors.callStage.withValues(alpha: 0),
                          colors.callStage.withValues(alpha: .73),
                        ],
                        stops: const [0, .45, 1],
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FlareSizes.spacingLg,
                  FlareSizes.spacingLg,
                  FlareSizes.spacingLg,
                  FlareSizes.spacing2xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    chrome(
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: _disc),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: side),
                            Expanded(
                              child: picture
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          w.peerName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: colors.callOnStage,
                                            fontSize: FlareSizes.fontSizeXl,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: FlareSizes.spacingXs,
                                        ),
                                        statusLine,
                                        if (detailText != null) detailText,
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            SizedBox(
                              width: side,
                              child: w.encrypted
                                  ? Padding(
                                      padding: EdgeInsetsDirectional.only(
                                        end: windowEnd,
                                      ),
                                      child: Align(
                                        alignment: AlignmentDirectional.topEnd,
                                        child: _encryptedCaption(
                                          strings,
                                          colors,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, region) => Stack(
                          children: [
                            Positioned.fill(child: Center(child: centre)),
                            if (small != null)
                              _previewIn(
                                region.biggest,
                                small,
                                colors,
                                swappable,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (w.state == FlareCallState.failed)
                      CallFailedKeys(
                        mode: w.mode,
                        onClose: w.onClose ?? w.onHangup,
                        onRedial: w.onRecover,
                        redialText: w.recoveryText,
                      )
                    else
                      FlareCallControls(
                        muted: w.muted,
                        cameraOn: w.cameraOn,
                        speakerOn: w.speakerOn,
                        speakerPicker: w.speakerPicker,
                        onPickDevices: w.onPickDevices,
                        mode: w.mode,
                        disabled: w.controlsDisabled || ended,
                        onToggleMute: w.onToggleMute,
                        onToggleCamera: w.onToggleCamera,
                        onToggleSpeaker: w.onToggleSpeaker,
                        onSwitchCamera: w.onSwitchCamera,
                        onHangup: ended ? null : w.onHangup,
                        onStartVideo: w.onStartVideo,
                      ),
                  ],
                ),
              ),
            ),
            if (w.onMinimize != null)
              SafeArea(
                child: Padding(
                  // The touch target reaches past the disc; the padding gives
                  // the difference back so the disc sits spacingLg from the
                  // edges.
                  padding: const EdgeInsetsDirectional.only(
                    start: FlareSizes.spacingLg - _targetInset,
                    top: FlareSizes.spacingLg - _targetInset,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: chrome(
                      CallFocusRing(
                        diameter: _disc,
                        child: FlareIconControl(
                          label: strings.callMinimize,
                          onTap: w.onMinimize,
                          child: Container(
                            width: _disc,
                            height: _disc,
                            decoration: BoxDecoration(
                              color: colors.callControl,
                              shape: BoxShape.circle,
                            ),
                            child: FlareIcon(
                              'collapse',
                              color: colors.callOnStage,
                              size: FlareSizes.iconSizeMd,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The corner preview inside the stage region between the top bar and the
  /// keys: dragged freely, it snaps to the nearest corner when let go.
  Widget _previewIn(
    Size region,
    Widget small,
    FlareColors colors,
    bool swappable,
  ) {
    final maxX = math.max(0.0, region.width - _previewWidth);
    final maxY = math.max(0.0, region.height - _previewHeight);
    final at = _drag ?? Offset(_end ? maxX : 0, _bottom ? maxY : 0);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget box = ClipRRect(
      borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
      child: SizedBox(
        width: _previewWidth,
        height: _previewHeight,
        child: ColoredBox(color: colors.callStage, child: small),
      ),
    );
    if (swappable) {
      box = FlareIconControl(
        label: FlareStrings.of(context).callSwapVideo,
        tooltip: false,
        onTap: () => setState(() => _swapped = !_swapped),
        child: box,
      );
    }
    return AnimatedPositionedDirectional(
      duration: _drag != null || _still ? Duration.zero : FlareMotion.normal,
      curve: FlareMotion.normalCurve,
      start: at.dx,
      top: at.dy,
      width: _previewWidth,
      height: _previewHeight,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _drag = at),
        onPanUpdate: (d) => setState(() {
          final from = _drag ?? at;
          _drag = Offset(
            math.min(
              maxX,
              math.max(0, from.dx + (rtl ? -d.delta.dx : d.delta.dx)),
            ),
            math.min(maxY, math.max(0, from.dy + d.delta.dy)),
          );
        }),
        onPanEnd: (_) => setState(() {
          final end = _drag ?? at;
          _end = end.dx + _previewWidth / 2 > region.width / 2;
          _bottom = end.dy + _previewHeight / 2 > region.height / 2;
          _drag = null;
        }),
        onPanCancel: () => setState(() => _drag = null),
        child: box,
      ),
    );
  }

  /// The lock and `callEncrypted`, at the top bar's end.
  static Widget _encryptedCaption(FlareStrings strings, FlareColors colors) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlareIcon(
            'lock',
            size: FlareSizes.iconSizeSm,
            color: colors.callOnStageSecondary,
          ),
          const SizedBox(width: FlareSizes.spacingXs),
          Flexible(
            child: Text(
              strings.callEncrypted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.callOnStageSecondary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ),
        ],
      );

  /// mic-off 14 and 「对方已静音」 after the status line, read once.
  static Widget _peerMuted(
    FlareStrings strings,
    FlareColors colors,
    TextStyle style,
  ) => Semantics(
    container: true,
    label: strings.callPeerMuted,
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlareIcon('mic-off', color: style.color, size: FlareSizes.iconSizeXs),
        const SizedBox(width: FlareSizes.spacingXs),
        Flexible(
          child: Text(
            strings.callPeerMuted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    ),
  );
}
