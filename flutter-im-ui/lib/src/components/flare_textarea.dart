import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// A multi-line text input — auto-grows from [rows] up to [maxRows] (0 =
/// uncapped), with an optional character counter ([showCount] + [maxlength]) and
/// ⌘/Ctrl+Enter submit. Token-styled (bgSecondary → bgPrimary + focus ring on
/// focus). Custom-built from Flare tokens. Spec: Form/Textarea.
class FlareTextarea extends StatefulWidget {
  const FlareTextarea({
    super.key,
    this.value = '',
    this.placeholder,
    this.size = FlareControlSize.md,
    this.rows = 3,
    this.maxRows = 0,
    this.showCount = false,
    this.maxlength,
    this.disabled = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmit,
  });

  final String value;
  final String? placeholder;
  final FlareControlSize size;

  /// Fixed visible rows before auto-grow kicks in.
  final int rows;

  /// Cap auto-grow at this many rows (0 = uncapped).
  final int maxRows;

  /// Show a character counter; requires [maxlength] for the "n / max" form.
  final bool showCount;
  final int? maxlength;
  final bool disabled;
  final bool autofocus;
  final void Function(String)? onChanged;

  /// Raised on ⌘/Ctrl+Enter (the Vue `enter` event).
  final VoidCallback? onSubmit;

  @override
  State<FlareTextarea> createState() => _FlareTextareaState();
}

class _FlareTextareaState extends State<FlareTextarea> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(FlareTextarea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      final sel = _controller.selection;
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: sel.baseOffset <= widget.value.length
            ? sel
            : TextSelection.collapsed(offset: widget.value.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double get _fontSize => switch (widget.size) {
        FlareControlSize.sm => 13,
        FlareControlSize.md => 14,
        FlareControlSize.lg => 15,
      };

  EdgeInsets get _padding => switch (widget.size) {
        FlareControlSize.sm => const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        FlareControlSize.md => const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        FlareControlSize.lg => const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      final pressed = HardwareKeyboard.instance.logicalKeysPressed;
      final meta = pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight) ||
          pressed.contains(LogicalKeyboardKey.controlLeft) ||
          pressed.contains(LogicalKeyboardKey.controlRight);
      if (meta) {
        widget.onSubmit?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final count = widget.value.runes.length;

    return Opacity(
      opacity: widget.disabled ? 0.55 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _focused ? colors.bgPrimary : colors.bgSecondary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          border: Border.all(
            color: _focused ? colors.primary : colors.borderPrimary,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: colors.focusRing,
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: _padding,
              child: Focus(
                onKeyEvent: _onKey,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !widget.disabled,
                  autofocus: widget.autofocus,
                  minLines: widget.rows,
                  maxLines: widget.maxRows > 0 ? widget.maxRows : null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLength: widget.maxlength,
                  cursorColor: colors.primary,
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: FlareSizes.lineHeightNormal,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      fontSize: _fontSize,
                      color: colors.textTertiary,
                    ),
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ),
            if (widget.showCount)
              Positioned(
                right: 10,
                bottom: 6,
                child: Text(
                  widget.maxlength != null
                      ? '$count / ${widget.maxlength}'
                      : '$count',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
