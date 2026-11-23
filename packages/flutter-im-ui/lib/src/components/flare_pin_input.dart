import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_overlay.dart' show flareReduceMotion;

/// Six PIN cells for a payment password. Spec: Input/PinInput
/// (`FlarePinInput`); docs/plugin-experience.md §5.10.
///
/// Digits only on a number keyboard, drawn as dots, focused on arrival
/// ([autoFocus]); each digit fills the next cell, Backspace clears the last.
/// [onComplete] runs once the sixth digit is in (and on Enter when full).
/// [error] turning on gives the cells the error border, clears the digits
/// ([onChange] with "") and shakes the row once — not under reduced motion.
/// One input lies over the cells, so the whole 52-high row is the touch target
/// and a screen reader hears one field named [label] with how many digits are
/// in, never the digits.
class FlarePinInput extends StatefulWidget {
  const FlarePinInput({
    super.key,
    this.value = '',
    required this.label,
    this.error = false,
    this.disabled = false,
    this.autoFocus = true,
    this.onChange,
    this.onComplete,
  });

  /// How many digits a PIN has.
  static const int length = 6;

  /// The digits typed so far (0–6); a new value from the host replaces them.
  final String value;

  /// The accessible name, such as "支付密码".
  final String label;
  final bool error;

  /// Locked while verifying.
  final bool disabled;
  final bool autoFocus;
  final ValueChanged<String>? onChange;
  final ValueChanged<String>? onComplete;

  /// The filled dot of cell [index] (tests).
  static Key dotKey(int index) => ValueKey('flare-pin-dot-$index');

  @override
  State<FlarePinInput> createState() => _FlarePinInputState();
}

class _FlarePinInputState extends State<FlarePinInput>
    with SingleTickerProviderStateMixin {
  late final _controller = TextEditingController(text: _digits(widget.value));
  final _focus = FocusNode();
  late final _shake = AnimationController(
    vsync: this,
    duration: FlareMotion.spring,
  );

  static const double _cellWidth = FlareSizes.componentPinCellWidth;
  static const double _cellHeight = FlareSizes.componentPinCellHeight;

  /// §12.19: how narrow a cell may get in a narrow panel (320 wide).
  static const double _cellMinWidth = FlareSizes.componentPinCellMinWidth;

  static String _digits(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > FlarePinInput.length
        ? digits.substring(0, FlarePinInput.length)
        : digits;
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void didUpdateWidget(FlarePinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = _digits(widget.value);
    if (widget.value != oldWidget.value && value != _controller.text) {
      _controller.text = value;
    }
    final failed = widget.error && !oldWidget.error;
    // Unlocked after verifying, or told the PIN was wrong: back to typing
    // (a disabled field drops focus, and autoFocus only acts on mount).
    if (widget.autoFocus &&
        (failed || (oldWidget.disabled && !widget.disabled))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.disabled) _focus.requestFocus();
      });
    }
    if (!failed) return;
    if (_controller.text.isNotEmpty) {
      _controller.clear();
      // The host hears it after this build, never during it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChange?.call('');
      });
    }
    if (!flareReduceMotion(context)) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    widget.onChange?.call(value);
    if (value.length == FlarePinInput.length) widget.onComplete?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final count = _controller.text.length;
    final progress = strings.pinInputProgress
        .replaceAll('{label}', widget.label)
        .replaceAll('{count}', '$count');
    final next = math.min(count, FlarePinInput.length - 1);
    // The cells give way to the row (44 → 36) and keep the 8 gap while they
    // can; under 36 the gap takes the squeeze.
    final cells = LayoutBuilder(
      builder: (context, box) {
        const gaps = FlareSizes.spacingSm * (FlarePinInput.length - 1);
        final width = ((box.maxWidth - gaps) / FlarePinInput.length).clamp(
          _cellMinWidth,
          _cellWidth,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < FlarePinInput.length; i++)
              Container(
                width: width,
                height: _cellHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.disabled
                      ? colors.bgPrimary
                      : colors.bgSecondary,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
                  border: Border.all(
                    color: widget.error
                        ? colors.error
                        : _focus.hasFocus && i == next
                        ? colors.borderSelected
                        : colors.borderPrimary,
                  ),
                  // §12.22: the current cell is an input's focus (as Vue is-active).
                  boxShadow: _focus.hasFocus && i == next
                      ? [
                          BoxShadow(
                            color: colors.focusRing,
                            spreadRadius: FlareSizes.componentFocusRingWidth,
                          ),
                        ]
                      : null,
                ),
                child: i < count
                    ? Container(
                        key: FlarePinInput.dotKey(i),
                        width: FlareSizes.spacing2sm,
                        height: FlareSizes.spacing2sm,
                        decoration: BoxDecoration(
                          color: colors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
          ],
        );
      },
    );
    final input = MergeSemantics(
      child: Semantics(
        label: progress,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: widget.autoFocus,
          enabled: !widget.disabled,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(FlarePinInput.length),
          ],
          showCursor: false,
          enableInteractiveSelection: false,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration.collapsed(hintText: null),
          onChanged: _changed,
          onSubmitted: (value) {
            if (value.length == FlarePinInput.length) {
              widget.onComplete?.call(value);
            }
          },
        ),
      ),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth:
              _cellWidth * FlarePinInput.length +
              FlareSizes.spacingSm * (FlarePinInput.length - 1),
        ),
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              math.sin(_shake.value * math.pi * 6) *
                  FlareSizes.spacingSm *
                  (1 - _shake.value),
              0,
            ),
            child: child,
          ),
          child: Stack(
            children: [
              ExcludeSemantics(child: cells),
              // The input lies invisibly over the cells: a tap on any of them
              // focuses it, and it alone speaks.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  alwaysIncludeSemantics: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: input,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
