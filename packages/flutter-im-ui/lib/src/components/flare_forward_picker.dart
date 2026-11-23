import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

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
    this.title,
    this.searchPlaceholder,
    this.sendLabel,
    this.selectedText,
    this.busy = false,
    this.selected,
    this.onSelectionChanged,
  });

  final List<FlareForwardTarget> targets;
  final bool multiple;
  final bool dismissible;
  final void Function(List<String> ids)? onConfirm;
  final VoidCallback? onClose;
  final String? title;
  final String? searchPlaceholder;
  final String? sendLabel;

  /// Formats the "N selected" footer text (defaults to "已选 N").
  final String Function(int count)? selectedText;

  /// The host is forwarding to the chosen chats (the Vue kit's `busy`): the
  /// send key shows progress, and neither the rows nor the close control
  /// take taps.
  final bool busy;

  /// The chosen chats as the host holds them (the Vue kit's `v-model`): the
  /// picker starts from them and takes them again whenever the host passes a
  /// different list — after a partial failure, only the chats still waiting
  /// for the forward. Ids that are not among [targets] are dropped. Null
  /// leaves the choice to the picker.
  final List<String>? selected;

  /// Every change of the choice made in the picker, in the order chosen.
  final ValueChanged<List<String>>? onSelectionChanged;

  @override
  State<FlareForwardPicker> createState() => _FlareForwardPickerState();
}

class _FlareForwardPickerState extends State<FlareForwardPicker> {
  String get _title => widget.title ?? FlareStrings.of(context).forwardTo;
  String get _searchPlaceholder =>
      widget.searchPlaceholder ?? FlareStrings.of(context).searchConversations;
  String get _sendLabel => widget.sendLabel ?? FlareStrings.of(context).send;
  final TextEditingController _query = TextEditingController();
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    _takeSelection();
  }

  @override
  void didUpdateWidget(covariant FlareForwardPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final held = widget.selected;
    if (held != null && !listEquals(held, oldWidget.selected)) {
      _takeSelection();
    } else if (!identical(widget.targets, oldWidget.targets)) {
      final ids = {for (final target in widget.targets) target.id};
      _selected.removeWhere((id) => !ids.contains(id));
    }
  }

  /// The host's choice, kept to the chats on offer.
  void _takeSelection() {
    final held = widget.selected;
    if (held == null) return;
    final ids = {for (final target in widget.targets) target.id};
    _selected
      ..clear()
      ..addAll(held.where(ids.contains));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    if (widget.busy) return;
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
    widget.onSelectionChanged?.call(_selected.toList());
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
    final colors = FlareColors.of(context);
    final rows = _filtered;
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2915131C),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingLg,
              FlareSizes.spacingLg,
              FlareSizes.spacingSm,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSize2xl,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.dismissible)
                  FlareIconControl(
                    label: FlareStrings.of(context).close,
                    onTap: widget.busy ? null : widget.onClose,
                    child: FlareIcon(
                      'close',
                      size: 18,
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingLg,
              FlareSizes.spacingMd,
              FlareSizes.spacingLg,
              0,
            ),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacing2sm,
              ),
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
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSizeLg,
                      ),
                      cursorColor: colors.primary,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: _searchPlaceholder,
                        hintStyle: TextStyle(
                          color: colors.textTertiary,
                          fontSize: FlareSizes.fontSizeLg,
                        ),
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
      onTap: widget.busy ? null : () => _toggle(t.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: selected ? colors.bgSelected : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingLg,
          vertical: FlareSizes.spacingSm,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colors.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? colors.primary : colors.borderHover,
                ),
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
                  Text(
                    t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (t.subtitle != null && t.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      t.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeSm,
                      ),
                    ),
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
    final enabled = count > 0 && !widget.busy;
    return Container(
      padding: const EdgeInsets.all(FlareSizes.spacingMd),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderPrimary)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.selectedText?.call(count) ??
                  FlareStrings.of(context).selectedCount(count),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ),
          GestureDetector(
            onTap: enabled
                ? () => widget.onConfirm?.call(_selected.toList())
                : null,
            child: Opacity(
              opacity: enabled || (widget.busy && count > 0) ? 1 : 0.4,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary,
                      colors.primary.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.busy)
                      const SizedBox.square(
                        key: ValueKey('flare-forward-picker-busy'),
                        dimension: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const FlareIcon('send', size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _sendLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: FlareSizes.fontSizeLg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
