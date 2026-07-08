import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Unified search field — the entry to conversation/contact/message search.
/// Spec: General/SearchBar (`FlareSearchBar`).
class FlareSearchBar extends StatefulWidget {
  const FlareSearchBar({
    super.key,
    this.controller,
    this.placeholder = '搜索',
    this.loading = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String placeholder;
  final bool loading;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<FlareSearchBar> createState() => _FlareSearchBarState();
}

class _FlareSearchBarState extends State<FlareSearchBar> {
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
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: colors.textTertiary),
          const SizedBox(width: FlareSizes.spacingSm),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: TextStyle(color: colors.textTertiary),
              ),
            ),
          ),
          if (widget.loading)
            const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          else if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () => _controller.clear(),
              child: Icon(Icons.cancel, size: 18, color: colors.textTertiary),
            ),
        ],
      ),
    );
  }
}
