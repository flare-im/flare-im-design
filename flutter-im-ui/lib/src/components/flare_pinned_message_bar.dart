import 'package:flutter/material.dart';

import '../models/pinned_message_data.dart';
import '../tokens/flare_tokens.dart';

/// Sticky bar above the thread showing pinned messages; tap to focus one, and
/// (when many) cycle through them. Spec: Message/PinnedMessageBar
/// (`FlarePinnedMessageBar`).
class FlarePinnedMessageBar extends StatefulWidget {
  const FlarePinnedMessageBar({
    super.key,
    required this.items,
    this.onFocus,
  });

  final List<FlarePinnedMessage> items;

  /// Called with the focused pinned message on tap.
  final void Function(FlarePinnedMessage item)? onFocus;

  @override
  State<FlarePinnedMessageBar> createState() => _FlarePinnedMessageBarState();
}

class _FlarePinnedMessageBarState extends State<FlarePinnedMessageBar> {
  int _index = 0;

  @override
  void didUpdateWidget(FlarePinnedMessageBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.items.length) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final colors = FlareColors.of(Theme.of(context).brightness);
    final item = widget.items[_index];

    return Material(
      color: colors.bgSecondary,
      child: InkWell(
        onTap: () {
          widget.onFocus?.call(item);
          if (widget.items.length > 1) {
            setState(() => _index = (_index + 1) % widget.items.length);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: colors.pinned, width: 3)),
          ),
          child: Row(
            children: [
              Icon(Icons.push_pin_outlined, size: 16, color: colors.pinned),
              const SizedBox(width: FlareSizes.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.senderName != null && item.senderName!.isNotEmpty)
                      Text(item.senderName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: colors.pinned,
                              fontSize: FlareSizes.fontSizeXs,
                              fontWeight: FontWeight.w600)),
                    Text(item.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: FlareSizes.fontSizeSm)),
                  ],
                ),
              ),
              if (widget.items.length > 1) ...[
                const SizedBox(width: FlareSizes.spacingSm),
                Text('${_index + 1}/${widget.items.length}',
                    style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeXs)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
