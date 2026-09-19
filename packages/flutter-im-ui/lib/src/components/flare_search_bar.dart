import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

/// Unified search field — the entry to conversation/contact/message search.
/// Spec: General/SearchBar (`FlareSearchBar`).
class FlareSearchBar extends StatefulWidget {
  const FlareSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.loading = false,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.onActivate,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final bool loading;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Entry mode: the bar shows its value or placeholder but takes no text — no
  /// caret, no text focus, no clear button. With [onActivate] the whole bar is
  /// one button (tap, click, Enter or Space), named by the placeholder; without
  /// it the bar is display-only.
  final bool readOnly;
  final VoidCallback? onActivate;

  @override
  State<FlareSearchBar> createState() => _FlareSearchBarState();
}

class _FlareSearchBarState extends State<FlareSearchBar> {
  String get _placeholder =>
      widget.placeholder ?? FlareStrings.of(context).search;
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  bool _own = false;

  @override
  void initState() {
    super.initState();
    _own = widget.controller == null;
    _controller.addListener(_onChange);
  }

  void _onChange() {
    widget.onChanged?.call(_controller.text);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    if (_own) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final readOnly = widget.readOnly;
    final row = Row(
      children: [
        Icon(
          Icons.search_rounded,
          size: FlareSizes.iconSizeMd,
          color: colors.textTertiary,
        ),
        const SizedBox(width: FlareSizes.spacingSm),
        Expanded(
          child: readOnly
              ? Text(
                  _controller.text.isEmpty ? _placeholder : _controller.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _controller.text.isEmpty
                        ? colors.textTertiary
                        : colors.textPrimary,
                    fontSize: FlareSizes.fontSizeLg,
                  ),
                )
              : TextField(
                  controller: _controller,
                  focusNode: widget.focusNode,
                  onSubmitted: widget.onSubmitted,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeLg,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: _placeholder,
                    hintStyle: TextStyle(color: colors.textTertiary),
                  ),
                ),
        ),
        if (widget.loading && !reduceMotion)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (widget.loading)
          Semantics(
            label: FlareStrings.of(context).loading,
            liveRegion: true,
            child: Icon(
              Icons.schedule_outlined,
              size: FlareSizes.iconSizeSm,
              color: colors.textTertiary,
            ),
          )
        else if (_controller.text.isNotEmpty && !readOnly)
          IconButton(
            onPressed: () => _controller.clear(),
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            constraints: const BoxConstraints(
              minWidth: FlareSizes.touchTarget,
              minHeight: FlareSizes.touchTarget,
            ),
            icon: Icon(
              Icons.cancel_outlined,
              size: 18,
              color: colors.textTertiary,
            ),
          ),
      ],
    );
    const padding = EdgeInsets.symmetric(
      horizontal: FlareSizes.spacingMd,
      vertical: FlareSizes.spacingSm,
    );
    final decoration = BoxDecoration(
      color: colors.bgSecondary,
      borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
    );
    final activate = widget.onActivate;
    if (!readOnly || activate == null) {
      return Container(decoration: decoration, padding: padding, child: row);
    }
    return Semantics(
      container: true,
      button: true,
      label: _placeholder,
      onTap: activate,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: decoration,
          child: InkWell(
            onTap: activate,
            borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
            hoverColor: colors.bgHover,
            highlightColor: colors.bgHover,
            focusColor: colors.focusRing,
            child: Padding(
              padding: padding,
              // As a button the bar is a full touch target.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: FlareSizes.touchTarget - padding.vertical,
                ),
                child: row,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
