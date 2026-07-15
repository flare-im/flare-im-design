import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Read-receipt sheet — who has / hasn't read a message, split into two tabs.
/// Spec: Message/ReadReceiptSheet (`FlareReadReceiptSheet`).
class FlareReadReceiptSheet extends StatefulWidget {
  const FlareReadReceiptSheet({
    super.key,
    required this.readers,
    required this.unread,
    this.dismissible = false,
    this.onSelect,
    this.onClose,
  });

  final List<FlareContact> readers;
  final List<FlareContact> unread;
  final bool dismissible;
  final void Function(String id)? onSelect;
  final VoidCallback? onClose;

  @override
  State<FlareReadReceiptSheet> createState() => _FlareReadReceiptSheetState();
}

class _FlareReadReceiptSheetState extends State<FlareReadReceiptSheet> {
  bool _showRead = true;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final list = _showRead ? widget.readers : widget.unread;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(color: Color(0x2915131C), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(colors),
          _tabs(colors),
          Flexible(
            child: list.isEmpty
                ? _empty(colors)
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
                      children: [for (final c in list) _row(colors, c)],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FlareSizes.spacingLg, FlareSizes.spacingMd,
          FlareSizes.spacingSm, FlareSizes.spacingMd),
      child: Row(
        children: [
          Icon(Icons.done_all, size: 18, color: colors.primary),
          const SizedBox(width: FlareSizes.spacingSm),
          Expanded(
            child: Text('Read receipt',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeLg,
                    fontWeight: FontWeight.w600)),
          ),
          if (widget.dismissible)
            GestureDetector(
              onTap: widget.onClose,
              child: Icon(Icons.close, size: 18, color: colors.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _tabs(FlareColors colors) {
    return Row(
      children: [
        _tab(colors, 'Read (${widget.readers.length})', _showRead, () {
          setState(() => _showRead = true);
        }),
        _tab(colors, 'Unread (${widget.unread.length})', !_showRead, () {
          setState(() => _showRead = false);
        }),
      ],
    );
  }

  Widget _tab(FlareColors colors, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? colors.primary : colors.textSecondary,
              fontSize: FlareSizes.fontSizeMd,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(FlareColors colors, FlareContact c) {
    return GestureDetector(
      onTap: () => widget.onSelect?.call(c.id),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
        child: Row(
          children: [
            FlareAvatar(userId: c.id, displayName: c.name, avatarUrl: c.avatarUrl, size: 36),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Text(c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: FlareSizes.spacingLg),
      child: Center(
        child: Text(
          _showRead ? 'No one has read this yet' : 'Everyone has read this',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeMd),
        ),
      ),
    );
  }
}
