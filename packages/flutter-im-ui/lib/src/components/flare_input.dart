import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

/// General text input — single/multi-line, char limit, clearable, disabled.
/// Spec: General/Input (`FlareInput`).
class FlareInput extends StatefulWidget {
  const FlareInput({
    super.key,
    this.controller,
    this.placeholder,
    this.multiline = false,
    this.secure = false,
    this.revealable = false,
    this.maxLength,
    this.disabled = false,
    this.clearable = false,
    this.autofocus = false,
    this.prefix,
    this.monospace = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final bool multiline;

  /// Optional leading widget rendered inside the field (e.g. a search icon).
  final Widget? prefix;

  /// Mask the value (password entry). Mutually exclusive with [multiline].
  final bool secure;

  /// A secure field the person can unmask: the field draws the reveal key itself, named by the kit.
  final bool revealable;
  final int? maxLength;
  final bool disabled;
  final bool clearable;

  /// Request focus when first shown (e.g. the primary field in a dialog).
  final bool autofocus;

  /// Draw the value in the platform's monospaced face (codes, identifiers);
  /// the field's geometry does not change.
  final bool monospace;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<FlareInput> createState() => _FlareInputState();
}

class _FlareInputState extends State<FlareInput> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);
  bool _own = false;
  bool _focused = false;

  /// Unmasking is the person's own, momentary choice: it lives in the field and is never reported.
  bool _revealed = false;

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

  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _focus.removeListener(_onFocus);
    _focus.dispose();
    if (_own) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final atLimit =
        widget.maxLength != null &&
        _controller.text.characters.length >= widget.maxLength!;
    final showClear =
        widget.clearable && _controller.text.isNotEmpty && !widget.disabled;
    final showReveal =
        widget.secure &&
        widget.revealable &&
        !widget.multiline &&
        !widget.disabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
            border: Border.all(
              color: _focused ? colors.borderSelected : colors.borderPrimary,
              width: 1,
            ),
          ),
          // A clearable field is a touch target tall, so its clear control fits
          // inside and the field keeps its size when the control appears.
          padding: widget.clearable
              ? const EdgeInsetsDirectional.only(start: FlareSizes.spacingMd)
              : const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingMd,
                  vertical: FlareSizes.spacingSm,
                ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.clearable ? FlareSizes.touchTarget : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.prefix != null)
                  Padding(
                    padding: const EdgeInsets.only(right: FlareSizes.spacingSm),
                    child: widget.prefix!,
                  ),
                Expanded(
                  child: TextField(
                    obscureText:
                        widget.secure && !widget.multiline && !_revealed,
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    enabled: !widget.disabled,
                    minLines: 1,
                    maxLines: widget.multiline ? 6 : 1,
                    maxLength: widget.maxLength,
                    onSubmitted: widget.onSubmitted,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          maxLength,
                          required isFocused,
                        }) => null,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSizeLg,
                      fontFamily: widget.monospace ? 'monospace' : null,
                      fontFamilyFallback: widget.monospace
                          ? const ['Menlo', 'Roboto Mono', 'Courier New']
                          : null,
                      letterSpacing: widget.monospace ? 1.2 : null,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(color: colors.textTertiary),
                    ),
                  ),
                ),
                if (showClear)
                  FlareIconControl(
                    label: FlareStrings.of(context).clear,
                    onTap: () => _controller.clear(),
                    child: FlareIcon(
                      'close',
                      size: 18,
                      color: colors.textTertiary,
                    ),
                  )
                else if (widget.clearable)
                  const SizedBox(width: FlareSizes.spacingMd),
                if (showReveal)
                  FlareIconControl(
                    label: _revealed
                        ? FlareStrings.of(context).inputHide
                        : FlareStrings.of(context).inputReveal,
                    onTap: () => setState(() => _revealed = !_revealed),
                    child: FlareIcon(
                      _revealed ? 'eye-off' : 'eye',
                      size: 18,
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
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
