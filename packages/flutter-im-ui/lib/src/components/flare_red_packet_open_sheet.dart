import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/red_packet.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_avatar.dart';
import 'flare_icon_button.dart';
import 'flare_overlay.dart';

/// The open-a-red-packet layer: a red envelope centred over the kit scrim —
/// an arched flap with the sender and the blessing, and the gold 開 coin on
/// the flap's seam — with the close control under the envelope.
/// Spec: Message/RedPacketOpenSheet (`FlareRedPacketOpenSheet`).
///
/// It only draws. Whether the viewer can claim, and what they get, is the
/// plugin's answer; the host turns it into [state]. [onOpen] is the 開 press —
/// the host claims and sets [FlareRedPacketOpenState.opening], which flips the
/// coin (a spinner instead when the platform asks for reduced motion) and
/// blocks a second press. Finished, expired, refunded and not-eligible
/// packets say why (the host's [message] replaces the default copy). The
/// details key ([onViewDetails]) shows only for a finished, expired or
/// refunded packet whose
/// personal layer lets the viewer see them ([canViewDetails]); a not-eligible
/// viewer never gets one — the server returns no amounts or records to them
/// (`spec/red-packet-vectors.json` → openSheet).
///
/// The widget fills its parent and paints the scrim itself, so a host can lay
/// it over a page in a [Stack]; [FlareRedPacketOpenSheet.show] puts it on its
/// own route instead. Either way a scrim tap, Escape and the platform back
/// call [onClose] (with no [onClose] they pop the route).
class FlareRedPacketOpenSheet extends StatefulWidget {
  const FlareRedPacketOpenSheet({
    super.key,
    required this.senderName,
    this.senderAvatar,
    required this.blessing,
    this.kindLabel,
    this.state = FlareRedPacketOpenState.ready,
    this.message,
    this.canViewDetails = true,
    this.reviewOnError = false,
    this.onOpen,
    this.onViewDetails,
    this.onClose,
  });

  final String senderName;
  final String? senderAvatar;
  final String blessing;

  /// Packet kind under the sender, e.g. "拼手气红包".
  final String? kindLabel;
  final FlareRedPacketOpenState state;

  /// Host notice that replaces the default copy of a non-ready state.
  final String? message;

  /// From the personal layer: a finished, expired or refunded sheet offers the
  /// details key only when true. [FlareRedPacketOpenState.notEligible] never does.
  final bool canViewDetails;

  /// In [FlareRedPacketOpenState.error] the key reads "查看结果" and calls
  /// [onViewDetails] instead of offering 開 again: the claim may have landed.
  final bool reviewOnError;
  final VoidCallback? onOpen;
  final VoidCallback? onViewDetails;
  final VoidCallback? onClose;

  /// Key of the 開 coin, for tests and hosts that drive it.
  static const Key coinKey = Key('flare-red-packet-open-coin');

  /// Shows what [builder] returns — normally a [FlareRedPacketOpenSheet] the
  /// host rebuilds as [state] changes — on a route over the window. The sheet
  /// paints its own scrim, so the route's barrier is transparent and never
  /// dismisses by itself; the sheet's [onClose] decides. Motion is skipped when
  /// the platform asks for reduced motion.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    final scopes = flareOverlayScopes(context);
    final reduce = flareReduceMotion(context);
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: reduce ? Duration.zero : FlareMotion.normal,
      pageBuilder: (routeContext, _, _) => scopes(Builder(builder: builder)),
      transitionBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<FlareRedPacketOpenSheet> createState() =>
      _FlareRedPacketOpenSheetState();
}

class _FlareRedPacketOpenSheetState extends State<FlareRedPacketOpenSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  bool get _opening => widget.state == FlareRedPacketOpenState.opening;

  bool get _review =>
      widget.reviewOnError && widget.state == FlareRedPacketOpenState.error;

  bool get _showsCoin =>
      !_review && flareRedPacketOpenSheetKeys(widget.state).coin;

  bool get _showsDetails =>
      _review ||
      flareRedPacketOpenSheetKeys(
        widget.state,
        canViewDetails: widget.canViewDetails,
      ).details;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFlip();
  }

  @override
  void didUpdateWidget(FlareRedPacketOpenSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFlip();
  }

  void _syncFlip() {
    final spin = _opening && !flareReduceMotion(context);
    if (spin && !_flip.isAnimating) {
      _flip.repeat();
    } else if (!spin && (_flip.isAnimating || _flip.value != 0)) {
      _flip
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _close() {
    // §4.5: nothing closes the envelope while the claim runs.
    if (_opening) return;
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      Navigator.maybePop(context);
    }
  }

  void _press() {
    if (!_opening) widget.onOpen?.call();
  }

  String _headline(FlareStrings strings) {
    final message = widget.message;
    final custom = message != null && message.isNotEmpty ? message : null;
    return switch (widget.state) {
      FlareRedPacketOpenState.finished => custom ?? strings.packetMissed,
      FlareRedPacketOpenState.expired => custom ?? strings.packetExpiredNotice,
      FlareRedPacketOpenState.refunded =>
        custom ?? strings.packetRefundedNotice,
      FlareRedPacketOpenState.notEligible =>
        custom ?? strings.packetNotEligible,
      _ => widget.blessing,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final title = strings.packetFromSender(widget.senderName);
    return PopScope(
      canPop: widget.onClose == null && !_opening,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_opening) widget.onClose?.call();
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _close();
              return null;
            },
          ),
        },
        child: FocusScope(
          autofocus: true,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: ExcludeSemantics(
                    child: ColoredBox(color: colors.scrim),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FlareSizes.spacingLg,
                        vertical: FlareSizes.spacingXl,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: FlareSizes.componentRedPacketEnvelopeWidth,
                        ),
                        child: Semantics(
                          scopesRoute: true,
                          namesRoute: true,
                          explicitChildNodes: true,
                          label: title,
                          child: _envelope(colors, strings, title),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _envelope(FlareColors colors, FlareStrings strings, String title) {
    const height = FlareSizes.componentRedPacketEnvelopeMinHeight;
    const coin = FlareSizes.componentRedPacketOpenButtonSize;
    // The pocket under the flap keeps 28% of the envelope (Vue's foot); the
    // flap takes the rest, less the half of the coin that hangs below its seam.
    const footHeight = height * 0.28;
    final coverHeight = height - footHeight - (_showsCoin ? coin / 2 : 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cover = Container(
          width: width,
          constraints: BoxConstraints(minHeight: coverHeight),
          padding: EdgeInsets.fromLTRB(
            FlareSizes.spacing2xl,
            FlareSizes.spacing2xl,
            FlareSizes.spacing2xl,
            (_showsCoin ? coin / 2 : 0) + FlareSizes.spacingLg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.redPacketEnd, colors.redPacketMiddle],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.elliptical(width / 2, FlareSizes.spacing2xl),
            ),
            boxShadow: flareOverlayShadow(context),
          ),
          child: _coverContent(colors, strings, title),
        );
        final envelope = Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.redPacketEnd,
            borderRadius: BorderRadius.circular(FlareSizes.radius2xl),
            boxShadow: flareOverlayShadow(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showsCoin)
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: coin / 2),
                      child: cover,
                    ),
                    _coin(colors, strings),
                  ],
                )
              else
                cover,
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: footHeight),
                child: Padding(
                  padding: const EdgeInsets.all(FlareSizes.spacingLg),
                  child: Center(
                    child: _showsDetails
                        ? _detailsLink(
                            colors,
                            _review
                                ? strings.packetViewResult
                                : strings.packetViewDetails,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        );
        // §4.5: the close key sits in the envelope's top trailing corner, a
        // 36 disc with the kit's 48 touch target around it.
        return Stack(
          children: [
            envelope,
            PositionedDirectional(
              top: FlareSizes.spacingXs,
              end: FlareSizes.spacingXs,
              child: FlareIconButton(
                icon: 'close',
                semanticLabel: strings.close,
                customSize: _closeSide,
                tintColor: colors.redPacketOnSurface,
                backgroundColor: colors.scrim.withValues(alpha: 0.16),
                disabled: _opening,
                onPressed: _close,
              ),
            ),
          ],
        );
      },
    );
  }

  static const double _closeSide = FlareSizes.componentRedPacketCloseSize;

  Widget _coverContent(FlareColors colors, FlareStrings strings, String title) {
    final message = widget.message;
    final notice = widget.state == FlareRedPacketOpenState.notEligible;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: FlareAvatar(
            userId: widget.senderName,
            displayName: widget.senderName,
            avatarUrl: widget.senderAvatar,
            // The sender is the same 56 here as on the details page.
            size: FlareSizes.componentRedPacketDetailAvatarSize,
          ),
        ),
        const SizedBox(height: FlareSizes.spacingSm),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.redPacketOnSurface,
            fontSize: FlareSizes.fontSizeXl,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.kindLabel != null) ...[
          const SizedBox(height: FlareSizes.spacingMd),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingSm,
              vertical: FlareSizes.spacing3xs,
            ),
            decoration: BoxDecoration(
              color: colors.scrim.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
            ),
            child: Text(
              widget.kindLabel!,
              style: TextStyle(
                color: colors.redPacketGold,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ),
        ],
        const SizedBox(height: FlareSizes.spacingXl),
        Semantics(
          liveRegion: true,
          child: Text(
            _headline(strings),
            textAlign: TextAlign.center,
            // A host notice can run long: body line spacing, three lines;
            // the blessing keeps two.
            maxLines: notice ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.redPacketGold,
              fontSize: FlareSizes.fontSize4xl,
              height: notice
                  ? FlareSizes.lineHeightNormal
                  : FlareSizes.lineHeightSnug,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.state == FlareRedPacketOpenState.error) ...[
          const SizedBox(height: FlareSizes.spacingMd),
          Semantics(
            liveRegion: true,
            child: Text(
              message != null && message.isNotEmpty
                  ? message
                  : strings.packetOpenFailed,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.redPacketOnSurface,
                fontSize: FlareSizes.fontSizeLg,
                height: FlareSizes.lineHeightNormal,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _coin(FlareColors colors, FlareStrings strings) {
    const size = FlareSizes.componentRedPacketOpenButtonSize;
    final label = strings.packetOpenAction;
    final reduce = flareReduceMotion(context);
    // One ideograph fills the coin; a word ("Open") is set smaller.
    final word = label.characters.length > 2;
    final Widget face = _opening && reduce
        ? SizedBox.square(
            dimension: FlareSizes.iconSizeLg,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.redPacketEnd,
            ),
          )
        : Text(
            label,
            style: TextStyle(
              color: colors.redPacketEnd,
              fontSize: word ? FlareSizes.fontSize3xl : size * 0.42,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          );
    final disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -0.28),
          colors: [colors.redPacketGold, colors.redPacketGoldDeep],
          stops: const [0, 0.78],
        ),
        border: Border.all(
          color: colors.redPacketGold.withValues(alpha: 0.7),
          width: 3,
        ),
        boxShadow: flareOverlayShadow(context),
      ),
      child: face,
    );
    return Semantics(
      button: true,
      enabled: !_opening,
      label: _opening ? strings.packetBusy : label,
      liveRegion: _opening,
      onTap: _opening ? null : _press,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _flip,
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateY(_flip.value * 2 * math.pi),
            child: child,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            child: InkWell(
              key: FlareRedPacketOpenSheet.coinKey,
              customBorder: const CircleBorder(),
              autofocus: widget.state == FlareRedPacketOpenState.ready,
              onTap: _opening ? null : _press,
              child: disc,
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsLink(FlareColors colors, String label) {
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
          onTap: widget.onViewDetails,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FlareSizes.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: colors.redPacketGold,
                        fontSize: FlareSizes.fontSizeLg,
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      flareIconGlyph('chevron-right'),
                      size: FlareSizes.iconSizeSm,
                      color: colors.redPacketGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
