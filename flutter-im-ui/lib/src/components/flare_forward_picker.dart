import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Forward-message picker — a searchable, (multi-)selectable list of chats to
/// forward a message to. Spec: Message/ForwardPicker (`FlareForwardPicker`).
class FlareForwardPicker extends StatefulWidget {
  const FlareForwardPicker({
    super.key,
    required this.targets,
    this.multiple = true,
    this.dismissible = true,
    this.onConfirm,
    this.onClose,
    this.title = '转发给',
    this.searchPlaceholder = '搜索会话',
    this.sendLabel = '发送',
    this.selectedText,
  });

  final List<FlareForwardTarget> targets;
  final bool multiple;
  final bool dismissible;
  final void Function(List<String> ids)? onConfirm;
  final VoidCallback? onClose;
  final String title;
  final String searchPlaceholder;
  final String sendLabel;

  /// Formats the "N selected" footer text (defaults to "已选 N").
  final String Function(int count)? selectedText;

  @override
  State<FlareForwardPicker> createState() => _FlareForwardPickerState();
}

class _FlareForwardPickerState extends State<FlareForwardPicker> {
  final TextEditingController _query = TextEditingController();
  final Set<String> _selected = <String>{};

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

  void _toggle(String id) {
    setState(() {
      if (widget.multiple) {
        if (!_selected.remove(id)) _selected.add(id);
      } else {
        final wasSelected = _selected.contains(id);
        _selected
          ..clear()
          ..addAll(wasSelected ? const <String>[] : [id]);
      }
    });
  }

  List<FlareForwardTarget> get _filtered {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return widget.targets;
    return widget.targets.where((t) {
      final name = t.name.toLowerCase();
      final sub = (t.subtitle ?? '').toLowerCase();
      return name.contains(q) || sub.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final rows = _filtered;
    return Container(
      width: 340,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingLg, FlareSizes.spacingLg, FlareSizes.spacingSm, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSize2xl,
                          fontWeight: FontWeight.w600)),
                ),
                if (widget.dismissible)
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(FlareSizes.spacingSm),
                      child: Icon(Icons.close, size: 18, color: colors.textTertiary),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingLg, FlareSizes.spacingMd, FlareSizes.spacingLg, 0),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 17, color: colors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      style: TextStyle(
                          color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg),
                      cursorColor: colors.primary,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: widget.searchPlaceholder,
                        hintStyle: TextStyle(
                            color: colors.textTertiary, fontSize: FlareSizes.fontSizeLg),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FlareSizes.spacingSm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              itemBuilder: (context, i) => _row(colors, rows[i]),
            ),
          ),
          _footer(colors),
        ],
      ),
    );
  }

  Widget _row(FlareColors colors, FlareForwardTarget t) {
    final selected = _selected.contains(t.id);
    return GestureDetector(
      onTap: () => _toggle(t.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: selected ? colors.bgSelected : Colors.transparent,
        padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colors.primary : Colors.transparent,
                border: Border.all(color: selected ? colors.primary : colors.borderHover),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            FlareAvatar(
              userId: t.id,
              displayName: t.name,
              avatarUrl: t.avatarUrl,
              size: 38,
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w500)),
                  if (t.subtitle != null && t.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(t.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(FlareColors colors) {
    final count = _selected.length;
    final enabled = count > 0;
    return Container(
      padding: const EdgeInsets.all(FlareSizes.spacingMd),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderPrimary)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.selectedText?.call(count) ?? '已选 $count',
                style: TextStyle(
                    color: colors.textSecondary, fontSize: FlareSizes.fontSizeSm)),
          ),
          GestureDetector(
            onTap: enabled ? () => widget.onConfirm?.call(_selected.toList()) : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primary.withValues(alpha: 0.82)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.send, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(widget.sendLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: FlareSizes.fontSizeLg,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
