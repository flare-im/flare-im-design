import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// Quick phrases — grouped canned replies with optional group tabs and a manage
/// action. Spec: Composer/QuickPhrases (`FlareQuickPhrases`).
class FlareQuickPhrases extends StatefulWidget {
  const FlareQuickPhrases({
    super.key,
    required this.groups,
    this.manageable = false,
    this.onSelect,
    this.onManage,
  });

  final List<FlareQuickPhraseGroup> groups;
  final bool manageable;
  final void Function(String text)? onSelect;
  final VoidCallback? onManage;

  @override
  State<FlareQuickPhrases> createState() => _FlareQuickPhrasesState();
}

class _FlareQuickPhrasesState extends State<FlareQuickPhrases> {
  String? _activeKey;

  @override
  void initState() {
    super.initState();
    _activeKey = widget.groups.isNotEmpty ? widget.groups.first.key : null;
  }

  FlareQuickPhraseGroup? get _active {
    if (widget.groups.isEmpty) return null;
    return widget.groups.firstWhere(
      (g) => g.key == _activeKey,
      orElse: () => widget.groups.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final active = _active;
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
          if (widget.groups.length > 1) _tabs(colors),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                    horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
                children: [
                  for (final p in active?.phrases ?? const <FlareQuickPhrase>[])
                    _phraseRow(colors, p),
                ],
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
          FlareSizes.spacingLg, FlareSizes.spacingSm),
      child: Row(
        children: [
          Icon(Icons.flash_on, size: 18, color: colors.primary),
          const SizedBox(width: FlareSizes.spacingSm),
          Expanded(
            child: Text('Quick phrases',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeLg,
                    fontWeight: FontWeight.w600)),
          ),
          if (widget.manageable)
            GestureDetector(
              onTap: widget.onManage,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 15, color: colors.primary),
                  const SizedBox(width: FlareSizes.spacingXs),
                  Text('Manage',
                      style: TextStyle(color: colors.primary, fontSize: FlareSizes.fontSizeSm)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabs(FlareColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          FlareSizes.spacingLg, 0, FlareSizes.spacingLg, FlareSizes.spacingSm),
      child: Row(
        children: [
          for (final g in widget.groups) _tab(colors, g),
        ],
      ),
    );
  }

  Widget _tab(FlareColors colors, FlareQuickPhraseGroup g) {
    final active = g.key == _activeKey;
    return Padding(
      padding: const EdgeInsets.only(right: FlareSizes.spacingSm),
      child: GestureDetector(
        onTap: () => setState(() => _activeKey = g.key),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? colors.bgSelected : colors.bgSecondary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(g.title,
              style: TextStyle(
                  color: active ? colors.primary : colors.textSecondary,
                  fontSize: FlareSizes.fontSizeSm,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ),
      ),
    );
  }

  Widget _phraseRow(FlareColors colors, FlareQuickPhrase p) {
    return GestureDetector(
      onTap: () => widget.onSelect?.call(p.text),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: FlareSizes.spacingXs),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        ),
        child: Text(p.text,
            style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
      ),
    );
  }
}
