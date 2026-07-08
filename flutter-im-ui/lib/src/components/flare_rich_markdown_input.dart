import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_markdown_preview.dart';

/// The rich (RichDoc/Markdown) text field with a formatting bar, optional live
/// preview, and length limit. Spec: Composer/RichMarkdownInput
/// (`FlareRichMarkdownInput`). Used inside `FlareComposer`.
class FlareRichMarkdownInput extends StatefulWidget {
  const FlareRichMarkdownInput({
    super.key,
    this.controller,
    this.focusNode,
    this.disabled = false,
    this.formattingPreview = false,
    this.showFormatBar = true,
    this.maxLength,
    this.placeholder,
    this.onChanged,
    this.onSubmit,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool disabled;
  final bool formattingPreview;
  final bool showFormatBar;
  final int? maxLength;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;

  @override
  State<FlareRichMarkdownInput> createState() => _FlareRichMarkdownInputState();
}

class _FlareRichMarkdownInputState extends State<FlareRichMarkdownInput> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _ownController = false;
  bool _ownFocus = false;

  @override
  void initState() {
    super.initState();
    _ownController = widget.controller == null;
    _ownFocus = widget.focusNode == null;
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    widget.onChanged?.call(_controller.text);
    if (widget.formattingPreview || widget.maxLength != null) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownController) _controller.dispose();
    if (_ownFocus) _focus.dispose();
    super.dispose();
  }

  void _wrap(String left, [String? right]) {
    final r = right ?? left;
    final sel = _controller.selection;
    final text = _controller.text;
    if (!sel.isValid) {
      _controller.text = '$text$left$r';
      return;
    }
    final selected = sel.textInside(text);
    final replaced = '$left$selected$r';
    final newText = text.replaceRange(sel.start, sel.end, replaced);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: sel.start + left.length + selected.length),
    );
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final atLimit = widget.maxLength != null &&
        _controller.text.runes.length >= widget.maxLength!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showFormatBar && !widget.disabled) _formatBar(colors),
        TextField(
          controller: _controller,
          focusNode: _focus,
          enabled: !widget.disabled,
          minLines: 1,
          maxLines: 6,
          maxLength: widget.maxLength,
          onSubmitted: widget.onSubmit,
          buildCounter: (_, {required currentLength, maxLength, required isFocused}) =>
              null,
          style: TextStyle(
              color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: widget.placeholder,
            hintStyle: TextStyle(color: colors.textTertiary),
          ),
        ),
        if (widget.maxLength != null)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_controller.text.runes.length}/${widget.maxLength}',
              style: TextStyle(
                color: atLimit ? colors.error : colors.textTertiary,
                fontSize: FlareSizes.fontSizeXs,
              ),
            ),
          ),
        if (widget.formattingPreview && _controller.text.trim().isNotEmpty) ...[
          Divider(color: colors.borderSecondary, height: FlareSizes.spacingMd),
          FlareMarkdownPreview(content: _controller.text),
        ],
      ],
    );
  }

  Widget _formatBar(FlareColors colors) {
    Widget btn(IconData icon, VoidCallback onTap, String tip) => IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          color: colors.textSecondary,
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        );
    return Row(
      children: [
        btn(Icons.format_bold_rounded, () => _wrap('**'), '加粗'),
        btn(Icons.format_italic_rounded, () => _wrap('*'), '斜体'),
        btn(Icons.code_rounded, () => _wrap('`'), '代码'),
        btn(Icons.format_list_bulleted_rounded, () => _wrap('\n- ', ''), '列表'),
        btn(Icons.link_rounded, () => _wrap('[', '](url)'), '链接'),
      ],
    );
  }
}
