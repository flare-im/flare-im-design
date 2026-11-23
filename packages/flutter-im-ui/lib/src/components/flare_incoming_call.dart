import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'call_stage.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

/// How an incoming call is shown — spec union `'fullscreen' | 'banner'`.
/// [banner] is the PC's non-modal card at the window's top trailing corner.
enum FlareIncomingCallPresentation { fullscreen, banner }

/// Incoming call / invite — caller avatar/name, audio/video kind, accept &
/// reject, on the dark call stage. Spec: Call/IncomingCall
/// (`FlareIncomingCall`), docs/plugin-experience.md §3.2.
///
/// [FlareIncomingCallPresentation.fullscreen] (phones, the default) breathes a
/// halo around the caller and puts focus on accept;
/// [FlareIncomingCallPresentation.banner] (PC) sits at the top trailing corner
/// and leaves focus where the user is working. Either way the invitation is
/// announced when it appears, and a video invitation adds "answer with
/// audio" when [onAcceptAudio] is given. The banner never takes focus, so a
/// stray Enter in the page never answers; a key the user tabbed to answers
/// to Space and Enter.
class FlareIncomingCall extends StatefulWidget {
  const FlareIncomingCall({
    super.key,
    required this.callerName,
    required this.mode,
    this.callerAvatarUrl,
    this.presentation = FlareIncomingCallPresentation.fullscreen,
    this.onAccept,
    this.onReject,
    this.onAcceptAudio,
  });

  final String callerName;
  final FlareCallMode mode;
  final String? callerAvatarUrl;
  final FlareIncomingCallPresentation presentation;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  /// Answers a video invitation with audio only; the key is drawn for video
  /// invitations when this is given.
  final VoidCallback? onAcceptAudio;

  @override
  State<FlareIncomingCall> createState() => _FlareIncomingCallState();
}

class _FlareIncomingCallState extends State<FlareIncomingCall> {
  final FocusNode _accept = FocusNode();

  bool get _banner =>
      widget.presentation == FlareIncomingCallPresentation.banner;

  @override
  void initState() {
    super.initState();
    if (!_banner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _accept.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _accept.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final invite = widget.mode == FlareCallMode.video
        ? strings.incomingVideoCall
        : strings.incomingVoiceCall;
    return CallAnnouncer(
      message: '${widget.callerName} $invite',
      child: _banner
          ? _bannerView(context, strings, invite)
          : _fullscreen(context, strings, invite),
    );
  }

  Widget _fullscreen(
    BuildContext context,
    FlareStrings strings,
    String invite,
  ) {
    final colors = FlareColors.of(context);
    const size = FlareSizes.componentCallHangupSize;
    final audio = _audioKey(strings, colors);
    return DecoratedBox(
      decoration: callStageDecoration(colors),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned(
                top: box.maxHeight * .22,
                left: FlareSizes.spacingLg,
                right: FlareSizes.spacingLg,
                child: Column(
                  children: [
                    _haloAvatar(colors),
                    const SizedBox(height: FlareSizes.spacingLg),
                    Text(
                      widget.callerName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.callOnStage,
                        fontSize: FlareSizes.fontSize5xl,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: FlareSizes.spacingXs),
                    Text(
                      invite,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.callOnStageSecondary,
                        fontSize: FlareSizes.fontSizeXl,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: size,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (audio != null) ...[
                      audio,
                      const SizedBox(height: FlareSizes.spacing2xl),
                    ],
                    // Each key's centre at a quarter and three quarters of
                    // the width.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _labelled(
                            _key(
                              icon: 'end-call',
                              label: strings.callDecline,
                              size: size,
                              color: colors.callHangup,
                              pressedColor: colors.callHangupPressed,
                              iconColor: colors.callOnStage,
                              onTap: widget.onReject,
                            ),
                            strings.callDecline,
                            colors,
                          ),
                        ),
                        Expanded(
                          child: _labelled(
                            _key(
                              icon: widget.mode == FlareCallMode.video
                                  ? 'video'
                                  : 'phone',
                              label: strings.accept,
                              size: size,
                              color: colors.callAccept,
                              pressedColor: colors.callAcceptPressed,
                              iconColor: colors.callOnStage,
                              onTap: widget.onAccept,
                              focusNode: _accept,
                            ),
                            strings.accept,
                            colors,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerView(
    BuildContext context,
    FlareStrings strings,
    String invite,
  ) {
    final colors = FlareColors.of(context);
    const size = FlareSizes.controlHeightMd;
    final audio = _audioKey(strings, colors);
    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.topEnd,
        child: Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingLg),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: FlareSizes.componentCallIncomingBannerWidth,
              minHeight: FlareSizes.componentCallIncomingBannerHeight,
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(
              FlareSizes.spacingLg,
              FlareSizes.spacingSm,
              FlareSizes.spacingSm,
              FlareSizes.spacingSm,
            ),
            decoration: callStageDecoration(colors).copyWith(
              borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
              boxShadow: FlareShadows.of(Theme.of(context).brightness).lg,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  FlareAvatar(
                    userId: widget.callerName,
                    displayName: widget.callerName,
                    avatarUrl: widget.callerAvatarUrl,
                    size: FlareSizes.componentCallIncomingBannerAvatar,
                  ),
                  const SizedBox(width: FlareSizes.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.callerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.callOnStage,
                            fontSize: FlareSizes.fontSizeXl,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          invite,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.callOnStageSecondary,
                            fontSize: FlareSizes.fontSizeMd,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _key(
                    icon: 'end-call',
                    label: strings.callDecline,
                    size: size,
                    color: colors.callHangup,
                    pressedColor: colors.callHangupPressed,
                    iconColor: colors.callOnStage,
                    onTap: widget.onReject,
                  ),
                  if (audio != null) audio,
                  _key(
                    icon: widget.mode == FlareCallMode.video
                        ? 'video'
                        : 'phone',
                    label: strings.accept,
                    size: size,
                    color: colors.callAccept,
                    pressedColor: colors.callAcceptPressed,
                    iconColor: colors.callOnStage,
                    onTap: widget.onAccept,
                    focusNode: _accept,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The "answer with audio" key of a video invitation, or null. IconButton
  /// md geometry, drawn as a call key so it keeps the round focus ring and
  /// Tab / Space / Enter (FlareIconButton takes no keyboard focus).
  Widget? _audioKey(FlareStrings strings, FlareColors colors) =>
      widget.mode == FlareCallMode.video && widget.onAcceptAudio != null
      ? _key(
          icon: 'phone',
          label: strings.callAnswerAudio,
          size: FlareSizes.componentIconButtonSideMd,
          color: colors.callControl,
          pressedColor: colors.callControlHover,
          iconColor: colors.callOnStage,
          onTap: widget.onAcceptAudio,
        )
      : null;

  /// The caller's avatar in the ringing halo (§3.2: onStage at 20%).
  Widget _haloAvatar(FlareColors colors) => CallHalo(
    color: colors.callOnStage.withValues(alpha: .2),
    breathing: true,
    child: FlareAvatar(
      userId: widget.callerName,
      displayName: widget.callerName,
      avatarUrl: widget.callerAvatarUrl,
      size: FlareSizes.componentCallAvatarSize,
    ),
  );

  Widget _labelled(Widget key, String label, FlareColors colors) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      key,
      const SizedBox(height: FlareSizes.spacingSm),
      ExcludeSemantics(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.callOnStageSecondary,
            fontSize: FlareSizes.fontSizeSm,
          ),
        ),
      ),
    ],
  );

  /// A round key with its focus ring; hover and press darken it. A focused
  /// key answers to Space and Enter.
  Widget _key({
    required String icon,
    required String label,
    required double size,
    required Color color,
    required Color pressedColor,
    required Color iconColor,
    required VoidCallback? onTap,
    FocusNode? focusNode,
  }) => CallFocusRing(
    diameter: size,
    child: CallPressTint(
      builder: (active) => FlareIconControl(
        label: label,
        onTap: onTap,
        focusNode: focusNode,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: active ? pressedColor : color,
            shape: BoxShape.circle,
          ),
          child: FlareIcon(
            icon,
            color: iconColor,
            size: size > FlareSizes.controlHeightMd
                ? FlareSizes.iconSizeLg
                : FlareSizes.iconSizeMd,
          ),
        ),
      ),
    ),
  );
}
