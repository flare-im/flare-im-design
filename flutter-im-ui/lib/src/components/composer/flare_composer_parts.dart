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
    this.size = 26,
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

/// The send button — a brand-purple circle that lights up when there is
/// something to send. Composer part.
class FlareComposerSendButton extends StatelessWidget {
  const FlareComposerSendButton({super.key, required this.active, this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Material(
        color: active ? colors.primary : colors.bgDisabled,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: active ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.send_rounded,
                size: 20,
                color: active ? Colors.white : colors.textDisabled),
          ),
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
  });

  final String senderName;
  final String summary;

  /// Leading text before the sender (host-provided, no baked-in language).
  final String label;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      margin: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
      padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingSm, vertical: FlareSizes.spacingXs),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$label $senderName',
                    style: TextStyle(
                        color: colors.primary,
                        fontSize: FlareSizes.fontSizeXs,
                        fontWeight: FontWeight.w600)),
                Text(summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FlareSizes.fontSizeSm)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(Icons.close_rounded, size: 18, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
