import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// @-mention picker — searchable member list with an optional "Everyone" row.
/// Spec: Composer/MentionPicker (`FlareMentionPicker`).
class FlareMentionPicker extends StatefulWidget {
  const FlareMentionPicker({
    super.key,
    required this.candidates,
    this.allowEveryone = false,
    this.onSelect,
    this.onClose,
    this.searchPlaceholder = '搜索成员',
    this.everyoneLabel = '所有人',
    this.everyoneDetail = '通知所有成员',
    this.emptyText = '没有匹配的成员',
  });

  final List<FlareMentionCandidate> candidates;
  final bool allowEveryone;
  final void Function(FlareMentionCandidate)? onSelect;
  final VoidCallback? onClose;
  final String searchPlaceholder;
  final String everyoneLabel;
  final String everyoneDetail;
  final String emptyText;

  @override
  State<FlareMentionPicker> createState() => _FlareMentionPickerState();
}

class _FlareMentionPickerState extends State<FlareMentionPicker> {
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final q = _query.text.trim().toLowerCase();
    final filtered = widget.candidates.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          (c.detail?.toLowerCase().contains(q) ?? false);
    }).toList();
    final showEveryone =
        widget.allowEveryone && (q.isEmpty || 'everyone'.contains(q));

    return Container(
      width: 280,
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
          _search(colors),
          Flexible(
            child: (filtered.isEmpty && !showEveryone)
                ? _empty(colors)
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 264),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
                      children: [
                        if (showEveryone) _everyoneRow(colors),
                        for (final c in filtered) _personRow(colors, c),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _search(FlareColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderPrimary)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: colors.textTertiary),
          const SizedBox(width: FlareSizes.spacingSm),
          Expanded(
            child: TextField(
              controller: _query,
              style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.searchPlaceholder,
                hintStyle:
                    TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeLg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _everyoneRow(FlareColors colors) {
    return GestureDetector(
      onTap: () => widget.onSelect?.call(
        FlareMentionCandidate(id: '__all__', name: widget.everyoneLabel, isEveryone: true),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.people_outline, size: 18, color: Colors.white),
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.everyoneLabel,
                      style: TextStyle(
                          color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
                  Text(widget.everyoneDetail,
                      style: TextStyle(
                          color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personRow(FlareColors colors, FlareMentionCandidate c) {
    return GestureDetector(
      onTap: () => widget.onSelect?.call(c),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
        child: Row(
          children: [
            FlareAvatar(userId: c.id, displayName: c.name, avatarUrl: c.avatarUrl, size: 32),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
                  if (c.detail != null && c.detail!.isNotEmpty)
                    Text(c.detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: FlareSizes.spacingLg),
      child: Center(
        child: Text(widget.emptyText,
            style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeMd)),
      ),
    );
  }
}
