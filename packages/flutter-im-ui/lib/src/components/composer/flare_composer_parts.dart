import 'package:flutter/material.dart';

import '../../tokens/flare_strings.dart';
import '../../tokens/flare_tokens.dart';
import '../action_icon.dart';
import '../flare_icon.dart';
import '../icon_control.dart';

/// A round icon button used across the composer toolbar (attach, emoji, voice,
/// keyboard). A composable part so hosts can assemble their own toolbar.
///
/// [label] is the key's accessible name and tooltip — what tapping it does,
/// such as [FlareStrings.composerVoiceInput] — so a toolbar assembled from
/// parts is never a row of unnamed glyphs. The key is a full touch target.
class FlareComposerIconButton extends StatelessWidget {
  const FlareComposerIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.disabled = false,
    this.active = false,
    this.size = 24,
  });

  /// A semantic icon name from `flareIconNames`.
  final String icon;

  /// Accessible name and tooltip of the key.
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return IconButton(
      tooltip: label,
      onPressed: disabled ? null : onTap,
      icon: Icon(flareIconGlyph(icon), size: size),
      color: active ? colors.primary : colors.textSecondary,
      constraints: const BoxConstraints(
        minWidth: FlareSizes.touchTarget,
        minHeight: FlareSizes.touchTarget,
      ),
    );
  }
}

/// Send — a paper plane, and nothing else.
///
/// It used to be a filled brand disc with a white glyph inside. Sending is the
/// same kind of act as every other key in the tool row — one tap, one outcome —
/// so it is drawn the same way, and only colour says which one sends: the brand
/// at rest against the row, faded while there is nothing to send. That is also
/// what [FlareComposer]'s own send key does, and the two must not drift.
class FlareComposerSendButton extends StatelessWidget {
  const FlareComposerSendButton({
    super.key,
    required this.active,
    this.busy = false,
    this.onTap,
  });

  final bool active;

  /// A send is in flight: the key shows progress, says so, and takes no taps.
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // An IconButton like every other key in the tool row: same target, same
    // ink, same hit-testing. Only the colour differs, and only by state.
    return IconButton(
      tooltip: busy ? strings.messageSending : strings.send,
      onPressed: active && !busy ? onTap : null,
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      // shrinkWrap, or Material pads the target out to 48 and the tool row
      // overflows a 320-wide screen by exactly the difference.
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
      ),
      icon: !busy
          ? Icon(
              flareIconGlyph('send'),
              color: colors.primaryText.withValues(alpha: active ? 1 : 0.38),
            )
          : reduceMotion
          ? Icon(Icons.schedule_outlined, color: colors.primaryText)
          : SizedBox.square(
              dimension: FlareSizes.iconSizeMd,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
    );
  }
}

/// A reply-target preview strip shown above the input. Composer part.
class FlareComposerReplyStrip extends StatelessWidget {
  const FlareComposerReplyStrip({
    super.key,
    required this.senderName,
    required this.summary,
    this.label = '回复',
    this.onCancel,
    this.flush = false,
  });

  final String senderName;
  final String summary;

  /// Leading text before the sender (host-provided, no baked-in language).
  final String label;
  final VoidCallback? onCancel;

  /// Part of the writing band rather than a card on top of it: full width, no
  /// rounding, closed by a hairline. What a phone composer passes.
  final bool flush;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Container(
      margin: flush
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: FlareSizes.spacingSm),
      // The cancel control is a touch target tall and sets the strip's
      // height; the text centres in it, so no vertical padding is added.
      padding: EdgeInsets.symmetric(
        horizontal: flush ? FlareSizes.spacingLg : FlareSizes.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.messageReplyBackground,
        borderRadius: flush ? null : BorderRadius.circular(FlareSizes.radiusMd),
        border: Border(
          left: BorderSide(color: colors.messageReplyBorder, width: 3),
          bottom: flush
              ? BorderSide(color: colors.borderPrimary)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label $senderName',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: FlareSizes.fontSizeXs,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
              ],
            ),
          ),
          FlareIconControl(
            label: FlareStrings.of(context).cancelReply,
            onTap: onCancel,
            alignment: AlignmentDirectional.centerEnd,
            child: FlareIcon('close', size: 18, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
