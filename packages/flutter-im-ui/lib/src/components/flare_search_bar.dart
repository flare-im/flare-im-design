import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import 'flare_icon.dart';
import '../tokens/flare_tokens.dart';

/// Unified search field — the entry to conversation/contact/message search.
/// Spec: General/SearchBar (`FlareSearchBar`).
/// How a [FlareSearchBar] sits on its surface (Vue `appearance`, the same
/// words as [FlareFilterTabsAppearance]).
enum FlareSearchBarAppearance {
  /// A light filled, rounded field.
  filled,

  /// No fill and no rounding: the field reads as part of the list it filters
  /// (a contacts or groups list); the glass, the placeholder and the touch
  /// target stay.
  quiet,
}

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
    this.autofocus = false,
    this.onCancel,
    this.dismissesKeyboardOnOutsideTap = false,
    this.appearance = FlareSearchBarAppearance.filled,
  });

  final FlareSearchBarAppearance appearance;

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

  /// Focus the field when it first appears (a search page opened to type in).
  final bool autofocus;

  /// Dismisses focus on mouse and touch taps outside the search controls.
  final bool dismissesKeyboardOnOutsideTap;

  /// A text「取消」key beside the field (Vue `searchBar.cancel`), for a search
  /// page or panel the bar closes; absent without it.
  final VoidCallback? onCancel;

  @override
  State<FlareSearchBar> createState() => _FlareSearchBarState();
}

class _FlareSearchBarState extends State<FlareSearchBar> {
  String get _placeholder =>
      widget.placeholder ?? FlareStrings.of(context).search;
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  bool _own = false;
  // The field's own edge shows its focus (Vue `.flare-search:focus-within`).
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _own = widget.controller == null;
    _controller.addListener(_onChange);
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void didUpdateWidget(FlareSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  void _onChange() {
    widget.onChanged?.call(_controller.text);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
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
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  onSubmitted: (value) {
                    if (widget.dismissesKeyboardOnOutsideTap) _focus.unfocus();
                    widget.onSubmitted?.call(value);
                  },
                  onTapOutside: widget.dismissesKeyboardOnOutsideTap
                      ? (_) => _focus.unfocus()
                      : null,
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
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.textTertiary,
              backgroundColor: colors.borderPrimary,
            ),
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
            tooltip: FlareStrings.of(context).clear,
            constraints: const BoxConstraints(
              minWidth: FlareSizes.touchTarget,
              minHeight: FlareSizes.touchTarget,
            ),
            icon: FlareIcon(
              'close',
              size: FlareSizes.iconSizeSm,
              color: colors.textTertiary,
            ),
          ),
      ],
    );
    // Vue `.flare-search`: one touch-target-high row; the clear key runs to
    // the field's end edge.
    final clearShown =
        !widget.loading && _controller.text.isNotEmpty && !readOnly;
    final quiet = widget.appearance == FlareSearchBarAppearance.quiet;
    final inset = quiet ? FlareSizes.spacingSm : FlareSizes.spacingMd;
    final padding = EdgeInsetsDirectional.only(
      start: inset,
      end: clearShown ? 0 : inset,
    );
    final decoration = BoxDecoration(
      color: quiet ? Colors.transparent : colors.bgSecondary,
      borderRadius: quiet
          ? BorderRadius.zero
          : BorderRadius.circular(FlareSizes.radiusLg),
      border: Border.all(
        color: !readOnly && _focus.hasFocus
            ? colors.borderSelected
            : Colors.transparent,
      ),
    );
    final activate = widget.onActivate;
    if (!readOnly || activate == null) {
      final field = Container(
        constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
        decoration: decoration,
        padding: padding,
        child: row,
      );
      final cancel = widget.onCancel;
      final search = widget.dismissesKeyboardOnOutsideTap
          ? TextFieldTapRegion(child: field)
          : field;
      if (cancel == null) return search;
      return Row(
        children: [
          Expanded(child: search),
          // Vue `.flare-search__cancel`: a primary-tinted word beside the field.
          TextButton(
            onPressed: cancel,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, FlareSizes.touchTargetMin),
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingSm,
              ),
            ),
            child: Text(
              FlareStrings.of(context).cancel,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: FlareSizes.fontSizeLg,
              ),
            ),
          ),
        ],
      );
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
