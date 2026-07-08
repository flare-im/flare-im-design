import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// General text input — single/multi-line, char limit, clearable, disabled.
/// Spec: General/Input (`FlareInput`).
class FlareInput extends StatefulWidget {
  const FlareInput({
    super.key,
    this.controller,
    this.placeholder,
    this.multiline = false,
    this.maxLength,
    this.disabled = false,
    this.clearable = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final bool multiline;
  final int? maxLength;
  final bool disabled;
  final bool clearable;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<FlareInput> createState() => _FlareInputState();
}

class _FlareInputState extends State<FlareInput> {
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
    if (widget.maxLength != null || widget.clearable) setState(() {});
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
    final atLimit = widget.maxLength != null &&
        _controller.text.characters.length >= widget.maxLength!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
            border: Border(bottom: BorderSide(color: colors.primary, width: 2)),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.disabled,
                  minLines: 1,
                  maxLines: widget.multiline ? 6 : 1,
                  maxLength: widget.maxLength,
                  onSubmitted: widget.onSubmitted,
                  buildCounter: (_,
                          {required currentLength, maxLength, required isFocused}) =>
                      null,
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
              if (widget.clearable && _controller.text.isNotEmpty && !widget.disabled)
                GestureDetector(
                  onTap: () => _controller.clear(),
                  child: Icon(Icons.cancel, size: 18, color: colors.textTertiary),
                ),
            ],
          ),
        ),
        if (widget.maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_controller.text.characters.length}/${widget.maxLength}',
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeXs,
                  color: atLimit ? colors.error : colors.textTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
