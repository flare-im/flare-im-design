import 'package:flutter/material.dart';

import '../../tokens/flare_tokens.dart';

/// A round icon button used across the composer toolbar (attach, emoji, voice,
/// keyboard). A composable part so hosts can assemble their own toolbar.
class FlareComposerIconButton extends StatelessWidget {
  const FlareComposerIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.disabled = false,
    this.active = false,
    this.size = 24,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return IconButton(
      onPressed: disabled ? null : onTap,
      icon: Icon(icon, size: size),
      color: active ? colors.primary : colors.textSecondary,
      visualDensity: VisualDensity.compact,
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
  const FlareComposerSendButton({super.key, required this.active, this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    // An IconButton like every other key in the tool row: same target, same
    // ink, same hit-testing. Only the colour differs, and only by state.
    return IconButton(
      onPressed: active ? onTap : null,
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
      icon: Icon(
        Icons.send_outlined,
        color: colors.primary.withValues(alpha: active ? 1 : 0.38),
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
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      margin: flush
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: FlareSizes.spacingSm),
      padding: EdgeInsets.symmetric(
        horizontal: flush ? 16 : FlareSizes.spacingSm,
        vertical: FlareSizes.spacingXs,
      ),
      decoration: BoxDecoration(
        color: flush ? colors.bgPrimary : colors.bgSecondary,
        borderRadius: flush ? null : BorderRadius.circular(FlareSizes.radiusMd),
        border: Border(
          left: BorderSide(color: colors.primary, width: 3),
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
                    color: colors.primary,
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
          GestureDetector(
            onTap: onCancel,
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
