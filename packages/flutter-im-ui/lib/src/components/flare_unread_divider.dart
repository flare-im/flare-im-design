import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

/// Unread divider — the "N new messages" line in the timeline.
/// Spec: Message/UnreadDivider (`FlareUnreadDivider`).
class FlareUnreadDivider extends StatelessWidget {
  const FlareUnreadDivider({super.key, this.count = 0, this.label});

  final int count;

  /// Override text; defaults to "N new messages" / "New messages".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final text = label ?? FlareStrings.of(context).newMessages(count);
    final line = Expanded(
      child: Container(
        height: 1,
        color: colors.primary.withValues(alpha: 0.24),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingLg,
        vertical: FlareSizes.spacingSm,
      ),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd,
            ),
            child: Text(
              text,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: FlareSizes.fontSizeSm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}
