import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/in_app_notification.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_icon_button.dart';

/// The banner for a message that arrived while the app is open on another
/// screen. Spec: Feedback/InAppNotificationBanner
/// (`FlareInAppNotificationBanner`).
///
/// Avatar (the host's `avatarUrl`, else the title's initials coloured by the
/// conversation), the title and one line of preview, both ellipsised; above one
/// message the kit's "[3条]" goes before the body, and mentions / urgent put
/// their tag before it with an accent. A tap opens: [onOpen] with the item's
/// conversation and message. A swipe up past a short distance or the close
/// key dismisses ([onDismiss]); assistive technology gets the same as its
/// dismiss action. [FlareInAppNotificationHost] places the banner, queues the next
/// ones and runs its time.
class FlareInAppNotificationBanner extends StatefulWidget {
  const FlareInAppNotificationBanner({
    super.key,
    required this.notification,
    this.onOpen,
    this.onDismiss,
  });

  /// What the banner shows.
  final FlareInAppNotification notification;

  /// Opens the conversation: `(conversationId, messageId)`.
  final void Function(String conversationId, String? messageId)? onOpen;

  /// The banner goes (swipe up, the close key or the Close action).
  final VoidCallback? onDismiss;

  @override
  State<FlareInAppNotificationBanner> createState() =>
      _FlareInAppNotificationBannerState();
}

class _FlareInAppNotificationBannerState
    extends State<FlareInAppNotificationBanner> {
  /// How far the banner follows the finger upwards (0 or less).
  double _offset = 0;

  /// An upward fling this fast dismisses however short it was.
  static const double _flingVelocity = 600;

  /// The avatar, the same on the four kits.
  static const double _avatarSize = 40;

  void _open() {
    final n = widget.notification;
    widget.onOpen?.call(n.conversationId, n.messageId);
  }

  void _dragUpdate(DragUpdateDetails details) {
    setState(() => _offset = math.min(0.0, _offset + details.delta.dy));
  }

  void _dragEnd(DragEndDetails details) {
    final dismissed =
        _offset <= -inAppNotificationSwipeDismissDistance ||
        (details.primaryVelocity ?? 0) < -_flingVelocity;
    setState(() => _offset = 0);
    if (dismissed) widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final n = widget.notification;
    final urgent = n.channel == FlareInAppNotificationChannel.urgent;
    final tag = n.tag(strings);
    final tagColor = urgent ? colors.errorText : colors.primaryText;
    final bodyStyle = TextStyle(
      color: colors.textSecondary,
      fontSize: FlareSizes.fontSizeMd,
      height: FlareSizes.lineHeightNormal,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final card = Container(
      padding: const EdgeInsets.all(FlareSizes.spacingSm),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(
          color: urgent ? colors.error : colors.borderSecondary,
        ),
        boxShadow: FlareShadows.of(Theme.of(context).brightness).lg,
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: FlareAvatar(
              userId: n.conversationId,
              displayName: n.title,
              avatarUrl: n.avatarUrl,
              size: _avatarSize,
            ),
          ),
          const SizedBox(width: FlareSizes.spacingMd),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeLg,
                    fontWeight: FontWeight.w600,
                    height: FlareSizes.lineHeightTight,
                  ),
                ),
                const SizedBox(height: FlareSizes.spacing3xs),
                Text.rich(
                  TextSpan(
                    children: [
                      if (tag != null)
                        TextSpan(
                          text: '$tag ',
                          style: TextStyle(
                            color: tagColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (n.showsCount)
                        TextSpan(
                          text: '${strings.inAppNotificationCount(n.count)} ',
                        ),
                      TextSpan(text: n.body),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle,
                ),
              ],
            ),
          ),
          FlareIconButton(
            icon: 'close',
            semanticLabel: strings.close,
            size: FlareControlSize.sm,
            tintColor: colors.textTertiary,
            onPressed: widget.onDismiss,
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      button: true,
      label: n.spoken(strings),
      hint: strings.inAppNotificationOpenHint,
      onTap: _open,
      onDismiss: widget.onDismiss,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _open,
        onVerticalDragUpdate: _dragUpdate,
        onVerticalDragEnd: _dragEnd,
        onVerticalDragCancel: () => setState(() => _offset = 0),
        child: AnimatedContainer(
          duration: _offset == 0 && !reduceMotion
              ? FlareMotion.fast
              : Duration.zero,
          transform: Matrix4.translationValues(0, _offset, 0),
          child: card,
        ),
      ),
    );
  }
}
