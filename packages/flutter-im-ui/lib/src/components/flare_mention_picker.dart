import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// @-mention picker — searchable member list with an optional "Everyone" row.
/// Labels default to [FlareStrings]. `FlareComposer` presents it in a
/// `FlareBottomSheet` when "@" is typed. Spec: Composer/MentionPicker
/// (`FlareMentionPicker`).
///
/// With a keyboard it is a combobox: focus stays in the search field, the
/// first match is highlighted, the arrow keys move the highlight, Enter picks
/// it (the Enter that commits an input-method composition is left to the input
/// method) and Escape calls [onClose]. Touch works as before.
class FlareMentionPicker extends StatefulWidget {
  const FlareMentionPicker({
    super.key,
    required this.candidates,
    this.allowEveryone = false,
    this.onSelect,
    this.onClose,
    this.searchPlaceholder,
    this.everyoneLabel,
    this.everyoneDetail,
    this.emptyText,
    this.autofocus = false,
    this.framed = true,
  });

  final List<FlareMentionCandidate> candidates;
  final bool allowEveryone;
  final void Function(FlareMentionCandidate)? onSelect;
  final VoidCallback? onClose;
  final String? searchPlaceholder;
  final String? everyoneLabel;
  final String? everyoneDetail;
  final String? emptyText;

  /// Focuses the search field when the picker opens.
  final bool autofocus;

  /// True draws the picker as its own floating card; false fills the surface
  /// that frames it, such as a sheet.
  final bool framed;

  @override
  State<FlareMentionPicker> createState() => _FlareMentionPickerState();
}

class _FlareMentionPickerState extends State<FlareMentionPicker> {
  final TextEditingController _query = TextEditingController();
  final _rowKeys = <String, GlobalKey>{};
  String _lastQuery = '';
  int _active = 0;

  /// The rows the query matches, the everyone row first when it is offered.
  List<FlareMentionCandidate> _results = const [];

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQuery);
  }

  void _onQuery() {
    final text = _query.text;
    if (text == _lastQuery) {
      // Selection or composing moved; the matches did not change.
      return;
    }
    _lastQuery = text;
    // New matches: the first one is highlighted again.
    setState(() => _active = 0);
  }

  @override
  void dispose() {
    _query.removeListener(_onQuery);
    _query.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      final close = widget.onClose;
      if (close == null) return KeyEventResult.ignored;
      close();
      return KeyEventResult.handled;
    }
    // An input-method commit also sends Enter; it confirms the typed letters,
    // not a person.
    if (_query.value.composing.isValid) return KeyEventResult.ignored;
    final count = _results.length;
    if (count == 0) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      final step = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      setState(() => _active = (_active + step + count) % count);
      _revealActive();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyRepeatEvent) return KeyEventResult.handled;
      widget.onSelect?.call(_results[_active.clamp(0, count - 1)]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _revealActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _results.isEmpty) return;
      final row = _rowKeys[_results[_active.clamp(0, _results.length - 1)].id]
          ?.currentContext;
      if (row != null) Scrollable.ensureVisible(row, alignment: 0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final q = _query.text.trim().toLowerCase();
    final filtered = widget.candidates.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          (c.detail?.toLowerCase().contains(q) ?? false);
    }).toList();
    final showEveryone =
        widget.allowEveryone && (q.isEmpty || 'everyone'.contains(q));
    final everyone = FlareMentionCandidate(
      id: '__all__',
      name: widget.everyoneLabel ?? strings.everyone,
      isEveryone: true,
    );
    _results = [if (showEveryone) everyone, ...filtered];
    final active = _results.isEmpty
        ? -1
        : _active.clamp(0, _results.length - 1);

    final picker = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _search(colors, strings),
        Flexible(
          child: (filtered.isEmpty && !showEveryone)
              ? _empty(colors, strings)
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 264),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: FlareSizes.spacingSm,
                    ),
                    children: [
                      for (var i = 0; i < _results.length; i++)
                        _results[i].isEveryone
                            ? _everyoneRow(
                                colors,
                                strings,
                                _results[i],
                                i == active,
                              )
                            : _personRow(colors, _results[i], i == active, i),
                    ],
                  ),
                ),
        ),
      ],
    );
    if (!widget.framed) return picker;
    return Container(
      width: 280,
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
      child: picker,
    );
  }

  Widget _search(FlareColors colors, FlareStrings strings) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingMd,
        vertical: FlareSizes.spacingSm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderPrimary)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: colors.textTertiary),
          const SizedBox(width: FlareSizes.spacingSm),
          Expanded(
            child: Focus(
              onKeyEvent: _onKey,
              child: TextField(
                controller: _query,
                autofocus: widget.autofocus,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeLg,
                ),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: widget.searchPlaceholder ?? strings.searchMembers,
                  hintStyle: TextStyle(
                    color: colors.textTertiary,
                    fontSize: FlareSizes.fontSizeLg,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A pickable row: highlighted when the keyboard points at it, and pointed
  /// at by a hovering mouse.
  Widget _row(
    FlareColors colors,
    FlareMentionCandidate candidate,
    bool highlighted,
    int index,
    Widget child,
  ) {
    return MouseRegion(
      key: _rowKeys.putIfAbsent(candidate.id, GlobalKey.new),
      onHover: (_) {
        if (_active != index) setState(() => _active = index);
      },
      child: Semantics(
        button: true,
        selected: highlighted,
        child: GestureDetector(
          onTap: () => widget.onSelect?.call(candidate),
          behavior: HitTestBehavior.opaque,
          child: ColoredBox(
            color: highlighted ? colors.bgSelected : Colors.transparent,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _everyoneRow(
    FlareColors colors,
    FlareStrings strings,
    FlareMentionCandidate everyone,
    bool highlighted,
  ) {
    final label = everyone.name;
    return _row(
      colors,
      everyone,
      highlighted,
      0,
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd,
          vertical: FlareSizes.spacingSm,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSizeLg,
                    ),
                  ),
                  Text(
                    widget.everyoneDetail ?? strings.notifyEveryone,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: FlareSizes.fontSizeSm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personRow(
    FlareColors colors,
    FlareMentionCandidate c,
    bool highlighted,
    int index,
  ) {
    return _row(
      colors,
      c,
      highlighted,
      index,
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd,
          vertical: FlareSizes.spacingSm,
        ),
        child: Row(
          children: [
            FlareAvatar(
              userId: c.id,
              displayName: c.name,
              avatarUrl: c.avatarUrl,
              size: 32,
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSizeLg,
                    ),
                  ),
                  if (c.detail != null && c.detail!.isNotEmpty)
                    Text(
                      c.detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeSm,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(FlareColors colors, FlareStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: FlareSizes.spacingLg,
      ),
      child: Center(
        child: Text(
          widget.emptyText ?? strings.noMatchingMembers,
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: FlareSizes.fontSizeMd,
          ),
        ),
      ),
    );
  }
}
