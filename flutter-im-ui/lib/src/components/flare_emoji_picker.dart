import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// Emoji picker — a searchable emoji grid with a recents tab, per-category
/// tabs, an optional skin-tone selector, and a bottom category rail. Presents
/// [categories] plus, when non-empty, a synthetic "recent" tab from [recents].
/// Spec: Composer/EmojiPicker (`FlareEmojiPicker`).
class FlareEmojiPicker extends StatefulWidget {
  const FlareEmojiPicker({
    super.key,
    required this.categories,
    this.recents = const [],
    this.skinTones = false,
    this.onSelect,
    this.onToneChange,
  });

  final List<FlareEmojiCategory> categories;
  final List<String> recents;
  final bool skinTones;
  final void Function(String emoji)? onSelect;
  final void Function(String tone)? onToneChange;

  @override
  State<FlareEmojiPicker> createState() => _FlareEmojiPickerState();
}

class _FlareEmojiPickerState extends State<FlareEmojiPicker> {
  static const String _recentKey = '__recent';
  static const List<String> _tones = [
    '',
    '\u{1F3FB}',
    '\u{1F3FC}',
    '\u{1F3FD}',
    '\u{1F3FE}',
    '\u{1F3FF}',
  ];

  final TextEditingController _query = TextEditingController();
  String _tone = '';
  late String _activeKey;

  @override
  void initState() {
    super.initState();
    _activeKey = widget.recents.isNotEmpty
        ? _recentKey
        : (widget.categories.isNotEmpty ? widget.categories.first.key : '');
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<String> _activeEmojis() {
    if (_activeKey == _recentKey) return widget.recents;
    for (final c in widget.categories) {
      if (c.key == _activeKey) return c.emojis;
    }
    return const [];
  }

  List<String> _searchResults(String q) {
    final seen = <String>{};
    final out = <String>[];
    for (final c in widget.categories) {
      for (final e in c.emojis) {
        if (e.contains(q) && seen.add(e)) out.add(e);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final query = _query.text.trim();
    final searching = query.isNotEmpty;
    final emojis = searching ? _searchResults(query) : _activeEmojis();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchRow(colors),
          if (!searching) _tabs(colors),
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: emojis.isEmpty
                ? Center(
                    child: Text('No emoji',
                        style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: FlareSizes.fontSizeSm)),
                  )
                : GridView.count(
                    crossAxisCount: 8,
                    padding: EdgeInsets.zero,
                    children: [
                      for (final e in emojis) _emojiCell(e),
                    ],
                  ),
          ),
          if (!searching) _rail(colors),
        ],
      ),
    );
  }

  Widget _searchRow(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: colors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _query,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: FlareSizes.fontSizeMd),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search emoji',
                hintStyle: TextStyle(
                    color: colors.textTertiary, fontSize: FlareSizes.fontSizeMd),
              ),
            ),
          ),
          if (widget.skinTones) ...[
            const SizedBox(width: 8),
            for (final t in _tones) _toneSwatch(colors, t),
          ],
        ],
      ),
    );
  }

  Widget _toneSwatch(FlareColors colors, String tone) {
    final active = _tone == tone;
    return GestureDetector(
      onTap: () {
        setState(() => _tone = tone);
        widget.onToneChange?.call(tone);
      },
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: active ? colors.bgSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
        ),
        child: Text('✋$tone', style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _tabs(FlareColors colors) {
    final tabs = <_Tab>[
      if (widget.recents.isNotEmpty)
        const _Tab(key: _recentKey, icon: Icons.schedule),
      for (final c in widget.categories)
        _Tab(key: c.key, label: c.label),
    ];
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderPrimary)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final t in tabs) _tabButton(colors, t),
        ],
      ),
    );
  }

  Widget _tabButton(FlareColors colors, _Tab tab) {
    final active = _activeKey == tab.key;
    return GestureDetector(
      onTap: () => setState(() => _activeKey = tab.key),
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: tab.icon != null
            ? Icon(tab.icon,
                size: 16,
                color: active ? colors.primary : colors.textTertiary)
            : Text(
                tab.label ?? '',
                style: TextStyle(
                  color: active ? colors.primary : colors.textSecondary,
                  fontSize: FlareSizes.fontSizeSm,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
      ),
    );
  }

  Widget _emojiCell(String e) {
    return GestureDetector(
      onTap: () => widget.onSelect?.call(_tone.isEmpty ? e : e + _tone),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(e, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  Widget _rail(FlareColors colors) {
    final tabs = <_Tab>[
      if (widget.recents.isNotEmpty)
        const _Tab(key: _recentKey, icon: Icons.schedule),
      for (final c in widget.categories)
        _Tab(
          key: c.key,
          label: c.symbol ??
              (c.emojis.isNotEmpty ? c.emojis.first : c.label),
        ),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderPrimary)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          for (final t in tabs)
            Expanded(child: _railButton(colors, t)),
        ],
      ),
    );
  }

  Widget _railButton(FlareColors colors, _Tab tab) {
    final active = _activeKey == tab.key;
    return GestureDetector(
      onTap: () => setState(() => _activeKey = tab.key),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? colors.bgSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
        ),
        child: tab.icon != null
            ? Icon(tab.icon,
                size: 16,
                color: active ? colors.primary : colors.textTertiary)
            : Text(tab.label ?? '', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _Tab {
  final String key;
  final String? label;
  final IconData? icon;
  const _Tab({required this.key, this.label, this.icon});
}
